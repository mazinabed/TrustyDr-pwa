import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/daily_health_weather.dart';

/// One-time read of public_daily_health_weather/{provinceKey}.
/// Returns null if the document does not exist yet.
/// Keyed by provinceKey — empty string returns null immediately.
final healthWeatherProvider = FutureProvider.autoDispose
    .family<DailyHealthWeather?, String>((ref, provinceKey) async {
  if (provinceKey.isEmpty) return null;

  final doc = await FirebaseFirestore.instance
      .collection('public_daily_health_weather')
      .doc(provinceKey)
      .get();

  if (!doc.exists || doc.data() == null) return null;

  return DailyHealthWeather.fromMap(doc.data()!);
});
