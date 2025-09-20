import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'fitness_log_databass.dart';

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
  Set<DateTime> _doneDays = {};

  @override
  void initState() {
    super.initState();
    _loadAllDays();
  }

  Future<void> _loadAllDays() async {
    final days = await FitnessDayDatabase.getAllDays();
    setState(() {
      _doneDays = days
          .where((d) => d.done)
          .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
          .toSet();
    });
  }

  bool _isDone(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _doneDays.contains(key);
  }

  Future<void> _handleDayTap(DateTime selectedDay, DateTime focusedDay) async {
    if (_selectedDay != null && isSameDay(_selectedDay, selectedDay)) {
      // 再次点击同一天 → 切换打勾
      await FitnessDayDatabase.toggleDay(selectedDay);
      await _loadAllDays();
    } else {
      // 第一次点击 → 切换选中日期
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("健身日历")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isMarked = _isDone(day);
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text("${day.day}"),
                      if (isMarked)
                        Positioned(
                          bottom: 2,
                          child: Icon(Icons.check, size: 14, color: Colors.green),
                        ),
                    ],
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final isMarked = _isDone(day);
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text("${day.day}", style: TextStyle(color: Colors.white)),
                      if (isMarked)
                        Positioned(
                          bottom: 2,
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                    ],
                  ),
                );
              },
            ),
            onDaySelected: _handleDayTap,
          ),
          Expanded(
            child: Center(
              child: Text(
                _selectedDay == null
                    ? "请选择日期"
                    : (_isDone(_selectedDay!)
                    ? "${_selectedDay!.toLocal()} ✅ 已健身"
                    : "${_selectedDay!.toLocal()} ❌ 未健身"),
              ),
            ),
          )
        ],
      ),
    );
  }
}