// lib/core/providers/marketplace_providers.dart
//
// Patient Marketplace (Phase 1C, browse-only). Every read here goes through
// a Healthcare-owned callable — never Commerce, never Odoo, directly (see
// doctor_functions/functions/commerce/getActiveMarketplaceStores.js and
// getMarketplaceCatalog.js for the full server-side contract).
//
// PUBLIC BROWSE (2026-07-15): both callables below are deliberately
// unauthenticated on the backend now (the `request.auth` gate was removed
// from both Healthcare functions), matching TrustyDr's existing healthcare
// discovery model — guests can browse the full public Marketplace, and
// authentication is required only for protected actions (cart, checkout,
// orders, prescriptions, saved addresses, payments), never merely to see
// it. These providers used to wait for `authStateProvider.future` and throw
// a `MarketplaceAuthRequiredException` when no user was present — removed
// entirely, not worked around, since the actual fix belonged on the
// backend's auth gate, not a client-side guard hiding it. See
// marketplace_widgets.dart's `ensureMarketplaceLogin()` for the reusable
// tap-time login gate protected actions should use instead.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';

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

/// One of a product's assigned categories, as embedded on the product doc
/// (denormalized at sync time — a small, bounded set per product, not
/// worth a second lookup against the global categories collection).
/// [categoryKey] is the Shared Marketplace Category Engine's stable identity
/// (2026-07-14 milestone) — [engineId] (the raw Odoo numeric id) survives
/// only for reference/debugging and must never be used for filtering.
class MarketplaceCategoryRef {
  const MarketplaceCategoryRef({
    required this.engineId,
    required this.categoryKey,
    required this.nameEn,
    required this.nameAr,
  });

  final String engineId;
  final String? categoryKey;
  final String nameEn;
  final String nameAr;

  factory MarketplaceCategoryRef.fromMap(Map<String, dynamic> m) {
    return MarketplaceCategoryRef(
      engineId: m['engineId']?.toString() ?? '',
      categoryKey: m['categoryKey']?.toString(),
      nameEn: m['name_en']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
    );
  }
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
    required this.categoryEngineIds,
    required this.categoryKeys,
    required this.categories,
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
  // ALL assigned category ids — a product appears under every category it
  // belongs to (never duplicated as separate cards).
  // [categoryEngineId]/[categoryNameEn]/[categoryNameAr] (singular, first
  // entry) survive only as a breadcrumb-display convenience.
  //
  // Shared Marketplace Category Engine (2026-07-14): [categoryKeys] is the
  // stable identity that filtering/search/category-browsing must check
  // membership against now — never [categoryEngineIds] (raw Odoo numeric
  // ids), which survives only for reference/debugging.
  final List<String> categoryEngineIds;
  final List<String> categoryKeys;
  final List<MarketplaceCategoryRef> categories;
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
    final rawCategories = m['categories'];
    return MarketplaceProduct(
      orgId: m['orgId']?.toString() ?? '',
      engineId: m['engineId']?.toString() ?? '',
      sku: m['sku']?.toString() ?? '',
      nameEn: m['name_en']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
      descriptionEn: m['description_en']?.toString(),
      descriptionAr: m['description_ar']?.toString(),
      brandName: m['brandName']?.toString(),
      categoryEngineIds: (m['categoryEngineIds'] is List)
          ? (m['categoryEngineIds'] as List).map((e) => e.toString()).toList()
          : const [],
      categoryKeys: (m['categoryKeys'] is List)
          ? (m['categoryKeys'] as List).map((e) => e.toString()).toList()
          : const [],
      categories: (rawCategories is List)
          ? rawCategories
              .map((e) => MarketplaceCategoryRef.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
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

  /// Breadcrumb/display-only single category name (first assigned). Never
  /// use for filtering — see [categoryEngineIds].
  String? localizedCategoryName(String lang) {
    final en = categoryNameEn ?? '';
    final ar = categoryNameAr ?? '';
    if (en.isEmpty && ar.isEmpty) return null;
    return _localizeNoKu(en, ar, lang);
  }

  /// Every assigned category's localized name — for a product detail page
  /// or anywhere that should show the full set, not just the primary one.
  List<String> localizedCategoryNames(String lang) => categories
      .map((c) => _localizeNoKu(c.nameEn, c.nameAr, lang))
      .where((n) => n.isNotEmpty)
      .toList();

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

/// Shared Marketplace Category Engine (2026-07-14) — sourced from Commerce's
/// marketplace_category_definitions (never Odoo, never the legacy
/// marketplace_categories mirror). [categoryKey] is the permanent, stable
/// identity every filter/navigation/hierarchy operation in this app must use
/// — [odooCategoryId] survives only for reference, never for filtering.
class MarketplaceCategory {
  const MarketplaceCategory({
    required this.categoryKey,
    required this.parentCategoryKey,
    required this.level,
    required this.nameEn,
    required this.nameAr,
    required this.nameKu,
    required this.iconKey,
    required this.sortOrder,
    required this.featured,
    required this.odooCategoryId,
  });

  final String categoryKey;
  final String? parentCategoryKey;
  final int level;
  final String nameEn;
  final String nameAr;
  final String nameKu;
  final String? iconKey;
  final int sortOrder;
  final bool featured;
  final String? odooCategoryId;

  factory MarketplaceCategory.fromMap(Map<String, dynamic> m) {
    return MarketplaceCategory(
      categoryKey: m['categoryKey']?.toString() ?? '',
      parentCategoryKey: m['parentCategoryKey']?.toString(),
      level: (m['level'] is num) ? (m['level'] as num).toInt() : 0,
      nameEn: m['name_en']?.toString() ?? '',
      nameAr: m['name_ar']?.toString() ?? '',
      nameKu: m['name_ku']?.toString() ?? '',
      iconKey: m['iconKey']?.toString(),
      sortOrder: (m['sortOrder'] is num) ? (m['sortOrder'] as num).toInt() : 0,
      featured: m['featured'] == true,
      odooCategoryId: m['odooCategoryId']?.toString(),
    );
  }

  // Categories, unlike products, DO have a real (if partially populated)
  // name_ku from the Category Engine — falls back to Arabic (never a blank
  // string) when a specific category hasn't been translated yet, matching
  // the taxonomy's own documented translation-coverage gaps.
  String localizedName(String lang) {
    if (lang == 'ku' && nameKu.isNotEmpty) return nameKu;
    if (lang == 'ku' && nameAr.isNotEmpty) return nameAr;
    if (lang == 'ar' && nameAr.isNotEmpty) return nameAr;
    return nameEn.isNotEmpty ? nameEn : nameAr;
  }
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

/// Marketplace browse data (Stores + cross-store Products + global
/// Categories) for the currently selected province/city — powers all three
/// Marketplace landing-page tabs from one call. Reuses [appLocationProvider]
/// (the same location state the existing pharmacy discovery screen watches)
/// rather than introducing a second location system. Loads identically for
/// guests and logged-in patients (public browse, 2026-07-15) — no auth wait,
/// no auth-required error path.
final marketplaceBrowseProvider =
    FutureProvider.autoDispose<MarketplaceBrowseData>((ref) async {
  final location = ref.watch(appLocationProvider);
  if (location == null ||
      location.cityEn.isEmpty ||
      location.provinceKey.isEmpty) {
    return MarketplaceBrowseData.empty;
  }

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
/// Loads identically for guests and logged-in patients (public browse,
/// 2026-07-15).
final marketplaceCatalogProvider = FutureProvider.autoDispose
    .family<MarketplaceCatalog, String>((ref, orgId) async {
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
