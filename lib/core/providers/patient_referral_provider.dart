import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_referral_request.dart';

/// Streams a single patient_referral_requests document.
/// Returns null when the doc doesn't exist or patientId doesn't match the
/// current user (defence-in-depth — Firestore rules are the primary guard).
final patientReferralProvider = StreamProvider.autoDispose
    .family<PatientReferralRequest?, String>((ref, referralId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('patient_referral_requests')
      .doc(referralId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final data = snap.data()!;
    if ((data['patientId'] ?? '') != user.uid) return null;
    return PatientReferralRequest.fromMap(snap.id, data);
  });
});
