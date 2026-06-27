import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight model for a single bookable service from the provider catalog.
///
/// Read from [diagnostic_providers/{providerId}/services] — a provider-owned
/// subcollection managed by lab/imaging staff in the doctor portal.
class ProviderCatalogService {
  const ProviderCatalogService({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.nameKu,
    required this.category,
    required this.subcategory,
    required this.estimatedDurationMinutes,
    this.price,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String nameKu;
  final String category;
  final String subcategory;
  final int estimatedDurationMinutes;
  final int? price;

  factory ProviderCatalogService.fromMap(
      String id, Map<String, dynamic> d) {
    return ProviderCatalogService(
      id: id,
      nameEn: (d['name_en'] ?? '').toString(),
      nameAr: (d['name_ar'] ?? '').toString(),
      nameKu: (d['name_ku'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      subcategory: (d['subcategory'] ?? '').toString(),
      estimatedDurationMinutes:
          (d['estimatedDurationMinutes'] as int?) ?? 30,
      price: d['price'] as int?,
    );
  }

  String name(String lang) {
    if (lang == 'ar' && nameAr.isNotEmpty) return nameAr;
    if (lang == 'ku' && nameKu.isNotEmpty) return nameKu;
    return nameEn;
  }
}

/// Fetches active, online-bookable services for a single diagnostic provider.
///
/// Queries: isActive == true, onlineBookingEnabled == true, isArchived == false.
/// Requires composite index: (isActive ASC, onlineBookingEnabled ASC, isArchived ASC, displayOrder ASC).
/// This index was created in Phase 0 of the Diagnostic Service Catalog.
///
/// Returns [] when [providerId] is empty (no unnecessary reads).
final providerCatalogProvider = FutureProvider.family
    .autoDispose<List<ProviderCatalogService>, String>(
        (ref, providerId) async {
  if (providerId.isEmpty) return [];
  final snap = await FirebaseFirestore.instance
      .collection('diagnostic_providers')
      .doc(providerId)
      .collection('services')
      .where('isActive', isEqualTo: true)
      .where('onlineBookingEnabled', isEqualTo: true)
      .where('isArchived', isEqualTo: false)
      .orderBy('displayOrder')
      .get();
  return snap.docs
      .map((d) => ProviderCatalogService.fromMap(d.id, d.data()))
      .toList();
});
