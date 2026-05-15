import 'package:flutter/foundation.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String patientId;
  final String patientName;
  final String date;
  final String time;
  final String appointmentType;
  final String status;
  final String? notes;
  final String? doctorAvatarUrl;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.appointmentType,
    required this.status,
    this.notes,
    this.doctorAvatarUrl,
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      doctorId: data['doctorId'] as String? ?? 'Unknown ID',
      doctorName: data['doctorName'] as String? ?? 'Unknown Doctor',
      specialty: data['specialty'] as String? ?? 'General',
      patientId: data['patientId'] as String? ?? 'Unknown Patient ID',
      patientName: data['patientName'] as String? ?? 'Self',
      date: data['date'] as String? ?? 'N/A',
      time: data['time'] as String? ?? 'N/A',
      appointmentType: data['appointmentType'] as String? ?? 'Consultation',
      status: data['status'] as String? ?? 'pending',
      notes: data['notes'] as String?,
      doctorAvatarUrl: data['doctorAvatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'patientId': patientId,
      'patientName': patientName,
      'date': date,
      'time': time,
      'appointmentType': appointmentType,
      'status': status,
      'notes': notes,
      'doctorAvatarUrl': doctorAvatarUrl,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    if (kDebugMode) {
      return 'Appointment(id: $id, doctor: $doctorName, patient: $patientName, date: $date)';
    }
    return super.toString();
  }
}
