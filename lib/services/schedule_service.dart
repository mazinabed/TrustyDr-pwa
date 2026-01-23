import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> getDoctorSchedules(
      String doctorId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'clinic')
        .get();

    return snapshot.docs.map((d) => d.data()).toList();
  }

  static Future<Map<String, List<String>>> buildMonthlyCalendar({
    required String doctorId,
    required int year,
    required int month,
  }) async {
    final schedules = await getDoctorSchedules(doctorId);
    final result = <String, List<String>>{};

    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final weekday = date.weekday;

      final match = schedules.firstWhere(
        (s) => s['dayOfWeek'] == weekday,
        orElse: () => {},
      );

      if (match.isEmpty) continue;

      final start = _parseTime(match['startTime']);
      final end = _parseTime(match['endTime']);
      final duration = match['slotDurationMinutes'] ?? 30;

      final slots = <String>[];
      DateTime current = start;
      while (current.isBefore(end)) {
        final hour = current.hour > 12 ? current.hour - 12 : current.hour;
        final minute = current.minute.toString().padLeft(2, '0');
        final amPm = current.hour >= 12 ? 'PM' : 'AM';
        slots.add('$hour:$minute $amPm');
        current = current.add(Duration(minutes: duration));
      }

      result[date.toIso8601String()] = slots;
    }

    return result;
  }

  static DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(0, 0, 0, hour, minute);
  }
}
