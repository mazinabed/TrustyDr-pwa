import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_health_profile.dart';

/// Stream of the signed-in patient's health profile document.
/// Emits null when the document does not exist yet.
/// Empty uid guard prevents reads before auth is established.
final healthProfileProvider = StreamProvider.autoDispose
    .family<PatientHealthProfile?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('patient_health_profiles')
      .doc(uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return PatientHealthProfile.fromFirestore(snap.data()!);
  });
});
