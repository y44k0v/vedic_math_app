import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vedic_math_app/database/db_helper.dart';
import 'package:vedic_math_app/engine/exercise_generator.dart';
import 'package:vedic_math_app/models/multiplayer_models.dart';
import 'package:vedic_math_app/models/vedic_models.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vedic_db_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    await DatabaseHelper.instance.resetForTesting();
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Player CRUD & Active Selection', () {
    test('Empty database returns null active player', () async {
      expect(await DatabaseHelper.instance.getActivePlayer(), isNull);
      expect(await DatabaseHelper.instance.getAllPlayers(), isEmpty);
    });

    test('Create, read, switch, update, and cascade delete players', () async {
      final p1 = await DatabaseHelper.instance.createPlayer('Aarav');
      final p2 = await DatabaseHelper.instance.createPlayer(
        'Maya',
        setActive: true,
      );

      expect(p1.uuid, isNotEmpty);
      expect(p2.uuid, isNot(p1.uuid));
      expect((await DatabaseHelper.instance.getActivePlayer())!.id, p2.id);

      // Update name
      await DatabaseHelper.instance.updatePlayerName(p1.id!, 'Aarav S.');
      final all = await DatabaseHelper.instance.getAllPlayers();
      expect(all.first.name, 'Aarav S.');

      // Save score for p2 and verify isolation from p1
      await DatabaseHelper.instance.saveSessionResult(
        SessionRecord(
          playerId: p2.id!,
          itemId: 's1',
          itemTitle: 'Ekadhikena Purvena',
          score: 210,
          correctCount: 21,
          totalQuestions: 25,
          durationSeconds: 45,
          completedAt: DateTime(2026, 11, 26),
        ),
      );

      expect(await DatabaseHelper.instance.getTotalScore(p2.id!), 210);
      expect(await DatabaseHelper.instance.getTotalScore(p1.id!), 0);

      // Delete active p2 -> cascades scores and activates p1
      await DatabaseHelper.instance.deletePlayer(p2.id!);
      final newActive = await DatabaseHelper.instance.getActivePlayer();
      expect(newActive?.id, p1.id);
      expect(await DatabaseHelper.instance.getSessionHistory(p2.id!), isEmpty);

      // Delete final player -> returns null
      await DatabaseHelper.instance.deletePlayer(p1.id!);
      expect(await DatabaseHelper.instance.getActivePlayer(), isNull);
    });
  });

  group('Schema Migration v1 -> v3', () {
    test('Preserves existing v1 scores under default Player 1', () async {
      final dbPath = p.join(tempDir.path, 'vedic_math_progress.db');
      final v1Db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE session_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id TEXT NOT NULL,
              item_title TEXT NOT NULL,
              score INTEGER NOT NULL,
              correct_count INTEGER NOT NULL,
              total_questions INTEGER NOT NULL,
              duration_seconds INTEGER NOT NULL,
              completed_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE item_progress (
              item_id TEXT PRIMARY KEY,
              best_score INTEGER NOT NULL,
              attempts INTEGER NOT NULL,
              last_completed_at TEXT NOT NULL
            )
          ''');
        },
      );

      await v1Db.insert('session_history', {
        'item_id': 's1',
        'item_title': 'Ekadhikena Purvena',
        'score': 240,
        'correct_count': 24,
        'total_questions': 25,
        'duration_seconds': 30,
        'completed_at': '2026-11-20T10:00:00.000',
      });
      await v1Db.insert('item_progress', {
        'item_id': 's1',
        'best_score': 240,
        'attempts': 1,
        'last_completed_at': '2026-11-20T10:00:00.000',
      });
      await v1Db.close();

      // Opening through DatabaseHelper triggers v1 -> v3 upgrade
      final active = await DatabaseHelper.instance.getActivePlayer();
      expect(active, isNotNull);
      expect(active!.name, 'Player 1');
      expect(await DatabaseHelper.instance.getTotalScore(active.id!), 240);

      final progress = await DatabaseHelper.instance.getAllItemProgress(
        active.id!,
      );
      expect(progress['s1']?['best_score'], 240);
    });
  });

  group('Multiplayer Snapshot & Host Problem Persistence', () {
    test('Saves, resumes, and finishes multiplayer matches cleanly', () async {
      final problems = ExerciseGenerator().generateSession('s1', count: 5);
      final snap = MatchSnapshot(
        matchId: 'VM-7777',
        hostIp: '192.168.1.50',
        port: 8080,
        itemId: 's1',
        itemTitle: 'Ekadhikena Purvena',
        isHost: true,
        status: MatchStatus.inProgress,
        currentQuestionIndex: 2,
        totalQuestions: 5,
        currentQuestion: PublicQuestion(
          index: 2,
          prompt: problems[2].prompt,
          answerType: problems[2].answerType,
          hint: problems[2].hint,
        ),
        competitors: const [
          CompetitorScore(
            playerUuid: 'u1',
            playerName: 'Host',
            score: 20,
            correctWins: 2,
            latencyMs: 0,
            isConnected: true,
          ),
          CompetitorScore(
            playerUuid: 'u2',
            playerName: 'Guest',
            score: 10,
            correctWins: 1,
            latencyMs: 14,
            isConnected: true,
          ),
        ],
      );

      await DatabaseHelper.instance.upsertMatchSnapshot(
        snap,
        hostProblems: problems,
      );

      final resumable = await DatabaseHelper.instance.getLatestResumableMatch();
      expect(resumable, isNotNull);
      expect(resumable!.matchId, 'VM-7777');
      expect(resumable.currentQuestionIndex, 2);
      expect(resumable.competitors.length, 2);

      final loadedProblems = await DatabaseHelper.instance.loadHostProblems(
        'VM-7777',
      );
      expect(loadedProblems?.length, 5);
      expect(loadedProblems![2].primaryAnswer, problems[2].primaryAnswer);

      // Mark finished -> no longer appears as resumable
      await DatabaseHelper.instance.upsertMatchSnapshot(
        snap.copyWith(status: MatchStatus.finished, clearQuestion: true),
      );
      expect(await DatabaseHelper.instance.getLatestResumableMatch(), isNull);
      final recent = await DatabaseHelper.instance
          .getRecentMultiplayerMatches();
      expect(recent.length, 1);
    });
  });
}
