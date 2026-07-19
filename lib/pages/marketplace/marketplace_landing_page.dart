import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_all_categories_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_action.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_nav_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
import 'package:trustydr/pages/marketplace/marketplace_collection_section.dart';
import 'package:trustydr/pages/marketplace/marketplace_orders_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_products_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_search_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_stores_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_widgets.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Marketplace landing page (Patient Marketplace, Phase 1C, browse-only).
///
/// Ecommerce-home structure, not a provider directory or a wall of tabs:
/// prominent search up top, then "Shop by Category" / "Popular Products" /
/// "Stores Near You" preview sections, each with a "View All" into its own
/// full browse page. Typing a search query replaces the whole discover body
/// with unified, labeled results (matching stores/products/categories) —
/// there is no separate "search results" navigation, matching how live
/// search behaves in mature shopping apps. One [marketplaceBrowseProvider]
/// call powers every section here and every "View All" destination; no
/// section switch or search keystroke ever triggers a new network request.
class MarketplaceLandingPage extends ConsumerStatefulWidget {
  const MarketplaceLandingPage({super.key});

  @override
  ConsumerState<MarketplaceLandingPage> createState() =>
      _MarketplaceLandingPageState();
}

class _MarketplaceLandingPageState
    extends ConsumerState<MarketplaceLandingPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(appLocationProvider);
    final browseAsync = ref.watch(marketplaceBrowseProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'marketplace_enter_stores'.tr(),
                showBack: true,
                height: 120,
                // My Orders entry point (Milestone 6 — the patient must
                // never rely only on the post-checkout SnackBar) alongside
                // the persistent Cart action. A small icon-only button, not
                // MarketplaceCartAction's badge treatment — orders have no
                // "unread count" concept to show.
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.receipt_long,
                            color: Colors.white, size: 20),
                        tooltip: 'marketplace_my_orders_title'.tr(),
                        onPressed: () => Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const MarketplaceOrdersPage(),
                          ),
                        ),
                      ),
                    ),
                    const MarketplaceCartAction(compact: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MarketplaceSearchBar(
                  hintText: 'marketplace_search_hint'.tr(),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: location == null ||
                        location.cityEn.isEmpty ||
                        location.provinceKey.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'select_city_first'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : browseAsync.when(
                        data: (data) => _searchQuery.trim().length >= 2
                            ? _SearchResultsView(
                                data: data, searchQuery: _searchQuery)
                            : _DiscoverView(data: data),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: PatientAppColors.brandTeal,
                          ),
                        ),
                        // Public browse (2026-07-15) — guests load the same
                        // data as logged-in patients, so any error here is a
                        // real network/server failure, never "please log
                        // in." Login is gated at protected-action tap time
                        // only (ensureMarketplaceLogin in
                        // marketplace_widgets.dart), never at browse load.
                        error: (err, __) => Center(
                          child: Text(
                            'error_generic'.tr(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
              ),
            ],
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

// ─── Discover (default) view ────────────────────────────────────────────────

/// Marketplace Home information architecture (2026-07-19 simplification —
/// removed a real "three competing category-entry patterns" defect: an
/// icon-based "Browse Categories" entry card, a small pill/chip row that
/// scrolled to it, AND the newer compact [CommerceCategoryNavBar], all
/// doing the same job). Current order: Search (page-level, above this
/// widget) -> compact Browse Stores row (store discovery is a genuinely
/// distinct action, kept) -> compact category nav bar -> category
/// collection sections -> Featured Stores. Stateless now — the old
/// scroll-to-section anchor mechanism this page used is gone along with
/// the pill row it powered.
///
/// "Featured Stores" (not "Stores Near You" / "Nearby Stores") is a
/// deliberately scalable section name — it does not encode proximity as the
/// section's identity, since at 1 pharmacy vs. 5,000+ the meaning of
/// "nearby" changes completely but "featured" does not. City/address still
/// appears as metadata on each store card (see MarketplaceStoreCard) — true
/// numeric distance is NOT available today (no lat/lng captured or
/// distance computed anywhere in the current data model) and is
/// deliberately not fabricated here.
class _DiscoverView extends StatelessWidget {
  const _DiscoverView({required this.data});

  final MarketplaceBrowseData data;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'marketplace_no_stores_found'.tr(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final featuredStores = data.stores.take(8).toList();

    // Milestone 5 (Marketplace Home upgrade, 2026-07-19) — the flat,
    // single "Popular Products" rail (sorted only by isFeatured, no
    // category grouping at all) is replaced with one collection section
    // PER featured global category that currently has at least one
    // eligible public product — real Category Engine taxonomy, never a
    // hardcoded category list (see buildCategoryCollections' own doc
    // comment for the onlyFeatured/curation rule). Built entirely from
    // data this page already has in memory — zero extra network requests.
    final categoryCollections = buildCategoryCollections(
      products: data.products,
      categories: data.categories,
      lang: lang,
      onlyFeatured: true,
    );
    // Same featured, has-products category set the collections below
    // already use, kept in sync so the nav bar never offers a tap-through
    // to a category with no corresponding collection.
    final navCategories = [
      for (final c in categoryCollections)
        CommerceCategoryNavItem(
            categoryKey: c.categoryKey, label: c.categoryName),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          // Store discovery — kept (distinct purpose from category
          // browsing), but as ONE compact row instead of an equal-weight
          // pairing with the now-removed category entry card.
          if (data.stores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BrowseStoresRow(
                storeCount: data.stores.length,
                onTap: () => Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: MarketplaceStoresPage(data: data),
                  ),
                ),
              ),
            ),
          // Compact text-only category nav bar — the ONLY category-entry
          // pattern left near the top (2026-07-19 Issue 3 cleanup).
          // "All Categories" opens the full category browser.
          if (navCategories.isNotEmpty) ...[
            SizedBox(height: data.stores.isNotEmpty ? 14 : 6),
            CommerceCategoryNavBar(
              categories: navCategories,
              selectedCategoryKey: null,
              onCategoryTap: (categoryKey) => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child:
                      MarketplaceProductsPage(initialCategoryKey: categoryKey),
                ),
              ),
              onAllCategoriesTap: () => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: MarketplaceAllCategoriesPage(
                    categories: data.categories,
                    onCategorySelected: (id) => Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: MarketplaceProductsPage(initialCategoryKey: id),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (categoryCollections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: CommerceCollectionGrid(
                children: [
                  for (final collection in categoryCollections)
                    CommerceCollectionSection(
                      collection: collection,
                      // Cross-store Home: show which pharmacy each
                      // product belongs to, avoiding ambiguity — the
                      // same showStoreName toggle every other
                      // cross-store product surface in this app uses.
                      showStoreName: true,
                      onViewAll: () => Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: MarketplaceProductsPage(
                            initialCategoryKey: collection.categoryKey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (featuredStores.isNotEmpty)
            MarketplaceSection(
              // "Featured Stores", not "Nearby"/"Stores Near You" — a
              // deliberately scalable section name that doesn't encode
              // proximity as its identity. City/address still shows as
              // metadata on each card (see MarketplaceStoreCard) — real
              // numeric distance isn't available in the data model today.
              title: 'marketplace_featured_stores'.tr(),
              viewAllLabel: 'marketplace_view_all_stores'.tr(),
              onViewAll: () => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: MarketplaceStoresPage(data: data),
                ),
              ),
              child: SizedBox(
                height: 234,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featuredStores.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 260,
                    child: MarketplaceStoreCard(
                      store: featuredStores[i],
                      categorySummary: _categorySummaryFor(
                          data, featuredStores[i].orgId, lang),
                      categoryCount:
                          _categoryCountFor(data, featuredStores[i].orgId),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String? _categorySummaryFor(
      MarketplaceBrowseData data, String orgId, String lang) {
    final names = <String>{};
    for (final p in data.products) {
      if (p.orgId != orgId) continue;
      final name = p.localizedCategoryName(lang);
      if (name != null && name.isNotEmpty) names.add(name);
      if (names.length >= 2) break;
    }
    return names.isEmpty ? null : names.join(' · ');
  }

  static int _categoryCountFor(MarketplaceBrowseData data, String orgId) {
    return distinctCategoryCount(
      data.products.where((p) => p.orgId == orgId).toList(),
    );
  }
}

/// Compact single-row Store Discovery entry (2026-07-19 simplification) —
/// replaces the old equal-weight 2-card row (Categories + Stores). Category
/// browsing now lives entirely in [CommerceCategoryNavBar]; this row keeps
/// exactly the one remaining distinct action, "Browse Stores," at a much
/// smaller footprint than the old oversized icon card.
class _BrowseStoresRow extends StatelessWidget {
  const _BrowseStoresRow({required this.storeCount, required this.onTap});

  final int storeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // This app's own RTL source of truth (matches main.dart's top-level
    // Directionality switch) — a forward-pointing chevron must point left
    // under RTL, never automatic icon mirroring.
    final isRtl = context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'ku';

    return Material(
      color: PatientAppColors.brandTeal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  size: 18, color: PatientAppColors.brandTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'marketplace_entry_stores_title'.tr(),
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    if (storeCount > 0) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'marketplace_store_count'
                              .tr(namedArgs: {'count': '$storeCount'}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: PatientAppColors.brandTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search results view ────────────────────────────────────────────────────

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({required this.data, required this.searchQuery});

  final MarketplaceBrowseData data;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final q = searchQuery.trim().toLowerCase();

    final matchingStores = data.stores
        .where((s) => s.localizedName(lang).toLowerCase().contains(q))
        .toList();
    final matchingProducts = data.products
        .where((p) =>
            p.localizedName(lang).toLowerCase().contains(q) ||
            (p.brandName ?? '').toLowerCase().contains(q))
        .toList();
    final matchingCategories = data.categories
        .where((c) => c.localizedName(lang).toLowerCase().contains(q))
        .toList();

    if (matchingStores.isEmpty &&
        matchingProducts.isEmpty &&
        matchingCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'marketplace_no_search_results'.tr(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (matchingCategories.isNotEmpty) ...[
            _SearchSectionHeader(
              title: 'marketplace_tab_categories'.tr(),
              count: matchingCategories.length,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: matchingCategories
                    .map(
                      (c) => ActionChip(
                        label: Text(c.localizedName(lang)),
                        onPressed: () => Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: MarketplaceProductsPage(
                              initialCategoryKey: c.categoryKey,
                            ),
                          ),
                        ),
                        backgroundColor:
                            PatientAppColors.brandTeal.withValues(alpha: 0.10),
                        labelStyle: const TextStyle(
                          color: PatientAppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (matchingStores.isNotEmpty) ...[
            _SearchSectionHeader(
              title: 'marketplace_tab_stores'.tr(),
              count: matchingStores.length,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: matchingStores
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MarketplaceStoreCard(store: s),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (matchingProducts.isNotEmpty) ...[
            _SearchSectionHeader(
              title: 'marketplace_tab_products'.tr(),
              count: matchingProducts.length,
            ),
            SizedBox(
              height:
                  168.0 + marketplaceProductCardTextHeight(showStoreName: true),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matchingProducts.length,
                separatorBuilder: (context, i) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 168,
                  child: MarketplaceProductCard(
                    product: matchingProducts[i],
                    showStoreName: true,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Text(
        '$title ($count)',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}
