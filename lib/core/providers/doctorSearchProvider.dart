import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_location_provider.dart';

final doctorSearchProvider = FutureProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>(
  (ref, query) async {
    final location = ref.watch(appLocationProvider);

    // 🔒 HARD GUARDS
    if (location == null ||
        location.cityEn == null ||
        location.cityEn!.isEmpty ||
        location.provinceKey == null ||
        location.provinceKey!.isEmpty ||
        query.trim().length < 3) {
      return [];
    }

    final q = query.toLowerCase().trim();
    final end = '$q\uf8ff';

    final fs = FirebaseFirestore.instance;

    // 🔍 search by name
    final nameSnap = await fs
        .collection('public_doctors')
        .where('status', isEqualTo: 'active')
        .where('province_key', isEqualTo: location.provinceKey)
        .where('city_en', isEqualTo: location.cityEn)
        .where('name_lower', isGreaterThanOrEqualTo: q)
        .where('name_lower', isLessThan: end)
        .limit(10)
        .get();

    // 🔍 search by specialty
    final specialtySnap = await fs
        .collection('public_doctors')
        .where('status', isEqualTo: 'active')
        .where('province_key', isEqualTo: location.provinceKey)
        .where('city_en', isEqualTo: location.cityEn)
        .where('specialty_lower', isGreaterThanOrEqualTo: q)
        .where('specialty_lower', isLessThan: end)
        .limit(10)
        .get();

    // 🔗 merge & dedupe
    final seen = <String>{};
    final results = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final snap in [nameSnap, specialtySnap]) {
      for (final doc in snap.docs) {
        if (seen.add(doc.id)) {
          results.add(doc);
        }
      }
    }

    return results;
  },
);
