import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'dart:convert';

import '../models/vedic_models.dart';
import '../models/multiplayer_models.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _uuid = Uuid();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vedic_math_progress.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV2Tables(db);
        await _createV3Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
        if (oldVersion < 3) {
          await _createV3Tables(db);
        }
      },
    );
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE session_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        item_id TEXT NOT NULL,
        item_title TEXT NOT NULL,
        score INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE item_progress (
        player_id INTEGER NOT NULL,
        item_id TEXT NOT NULL,
        best_score INTEGER NOT NULL,
        attempts INTEGER NOT NULL,
        last_completed_at TEXT NOT NULL,
        PRIMARY KEY (player_id, item_id),
        FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE players (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      // Preserve any v1 scores under a default Player 1
      final defaultPlayerId = await txn.insert('players', {
        'uuid': _uuid.v4(),
        'name': 'Player 1',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      await txn.execute('''
        CREATE TABLE session_history_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          player_id INTEGER NOT NULL,
          item_id TEXT NOT NULL,
          item_title TEXT NOT NULL,
          score INTEGER NOT NULL,
          correct_count INTEGER NOT NULL,
          total_questions INTEGER NOT NULL,
          duration_seconds INTEGER NOT NULL,
          completed_at TEXT NOT NULL,
          FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
        )
      ''');

      await txn.execute('''
        INSERT INTO session_history_new
          (id, player_id, item_id, item_title, score, correct_count, total_questions, duration_seconds, completed_at)
        SELECT id, $defaultPlayerId, item_id, item_title, score, correct_count, total_questions, duration_seconds, completed_at
        FROM session_history
      ''');
      await txn.execute('DROP TABLE session_history');
      await txn.execute(
        'ALTER TABLE session_history_new RENAME TO session_history',
      );

      await txn.execute('''
        CREATE TABLE item_progress_new (
          player_id INTEGER NOT NULL,
          item_id TEXT NOT NULL,
          best_score INTEGER NOT NULL,
          attempts INTEGER NOT NULL,
          last_completed_at TEXT NOT NULL,
          PRIMARY KEY (player_id, item_id),
          FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
        )
      ''');

      await txn.execute('''
        INSERT INTO item_progress_new
          (player_id, item_id, best_score, attempts, last_completed_at)
        SELECT $defaultPlayerId, item_id, best_score, attempts, last_completed_at
        FROM item_progress
      ''');
      await txn.execute('DROP TABLE item_progress');
      await txn.execute(
        'ALTER TABLE item_progress_new RENAME TO item_progress',
      );
    });
  }

  // ========================
  // PLAYER CRUD OPERATIONS
  // ========================

  Future<Player> createPlayer(String name, {bool setActive = true}) async {
    final db = await database;
    final cleanName = name.trim();
    final newUuid = _uuid.v4();
    final now = DateTime.now();

    late int newId;
    await db.transaction((txn) async {
      if (setActive) {
        await txn.update('players', {'is_active': 0});
      }
      newId = await txn.insert('players', {
        'uuid': newUuid,
        'name': cleanName,
        'is_active': setActive ? 1 : 0,
        'created_at': now.toIso8601String(),
      });
    });

    return Player(
      id: newId,
      uuid: newUuid,
      name: cleanName,
      isActive: setActive,
      createdAt: now,
    );
  }

  Future<List<Player>> getAllPlayers() async {
    final db = await database;
    final rows = await db.query('players', orderBy: 'created_at ASC');
    return rows.map((row) => Player.fromMap(row)).toList();
  }

  Future<Player?> getActivePlayer() async {
    final db = await database;
    final activeRows = await db.query(
      'players',
      where: 'is_active = 1',
      limit: 1,
    );
    if (activeRows.isNotEmpty) {
      return Player.fromMap(activeRows.first);
    }

    final anyRows = await db.query('players', orderBy: 'id ASC', limit: 1);
    if (anyRows.isNotEmpty) {
      final first = Player.fromMap(anyRows.first);
      await setActivePlayer(first.id!);
      return Player(
        id: first.id,
        uuid: first.uuid,
        name: first.name,
        isActive: true,
        createdAt: first.createdAt,
      );
    }
    return null;
  }

  Future<void> setActivePlayer(int playerId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('players', {'is_active': 0});
      await txn.update(
        'players',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [playerId],
      );
    });
  }

  Future<void> updatePlayerName(int playerId, String newName) async {
    final db = await database;
    await db.update(
      'players',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [playerId],
    );
  }

  Future<void> deletePlayer(int playerId) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'players',
        where: 'id = ?',
        whereArgs: [playerId],
      );
      final wasActive =
          rows.isNotEmpty && (rows.first['is_active'] as int) == 1;

      await txn.delete('players', where: 'id = ?', whereArgs: [playerId]);

      if (wasActive) {
        final remaining = await txn.query(
          'players',
          orderBy: 'id ASC',
          limit: 1,
        );
        if (remaining.isNotEmpty) {
          await txn.update(
            'players',
            {'is_active': 1},
            where: 'id = ?',
            whereArgs: [remaining.first['id']],
          );
        }
      }
    });
  }

  // ========================
  // PLAYER-SCOPED SCORES
  // ========================

  Future<void> saveSessionResult(SessionRecord record) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('session_history', record.toMap());

      final existing = await txn.query(
        'item_progress',
        where: 'player_id = ? AND item_id = ?',
        whereArgs: [record.playerId, record.itemId],
      );

      if (existing.isEmpty) {
        await txn.insert('item_progress', {
          'player_id': record.playerId,
          'item_id': record.itemId,
          'best_score': record.score,
          'attempts': 1,
          'last_completed_at': record.completedAt.toIso8601String(),
        });
      } else {
        final prevBest = existing.first['best_score'] as int;
        final prevAttempts = existing.first['attempts'] as int;
        await txn.update(
          'item_progress',
          {
            'best_score': record.score > prevBest ? record.score : prevBest,
            'attempts': prevAttempts + 1,
            'last_completed_at': record.completedAt.toIso8601String(),
          },
          where: 'player_id = ? AND item_id = ?',
          whereArgs: [record.playerId, record.itemId],
        );
      }
    });
  }

  Future<List<SessionRecord>> getSessionHistory(int playerId) async {
    final db = await database;
    final rows = await db.query(
      'session_history',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'completed_at ASC',
    );
    return rows.map((row) => SessionRecord.fromMap(row)).toList();
  }

  Future<Map<String, Map<String, dynamic>>> getAllItemProgress(
    int playerId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'item_progress',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
    return {for (final row in rows) row['item_id'] as String: row};
  }

  Future<int> getTotalScore(int playerId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(score), 0) AS total FROM session_history WHERE player_id = ?',
      [playerId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Map<int, int>> getAllPlayersTotalScores() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT player_id, COALESCE(SUM(score), 0) AS total FROM session_history GROUP BY player_id',
    );
    return {
      for (final row in rows) row['player_id'] as int: row['total'] as int,
    };
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS multiplayer_matches (
        match_id TEXT PRIMARY KEY,
        host_ip TEXT NOT NULL,
        port INTEGER NOT NULL,
        item_id TEXT NOT NULL,
        item_title TEXT NOT NULL,
        is_host INTEGER NOT NULL,
        status TEXT NOT NULL,
        current_question_index INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        current_question_json TEXT,
        problems_json TEXT,
        recorded_in_history INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS multiplayer_participants (
        match_id TEXT NOT NULL,
        player_uuid TEXT NOT NULL,
        player_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        correct_wins INTEGER NOT NULL,
        latency_ms INTEGER NOT NULL DEFAULT 0,
        is_connected INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (match_id, player_uuid),
        FOREIGN KEY (match_id) REFERENCES multiplayer_matches (match_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> upsertMatchSnapshot(
    MatchSnapshot snapshot, {
    List<MathProblem>? hostProblems,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'multiplayer_matches',
        columns: ['problems_json', 'recorded_in_history'],
        where: 'match_id = ?',
        whereArgs: [snapshot.matchId],
      );

      final existingProblemsJson = existing.isNotEmpty
          ? existing.first['problems_json'] as String?
          : null;
      final existingRecorded = existing.isNotEmpty
          ? ((existing.first['recorded_in_history'] as int) == 1)
          : false;

      await txn.insert('multiplayer_matches', {
        'match_id': snapshot.matchId,
        'host_ip': snapshot.hostIp,
        'port': snapshot.port,
        'item_id': snapshot.itemId,
        'item_title': snapshot.itemTitle,
        'is_host': snapshot.isHost ? 1 : 0,
        'status': snapshot.status.name,
        'current_question_index': snapshot.currentQuestionIndex,
        'total_questions': snapshot.totalQuestions,
        'current_question_json': snapshot.currentQuestion != null
            ? jsonEncode(snapshot.currentQuestion!.toJson())
            : null,
        'problems_json': hostProblems != null
            ? jsonEncode(hostProblems.map((p) => p.toJson()).toList())
            : existingProblemsJson,
        'recorded_in_history': (snapshot.recordedInHistory || existingRecorded)
            ? 1
            : 0,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'multiplayer_participants',
        where: 'match_id = ?',
        whereArgs: [snapshot.matchId],
      );

      for (final c in snapshot.competitors) {
        await txn.insert('multiplayer_participants', {
          'match_id': snapshot.matchId,
          'player_uuid': c.playerUuid,
          'player_name': c.playerName,
          'score': c.score,
          'correct_wins': c.correctWins,
          'latency_ms': c.latencyMs,
          'is_connected': c.isConnected ? 1 : 0,
        });
      }
    });
  }

  Future<MatchSnapshot?> getLatestResumableMatch() async {
    final db = await database;
    final rows = await db.query(
      'multiplayer_matches',
      where: 'status != ?',
      whereArgs: [MatchStatus.finished.name],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrateMatchRow(db, rows.first);
  }

  Future<List<MatchSnapshot>> getRecentMultiplayerMatches() async {
    final db = await database;
    final rows = await db.query(
      'multiplayer_matches',
      orderBy: 'updated_at DESC',
      limit: 15,
    );
    final List<MatchSnapshot> list = [];
    for (final row in rows) {
      list.add(await _hydrateMatchRow(db, row));
    }
    return list;
  }

  Future<List<MathProblem>?> loadHostProblems(String matchId) async {
    final db = await database;
    final rows = await db.query(
      'multiplayer_matches',
      columns: ['problems_json'],
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['problems_json'] as String?;
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MathProblem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markMatchRecordedInHistory(String matchId) async {
    final db = await database;
    await db.update(
      'multiplayer_matches',
      {'recorded_in_history': 1},
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
  }

  Future<MatchSnapshot> _hydrateMatchRow(
    Database db,
    Map<String, dynamic> row,
  ) async {
    final matchId = row['match_id'] as String;
    final compRows = await db.query(
      'multiplayer_participants',
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'score DESC, correct_wins DESC',
    );
    final qRaw = row['current_question_json'] as String?;
    return MatchSnapshot(
      matchId: matchId,
      hostIp: row['host_ip'] as String,
      port: row['port'] as int,
      itemId: row['item_id'] as String,
      itemTitle: row['item_title'] as String,
      isHost: (row['is_host'] as int) == 1,
      status: MatchStatus.values.byName(row['status'] as String),
      currentQuestionIndex: row['current_question_index'] as int,
      totalQuestions: row['total_questions'] as int,
      currentQuestion: qRaw != null
          ? PublicQuestion.fromJson(jsonDecode(qRaw) as Map<String, dynamic>)
          : null,
      competitors: compRows
          .map(
            (c) => CompetitorScore(
              playerUuid: c['player_uuid'] as String,
              playerName: c['player_name'] as String,
              score: c['score'] as int,
              correctWins: c['correct_wins'] as int,
              latencyMs: c['latency_ms'] as int,
              isConnected: (c['is_connected'] as int) == 1,
            ),
          )
          .toList(),
      recordedInHistory: (row['recorded_in_history'] as int) == 1,
    );
  }
}
