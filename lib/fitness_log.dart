import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FitnessLog {
  final int? id;
  final DateTime date;
  final String content;

  FitnessLog({this.id, required this.date, required this.content});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': _dateOnly(date), // 存 yyyy-MM-dd
      'content': content,
    };
  }

  factory FitnessLog.fromMap(Map<String, dynamic> map) {
    return FitnessLog(
      id: map['id'],
      date: DateTime.parse(map['date']),
      content: map['content'],
    );
  }

  static String _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).toIso8601String().split("T")[0];
  }
}

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

  /// 插入一条日志
  static Future<int> insertLog(FitnessLog log) async {
    final db = await database;
    return await db.insert('logs', log.toMap());
  }

  /// 获取某一天的日志
  static Future<List<FitnessLog>> getLogsByDate(DateTime date) async {
    final db = await database;
    final dateStr = FitnessLog._dateOnly(date);
    final result = await db.query(
      'logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return result.map((e) => FitnessLog.fromMap(e)).toList();
  }

  /// 获取所有日志（用于日历打点显示）
  static Future<List<FitnessLog>> getAllLogs() async {
    final db = await database;
    final result = await db.query('logs');
    return result.map((e) => FitnessLog.fromMap(e)).toList();
  }
}