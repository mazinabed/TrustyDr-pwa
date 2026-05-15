import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_location_provider.dart';

// /// ===============================
// /// Doctors (REGISTERED)
// /// ===============================
// final doctorsStreamProvider = StreamProvider.autoDispose<
//     List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
//   final location = ref.watch(appLocationProvider);

//   // 🔒 HARD GUARD — NO CITY = NO READS
//   if (location == null || location.cityEn == null || location.cityEn!.isEmpty) {
//     return const Stream.empty();
//   }

//   Query<Map<String, dynamic>> q =
//       FirebaseFirestore.instance.collection('doctors');

//   q = q.where('status', isEqualTo: 'active');
//   q = q.where('province_key', isEqualTo: location.provinceKey);

//   return q.snapshots().map((s) => s.docs);
// });

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpecialtiesCache {
  _SpecialtiesCache._();
  static final instance = _SpecialtiesCache._();

  static const _cacheKey = 'specialties_cache_json';
  static const _cacheTimeKey = 'specialties_cache_time';
  static const _ttlMinutes = 60 * 12; // 12 hours

  Stream<QuerySnapshot<Map<String, dynamic>>> stream() async* {
    final prefs = await SharedPreferences.getInstance();

    final cachedJson = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt(_cacheTimeKey);

    final now = DateTime.now().millisecondsSinceEpoch;

    final cacheValid = cachedJson != null &&
        cachedTime != null &&
        (now - cachedTime) < _ttlMinutes * 60 * 1000;

    if (cacheValid) {
      // Emit cached snapshot-like object (empty stream but UI already has data)
      yield* const Stream.empty();
    }

    final snap = await FirebaseFirestore.instance
        .collection('specialties')
        .where('status', isEqualTo: 'active')
        .get();

    // Save cache (optional: serialize only required fields)
    prefs.setString(
        _cacheKey, snap.docs.map((e) => e.data()).toList().toString());
    prefs.setInt(_cacheTimeKey, now);

    yield snap;
  }
}

// /// ===============================
// /// Google Clinics (PLACEHOLDERS)
// /// ===============================

final googleClinicsStreamProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final location = ref.watch(appLocationProvider);

  // 🔒 HARD GUARD — NO CITY = NO READS
  if (location == null || location.cityEn == null || location.cityEn!.isEmpty) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collection('google_doctors')
      .where('isPlaceholder', isEqualTo: true)
      .where('province_key', isEqualTo: location.provinceKey)
      .where(
        'city_lower',
        isEqualTo: location.cityEn!.toLowerCase().trim(),
      )
      .snapshots();
});

/// ===============================
/// Specialties (GLOBAL, STATIC)
/// ===============================
final specialtiesStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return _SpecialtiesCache.instance.stream();
});

final doctorsStreamProvider = StreamProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final location = ref.watch(appLocationProvider);

  // 🔒 HARD GUARD — NO CITY = NO READS
  if (location == null ||
      location.cityEn == null ||
      location.cityEn!.isEmpty ||
      location.provinceKey == null ||
      location.provinceKey!.isEmpty) {
    return const Stream.empty();
  }

  Query<Map<String, dynamic>> q =
      FirebaseFirestore.instance.collection('doctors');

  q = q.where('status', isEqualTo: 'active');
  q = q.where('province_key', isEqualTo: location.provinceKey);
  q = q.where('city_en', isEqualTo: location.cityEn!.trim());

  // 🔒 COST GUARD
  q = q.limit(50);

  return q.snapshots().map((s) => s.docs);
});
