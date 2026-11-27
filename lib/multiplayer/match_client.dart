import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../database/db_helper.dart';
import '../models/multiplayer_models.dart';
import '../models/vedic_models.dart';

class MatchClient extends ChangeNotifier {
  final Player localPlayer;
  final String hostIp;
  final int port;
  final String matchId;
  final bool isHost;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool isConnected = false;
  String? errorMessage;
  String? feedbackMessage;
  bool? lastAnswerWasCorrect;

  MatchSnapshot? snapshot;

  MatchClient({
    required this.localPlayer,
    required this.hostIp,
    required this.port,
    required this.matchId,
    required this.isHost,
    MatchSnapshot? initialSnapshot,
  }) : snapshot = initialSnapshot;

  Future<void> connect() async {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    try {
      final ws = await WebSocket.connect('ws://$hostIp:$port')
          .timeout(const Duration(seconds: 4));
      if (_disposed) {
        await ws.close();
        return;
      }

      _socket = ws;
      isConnected = true;
      errorMessage = null;
      notifyListeners();

      // Send join/rejoin immediately
      _send({
        'type': 'rejoin',
        'matchId': matchId,
        'playerUuid': localPlayer.uuid,
        'playerName': localPlayer.name,
      });

      ws.listen(
        _onMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      isConnected = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    isConnected = false;
    _socket = null;
    notifyListeners();

    if (snapshot?.status == MatchStatus.finished) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), connect);
  }

  Future<void> _onMessage(dynamic raw) async {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (msg['type']) {
      case 'ping':
        // Echo immediately so server measures true RTT
        _send({'type': 'pong', 'seq': msg['seq']});
        break;

      case 'error':
        errorMessage = msg['message'] as String?;
        notifyListeners();
        break;

      case 'answer_feedback':
        final qIdx = msg['questionIndex'] as int?;
        if (qIdx == snapshot?.currentQuestionIndex) {
          final ok = msg['correct'] as bool;
          lastAnswerWasCorrect = ok;
          feedbackMessage = ok
              ? 'Correct! Verifying fastest arrival...'
              : 'Incorrect — try again!';
          notifyListeners();
        }
        break;

      case 'match_sync':
        final qJson = msg['currentQuestion'] as Map<String, dynamic>?;
        final newStatus = MatchStatus.values.byName(msg['status'] as String);
        final newIdx = msg['currentQuestionIndex'] as int;

        if (snapshot?.currentQuestionIndex != newIdx ||
            msg['lastRoundWinnerName'] != null) {
          feedbackMessage = null;
          lastAnswerWasCorrect = null;
        }

        final updated = MatchSnapshot(
          matchId: msg['matchId'] as String,
          hostIp: hostIp,
          port: port,
          itemId: msg['itemId'] as String,
          itemTitle: msg['itemTitle'] as String,
          isHost: isHost,
          status: newStatus,
          currentQuestionIndex: newIdx,
          totalQuestions: msg['totalQuestions'] as int,
          currentQuestion: qJson != null
              ? PublicQuestion.fromJson(qJson)
              : null,
          competitors: (msg['competitors'] as List<dynamic>)
              .map((e) => CompetitorScore.fromJson(e as Map<String, dynamic>))
              .toList(),
          lastRoundWinnerName: msg['lastRoundWinnerName'] as String?,
          lastRoundAnswer: msg['lastRoundAnswer'] as String?,
          lastRoundSolution: msg['lastRoundSolution'] as String?,
          recordedInHistory: snapshot?.recordedInHistory ?? false,
        );

        snapshot = updated;
        await DatabaseHelper.instance.upsertMatchSnapshot(updated);

        // Record local player's final score into solo/overall SQLite progress once
        if (updated.status == MatchStatus.finished &&
            !updated.recordedInHistory &&
            localPlayer.id != null) {
          final me = updated.competitors.where(
            (c) => c.playerUuid == localPlayer.uuid,
          );
          if (me.isNotEmpty) {
            await DatabaseHelper.instance.saveSessionResult(
              SessionRecord(
                playerId: localPlayer.id!,
                itemId: updated.itemId,
                itemTitle: '${updated.itemTitle} (MP)',
                score: me.first.score,
                correctCount: me.first.correctWins,
                totalQuestions: updated.totalQuestions,
                durationSeconds: 0,
                completedAt: DateTime.now(),
              ),
            );
            await DatabaseHelper.instance.markMatchRecordedInHistory(
              updated.matchId,
            );
            snapshot = updated.copyWith(recordedInHistory: true);
          }
        }

        notifyListeners();
        break;
    }
  }

  void startMatch() => _send({'type': 'start_match'});

  void submitAnswer({required String primary, String? secondary}) {
    final q = snapshot?.currentQuestion;
    if (q == null) return;
    _send({
      'type': 'submit_answer',
      'questionIndex': q.index,
      'primary': primary,
      'secondary': secondary,
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(data));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _socket?.close();
    super.dispose();
  }
}
