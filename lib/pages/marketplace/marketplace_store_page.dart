import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_all_categories_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_nav_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
import 'package:trustydr/pages/marketplace/marketplace_collection_section.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_products_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_search_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_widgets.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// A single pharmacy's Store (Patient Marketplace, Phase 1C, browse-only).
///
/// Marketplace Design System (2026-07-15, category-nav refined 2026-07-19):
/// this page follows the EXACT same visual language and section structure
/// as the Marketplace Home page — [MarketplaceStoreHeader] (not the
/// generic [TrustyDrCurvedHeader] used by doctor/patient/appointment
/// screens), [CommerceCategoryNavBar] for compact category navigation
/// (replacing the old large circular-icon chip grid both pages used to
/// have), [MarketplaceSection] + the shared
/// [MarketplaceProductCard]/[MarketplaceProductGrid] for the full "All
/// Products" grid. The intent is
/// that a patient tapping from Marketplace Home into a specific pharmacy
/// feels like walking further into the SAME shop, not landing on a
/// different app — Marketplace Home -> Pharmacy Store -> Category ->
/// Products -> Product Details should read as one continuous storefront,
/// never "marketplace, then a healthcare provider page, then products."
///
/// Fetches the catalog via [marketplaceCatalogProvider], the same call the
/// pharmacy profile page's "Visit Store" button already made to decide
/// whether to show itself — Riverpod's family caching means arriving here
/// right after that tap does not re-fetch.
class MarketplaceStorePage extends ConsumerStatefulWidget {
  const MarketplaceStorePage({
    super.key,
    required this.providerId,
    required this.orgId,
    required this.storeName,
    this.bannerUrl,
    this.logoUrl,
    this.city,
    this.tagline,
    this.description,
  });

  final String providerId;
  final String orgId;
  final String storeName;
  // Optional: every navigation path into this page must supply the SAME
  // real branding data (Store Branding V1, 2026-07-22) — see each call
  // site's own comment for where it sources these from. Null renders the
  // existing gradient/icon fallback, never a blank or clinical-looking
  // header, and never a sampled product image.
  final String? bannerUrl;
  final String? logoUrl;
  final String? city;
  final String? tagline;
  final String? description;

  @override
  ConsumerState<MarketplaceStorePage> createState() =>
      _MarketplaceStorePageState();
}

class _MarketplaceStorePageState extends ConsumerState<MarketplaceStorePage> {
  String? _selectedCategoryKey;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(marketplaceCatalogProvider(widget.orgId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = catalogAsync.when(
            data: (catalog) => _StoreBody(
              orgId: widget.orgId,
              storeName: widget.storeName,
              bannerUrl: widget.bannerUrl,
              logoUrl: widget.logoUrl,
              city: widget.city,
              tagline: widget.tagline,
              description: widget.description,
              catalog: catalog,
              selectedCategoryKey: _selectedCategoryKey,
              searchQuery: _searchQuery,
              onCategorySelected: (id) =>
                  setState(() => _selectedCategoryKey = id),
              onSearchChanged: (val) => setState(() => _searchQuery = val),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: PatientAppColors.brandTeal,
              ),
            ),
            // Public browse (2026-07-15) — see marketplace_landing_page.dart's
            // matching comment.
            error: (err, __) => Center(
              child: Text(
                'error_generic'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({
    required this.orgId,
    required this.storeName,
    required this.bannerUrl,
    required this.logoUrl,
    required this.city,
    this.tagline,
    this.description,
    required this.catalog,
    required this.selectedCategoryKey,
    required this.searchQuery,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  final String orgId;
  final String storeName;
  final String? bannerUrl;
  final String? logoUrl;
  final String? city;
  final String? tagline;
  final String? description;
  final MarketplaceCatalog catalog;
  final String? selectedCategoryKey;
  final String searchQuery;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    // Store Branding V1 (2026-07-22) — catalog.store is fetched by THIS
    // page's own marketplaceCatalogProvider(orgId) call, so it resolves
    // identically no matter which screen navigated here (store card,
    // pharmacy profile's "Visit Store", or a product's "Sold by" link) —
    // the constructor params above only matter as a fallback if the
    // catalog response is ever missing the store field. City has no
    // Commerce-side source (it's Healthcare's own public_pharmacy_providers
    // data), so it stays purely nav-param-sourced.
    final effectiveBannerUrl = catalog.store?.bannerUrl ?? bannerUrl;
    final effectiveLogoUrl = catalog.store?.logoUrl ?? logoUrl;
    final effectiveTagline = catalog.store?.localizedTagline(lang) ?? tagline;
    final effectiveDescription =
        catalog.store?.localizedDescription(lang) ?? description;

    final header = MarketplaceStoreHeader(
      storeName: storeName,
      bannerUrl: effectiveBannerUrl,
      logoUrl: effectiveLogoUrl,
      city: city,
      tagline: effectiveTagline,
      description: effectiveDescription,
      productCount: catalog.products.length,
      categoryCount: distinctCategoryCount(catalog.products),
    );

    if (catalog.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            header,
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 48,
                    color: Colors.black.withValues(alpha: 0.16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'marketplace_store_unavailable'.tr(),
                    style: const TextStyle(fontSize: 15, color: Colors.black45),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Store-specific category set (2026-07-15) — deliberately NOT the
    // global featured set Marketplace Home uses. Only categories this
    // store's own published products are actually assigned to (plus their
    // ancestors) ever appear here — a merchant storefront must never
    // advertise browsing into a category it has nothing in.
    final storeCategories =
        storeAvailableCategories(catalog.products, catalog.categories);
    final storeTopLevelCategories = storeCategories
        .where((c) => c.level == 0)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // 2026-07-19 category-nav refinement — the compact nav bar scrolls, so
    // (unlike the old wrapped chip grid) it never needs an arbitrary cap:
    // every top-level category this store's catalog actually uses gets a
    // slot, in the taxonomy's own configured sortOrder.
    final navCategories = [
      for (final c in storeTopLevelCategories)
        CommerceCategoryNavItem(
            categoryKey: c.categoryKey, label: c.localizedName(lang)),
    ];

    // Milestone 5 (Pharmacy Store Home upgrade, 2026-07-19) — the flat
    // "Popular Products" rail is replaced with one collection section per
    // category this store's catalog actually uses (storeCategories above —
    // never the global featured set; onlyFeatured: false here since
    // store-scoping, not platform curation, is what already narrowed the
    // input). Same reusable buildCategoryCollections/CommerceCollectionSection
    // Marketplace Home uses — this page just supplies store-scoped data
    // and a store-scoped "See All" destination.
    final categoryCollections = buildCategoryCollections(
      products: catalog.products,
      categories: storeCategories,
      lang: lang,
    );

    var filteredProducts = catalog.products;
    String? activeCategoryLabel;
    if (selectedCategoryKey != null) {
      final descendantKeys =
          descendantCategoryKeys(catalog.categories, selectedCategoryKey!);
      filteredProducts = filteredProducts
          .where(
              (p) => p.categoryKeys.any((key) => descendantKeys.contains(key)))
          .toList();
      final match = catalog.categories
          .where((c) => c.categoryKey == selectedCategoryKey)
          .toList();
      if (match.isNotEmpty) {
        activeCategoryLabel = match.first.localizedName(lang);
      }
    }
    if (searchQuery.trim().length >= 2) {
      final q = searchQuery.trim().toLowerCase();
      filteredProducts = filteredProducts
          .where((p) =>
              p.localizedName(lang).toLowerCase().contains(q) ||
              (p.brandName ?? '').toLowerCase().contains(q))
          .toList();
    }

    // Once the patient has drilled into a category or is searching, this
    // becomes a filtered-results view — the curated browse sections
    // (Shop by Category, Popular Products) step aside for the single
    // relevant product grid, same convention MarketplaceProductsPage uses.
    final isFiltering =
        selectedCategoryKey != null || searchQuery.trim().length >= 2;

    // 2026-07-19 header restructure — MarketplaceStoreHeader now renders the
    // full identity block itself (gradient with name/logo/verification, plus
    // its own compact metadata line below), so the search bar sits directly
    // under it with a small gap, and the category nav bar (full-bleed
    // tinted strip, not a card floating inside the page's own horizontal
    // padding) follows immediately: Store identity -> compact metadata ->
    // Search -> Compact category nav -> Collections, exactly the requested
    // order, reaching the first product collection noticeably sooner.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Branding V1 (2026-07-22) / readability fix (2026-07-23) —
          // MarketplaceStoreHeader now renders name/tagline/description
          // itself, below the banner (never overlaid on top of it — see
          // that widget's own header comment for why).
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: MarketplaceSearchBar(
              hintText: 'marketplace_search_products_in_store'.tr(),
              onChanged: onSearchChanged,
            ),
          ),
          // Store-scoped compact category nav bar (2026-07-19) — replaces
          // the old large circular-icon "Shop by Category" chip grid.
          // "All Categories" opens this store's own complete
          // product/category browser (MarketplaceAllCategoriesPage scoped
          // to storeCategories — never the global Marketplace catalog);
          // tapping a category preserves the EXISTING in-page filter
          // mechanism (onCategorySelected -> selectedCategoryKey -> the
          // "All Products" grid below narrows in place, same
          // removable-Chip affordance as before) rather than navigating to
          // a separate results page — this store page already IS the
          // category-results view once filtered, always still scoped to
          // this same orgId (never touches marketplaceBrowseProvider).
          if (navCategories.isNotEmpty)
            CommerceCategoryNavBar(
              categories: navCategories,
              selectedCategoryKey: selectedCategoryKey,
              onCategoryTap: onCategorySelected,
              onAllCategoriesTap: () => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: MarketplaceAllCategoriesPage(
                    categories: storeCategories,
                    onCategorySelected: onCategorySelected,
                  ),
                ),
              ),
            ),
          if (activeCategoryLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
                  label: Text(activeCategoryLabel),
                  onDeleted: () => onCategorySelected(null),
                  backgroundColor:
                      PatientAppColors.brandTeal.withValues(alpha: 0.12),
                  labelStyle: const TextStyle(
                    color: PatientAppColors.brandTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  deleteIconColor: PatientAppColors.brandTeal,
                ),
              ),
            ),
          if (!isFiltering && categoryCollections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: CommerceCollectionGrid(
                children: [
                  for (final collection in categoryCollections)
                    CommerceCollectionSection(
                      collection: collection,
                      // Store Home: the store is already obvious from
                      // context (header is right above) — never repeat it
                      // on every card.
                      showStoreName: false,
                      viewAllLabel: 'marketplace_view_all_from_store'.tr(),
                      onViewAll: () => Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: MarketplaceProductsPage(
                            initialCategoryKey: collection.categoryKey,
                            orgId: orgId,
                            storeName: storeName,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          MarketplaceSection(
            title: isFiltering
                ? 'marketplace_tab_products'.tr()
                : 'marketplace_all_products_in_store'.tr(),
            child: filteredProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Center(
                      child: Text(
                        'marketplace_no_products_found'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : MarketplaceProductGrid(
                    products: filteredProducts,
                    shrinkWrap: true,
                  ),
          ),
        ],
      ),
    );
  }
}
