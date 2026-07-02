import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_location_provider.dart';

/// Streams active pharmacy providers near the patient's city.
///
/// Reads from [public_pharmacy_providers] — a safe, sanitized projection of
/// [pharmacy_providers]. Only verified + active pharmacies are published there.
///
/// Guard: returns an empty stream when no city is selected (no location = no reads).
final pharmacyProvidersStreamProvider = StreamProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final location = ref.watch(appLocationProvider);

  if (location == null ||
      location.cityEn.isEmpty ||
      location.provinceKey.isEmpty) {
    return Stream.value(<QueryDocumentSnapshot<Map<String, dynamic>>>[]);
  }

  return FirebaseFirestore.instance
      .collection('public_pharmacy_providers')
      .where('status', isEqualTo: 'active')
      .where('province_key', isEqualTo: location.provinceKey)
      .where('city_en', isEqualTo: location.cityEn.trim())
      .limit(50)
      .snapshots()
      .map((s) => s.docs);
});
