import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarTimeline extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  final Color? activeBackgroundColor;
  final Color? activeTextColor;
  final Color? dayNameColor;

  const CalendarTimeline({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.activeBackgroundColor,
    this.activeTextColor,
    this.dayNameColor,
  });

  @override
  State<CalendarTimeline> createState() => _CalendarTimelineState();
}

class _CalendarTimelineState extends State<CalendarTimeline> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final activeBg =
        widget.activeBackgroundColor ?? Theme.of(context).colorScheme.primary;
    final activeFg = widget.activeTextColor ?? Colors.white;

    return TableCalendar(
      firstDay: DateTime.utc(
          widget.firstDate.year, widget.firstDate.month, widget.firstDate.day),
      lastDay: DateTime.utc(
          widget.lastDate.year, widget.lastDate.month, widget.lastDate.day),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.week,
      headerVisible: true,
      daysOfWeekVisible: true,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        widget.onDateSelected(selectedDay);
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: activeBg.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: activeBg,
          shape: BoxShape.circle,
        ),
        selectedTextStyle:
            TextStyle(color: activeFg, fontWeight: FontWeight.w600),
        weekendTextStyle: const TextStyle(color: Colors.redAccent),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: widget.dayNameColor ?? Colors.grey[600]),
        weekendStyle: TextStyle(color: widget.dayNameColor ?? Colors.grey[600]),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}
