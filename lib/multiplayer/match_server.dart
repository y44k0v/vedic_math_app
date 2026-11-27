import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../database/db_helper.dart';
import '../engine/exercise_generator.dart';
import '../models/multiplayer_models.dart';
import '../models/vedic_models.dart';

class _ClientSession {
  final WebSocket socket;
  String? playerUuid;
  final List<int> rttSamplesUs = [];
  final Map<int, int> pendingPingsUs = {};
  int pingSeq = 0;

  _ClientSession(this.socket);

  /// Conservative half-RTT estimate: minimum clean sample / 2, capped at 250ms
  /// so a client cannot intentionally delay pongs to gain unfair advantage.
  int get clampedHalfRttUs {
    if (rttSamplesUs.isEmpty) return 0;
    final bestRtt = rttSamplesUs.reduce(min);
    return min(bestRtt ~/ 2, 250000);
  }

  int get estimatedLatencyMs {
    if (rttSamplesUs.isEmpty) return 0;
    return (rttSamplesUs.reduce(min) / 1000).round();
  }
}

class _CorrectSubmission {
  final String playerUuid;
  final String playerName;
  final int adjustedArrivalUs;

  _CorrectSubmission({
    required this.playerUuid,
    required this.playerName,
    required this.adjustedArrivalUs,
  });
}

class MatchServer {
  static const int defaultPort = 8080;
  static const Duration _graceWindow = Duration(milliseconds: 250);

  final Stopwatch _clock = Stopwatch()..start();
  HttpServer? _httpServer;
  Timer? _pingTimer;
  Timer? _graceTimer;
  Timer? _advanceTimer;

  late String matchId;
  late String hostIp;
  int port = defaultPort;
  late String itemId;
  late String itemTitle;
  MatchStatus status = MatchStatus.lobby;
  int currentQuestionIndex = 0;
  late List<MathProblem> _problems;

  final Map<String, CompetitorScore> _competitors = {};
  final Set<_ClientSession> _sessions = {};
  final List<_CorrectSubmission> _roundWinnersBuffer = [];
  bool _roundResolved = false;

  Future<String> getLocalWifiIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback &&
            (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.'))) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<MatchSnapshot> startNewMatch({
    required VedicItem item,
    required Player hostPlayer,
    int totalQuestions = 25,
    int port = defaultPort,
  }) async {
    await stop();
    final rng = Random.secure();
    matchId = 'VM-${1000 + rng.nextInt(9000)}';
    this.port = port;
    hostIp = await getLocalWifiIp();
    itemId = item.id;
    itemTitle = item.sanskritName;
    status = MatchStatus.lobby;
    currentQuestionIndex = 0;
    _problems = ExerciseGenerator().generateSession(
      item.id,
      count: totalQuestions,
    );

    _competitors.clear();
    _competitors[hostPlayer.uuid] = CompetitorScore(
      playerUuid: hostPlayer.uuid,
      playerName: hostPlayer.name,
      score: 0,
      correctWins: 0,
      latencyMs: 0,
      isConnected: true,
    );

    await _bindAndServe();
    final snap = _buildSnapshot();
    await DatabaseHelper.instance.upsertMatchSnapshot(
      snap,
      hostProblems: _problems,
    );
    return snap;
  }

  Future<MatchSnapshot?> resumeHostMatch(MatchSnapshot saved) async {
    final loadedProblems = await DatabaseHelper.instance.loadHostProblems(
      saved.matchId,
    );
    if (loadedProblems == null || loadedProblems.isEmpty) return null;

    await stop();
    matchId = saved.matchId;
    port = saved.port;
    hostIp = await getLocalWifiIp();
    itemId = saved.itemId;
    itemTitle = saved.itemTitle;
    status = saved.status;
    currentQuestionIndex = saved.currentQuestionIndex;
    _problems = loadedProblems;

    _competitors.clear();
    for (final c in saved.competitors) {
      _competitors[c.playerUuid] = c.copyWith(isConnected: false);
    }

    await _bindAndServe();
    final snap = _buildSnapshot();
    await DatabaseHelper.instance.upsertMatchSnapshot(snap);
    return snap;
  }

  Future<void> _bindAndServe() async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _httpServer!.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final ws = await WebSocketTransformer.upgrade(request);
        _attachSocket(ws);
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('Vedic Math Match Server ($matchId)')
          ..close();
      }
    });

    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      for (final s in _sessions) {
        final seq = ++s.pingSeq;
        s.pendingPingsUs[seq] = _clock.elapsedMicroseconds;
        _send(s.socket, {
          'type': 'ping',
          'seq': seq,
          'serverClockUs': _clock.elapsedMicroseconds,
        });
      }
    });
  }

  void _attachSocket(WebSocket ws) {
    final session = _ClientSession(ws);
    _sessions.add(session);

    ws.listen(
      (raw) => _handleMessage(session, raw),
      onDone: () => _handleDisconnect(session),
      onError: (_) => _handleDisconnect(session),
    );
  }

  void _handleDisconnect(_ClientSession session) {
    _sessions.remove(session);
    final uuid = session.playerUuid;
    if (uuid != null && _competitors.containsKey(uuid)) {
      _competitors[uuid] = _competitors[uuid]!.copyWith(isConnected: false);
      _broadcastSync();
    }
  }

  Future<void> _handleMessage(_ClientSession session, dynamic raw) async {
    final arrivalUs = _clock.elapsedMicroseconds;
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (msg['type']) {
      case 'pong':
        final seq = msg['seq'] as int?;
        if (seq != null && session.pendingPingsUs.containsKey(seq)) {
          final sentUs = session.pendingPingsUs.remove(seq)!;
          final rttUs = arrivalUs - sentUs;
          session.rttSamplesUs.add(rttUs);
          if (session.rttSamplesUs.length > 6) {
            session.rttSamplesUs.removeAt(0);
          }
          final uuid = session.playerUuid;
          if (uuid != null && _competitors.containsKey(uuid)) {
            _competitors[uuid] = _competitors[uuid]!.copyWith(
              latencyMs: session.estimatedLatencyMs,
            );
          }
        }
        break;

      case 'join':
      case 'rejoin':
        final reqMatchId = (msg['matchId'] as String? ?? '')
            .trim()
            .toUpperCase();
        if (reqMatchId != matchId) {
          _send(session.socket, {
            'type': 'error',
            'message': 'Match ID "$reqMatchId" not found on this host.',
          });
          return;
        }

        final uuid = msg['playerUuid'] as String;
        final name = (msg['playerName'] as String).trim();
        session.playerUuid = uuid;

        final existing = _competitors[uuid];
        if (existing != null) {
          _competitors[uuid] = existing.copyWith(
            playerName: name,
            isConnected: true,
            latencyMs: session.estimatedLatencyMs,
          );
        } else {
          _competitors[uuid] = CompetitorScore(
            playerUuid: uuid,
            playerName: name,
            score: 0,
            correctWins: 0,
            latencyMs: session.estimatedLatencyMs,
            isConnected: true,
          );
        }
        await _broadcastSync();
        break;

      case 'start_match':
        if (status == MatchStatus.lobby) {
          status = MatchStatus.inProgress;
          currentQuestionIndex = 0;
          _roundResolved = false;
          _roundWinnersBuffer.clear();
          await _broadcastSync();
        }
        break;

      case 'submit_answer':
        if (status != MatchStatus.inProgress || _roundResolved) return;
        final qIdx = msg['questionIndex'] as int?;
        if (qIdx != currentQuestionIndex) return; // Reject stale submissions

        final uuid = session.playerUuid;
        if (uuid == null || !_competitors.containsKey(uuid)) return;

        final p1 = (msg['primary'] as String? ?? '').trim();
        final p2 = (msg['secondary'] as String?)?.trim();
        final problem = _problems[currentQuestionIndex];

        final bool isCorrect = switch (problem.answerType) {
          AnswerType.integer ||
          AnswerType.booleanYesNo => p1 == problem.primaryAnswer,
          AnswerType.quotientRemainder || AnswerType.pairXY =>
            p1 == problem.primaryAnswer &&
                p2 == (problem.secondaryAnswer ?? ''),
        };

        if (!isCorrect) {
          _send(session.socket, {
            'type': 'answer_feedback',
            'questionIndex': qIdx,
            'correct': false,
          });
          return;
        }

        // Fair latency adjustment using clamped half-RTT
        final adjustedArrivalUs = arrivalUs - session.clampedHalfRttUs;
        final alreadySubmitted = _roundWinnersBuffer.any(
          (s) => s.playerUuid == uuid,
        );
        if (!alreadySubmitted) {
          _roundWinnersBuffer.add(
            _CorrectSubmission(
              playerUuid: uuid,
              playerName: _competitors[uuid]!.playerName,
              adjustedArrivalUs: adjustedArrivalUs,
            ),
          );
        }

        _send(session.socket, {
          'type': 'answer_feedback',
          'questionIndex': qIdx,
          'correct': true,
        });

        // Start 250ms grace window on the first correct answer
        _graceTimer ??= Timer(_graceWindow, _resolveCurrentRound);
        break;
    }
  }

  Future<void> _resolveCurrentRound() async {
    _graceTimer = null;
    if (_roundResolved || _roundWinnersBuffer.isEmpty) return;
    _roundResolved = true;

    _roundWinnersBuffer.sort(
      (a, b) => a.adjustedArrivalUs.compareTo(b.adjustedArrivalUs),
    );
    final winner = _roundWinnersBuffer.first;

    final prev = _competitors[winner.playerUuid]!;
    _competitors[winner.playerUuid] = prev.copyWith(
      score: prev.score + 10,
      correctWins: prev.correctWins + 1,
    );

    final solvedProblem = _problems[currentQuestionIndex];
    final ansText = solvedProblem.secondaryAnswer != null
        ? '${solvedProblem.primaryAnswer}, ${solvedProblem.secondaryAnswer}'
        : solvedProblem.primaryAnswer;

    await _broadcastSync(
      lastWinner: winner.playerName,
      lastAnswer: ansText,
      lastSolution: solvedProblem.solutionSteps,
    );

    // Show round winner & solution briefly, then advance
    _advanceTimer = Timer(const Duration(seconds: 2), () async {
      _roundWinnersBuffer.clear();
      if (currentQuestionIndex + 1 >= _problems.length) {
        status = MatchStatus.finished;
      } else {
        currentQuestionIndex++;
        _roundResolved = false;
      }
      await _broadcastSync();
    });
  }

  MatchSnapshot _buildSnapshot({
    String? lastWinner,
    String? lastAnswer,
    String? lastSolution,
  }) {
    final sorted = _competitors.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final publicQ = status == MatchStatus.inProgress
        ? PublicQuestion(
            index: currentQuestionIndex,
            prompt: _problems[currentQuestionIndex].prompt,
            answerType: _problems[currentQuestionIndex].answerType,
            hint: _problems[currentQuestionIndex].hint,
          )
        : null;

    return MatchSnapshot(
      matchId: matchId,
      hostIp: hostIp,
      port: port,
      itemId: itemId,
      itemTitle: itemTitle,
      isHost: true,
      status: status,
      currentQuestionIndex: currentQuestionIndex,
      totalQuestions: _problems.length,
      currentQuestion: publicQ,
      competitors: sorted,
      lastRoundWinnerName: lastWinner,
      lastRoundAnswer: lastAnswer,
      lastRoundSolution: lastSolution,
    );
  }

  Future<void> _broadcastSync({
    String? lastWinner,
    String? lastAnswer,
    String? lastSolution,
  }) async {
    final snap = _buildSnapshot(
      lastWinner: lastWinner,
      lastAnswer: lastAnswer,
      lastSolution: lastSolution,
    );
    await DatabaseHelper.instance.upsertMatchSnapshot(snap);

    final payload = {
      'type': 'match_sync',
      'matchId': snap.matchId,
      'itemId': snap.itemId,
      'itemTitle': snap.itemTitle,
      'status': snap.status.name,
      'currentQuestionIndex': snap.currentQuestionIndex,
      'totalQuestions': snap.totalQuestions,
      'currentQuestion': snap.currentQuestion?.toJson(),
      'competitors': snap.competitors.map((c) => c.toJson()).toList(),
      'lastRoundWinnerName': lastWinner,
      'lastRoundAnswer': lastAnswer,
      'lastRoundSolution': lastSolution,
    };

    for (final s in _sessions) {
      _send(s.socket, payload);
    }
  }

  void _send(WebSocket socket, Map<String, dynamic> data) {
    if (socket.readyState == WebSocket.open) {
      socket.add(jsonEncode(data));
    }
  }

  Future<void> stop() async {
    _pingTimer?.cancel();
    _graceTimer?.cancel();
    _advanceTimer?.cancel();
    for (final s in _sessions) {
      await s.socket.close();
    }
    _sessions.clear();
    await _httpServer?.close(force: true);
    _httpServer = null;
  }
}
