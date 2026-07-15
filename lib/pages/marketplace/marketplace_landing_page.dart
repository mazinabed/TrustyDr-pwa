import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_all_categories_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
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

/// Marketplace Home information architecture (2026-07-15 "Dual-Path Hybrid"
/// pass, approved after a 3-layout UX proposal comparing Store-First,
/// Product-First, and this hybrid against Amazon/Walmart/Target/Noon/iHerb
/// and — the closer structural match for a multi-pharmacy marketplace —
/// Instacart/DoorDash-style vendor marketplaces). Adapted for TrustyDr
/// rather than copied from any one competitor:
///
/// Search -> an equal-weight "how would you like to shop?" entry row
/// (Browse by Category / Browse Stores) -> Popular Products -> Featured
/// Stores. Categories and Stores are deliberately given identical visual
/// weight as parallel entry points (neither is "the" primary axis) rather
/// than the previous single ordered stack, which read as an administrative
/// directory regardless of which section came first.
///
/// "Featured Stores" (not "Stores Near You" / "Nearby Stores") is a
/// deliberately scalable section name — it does not encode proximity as the
/// section's identity, since at 1 pharmacy vs. 5,000+ the meaning of
/// "nearby" changes completely but "featured" does not. City/address still
/// appears as metadata on each store card (see MarketplaceStoreCard) — true
/// numeric distance is NOT available today (no lat/lng captured or
/// distance computed anywhere in the current data model) and is
/// deliberately not fabricated here.
class _DiscoverView extends StatefulWidget {
  const _DiscoverView({required this.data});

  final MarketplaceBrowseData data;

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
  final _storesKey = GlobalKey();
  final _popularKey = GlobalKey();

  Future<void> _scrollTo(GlobalKey key) async {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
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

    final popularProducts = (List.of(data.products)
          ..sort((a, b) => (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0)))
        .take(12)
        .toList();

    final featuredStores = data.stores.take(8).toList();

    // Popular Products rail card size — MUST derive from
    // marketplaceProductCardTextHeight(), never an independent guess. A
    // hardcoded, unreconciled height/width pair here (150 wide -> a 150px
    // image, leaving only ~86px for a 2-line title + price + availability +
    // store byline) was the exact cause of a real "BOTTOM OVERFLOWED BY 34
    // PIXELS" report. Width 168 (rather than the old 150) gives 2-line
    // Arabic titles more breathing room; height is computed, not guessed.
    const railCardWidth = 168.0;
    final railCardHeight =
        railCardWidth + marketplaceProductCardTextHeight(showStoreName: true);

    final navItems = <_SectionNavItem>[
      if (popularProducts.isNotEmpty)
        _SectionNavItem(
          label: 'marketplace_section_popular'.tr(),
          onTap: () => _scrollTo(_popularKey),
        ),
      if (featuredStores.isNotEmpty)
        _SectionNavItem(
          label: 'marketplace_tab_stores'.tr(),
          onTap: () => _scrollTo(_storesKey),
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          // Categories and Stores as EQUAL-WEIGHT entry points — neither is
          // "the" primary discovery axis. Resolves the tension between
          // "patients search for products first" (still true — Popular
          // Products stays the dominant content below) and "stores need to
          // feel like real storefronts, not directory entries" by giving
          // each its own dignified "how would you like to shop" choice
          // up front, then converging into one shared product feed.
          _EntryPointRow(
            categoryCount: data.categories.where((c) => c.level == 0).length,
            storeCount: data.stores.length,
            onBrowseCategories: () => Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: MarketplaceAllCategoriesPage(
                  categories: data.categories,
                  onCategorySelected: (id) {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: MarketplaceProductsPage(initialCategoryKey: id),
                      ),
                    );
                  },
                ),
              ),
            ),
            onBrowseStores: () => Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: MarketplaceStoresPage(data: data),
              ),
            ),
          ),
          if (navItems.length > 1) ...[
            const SizedBox(height: 20),
            _SectionNavBar(items: navItems),
          ],
          if (popularProducts.isNotEmpty)
            MarketplaceSection(
              key: _popularKey,
              title: 'marketplace_popular_products'.tr(),
              onViewAll: () => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const MarketplaceProductsPage(),
                ),
              ),
              child: SizedBox(
                height: railCardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularProducts.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: railCardWidth,
                    child: MarketplaceProductCard(
                      product: popularProducts[i],
                      showStoreName: true,
                      // Badge is an exception signal, not decoration — only
                      // the single top-ranked item in this curated rail
                      // gets it, never every card.
                      highlightBadge: i == 0,
                    ),
                  ),
                ),
              ),
            ),
          if (featuredStores.isNotEmpty)
            MarketplaceSection(
              key: _storesKey,
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
                      categorySummary:
                          _categorySummaryFor(featuredStores[i].orgId, lang),
                      categoryCount: _categoryCountFor(featuredStores[i].orgId),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? _categorySummaryFor(String orgId, String lang) {
    final names = <String>{};
    for (final p in widget.data.products) {
      if (p.orgId != orgId) continue;
      final name = p.localizedCategoryName(lang);
      if (name != null && name.isNotEmpty) names.add(name);
      if (names.length >= 2) break;
    }
    return names.isEmpty ? null : names.join(' · ');
  }

  int _categoryCountFor(String orgId) {
    return distinctCategoryCount(
      widget.data.products.where((p) => p.orgId == orgId).toList(),
    );
  }
}

/// One tappable entry in the slim section-nav pill row (Noon/iHerb pattern:
/// scroll to a section in place, never a route change or tab switch).
class _SectionNavItem {
  const _SectionNavItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

class _SectionNavBar extends StatelessWidget {
  const _SectionNavBar({required this.items});

  final List<_SectionNavItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return Material(
            color: PatientAppColors.brandTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The "how would you like to shop?" entry row — Categories and Stores as
/// deliberately EQUAL-weight parallel entry points into the Marketplace
/// (2026-07-15 Dual-Path Hybrid IA). Neither card outranks the other in
/// size, color, or position; the only difference is icon/label/count.
class _EntryPointRow extends StatelessWidget {
  const _EntryPointRow({
    required this.categoryCount,
    required this.storeCount,
    required this.onBrowseCategories,
    required this.onBrowseStores,
  });

  final int categoryCount;
  final int storeCount;
  final VoidCallback onBrowseCategories;
  final VoidCallback onBrowseStores;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _EntryCard(
              icon: Icons.grid_view_rounded,
              title: 'marketplace_entry_categories_title'.tr(),
              subtitle: categoryCount > 0
                  ? 'marketplace_category_count'
                      .tr(namedArgs: {'count': categoryCount.toString()})
                  : null,
              onTap: onBrowseCategories,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _EntryCard(
              icon: Icons.storefront_rounded,
              title: 'marketplace_entry_stores_title'.tr(),
              subtitle: storeCount > 0
                  ? 'marketplace_store_count'
                      .tr(namedArgs: {'count': storeCount.toString()})
                  : null,
              onTap: onBrowseStores,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PatientAppColors.brandTeal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: PatientAppColors.brandTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: PatientAppColors.brandTeal),
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
