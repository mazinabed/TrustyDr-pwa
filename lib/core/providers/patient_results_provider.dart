import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_result.dart';

final patientResultsProvider =
    StreamProvider.autoDispose<List<PatientResult>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.empty();

  return FirebaseFirestore.instance
      .collection('clinical_requests')
      .where('patientId', isEqualTo: user.uid)
      .where('patientReleaseStatus', isEqualTo: 'released')
      .orderBy('releasedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(PatientResult.fromDoc).toList());
});

final patientResultAttachmentsProvider = StreamProvider.autoDispose
    .family<List<PatientAttachment>, String>((ref, requestId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.empty();

  return FirebaseFirestore.instance
      .collection('clinical_requests')
      .doc(requestId)
      .collection('attachments')
      .where('patientVisible', isEqualTo: true)
      .where('isDeleted', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.map(PatientAttachment.fromDoc).toList());
});
