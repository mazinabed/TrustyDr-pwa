import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';


final centersProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final location = ref.watch(appLocationProvider);

  if (location == null) {
    return const Stream.empty();
  }

  return firestore
      .collection('medical_centers')
      .where('tenantType', isEqualTo: 'center')
      .where('doctorCount', isGreaterThan: 0)
      .where('subscriptionStatus', isEqualTo: 'active')
      .where('provinceKey', isEqualTo: location.provinceKey)
      .where('city_en', isEqualTo: location.cityEn)
      .orderBy('doctorCount', descending: true)
      .snapshots();
});