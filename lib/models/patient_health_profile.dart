import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps to patient_health_profiles/{patientId}.
///
/// One document per patient. All clinical fields are optional — the profile is
/// recommended but never required to complete a booking.
///
/// Immutable after creation: patientId, schemaVersion
/// Mutable: all other fields (patient may update at any time)
class PatientHealthProfile {
  final String patientId;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final List<String>? currentMedications;
  final int schemaVersion;

  const PatientHealthProfile({
    required this.patientId,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.currentMedications,
    this.schemaVersion = 1,
  });

  factory PatientHealthProfile.fromFirestore(Map<String, dynamic> data) {
    final dob = data['dateOfBirth'];
    return PatientHealthProfile(
      patientId: (data['patientId'] as String?) ?? '',
      dateOfBirth: dob is Timestamp ? dob.toDate() : null,
      gender: data['gender'] as String?,
      bloodType: data['bloodType'] as String?,
      allergies: _toStringList(data['allergies']),
      chronicConditions: _toStringList(data['chronicConditions']),
      currentMedications: _toStringList(data['currentMedications']),
      schemaVersion: (data['schemaVersion'] as int?) ?? 1,
    );
  }

  /// Full write map for initial document creation (includes patientId + schemaVersion).
  Map<String, dynamic> toCreateMap() {
    return {
      'patientId': patientId,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    };
  }

  /// Partial write map for subsequent updates — mutable fields only.
  Map<String, dynamic> toUpdateMap() {
    return {
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<String>? _toStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }
}
