import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_location_provider.dart';
import '../utils/doctor_search_utils.dart';

final doctorSearchProvider = FutureProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>(
  (ref, query) async {
    final location = ref.watch(appLocationProvider);

    final stripped = stripDoctorTitles(query);

    if (location == null ||
        location.cityEn.isEmpty ||
        location.provinceKey.isEmpty ||
        stripped.trim().length < 3) {
      return [];
    }

    final q = stripped.trim().toLowerCase();
    final end = q + String.fromCharCode(0xF8FF);
    final field = nameSearchField(q);

    final snap = await FirebaseFirestore.instance
        .collection('public_doctors')
        .where('status', isEqualTo: 'active')
        .where('province_key', isEqualTo: location.provinceKey)
        .where('city_en', isEqualTo: location.cityEn)
        .where(field, isGreaterThanOrEqualTo: q)
        .where(field, isLessThan: end)
        .limit(10)
        .get();

    return snap.docs;
  },
);
