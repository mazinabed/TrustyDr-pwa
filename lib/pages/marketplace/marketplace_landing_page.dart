import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_all_categories_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_products_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_search_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_stores_page.dart';
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
                        error: (err, __) => Center(
                          child: Text(
                            err is MarketplaceAuthRequiredException
                                ? 'marketplace_login_required'.tr()
                                : 'error_generic'.tr(),
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

    final topLevelCategories = data.categories
        .where((c) => c.parentEngineId == null)
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final popularProducts = (List.of(data.products)
          ..sort((a, b) => (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0)))
        .take(12)
        .toList();

    final nearbyStores = data.stores.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topLevelCategories.isNotEmpty)
            _Section(
              title: 'marketplace_shop_by_category'.tr(),
              onViewAll: () => Navigator.push(
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
                          child: MarketplaceProductsPage(
                            initialCategoryEngineId: id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              child: _CategoryShortcutGrid(
                categories: topLevelCategories.take(7).toList(),
                lang: lang,
                onCategoryTap: (id) => Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: MarketplaceProductsPage(initialCategoryEngineId: id),
                  ),
                ),
                onOpenAllCategories: () => Navigator.push(
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
                            child: MarketplaceProductsPage(
                              initialCategoryEngineId: id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          if (popularProducts.isNotEmpty)
            _Section(
              title: 'marketplace_popular_products'.tr(),
              onViewAll: () => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const MarketplaceProductsPage(),
                ),
              ),
              child: SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularProducts.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 150,
                    child: MarketplaceProductCard(
                      product: popularProducts[i],
                      showStoreName: true,
                    ),
                  ),
                ),
              ),
            ),
          if (nearbyStores.isNotEmpty)
            _Section(
              title: 'marketplace_stores_near_you'.tr(),
              viewAllLabel: 'marketplace_view_all_stores'.tr(),
              onViewAll: () => Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: MarketplaceStoresPage(data: data),
                ),
              ),
              // Same scalable horizontal-card pattern regardless of count —
              // one store today still renders through this exact path, not
              // a special-cased single-card layout.
              child: SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: nearbyStores.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 260,
                    child: MarketplaceStoreCard(
                      store: nearbyStores[i],
                      categorySummary:
                          _categorySummaryFor(nearbyStores[i].orgId, lang),
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
    for (final p in data.products) {
      if (p.orgId != orgId) continue;
      final name = p.localizedCategoryName(lang);
      if (name != null && name.isNotEmpty) names.add(name);
      if (names.length >= 2) break;
    }
    return names.isEmpty ? null : names.join(' · ');
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.onViewAll,
    required this.child,
    this.viewAllLabel,
  });

  final String title;
  final VoidCallback onViewAll;
  final Widget child;
  final String? viewAllLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    viewAllLabel ?? 'marketplace_view_all'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CategoryShortcutGrid extends StatelessWidget {
  const _CategoryShortcutGrid({
    required this.categories,
    required this.lang,
    required this.onCategoryTap,
    required this.onOpenAllCategories,
  });

  final List<MarketplaceCategory> categories;
  final String lang;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onOpenAllCategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 640 ? 6 : 4;
          return GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...categories.map(
                (c) => _CategoryTile(
                  icon: Icons.category_outlined,
                  label: c.localizedName(lang),
                  onTap: () => onCategoryTap(c.engineId),
                ),
              ),
              _CategoryTile(
                icon: Icons.apps_rounded,
                label: 'marketplace_all_categories'.tr(),
                onTap: onOpenAllCategories,
                emphasized: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: emphasized
                  ? PatientAppColors.brandTeal
                  : PatientAppColors.brandTeal.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: emphasized ? Colors.white : PatientAppColors.brandTeal,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
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
                              initialCategoryEngineId: c.engineId,
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
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: matchingProducts.length,
                separatorBuilder: (context, i) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 150,
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
