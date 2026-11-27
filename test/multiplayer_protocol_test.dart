import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vedic_math_app/data/vedic_catalog.dart';
import 'package:vedic_math_app/database/db_helper.dart';
import 'package:vedic_math_app/models/multiplayer_models.dart';
import 'package:vedic_math_app/models/vedic_models.dart';
import 'package:vedic_math_app/multiplayer/match_client.dart';
import 'package:vedic_math_app/multiplayer/match_server.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vedic_mp_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    await DatabaseHelper.instance.resetForTesting();
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> waitUntil(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for condition');
      }
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }

  test(
    'Full multiplayer lifecycle: join, wrong/correct answer, rejoin & finish',
    () async {
      final hostPlayer = await DatabaseHelper.instance.createPlayer('Host');
      final guestPlayer = await DatabaseHelper.instance.createPlayer(
        'Guest',
        setActive: false,
      );

      final server = MatchServer(
        graceWindow: const Duration(milliseconds: 80),
        advanceDelay: const Duration(milliseconds: 80),
      );

      final initialSnap = await server.startNewMatch(
        item: vedicCatalog.first, // s1: Ekadhikena
        hostPlayer: hostPlayer,
        totalQuestions: 2,
        port: 0, // Ephemeral free port
      );

      final hostClient = MatchClient(
        localPlayer: hostPlayer,
        hostIp: '127.0.0.1',
        port: server.port,
        matchId: initialSnap.matchId,
        isHost: true,
        initialSnapshot: initialSnap,
      );

      final guestClient = MatchClient(
        localPlayer: guestPlayer,
        hostIp: '127.0.0.1',
        port: server.port,
        matchId: initialSnap.matchId,
        isHost: false,
      );

      await hostClient.connect();
      await guestClient.connect();

      await waitUntil(
        () => (hostClient.snapshot?.competitors.length ?? 0) == 2,
      );
      expect(guestClient.snapshot?.status, MatchStatus.lobby);

      // Start match
      hostClient.startMatch();
      await waitUntil(
        () => guestClient.snapshot?.status == MatchStatus.inProgress,
      );

      // Load exact problems from host DB to craft right/wrong answers in test
      final problems = await DatabaseHelper.instance.loadHostProblems(
        initialSnap.matchId,
      );
      expect(problems?.length, 2);

      // Wrong answer rejected
      guestClient.submitAnswer(primary: '9999999');
      await waitUntil(() => guestClient.lastAnswerWasCorrect == false);
      expect(guestClient.snapshot?.currentQuestionIndex, 0);

      // Guest answers Q0 correctly -> wins round + advances to Q1
      guestClient.submitAnswer(primary: problems![0].primaryAnswer);
      await waitUntil(() => guestClient.snapshot?.currentQuestionIndex == 1);

      final guestAfterQ0 = guestClient.snapshot!.competitors.firstWhere(
        (c) => c.playerUuid == guestPlayer.uuid,
      );
      expect(guestAfterQ0.score, 10);
      expect(guestAfterQ0.correctWins, 1);

      // Simulate guest disconnect & rejoin by matchId
      guestClient.dispose();
      await waitUntil(() {
        final g = hostClient.snapshot!.competitors.firstWhere(
          (c) => c.playerUuid == guestPlayer.uuid,
        );
        return !g.isConnected;
      });

      final rejoinedGuest = MatchClient(
        localPlayer: guestPlayer,
        hostIp: '127.0.0.1',
        port: server.port,
        matchId: initialSnap.matchId,
        isHost: false,
      );
      await rejoinedGuest.connect();
      await waitUntil(() => rejoinedGuest.snapshot?.currentQuestionIndex == 1);

      final restoredScore = rejoinedGuest.snapshot!.competitors
          .firstWhere((c) => c.playerUuid == guestPlayer.uuid)
          .score;
      expect(restoredScore, 10);

      // Host wins Q1 -> match finishes
      hostClient.submitAnswer(primary: problems[1].primaryAnswer);
      await waitUntil(
        () => hostClient.snapshot?.status == MatchStatus.finished,
      );
      await waitUntil(
        () => rejoinedGuest.snapshot?.status == MatchStatus.finished,
      );

      // Invalid match ID rejected
      final badClient = MatchClient(
        localPlayer: guestPlayer,
        hostIp: '127.0.0.1',
        port: server.port,
        matchId: 'VM-0000',
        isHost: false,
      );
      await badClient.connect();
      await waitUntil(() => badClient.errorMessage != null);
      expect(badClient.errorMessage, contains('not found'));

      badClient.dispose();
      rejoinedGuest.dispose();
      hostClient.dispose();
      await server.stop();
    },
  );
}
