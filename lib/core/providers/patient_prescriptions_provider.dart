import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_referral_request.dart';

final patientPrescriptionsProvider =
    StreamProvider.autoDispose<List<PatientReferralRequest>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.empty();

  return FirebaseFirestore.instance
      .collection('patient_referral_requests')
      .where('patientId', isEqualTo: user.uid)
      .where('serviceGroup', isEqualTo: 'pharmacy')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => PatientReferralRequest.fromMap(doc.id, doc.data()))
            .toList(),
      );
});
