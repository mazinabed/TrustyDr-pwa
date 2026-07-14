// lib/core/providers/marketplace_providers.dart
//
// Patient Marketplace (Phase 1C, browse-only). Every read here goes through
// a Healthcare-owned callable — never Commerce, never Odoo, directly (see
// doctor_functions/functions/commerce/getActiveMarketplaceStores.js and
// getMarketplaceCatalog.js for the full server-side contract).
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/auth_provider.dart';

/// Thrown by marketplace providers when Firebase Auth has finished
/// resolving and there is no signed-in user — distinct from a network/server
/// error so the UI can render a controlled "please log in" state instead of
/// a generic error or (worse) an indefinite spinner. The backend's
/// request.auth requirement is never weakened to work around this — every
/// call is gated to only fire once a real user is confirmed present.
class MarketplaceAuthRequiredException implements Exception {
  const MarketplaceAuthRequiredException();
}

const String kPharmacyOrgIdPrefix = 'hc_pharmacy_';

String pharmacyOrgIdFromProviderId(String providerId) =>
    '$kPharmacyOrgIdPrefix$providerId';

/// Shared localized-text fallback for fields that have real per-language
/// values curated in Healthcare (store/location names, which DO have a
/// genuine `_ku` field already): current language -> Kurdish/Arabic field if
/// non-empty -> English. Matches the existing convention already used
/// elsewhere in this app (see pharmacy_provider_profile_page.dart's `_loc`).
String _localizeWithKuField(String en, String ar, String ku, String lang) {
  if (lang == 'ar' && ar.isNotEmpty) return ar;
  if (lang == 'ku' && ku.isNotEmpty) return ku;
  return en.isNotEmpty ? en : (ar.isNotEmpty ? ar : ku);
}

/// Localized-text fallback for fields that have NO Kurdish backend value at
/// all (products/categories — Odoo has no Kurdish res.lang record, confirmed
/// live 2026-07-14, only en_US/ar_001 exist). Kurdish UI falls to Arabic
/// first, not English — closer to what a Kurdish-Iraqi reader actually
/// understands than English, and the user's own instruction explicitly
/// allows "Arabic or English" as the fallback for exactly this case.
String _localizeNoKu(String en, String ar, String lang) {
  if (lang == 'ar' && ar.isNotEmpty) return ar;
  if (lang == 'ku' && ar.isNotEmpty) return ar;
  return en.isNotEmpty ? en : ar;
}

class MarketplaceStore {
  const MarketplaceStore({
    required this.providerId,
    required this.orgId,
    required this.facilityNameEn,
    required this.facilityNameAr,
    required this.facilityNameKu,
    required this.imageUrl,
    required this.provinceEn,
    required this.provinceAr,
    required this.provinceKu,
    required this.cityEn,
    required this.cityAr,
    required this.cityKu,
    required this.facilityAddress,
    required this.productCount,
    required this.featuredImageUrl,
  });

  final String providerId;
  final String orgId;
  final String facilityNameEn;
  final String facilityNameAr;
  final String facilityNameKu;
  final String? imageUrl;
  final String provinceEn;
  final String provinceAr;
  final String provinceKu;
  final String cityEn;
  final String cityAr;
  final String cityKu;
  final String? facilityAddress;
  final int productCount;
  final String? featuredImageUrl;

  factory MarketplaceStore.fromMap(Map<String, dynamic> m) {
    return MarketplaceStore(
      providerId: m['providerId']?.toString() ?? '',
      orgId: m['orgId']?.toString() ?? '',
      facilityNameEn: m['facilityName_en']?.toString() ?? '',
      facilityNameAr: m['facilityName_ar']?.toString() ?? '',
      facilityNameKu: m['facilityName_ku']?.toString() ?? '',
      imageUrl: m['imageUrl']?.toString(),
      provinceEn: m['province_en']?.toString() ?? '',
      provinceAr: m['province_ar']?.toString() ?? '',
      provinceKu: m['province_ku']?.toString() ?? '',
      cityEn: m['city_en']?.toString() ?? '',
      cityAr: m['city_ar']?.toString() ?? '',
      cityKu: m['city_ku']?.toString() ?? '',
      facilityAddress: m['facilityAddress']?.toString(),
      productCount:
          (m['productCount'] is num) ? (m['productCount'] as num).toInt() : 0,
      featuredImageUrl: m['featuredImageUrl']?.toString(),
    );
  }

  String localizedName(String lang) => _localizeWithKuField(
      facilityNameEn, facilityNameAr, facilityNameKu, lang);

  String localizedCity(String lang) =>
      _localizeWithKuField(cityEn, cityAr, cityKu, lang);

  String localizedProvince(String lang) =>
      _localizeWithKuField(provinceEn, provinceAr, provinceKu, lang);
}

class MarketplaceProduct {
  const MarketplaceProduct({
    required this.orgId,
    required this.engineId,
    required this.sku,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.brandName,
    required this.categoryEngineId,
    required this.categoryNameEn,
    required this.categoryNameAr,
    required this.displayPrice,
    required this.currencyName,
    required this.isFeatured,
    required this.availabilityBadge,
    required this.imageUrl,
    required this.storeNameEn,
    required this.storeNameAr,
    required this.storeNameKu,
  });

  final String orgId;
  final String engineId;
  final String sku;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? brandName;
  final String? categoryEngineId;
  final String? categoryNameEn;
  final String? categoryNameAr;
  final double displayPrice;
  final String? currencyName;
  final bool isFeatured;
  final String availabilityBadge;
  final String? imageUrl;
  final String? storeNameEn;
  final String? storeNameAr;
  final String? storeNameKu;

  factory MarketplaceProduct.fromMap(Map<String, dynamic> m) {
    return MarketplaceProduct(
      orgId: m['orgId']?.toString() ?? '',
      engineId: m['engineId']?.toString() ?? '',
      sku: m['sku']?.toString() ?? '',
      nameEn: m['name_en']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
      descriptionEn: m['description_en']?.toString(),
      descriptionAr: m['description_ar']?.toString(),
      brandName: m['brandName']?.toString(),
      categoryEngineId: m['categoryEngineId']?.toString(),
      categoryNameEn: m['categoryName_en']?.toString(),
      categoryNameAr: m['categoryName_ar']?.toString(),
      displayPrice: (m['displayPrice'] is num)
          ? (m['displayPrice'] as num).toDouble()
          : 0.0,
      currencyName: m['currencyName']?.toString(),
      isFeatured: m['isFeatured'] == true,
      availabilityBadge: m['availabilityBadge']?.toString() ?? '',
      imageUrl: m['imageUrl']?.toString(),
      storeNameEn: m['storeName_en']?.toString(),
      storeNameAr: m['storeName_ar']?.toString(),
      storeNameKu: m['storeName_ku']?.toString(),
    );
  }

  String localizedName(String lang) => _localizeNoKu(nameEn, nameAr, lang);

  String? localizedDescription(String lang) {
    final en = descriptionEn ?? '';
    final ar = descriptionAr ?? '';
    if (en.isEmpty && ar.isEmpty) return null;
    return _localizeNoKu(en, ar, lang);
  }

  String? localizedCategoryName(String lang) {
    final en = categoryNameEn ?? '';
    final ar = categoryNameAr ?? '';
    if (en.isEmpty && ar.isEmpty) return null;
    return _localizeNoKu(en, ar, lang);
  }

  /// Store name is only present on cross-store results (Products tab) —
  /// null when this product came from a single-store catalog fetch, where
  /// the caller already knows which store it's looking at.
  String? localizedStoreName(String lang) {
    final en = storeNameEn ?? '';
    final ar = storeNameAr ?? '';
    final ku = storeNameKu ?? '';
    if (en.isEmpty && ar.isEmpty && ku.isEmpty) return null;
    return _localizeWithKuField(en, ar, ku, lang);
  }

  /// l10n KEY (not display text) for the availability badge — UI calls
  /// `.tr()` on this, matching this codebase's convention of doing all
  /// `.tr()` calls at the widget layer, never inside a provider/model file.
  String get availabilityL10nKey {
    switch (availabilityBadge) {
      case 'in_stock':
        return 'marketplace_availability_in_stock';
      case 'low_stock':
        return 'marketplace_availability_low_stock';
      case 'out_of_stock':
        return 'marketplace_availability_out_of_stock';
      default:
        return '';
    }
  }
}

class MarketplaceCategory {
  const MarketplaceCategory({
    required this.engineId,
    required this.nameEn,
    required this.nameAr,
    required this.parentEngineId,
    required this.sequence,
  });

  final String engineId;
  final String nameEn;
  final String nameAr;
  final String? parentEngineId;
  final int sequence;

  factory MarketplaceCategory.fromMap(Map<String, dynamic> m) {
    return MarketplaceCategory(
      engineId: m['engineId']?.toString() ?? '',
      nameEn: m['name_en']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
      parentEngineId: m['parentEngineId']?.toString(),
      sequence: (m['sequence'] is num) ? (m['sequence'] as num).toInt() : 0,
    );
  }

  String localizedName(String lang) => _localizeNoKu(nameEn, nameAr, lang);
}

class MarketplaceCatalog {
  const MarketplaceCatalog({required this.products, required this.categories});

  final List<MarketplaceProduct> products;
  final List<MarketplaceCategory> categories;

  bool get isEmpty => products.isEmpty;
}

/// Combined Store/Product/Category browse payload — one Healthcare call
/// powers all three Marketplace landing-page tabs, never a per-tab or
/// per-store request loop.
class MarketplaceBrowseData {
  const MarketplaceBrowseData({
    required this.stores,
    required this.products,
    required this.categories,
    required this.hasMoreProducts,
  });

  final List<MarketplaceStore> stores;
  final List<MarketplaceProduct> products;
  final List<MarketplaceCategory> categories;
  // Pagination — see marketplaceStoreDiscovery.ts's own header for the full
  // contract this reflects (smallest-viable, re-fetch-at-a-higher-limit,
  // not true cursor pagination). True whenever the cross-store product
  // list was truncated at the currently-applied
  // [marketplaceProductsLimitProvider] value.
  final bool hasMoreProducts;

  bool get isEmpty => stores.isEmpty && products.isEmpty;

  static const empty = MarketplaceBrowseData(
    stores: [],
    products: [],
    categories: [],
    hasMoreProducts: false,
  );
}

/// Current cross-store products page size requested from the backend —
/// starts at the backend's own default (100) and is bumped by the "Load
/// More" affordance on the Products page. Deliberately module-level state
/// (not per-page), matching [marketplaceBrowseProvider] itself being a
/// single shared fetch behind every Marketplace screen.
class MarketplaceProductsLimitNotifier extends Notifier<int> {
  @override
  int build() => 100;

  void loadMore() => state += 100;
}

final marketplaceProductsLimitProvider =
    NotifierProvider<MarketplaceProductsLimitNotifier, int>(
        MarketplaceProductsLimitNotifier.new);

Map<String, dynamic> _asStringKeyedMap(Object? raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

// TEMPORARY diagnostic logging for the marketplace-callable 401 bug — never
// logs the ID token itself, only uid + a success/failure boolean + the
// FirebaseApp identity, so it's safe to leave on briefly during live
// verification. Remove once the auth-gating fix above is confirmed stable.
Future<void> _logMarketplaceAuthDiagnostics(User user) async {
  final app = Firebase.app();
  debugPrint(
    '[marketplace][auth-debug] firebaseApp=${app.name} '
    'projectId=${app.options.projectId} uid=${user.uid}',
  );
  try {
    final token = await user.getIdToken();
    debugPrint(
      '[marketplace][auth-debug] getIdToken() succeeded=${token != null && token.isNotEmpty}',
    );
  } catch (e) {
    debugPrint('[marketplace][auth-debug] getIdToken() FAILED: $e');
  }
}

/// Marketplace browse data (Stores + cross-store Products + global
/// Categories) for the currently selected province/city — powers all three
/// Marketplace landing-page tabs from one call. Reuses [appLocationProvider]
/// (the same location state the existing pharmacy discovery screen watches)
/// rather than introducing a second location system.
final marketplaceBrowseProvider =
    FutureProvider.autoDispose<MarketplaceBrowseData>((ref) async {
  final location = ref.watch(appLocationProvider);
  if (location == null ||
      location.cityEn.isEmpty ||
      location.provinceKey.isEmpty) {
    return MarketplaceBrowseData.empty;
  }

  // Wait for Firebase Auth's session restoration to actually finish before
  // ever attempting the call. On Flutter Web, currentUser can be briefly
  // null immediately after page load while the persisted session is
  // restored asynchronously from IndexedDB — splashScreen.dart routes to
  // Home without waiting for that, so a naive `FirebaseAuth.instance.
  // currentUser` read here could easily be null even for a genuinely
  // logged-in user, sending the callable with no ID token and drawing a
  // 401 the backend is correctly right to issue (request.auth enforcement
  // stays exactly as-is — this fix belongs entirely on the client side).
  // `ref.watch` (not `ref.read`) on `.future` means this provider also
  // re-runs automatically once a real auth state arrives.
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    throw const MarketplaceAuthRequiredException();
  }
  await _logMarketplaceAuthDiagnostics(user);

  final productsLimit = ref.watch(marketplaceProductsLimitProvider);

  final callable =
      FirebaseFunctions.instance.httpsCallable('getActiveMarketplaceStores');
  final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
    'provinceKey': location.provinceKey,
    'cityEn': location.cityEn,
    'productsLimit': productsLimit,
  });

  final data = _asStringKeyedMap(result.data);

  final rawStores = data['stores'];
  final stores = rawStores is List
      ? rawStores
          .map((e) => MarketplaceStore.fromMap(_asStringKeyedMap(e)))
          .toList()
      : <MarketplaceStore>[];

  final rawProducts = data['products'];
  final products = rawProducts is List
      ? rawProducts
          .map((e) => MarketplaceProduct.fromMap(_asStringKeyedMap(e)))
          .toList()
      : <MarketplaceProduct>[];

  final rawCategories = data['categories'];
  final categories = rawCategories is List
      ? rawCategories
          .map((e) => MarketplaceCategory.fromMap(_asStringKeyedMap(e)))
          .toList()
      : <MarketplaceCategory>[];

  return MarketplaceBrowseData(
    stores: stores,
    products: products,
    categories: categories,
    hasMoreProducts: data['hasMoreProducts'] == true,
  );
});

/// A single store's catalog (products + categories), keyed by Commerce
/// orgId. Used both by the Store page and, on the pharmacy profile page, as
/// the single targeted call that decides whether "Visit Store" appears.
final marketplaceCatalogProvider = FutureProvider.autoDispose
    .family<MarketplaceCatalog, String>((ref, orgId) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    throw const MarketplaceAuthRequiredException();
  }
  await _logMarketplaceAuthDiagnostics(user);

  final callable =
      FirebaseFunctions.instance.httpsCallable('getMarketplaceCatalog');
  final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{
    'orgId': orgId,
  });

  final data = _asStringKeyedMap(result.data);

  final rawProducts = data['products'];
  final products = rawProducts is List
      ? rawProducts
          .map((e) => MarketplaceProduct.fromMap(_asStringKeyedMap(e)))
          .toList()
      : <MarketplaceProduct>[];

  final rawCategories = data['categories'];
  final categories = rawCategories is List
      ? rawCategories
          .map((e) => MarketplaceCategory.fromMap(_asStringKeyedMap(e)))
          .toList()
      : <MarketplaceCategory>[];

  return MarketplaceCatalog(products: products, categories: categories);
});
