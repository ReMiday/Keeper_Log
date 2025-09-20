import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FitnessDay {
  final int? id;
  final DateTime date;
  final bool done;

  FitnessDay({this.id, required this.date, required this.done});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': _dateOnly(date),
      'done': done ? 1 : 0,
    };
  }

  factory FitnessDay.fromMap(Map<String, dynamic> map) {
    return FitnessDay(
      id: map['id'],
      date: DateTime.parse(map['date']),
      done: map['done'] == 1,
    );
  }

  static String _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).toIso8601String().split("T")[0];
  }
}

class FitnessDayDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('fitness_days.db');
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
          CREATE TABLE days(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            done INTEGER
          )
        ''');
      },
    );
  }

  /// 切换打勾状态（如果没有就插入，有就更新）
  static Future<void> toggleDay(DateTime date) async {
    final db = await database;
    final dateStr = FitnessDay._dateOnly(date);

    final result = await db.query("days", where: "date = ?", whereArgs: [dateStr]);
    if (result.isEmpty) {
      await db.insert("days", {"date": dateStr, "done": 1});
    } else {
      final current = result.first["done"] == 1;
      await db.update(
        "days",
        {"done": current ? 0 : 1},
        where: "date = ?",
        whereArgs: [dateStr],
      );
    }
  }

  /// 获取所有已健身日期
  static Future<List<FitnessDay>> getAllDays() async {
    final db = await database;
    final result = await db.query("days");
    return result.map((e) => FitnessDay.fromMap(e)).toList();
  }
}