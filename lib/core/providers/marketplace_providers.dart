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
import 'package:flutter/foundation.dart' show debugPrint;
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

/// Store Branding V1 localization fix (2026-07-23) — for merchant-authored
/// free text (tagline/description) the active language's OWN field only,
/// never [_localizeWithKuField]'s cross-language fallback. That fallback is
/// correct for curated Healthcare identity fields (name/city, which the
/// rest of this file still uses it for) but was wrong here: an Arabic
/// reader seeing an untranslated English description read as if it were
/// "the" description, not a missing translation. Null means the merchant
/// hasn't written this field in the active language yet — the caller
/// renders nothing, never a different language standing in for it.
String? _localizeExactOrNull(String en, String ar, String ku, String lang) {
  final value = switch (lang) {
    'ar' => ar,
    'ku' => ku,
    _ => en,
  };
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
    required this.logoUrl,
    required this.bannerUrl,
    required this.taglineEn,
    required this.taglineAr,
    required this.taglineKu,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.descriptionKu,
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

  /// Store Branding V1 (2026-07-22) — no longer populated (always null).
  /// Previously a sampled PRODUCT image standing in for a store banner —
  /// removed at the source (Commerce's marketplaceStoreDiscovery.ts) since
  /// a product must never represent the merchant itself. Kept as a field
  /// only so this model's shape doesn't silently drop a key some other
  /// caller might still reference; [bannerUrl] is the real replacement and
  /// the only one any widget should render.
  final String? featuredImageUrl;

  /// Store Branding V1 — real, merchant-uploaded logo/banner
  /// (organizations/{orgId}.storeSettings.branding via Commerce's
  /// storeBranding.ts). Null means the merchant hasn't uploaded one yet —
  /// render the existing MarketplaceLogoFallback/MarketplaceBannerGradient,
  /// never fall back to [imageUrl]/[featuredImageUrl].
  final String? logoUrl;
  final String? bannerUrl;
  final String? taglineEn;
  final String? taglineAr;
  final String? taglineKu;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionKu;

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
      logoUrl: m['logoUrl']?.toString(),
      bannerUrl: m['bannerUrl']?.toString(),
      taglineEn: m['tagline_en']?.toString(),
      taglineAr: m['tagline_ar']?.toString(),
      taglineKu: m['tagline_ku']?.toString(),
      descriptionEn: m['description_en']?.toString(),
      descriptionAr: m['description_ar']?.toString(),
      descriptionKu: m['description_ku']?.toString(),
    );
  }

  String localizedName(String lang) => _localizeWithKuField(
      facilityNameEn, facilityNameAr, facilityNameKu, lang);

  String localizedCity(String lang) =>
      _localizeWithKuField(cityEn, cityAr, cityKu, lang);

  String localizedProvince(String lang) =>
      _localizeWithKuField(provinceEn, provinceAr, provinceKu, lang);

  /// Localization bug fix (2026-07-23) — exact active-language field only
  /// (see [_localizeExactOrNull]'s own doc comment for why this must NOT
  /// use [_localizeWithKuField]'s cross-language fallback here).
  String? localizedTagline(String lang) => _localizeExactOrNull(
      taglineEn ?? '', taglineAr ?? '', taglineKu ?? '', lang);

  String? localizedDescription(String lang) => _localizeExactOrNull(
      descriptionEn ?? '', descriptionAr ?? '', descriptionKu ?? '', lang);
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

/// Defensive parsing for [MarketplaceProduct.galleryImageUrls] — pure, no
/// Firebase/network dependency, deliberately public (not underscore-
/// prefixed) so it's directly unit-testable. Handles every response shape
/// that can reach the Patient App: the current backend contract (Primary +
/// up to 2 more), a legacy/pre-gallery response that only ever had
/// `imageUrl` (missing/null `raw`), a malformed or non-list `raw`, and a
/// gallery containing blank/null/duplicate entries — never throws, never
/// returns something the UI has to null-check further.
///
/// Contract: [imageUrl] (the Primary/cover image) always appears first
/// when present; the rest of [raw] is deduplicated (order preserved) and
/// blank/null entries are dropped; the result is capped at 3 entries.
List<String> parseGalleryImageUrls(dynamic raw, String? imageUrl) {
  final trimmedPrimary = imageUrl?.trim();
  final hasPrimary = trimmedPrimary != null && trimmedPrimary.isNotEmpty;

  if (raw is! List) {
    return hasPrimary ? [trimmedPrimary] : const [];
  }

  final cleaned = raw
      .map((e) => e?.toString().trim() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();

  final ordered = <String>[];
  if (hasPrimary) ordered.add(trimmedPrimary);
  for (final url in cleaned) {
    if (!ordered.contains(url)) ordered.add(url);
  }

  if (ordered.isEmpty) return const [];
  return ordered.take(3).toList();
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
    required this.galleryImageUrls,
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
  // Patient Marketplace gallery (2026-07-18) — Primary first (equal to
  // [imageUrl] when non-empty), deduplicated, max 3. Product cards must
  // keep using [imageUrl] only — this exists for the product detail
  // gallery. See [parseGalleryImageUrls] for the exact defensive-parsing
  // contract (handles a missing/non-list/legacy response safely).
  final List<String> galleryImageUrls;
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
      galleryImageUrls: parseGalleryImageUrls(
          m['galleryImageUrls'], m['imageUrl']?.toString()),
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

  /// Returns a copy with [orgId] replaced — used ONLY by
  /// [marketplaceCatalogProvider] to fix a real data gap (2026-07-19): the
  /// single-store catalog wire contract (getMarketplaceCatalogForHealthcare)
  /// deliberately omits orgId from each product ("the caller already knows
  /// the orgId it asked for" — see that Commerce function's own header), so
  /// [MarketplaceProduct.fromMap] parses orgId as an empty string for every
  /// product reached via a Store page. That was harmless before this
  /// product carried no further identity-dependent reads, but
  /// [marketplaceProductDetailProvider] (Patient Product Experience) reads
  /// orgId straight off this model to build its own request — an empty
  /// orgId there is a genuinely invalid request, not a stale cache, and the
  /// backend correctly (and permanently) rejects it with 400
  /// invalid-argument. The catalog provider is the one place that already
  /// knows the correct orgId for every product it returns, so it repairs
  /// this gap at the source rather than every downstream reader having to
  /// guess or thread the store's orgId through separately.
  MarketplaceProduct copyWithOrgId(String newOrgId) => MarketplaceProduct(
        orgId: newOrgId,
        engineId: engineId,
        sku: sku,
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        brandName: brandName,
        categoryEngineIds: categoryEngineIds,
        categoryKeys: categoryKeys,
        categories: categories,
        categoryEngineId: categoryEngineId,
        categoryNameEn: categoryNameEn,
        categoryNameAr: categoryNameAr,
        displayPrice: displayPrice,
        currencyName: currencyName,
        isFeatured: isFeatured,
        availabilityBadge: availabilityBadge,
        imageUrl: imageUrl,
        galleryImageUrls: galleryImageUrls,
        storeNameEn: storeNameEn,
        storeNameAr: storeNameAr,
        storeNameKu: storeNameKu,
      );
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
  const MarketplaceCatalog({
    required this.products,
    required this.categories,
    this.store,
  });

  final List<MarketplaceProduct> products;
  final List<MarketplaceCategory> categories;

  /// Store Branding V1 (2026-07-22) — real, merchant-controlled storefront
  /// identity for the orgId this catalog was fetched for, sourced from the
  /// SAME getMarketplaceCatalog call (never a second fetch). Null only if
  /// the response omitted it entirely (older/unexpected shape) — a present
  /// [MarketplaceStoreBranding] with all-null fields is the normal "no
  /// branding uploaded yet" case, not this being null.
  final MarketplaceStoreBranding? store;

  bool get isEmpty => products.isEmpty;
}

/// Store Branding V1 (2026-07-22) — see MarketplaceCatalog.store. Every
/// field is nullable and independently optional; a merchant may have
/// uploaded a logo but no banner, set a tagline but no description, etc.
class MarketplaceStoreBranding {
  const MarketplaceStoreBranding({
    this.logoUrl,
    this.bannerUrl,
    this.taglineEn,
    this.taglineAr,
    this.taglineKu,
    this.descriptionEn,
    this.descriptionAr,
    this.descriptionKu,
  });

  final String? logoUrl;
  final String? bannerUrl;
  final String? taglineEn;
  final String? taglineAr;
  final String? taglineKu;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionKu;

  factory MarketplaceStoreBranding.fromMap(Map<String, dynamic> m) {
    return MarketplaceStoreBranding(
      logoUrl: m['logoUrl']?.toString(),
      bannerUrl: m['bannerUrl']?.toString(),
      taglineEn: m['tagline_en']?.toString(),
      taglineAr: m['tagline_ar']?.toString(),
      taglineKu: m['tagline_ku']?.toString(),
      descriptionEn: m['description_en']?.toString(),
      descriptionAr: m['description_ar']?.toString(),
      descriptionKu: m['description_ku']?.toString(),
    );
  }

  /// Localization bug fix (2026-07-23) — see MarketplaceStore's own
  /// identical fix and [_localizeExactOrNull]'s doc comment.
  String? localizedTagline(String lang) => _localizeExactOrNull(
      taglineEn ?? '', taglineAr ?? '', taglineKu ?? '', lang);

  String? localizedDescription(String lang) => _localizeExactOrNull(
      descriptionEn ?? '', descriptionAr ?? '', descriptionKu ?? '', lang);
}

/// One resolved attribute/value on a product's detail read — EN/AR/KU
/// labels already resolved server-side against Commerce's own
/// attribute_definitions (mirrors doctor_portal's own
/// ProductVariantSelection contract exactly — same wire shape, same
/// backend resolver, reused here for the patient side). Used both for
/// [MarketplaceProductDetail.attributeSelections] (descriptive specs, e.g.
/// Strength/Pack Count) and each [MarketplaceProductVariant.selections]
/// (variant-generating picks, e.g. Size/Color).
class MarketplaceProductAttributeSelection {
  const MarketplaceProductAttributeSelection({
    required this.attributeKey,
    required this.attributeNameEn,
    required this.attributeNameAr,
    required this.attributeNameKu,
    required this.valueKey,
    required this.valueNameEn,
    required this.valueNameAr,
    required this.valueNameKu,
  });

  final String? attributeKey;
  final String? attributeNameEn;
  final String? attributeNameAr;
  final String? attributeNameKu;
  final String? valueKey;
  final String? valueNameEn;
  final String? valueNameAr;
  final String? valueNameKu;

  factory MarketplaceProductAttributeSelection.fromMap(
          Map<String, dynamic> m) =>
      MarketplaceProductAttributeSelection(
        attributeKey: m['attributeKey']?.toString(),
        attributeNameEn: m['attributeName_en']?.toString(),
        attributeNameAr: m['attributeName_ar']?.toString(),
        attributeNameKu: m['attributeName_ku']?.toString(),
        valueKey: m['valueKey']?.toString(),
        valueNameEn: m['valueName_en']?.toString(),
        valueNameAr: m['valueName_ar']?.toString(),
        valueNameKu: m['valueName_ku']?.toString(),
      );

  String localizedAttributeName(String lang) =>
      _localizeNoKu(attributeNameEn ?? '', attributeNameAr ?? '', lang);

  String localizedValueName(String lang) =>
      _localizeNoKu(valueNameEn ?? '', valueNameAr ?? '', lang);
}

/// One real, sellable Odoo product.product — only present once a product
/// actually has more than one variant (hasVariants/variantCount are always
/// populated regardless). Mirrors doctor_portal's own ProductVariant
/// contract (Milestone 5, Product Management), read here live so price/
/// stock are always current at the moment the patient opens this product
/// — never trusted from the ~15-minute Marketplace browse cache.
class MarketplaceProductVariant {
  const MarketplaceProductVariant({
    required this.variantEngineId,
    required this.selections,
    required this.salePrice,
    required this.quantityAvailable,
    required this.availabilityBadge,
    required this.isDefault,
  });

  final String variantEngineId;
  final List<MarketplaceProductAttributeSelection> selections;
  final double salePrice;
  final double quantityAvailable;
  final String availabilityBadge;
  final bool isDefault;

  factory MarketplaceProductVariant.fromMap(Map<String, dynamic> m) {
    final rawSelections = m['selections'];
    return MarketplaceProductVariant(
      variantEngineId: m['variantEngineId']?.toString() ?? '',
      selections: rawSelections is List
          ? rawSelections
              .map((e) => MarketplaceProductAttributeSelection.fromMap(
                  _asStringKeyedMap(e)))
              .toList()
          : const [],
      salePrice:
          (m['salePrice'] is num) ? (m['salePrice'] as num).toDouble() : 0.0,
      quantityAvailable: (m['quantityAvailable'] is num)
          ? (m['quantityAvailable'] as num).toDouble()
          : 0.0,
      availabilityBadge: m['availabilityBadge']?.toString() ?? 'out_of_stock',
      isDefault: m['isDefault'] == true,
    );
  }

  /// The value key this variant carries for a given attribute, or null if
  /// this variant doesn't select that attribute at all — the building
  /// block variant-matching logic (resolving a patient's picks to one
  /// exact variant) is built on.
  String? valueKeyFor(String attributeKey) => selections
      .firstWhere(
        (s) => s.attributeKey == attributeKey,
        orElse: () => const MarketplaceProductAttributeSelection(
          attributeKey: null,
          attributeNameEn: null,
          attributeNameAr: null,
          attributeNameKu: null,
          valueKey: null,
          valueNameEn: null,
          valueNameAr: null,
          valueNameKu: null,
        ),
      )
      .valueKey;
}

/// Live single-product detail — fetched fresh (never from the Marketplace
/// browse cache) the moment a patient opens Product Details, via
/// getMarketplaceProductDetail (Healthcare) -> getMarketplaceProductDetailForHealthcare
/// (Commerce) -> a direct Odoo read (trustydr-commerce/functions/src/
/// marketplaceProductDetail.ts). Carries exactly what [MarketplaceProduct]
/// (the browse-card shape) does NOT: variants, descriptive attribute
/// specs, and a truth-refreshed price/stock. The detail page keeps using
/// the already-loaded [MarketplaceProduct] for instant paint (title,
/// image, description) while this loads, then this becomes the price/
/// stock/variant authority once it resolves.
class MarketplaceProductDetail {
  const MarketplaceProductDetail({
    required this.engineId,
    required this.sku,
    required this.hasVariants,
    required this.variantCount,
    required this.variants,
    required this.attributeSelections,
    required this.listPrice,
    required this.currencyName,
    required this.quantityAvailable,
    required this.availabilityBadge,
  });

  final String engineId;
  final String sku;
  final bool hasVariants;
  final int variantCount;
  final List<MarketplaceProductVariant> variants;
  final List<MarketplaceProductAttributeSelection> attributeSelections;
  final double listPrice;
  final String? currencyName;
  final double quantityAvailable;
  final String availabilityBadge;

  factory MarketplaceProductDetail.fromMap(Map<String, dynamic> m) {
    final rawVariants = m['variants'];
    final rawAttributeSelections = m['attributeSelections'];
    return MarketplaceProductDetail(
      engineId: m['engineId']?.toString() ?? '',
      sku: m['sku']?.toString() ?? '',
      hasVariants: m['hasVariants'] == true,
      variantCount:
          (m['variantCount'] is num) ? (m['variantCount'] as num).toInt() : 1,
      variants: rawVariants is List
          ? rawVariants
              .map((e) =>
                  MarketplaceProductVariant.fromMap(_asStringKeyedMap(e)))
              .toList()
          : const [],
      attributeSelections: rawAttributeSelections is List
          ? rawAttributeSelections
              .map((e) => MarketplaceProductAttributeSelection.fromMap(
                  _asStringKeyedMap(e)))
              .toList()
          : const [],
      listPrice:
          (m['listPrice'] is num) ? (m['listPrice'] as num).toDouble() : 0.0,
      currencyName: m['currencyName']?.toString(),
      quantityAvailable: (m['quantityAvailable'] is num)
          ? (m['quantityAvailable'] as num).toDouble()
          : 0.0,
      availabilityBadge: m['availabilityBadge']?.toString() ?? 'out_of_stock',
    );
  }

  /// Every distinct attributeKey that actually varies across this
  /// product's own variants (Size, Color, Flavor, ...) — the set the
  /// detail page must render as a selectable control. Deliberately derived
  /// from the real variants, never the global attribute catalog (a product
  /// must only ever offer the attributes it actually has).
  List<String> get variantAttributeKeys {
    final keys = <String>{};
    for (final variant in variants) {
      for (final selection in variant.selections) {
        if (selection.attributeKey != null) keys.add(selection.attributeKey!);
      }
    }
    return keys.toList();
  }

  /// Resolves a patient's in-progress selections (attributeKey -> chosen
  /// valueKey) to the one exact variant matching ALL of them, or null if no
  /// variant matches (either the selection is incomplete or the
  /// combination doesn't exist) — the single required choke point every
  /// price/availability/Add-to-Cart decision on the detail page must go
  /// through for a multi-variant product. Never guesses: only exactly one
  /// variant satisfying every selected attribute is a match; anything else
  /// (0 or >1) returns null on purpose so the caller shows "select options"
  /// rather than an arbitrary price.
  ///
  /// Only meaningful when [hasVariants] is true (variants is only ever
  /// populated in that case — see this class' own field doc comment,
  /// mirroring EngineManagedProduct.variants exactly). A single-variant
  /// product needs no resolution at all: the backend's own
  /// resolveVariantDecision already auto-selects the one sellable variant
  /// at checkout time when no explicit variantEngineId is submitted — the
  /// Patient App simply omits variantEngineId entirely for that case,
  /// never calling this method.
  MarketplaceProductVariant? resolveVariant(Map<String, String> selections) {
    if (variants.isEmpty) return null;
    final matches = variants.where((variant) {
      for (final attributeKey in variantAttributeKeys) {
        final selected = selections[attributeKey];
        if (selected == null) return false;
        if (variant.valueKeyFor(attributeKey) != selected) return false;
      }
      return true;
    }).toList();
    return matches.length == 1 ? matches.first : null;
  }

  /// Every distinct value actually offered for a variant-generating
  /// attribute, in first-seen order — the picker's own option list, never
  /// the global attribute catalog (only options this specific product
  /// really has).
  List<MarketplaceProductAttributeSelection> optionsFor(String attributeKey) {
    final seenValueKeys = <String>{};
    final options = <MarketplaceProductAttributeSelection>[];
    for (final variant in variants) {
      for (final selection in variant.selections) {
        if (selection.attributeKey != attributeKey) continue;
        final valueKey = selection.valueKey;
        if (valueKey == null || !seenValueKeys.add(valueKey)) continue;
        options.add(selection);
      }
    }
    return options;
  }

  /// Whether choosing [valueKey] for [attributeKey] remains possible given
  /// the OTHER attributes already selected in [currentSelections] — that
  /// attribute's own current selection (if any) is ignored, since this
  /// answers "if I picked this value instead, would some real variant
  /// exist." Used to visibly disable combinations that don't exist rather
  /// than letting the patient pick a dead end.
  bool isValueAvailable(
    String attributeKey,
    String valueKey,
    Map<String, String> currentSelections,
  ) {
    return variants.any((variant) {
      if (variant.valueKeyFor(attributeKey) != valueKey) return false;
      for (final otherKey in variantAttributeKeys) {
        if (otherKey == attributeKey) continue;
        final selected = currentSelections[otherKey];
        if (selected == null) continue; // not yet chosen — doesn't constrain
        if (variant.valueKeyFor(otherKey) != selected) return false;
      }
      return true;
    });
  }

  /// Attribute keys where every real variant shares the exact same value —
  /// safe to preselect automatically (the approved "unambiguous value"
  /// initial-selection rule): there is genuinely no choice to make for that
  /// one attribute, even though the product has multiple variants overall
  /// (varying by some OTHER attribute). Never guesses across attributes
  /// that DO vary.
  Map<String, String> get unambiguousSelections {
    final result = <String, String>{};
    for (final attributeKey in variantAttributeKeys) {
      final values = variants.map((v) => v.valueKeyFor(attributeKey)).toSet();
      if (values.length == 1 && values.first != null) {
        result[attributeKey] = values.first!;
      }
    }
    return result;
  }

  /// Descriptive attribute specs to display as plain product information —
  /// everything in [attributeSelections] EXCEPT the attributes that are
  /// actually variant-generating on this product (those render as pickers
  /// instead, never duplicated as a spec row too). A null attributeKey
  /// means the backend could not resolve this Odoo attribute against
  /// Commerce's own attribute_definitions at all (confirmed live: the
  /// legacy "Brand" mechanism — see odooDriver.ts's resolveBrandNames —
  /// writes a template.attribute.value that was never migrated into the
  /// new Attribute Engine) — excluded here since there is no real
  /// localized attribute name to show, and [MarketplaceProduct.brandName]
  /// already surfaces that same value through its own dedicated field.
  List<MarketplaceProductAttributeSelection> get descriptiveAttributes {
    final variantKeys = variantAttributeKeys.toSet();
    return attributeSelections
        .where((s) =>
            s.attributeKey != null && !variantKeys.contains(s.attributeKey))
        .toList();
  }
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
  // 2026-07-19 fix (confirmed root cause of the Product Details 400):
  // getMarketplaceCatalogForHealthcare deliberately never echoes orgId per
  // product (this family's own orgId param is already the caller's
  // context), so MarketplaceProduct.fromMap parses every one of these as
  // orgId: ''. That was harmless before marketplaceProductDetailProvider
  // started reading orgId straight off this model — an empty orgId there
  // is a permanent, correctly-rejected 400, not a transient failure. This
  // is the one place that already knows the real orgId for every product
  // it returns, so it's repaired here at the source — see
  // MarketplaceProduct.copyWithOrgId's own doc comment.
  final products = rawProducts is List
      ? rawProducts
          .map((e) => MarketplaceProduct.fromMap(_asStringKeyedMap(e))
              .copyWithOrgId(orgId))
          .toList()
      : <MarketplaceProduct>[];

  final rawCategories = data['categories'];
  final categories = rawCategories is List
      ? rawCategories
          .map((e) => MarketplaceCategory.fromMap(_asStringKeyedMap(e)))
          .toList()
      : <MarketplaceCategory>[];

  // Store Branding V1 (2026-07-22) — same call, no second fetch. Every
  // caller of this provider (the Store page itself, and the pharmacy
  // profile page's "Visit Store" button) gets real branding for free.
  final rawStore = data['store'];
  final store = rawStore is Map
      ? MarketplaceStoreBranding.fromMap(_asStringKeyedMap(rawStore))
      : null;

  return MarketplaceCatalog(
      products: products, categories: categories, store: store);
});

/// Live single-product detail (Milestone 5, Patient Product Experience) —
/// keyed by (orgId, engineId) so switching products/stores always fetches
/// fresh rather than reusing a stale family instance. autoDispose so this
/// never lingers once the detail page closes. See
/// [MarketplaceProductDetail]'s own doc comment for why this is a live read
/// rather than a browse-cache field.
final marketplaceProductDetailProvider = FutureProvider.autoDispose
    .family<MarketplaceProductDetail, ({String orgId, String engineId})>(
  (ref, params) async {
    // Fail fast, locally, on a request we already know the backend must
    // reject — never send a callable request with an empty identifier
    // (the exact 2026-07-19 bug: MarketplaceProduct.orgId was empty for
    // every product reached via a Store page before copyWithOrgId's own
    // fix). This is now a defensive backstop, not the primary fix — but it
    // turns any FUTURE identity gap into an immediate, clearly-labeled,
    // non-retrying local error instead of a live 400 round trip.
    if (params.orgId.isEmpty || params.engineId.isEmpty) {
      debugPrint(
          '[marketplace_product_detail] refusing to call getMarketplaceProductDetail with '
          'an empty identifier (orgId empty: ${params.orgId.isEmpty}, engineId empty: '
          '${params.engineId.isEmpty}) — this product record is missing required identity.');
      throw const MarketplaceProductDetailRequestError();
    }

    final callable =
        FirebaseFunctions.instance.httpsCallable('getMarketplaceProductDetail');
    try {
      final result =
          await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'orgId': params.orgId,
        'engineId': params.engineId,
      });
      return MarketplaceProductDetail.fromMap(_asStringKeyedMap(result.data));
    } on FirebaseFunctionsException catch (e) {
      // Sanitized — error code/type and which identifier was sent, never
      // auth tokens or any patient data (this endpoint carries none).
      debugPrint(
          '[marketplace_product_detail] getMarketplaceProductDetail failed: '
          'code=${e.code} message=${e.message} orgId.isEmpty=${params.orgId.isEmpty} '
          'engineId=${params.engineId}');
      rethrow;
    }
  },
  // 2026-07-19 fix — the reported "endless spinner" symptom: Riverpod's
  // own default retry (exponential backoff, unlimited by app config) was
  // re-running this exact request forever after a DETERMINISTIC 400
  // (invalid-argument) that could never succeed on retry. Deterministic
  // callable error codes and the local pre-flight guard above stop
  // immediately (return null — no further automatic retry; the UI's own
  // explicit Retry button is the only way to try again). Only a genuinely
  // transient failure (network blip, backend temporarily unavailable) gets
  // a short, bounded exponential backoff — never unlimited.
  retry: (retryCount, error) {
    if (error is MarketplaceProductDetailRequestError) return null;
    if (error is FirebaseFunctionsException) {
      const permanentCodes = {
        'invalid-argument',
        'not-found',
        'failed-precondition',
        'permission-denied',
        'unauthenticated',
      };
      if (permanentCodes.contains(error.code)) return null;
    }
    if (retryCount >= 2) return null;
    return Duration(seconds: 1 << retryCount); // 1s, then 2s
  },
);

/// Thrown locally (never reaches the network) when a product record is
/// missing the identity a live detail fetch requires — see
/// [marketplaceProductDetailProvider]'s own pre-flight guard.
class MarketplaceProductDetailRequestError implements Exception {
  const MarketplaceProductDetailRequestError();
}
