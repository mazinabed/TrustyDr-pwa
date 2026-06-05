import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/models/patient_health_profile.dart';

/// Embedded sub-map written into appointments/{appointmentId}.patientHealthSnapshot
/// at booking time — self-bookings only (null for family/relative bookings).
///
/// dateOfBirth is NOT stored here. Only ageAtAppointment (calculated from DOB
/// at booking time) is stored, reducing sensitive data copied per appointment.
///
/// Immutable after the appointment is created — reflects what was known at booking.
class PatientHealthSnapshot {
  final int? ageAtAppointment;
  final String? gender;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final List<String>? currentMedications;
  final int schemaVersion;

  const PatientHealthSnapshot({
    this.ageAtAppointment,
    this.gender,
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.currentMedications,
    this.schemaVersion = 1,
  });

  /// Build from a PatientHealthProfile at a given appointment date.
  ///
  /// Returns null if the profile contains no clinical data worth snapshotting.
  /// Called only for self-bookings (relationship == null).
  static PatientHealthSnapshot? fromProfile(
    PatientHealthProfile profile,
    DateTime appointmentDate,
  ) {
    final age = profile.dateOfBirth != null
        ? _calculateAge(profile.dateOfBirth!, appointmentDate)
        : null;

    final hasData = age != null ||
        profile.gender != null ||
        profile.bloodType != null ||
        (profile.allergies?.isNotEmpty ?? false) ||
        (profile.chronicConditions?.isNotEmpty ?? false) ||
        (profile.currentMedications?.isNotEmpty ?? false);

    if (!hasData) return null;

    return PatientHealthSnapshot(
      ageAtAppointment: age,
      gender: profile.gender,
      bloodType: profile.bloodType,
      allergies: profile.allergies,
      chronicConditions: profile.chronicConditions,
      currentMedications: profile.currentMedications,
    );
  }

  /// Read from the patientHealthSnapshot sub-map in an appointment document.
  /// Used by the doctor portal to deserialize the embedded snapshot.
  static PatientHealthSnapshot? fromAppointmentMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return PatientHealthSnapshot(
      ageAtAppointment: (data['ageAtAppointment'] as num?)?.toInt(),
      gender: data['gender'] as String?,
      bloodType: data['bloodType'] as String?,
      allergies: _toStringList(data['allergies']),
      chronicConditions: _toStringList(data['chronicConditions']),
      currentMedications: _toStringList(data['currentMedications']),
      schemaVersion: (data['schemaVersion'] as int?) ?? 1,
    );
  }

  /// Write map for embedding inside the appointment document at booking time.
  Map<String, dynamic> toMap() {
    return {
      'ageAtAppointment': ageAtAppointment,
      'gender': gender,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'snapshotAt': FieldValue.serverTimestamp(),
      'schemaVersion': schemaVersion,
    };
  }

  static int _calculateAge(DateTime dob, DateTime referenceDate) {
    int age = referenceDate.year - dob.year;
    if (referenceDate.month < dob.month ||
        (referenceDate.month == dob.month && referenceDate.day < dob.day)) {
      age--;
    }
    return age;
  }

  static List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }
}
