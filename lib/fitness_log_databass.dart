import 'package:keeper/fitness_log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FitnessLogDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('fitness_logs.db');
    return _db!;
  }

  static Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            content TEXT
          )
        ''');
      },
    );
  }

  static Future<int> insertLog(FitnessLog log) async {
    final db = await database;
    return await db.insert('logs', log.toMap());
  }

  static Future<List<FitnessLog>> getLogsByDate(DateTime date) async {
    final db = await database;
    final result = await db.query(
      'logs',
      where: 'date = ?',
      whereArgs: [date.toIso8601String().split("T")[0]], // 精确到日期
    );
    return result.map((e) => FitnessLog.fromMap(e)).toList();
  }
}