import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_appointment_item.dart';

// ── Doctor appointments ──────────────────────────────────────────────────────
// All statuses, no whereIn — client-side tab filtering avoids multiple active
// subscriptions and keeps index requirements minimal.
final patientDoctorAppointmentsProvider =
    StreamProvider.autoDispose<List<PatientAppointmentItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('appointments')
      .where('patientId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) =>
              PatientAppointmentItem.fromAppointment(doc.data(), doc.id))
          .toList());
});

// ── Lab / imaging appointments ───────────────────────────────────────────────
// Patient-self-booked scheduled diagnostic requests only.
// The three where clauses match the Firestore rule exactly — all three are
// required for the list query to pass the allow read condition.
final patientLabAppointmentsProvider =
    StreamProvider.autoDispose<List<PatientAppointmentItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('clinical_requests')
      .where('patientId', isEqualTo: user.uid)
      .where('source', isEqualTo: 'scheduled')
      .where('createdByRole', isEqualTo: 'patient')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) =>
              PatientAppointmentItem.fromLabRequest(doc.data(), doc.id))
          .toList());
});

// ── Unified provider ─────────────────────────────────────────────────────────
// Merges both sources and sorts chronologically ascending.
//
// Loading strategy: shows doctor appointments as soon as they arrive (lab items
// default to [] while the second stream is loading) so the home card and
// appointments page never block on the slower stream.
final patientAllAppointmentsProvider =
    Provider.autoDispose<AsyncValue<List<PatientAppointmentItem>>>((ref) {
  final doctor = ref.watch(patientDoctorAppointmentsProvider);
  final lab = ref.watch(patientLabAppointmentsProvider);

  // Block until the primary (doctor) stream is ready.
  if (doctor.isLoading) return const AsyncLoading();
  if (doctor.hasError) return AsyncError(doctor.error!, doctor.stackTrace!);

  // Lab stream still loading → emit doctor items immediately (progressive).
  final labItems = lab.asData?.value ?? [];

  final merged = [...doctor.value!, ...labItems]
    ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
  return AsyncData(merged);
});
