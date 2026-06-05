import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_health_profile.dart';

class HealthProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates or updates the patient health profile.
  /// Pass [exists] = true when the document already exists in Firestore.
  Future<void> save(PatientHealthProfile profile,
      {required bool exists}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final docRef = FirebaseFirestore.instance
          .collection('patient_health_profiles')
          .doc(profile.patientId);
      if (exists) {
        await docRef.update(profile.toUpdateMap());
      } else {
        await docRef.set(profile.toCreateMap());
      }
    });
  }
}

final healthProfileControllerProvider =
    AsyncNotifierProvider<HealthProfileController, void>(
  HealthProfileController.new,
);
