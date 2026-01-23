import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createWeeklySchedule({
    required String doctorId,
    required String province,
    required String city,
    required String clinicName,
  }) async {
    try {
      final daysOfWeek = {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      };

      final now = DateTime.now().toUtc().toIso8601String();

      final batch = _firestore.batch();

      for (var i = 1; i <= 7; i++) {
        final docRef = _firestore.collection('schedules').doc();

        batch.set(docRef, {
          'doctorId': doctorId,
          'dayOfWeek': i,
          'dayName': daysOfWeek[i],
          'startTime': '09:00',
          'endTime': '17:00',
          'slotDurationMinutes': 30,
          'capacityPerSlot': 5,
          'status': 'clinic',
          'province': province,
          'city': city,
          'clinicName': clinicName,
          'createdAt': now,
          'updatedAt': now,
        });
      }

      await batch.commit();
      print('✅ Weekly schedule created for doctor: $doctorId');
    } catch (e) {
      print('❌ Error creating schedule: $e');
    }
  }
}
