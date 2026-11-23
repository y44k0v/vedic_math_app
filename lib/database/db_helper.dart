import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/vedic_models.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

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
      version: 1,
      onCreate: (db, version) async {
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
  }

  Future<void> saveSessionResult(SessionRecord record) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('session_history', record.toMap());

      final existing = await txn.query(
        'item_progress',
        where: 'item_id = ?',
        whereArgs: [record.itemId],
      );

      if (existing.isEmpty) {
        await txn.insert('item_progress', {
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
          where: 'item_id = ?',
          whereArgs: [record.itemId],
        );
      }
    });
  }

  Future<List<SessionRecord>> getSessionHistory() async {
    final db = await database;
    final rows = await db.query('session_history', orderBy: 'completed_at ASC');
    return rows.map((row) => SessionRecord.fromMap(row)).toList();
  }

  Future<Map<String, Map<String, dynamic>>> getAllItemProgress() async {
    final db = await database;
    final rows = await db.query('item_progress');
    return {for (final row in rows) row['item_id'] as String: row};
  }

  Future<int> getTotalScore() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(score), 0) AS total FROM session_history',
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
