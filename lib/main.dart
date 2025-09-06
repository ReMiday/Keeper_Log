import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'fitness_log.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: FitnessCalendarPage(),
    );
  }
}


class FitnessCalendarPage extends StatefulWidget {
  @override
  _FitnessCalendarPageState createState() => _FitnessCalendarPageState();
}

class _FitnessCalendarPageState extends State<FitnessCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<FitnessLog>> _events = {}; // 数据库的缓存

  @override
  void initState() {
    super.initState();
    _loadAllLogs();
  }

  Future<void> _loadAllLogs() async {
    final logs = await FitnessLogDatabase.getAllLogs();
    setState(() {
      _events.clear();
      for (var log in logs) {
        final key = DateTime(log.date.year, log.date.month, log.date.day);
        if (_events[key] == null) _events[key] = [];
        _events[key]!.add(log);
      }
    });
  }

  List<FitnessLog> _getLogsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("健身日志")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getLogsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showAddLogDialog(selectedDay);
            },
          ),
          Expanded(
            child: FutureBuilder<List<FitnessLog>>(
              future: FitnessLogDatabase.getLogsByDate(_selectedDay ?? DateTime.now()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: Text("暂无记录"));
                final logs = snapshot.data!;
                if (logs.isEmpty) return Center(child: Text("这一天没有记录"));
                return ListView(
                  children: logs.map((log) => ListTile(title: Text(log.content))).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLogDialog(DateTime day) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("添加健身日志"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "今天做了什么训练？"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              final log = FitnessLog(date: day, content: controller.text);
              await FitnessLogDatabase.insertLog(log);
              await _loadAllLogs();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("保存"),
          ),
        ],
      ),
    );
  }
}