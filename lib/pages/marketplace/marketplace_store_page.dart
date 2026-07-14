import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_all_categories_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_search_bar.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// A single pharmacy's Store — "Shop by Category" grid + product grid +
/// search (Patient Marketplace, Phase 1C, browse-only). Fetches the catalog
/// via [marketplaceCatalogProvider], the same call the pharmacy profile
/// page's "Visit Store" button already made to decide whether to show
/// itself — Riverpod's family caching means arriving here right after that
/// tap does not re-fetch.
class MarketplaceStorePage extends ConsumerStatefulWidget {
  const MarketplaceStorePage({
    super.key,
    required this.providerId,
    required this.orgId,
    required this.storeName,
  });

  final String providerId;
  final String orgId;
  final String storeName;

  @override
  ConsumerState<MarketplaceStorePage> createState() =>
      _MarketplaceStorePageState();
}

class _MarketplaceStorePageState extends ConsumerState<MarketplaceStorePage> {
  String? _selectedCategoryEngineId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(marketplaceCatalogProvider(widget.orgId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: widget.storeName,
                showBack: true,
                height: 140,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: catalogAsync.when(
                  data: (catalog) => _StoreBody(
                    catalog: catalog,
                    selectedCategoryEngineId: _selectedCategoryEngineId,
                    searchQuery: _searchQuery,
                    onCategorySelected: (id) =>
                        setState(() => _selectedCategoryEngineId = id),
                    onSearchChanged: (val) =>
                        setState(() => _searchQuery = val),
                  ),
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

class _StoreBody extends StatelessWidget {
  const _StoreBody({
    required this.catalog,
    required this.selectedCategoryEngineId,
    required this.searchQuery,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  final MarketplaceCatalog catalog;
  final String? selectedCategoryEngineId;
  final String searchQuery;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  static const int _maxCategoryTiles = 7; // + "All Categories" tile = 8

  @override
  Widget build(BuildContext context) {
    if (catalog.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
      );
    }

    final lang = context.locale.languageCode;

    var products = catalog.products;
    String? activeCategoryLabel;
    if (selectedCategoryEngineId != null) {
      final descendantIds =
          descendantCategoryIds(catalog.categories, selectedCategoryEngineId!);
      products = products
          .where((p) => descendantIds.contains(p.categoryEngineId))
          .toList();
      final match = catalog.categories
          .where((c) => c.engineId == selectedCategoryEngineId)
          .toList();
      if (match.isNotEmpty) {
        activeCategoryLabel = match.first.localizedName(lang);
      }
    }
    if (searchQuery.isNotEmpty && searchQuery.length >= 2) {
      final q = searchQuery.toLowerCase();
      products = products
          .where((p) =>
              p.localizedName(lang).toLowerCase().contains(q) ||
              (p.brandName ?? '').toLowerCase().contains(q))
          .toList();
    }

    final topLevelCategories = catalog.categories
        .where((c) => c.parentEngineId == null)
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MarketplaceSearchBar(
            hintText: 'marketplace_search_products'.tr(),
            onChanged: onSearchChanged,
          ),
        ),
        if (topLevelCategories.isNotEmpty &&
            selectedCategoryEngineId == null) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'marketplace_shop_by_category'.tr(),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ShopByCategoryGrid(
              categories: topLevelCategories.take(_maxCategoryTiles).toList(),
              lang: lang,
              onCategorySelected: onCategorySelected,
              onOpenAllCategories: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: MarketplaceAllCategoriesPage(
                      categories: catalog.categories,
                      onCategorySelected: onCategorySelected,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
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
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Text(
                    'marketplace_no_products_found'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : MarketplaceProductGrid(products: products),
        ),
      ],
    );
  }
}

/// Compact two-row "Shop by Category" grid — up to 7 top-level categories
/// plus a trailing "All Categories" tile, never the full unlimited
/// horizontal chip row this replaced (didn't scale to dozens of
/// categories/subcategories).
class _ShopByCategoryGrid extends StatelessWidget {
  const _ShopByCategoryGrid({
    required this.categories,
    required this.lang,
    required this.onCategorySelected,
    required this.onOpenAllCategories,
  });

  final List<MarketplaceCategory> categories;
  final String lang;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onOpenAllCategories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                onTap: () => onCategorySelected(c.engineId),
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
