import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_action.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_tree_nav.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_search_bar.dart';
import 'package:trustydr/pages/marketplace/marketplace_sort.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Full Products browse (Patient Marketplace, Phase 1C, browse-only) — a
/// proper ecommerce product-list page: result count, Categories/Filters,
/// Sort, and a responsive grid. Mobile opens category navigation as a
/// near-full-height bottom sheet; wide screens show a persistent sidebar
/// instead (left in LTR, right in RTL, via ambient Directionality — no
/// manual side-swapping logic needed).
///
/// Two scopes, chosen by whether [orgId] is set (Milestone 5, "See All"
/// navigation must never lose organization scope, 2026-07-19):
/// - Cross-store (orgId null): watches [marketplaceBrowseProvider] directly
///   (same shared, already-fetched data every other cross-store Marketplace
///   screen watches) rather than taking a data snapshot as a constructor
///   param — this is what lets "Load More" (bumping
///   [marketplaceProductsLimitProvider]) refresh this page in place. The
///   Marketplace Home "See All" (global category collections) uses this.
/// - Store-scoped (orgId set): watches [marketplaceCatalogProvider(orgId)]
///   instead — the SAME provider the Pharmacy Store Home page itself
///   already uses, so arriving here from that page's own "See All From
///   This Pharmacy" never re-fetches. No "Load More" in this scope (the
///   store catalog call already returns the store's complete catalog in
///   one request, unlike the cross-store browse call's deliberate limit).
class MarketplaceProductsPage extends ConsumerStatefulWidget {
  const MarketplaceProductsPage({
    super.key,
    this.initialCategoryKey,
    this.orgId,
    this.storeName,
  });

  final String? initialCategoryKey;
  // Store-scope identity for a "See All From This Pharmacy" navigation —
  // null means the ordinary cross-store Products browse. Never derived or
  // guessed here: the caller (MarketplaceStorePage) already has its own
  // real orgId and passes it straight through.
  final String? orgId;
  final String? storeName;

  @override
  ConsumerState<MarketplaceProductsPage> createState() =>
      _MarketplaceProductsPageState();
}

class _MarketplaceProductsPageState
    extends ConsumerState<MarketplaceProductsPage> {
  String _searchQuery = '';
  String? _categoryFilterKey;
  MarketplaceProductSort _sort = MarketplaceProductSort.recommended;

  static const double _desktopBreakpoint = 900;
  static const double _sidebarWidth = 220;

  @override
  void initState() {
    super.initState();
    _categoryFilterKey = widget.initialCategoryKey;
  }

  Future<void> _openSort() async {
    final picked = await showMarketplaceSortSheet(context, _sort);
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _openCategorySheetMobile(
    List<MarketplaceCategory> categories,
    Map<String, int> categoryCounts,
  ) async {
    final picked = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'marketplace_categories'.tr(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Expanded(
                child: MarketplaceCategoryTreeNav(
                  categories: categories,
                  selectedCategoryKey: _categoryFilterKey,
                  productCountByCategoryKey: categoryCounts,
                  onSelect: (id) =>
                      Navigator.pop(context, id ?? _CategoryNavCleared()),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (picked is _CategoryNavCleared) {
      setState(() => _categoryFilterKey = null);
    } else if (picked is String) {
      setState(() => _categoryFilterKey = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = widget.orgId;

    // Store-scoped "See All From This Pharmacy" — same
    // marketplaceCatalogProvider(orgId) the Pharmacy Store Home page
    // itself watches, so navigating here right after that page never
    // re-fetches (Riverpod family caching). No cross-store data ever
    // enters this branch.
    if (orgId != null) {
      final catalogAsync = ref.watch(marketplaceCatalogProvider(orgId));
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: catalogAsync.when(
          data: (catalog) => _buildBody(
            context,
            products: catalog.products,
            categories: catalog.categories,
            hasMoreProducts: false,
            showStoreName: false,
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: PatientAppColors.brandTeal),
          ),
          error: (err, __) => Center(
            child: Text(
              'error_generic'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final browseAsync = ref.watch(marketplaceBrowseProvider);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: browseAsync.when(
        data: (data) => _buildBody(
          context,
          products: data.products,
          categories: data.categories,
          hasMoreProducts: data.hasMoreProducts,
          showStoreName: true,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: PatientAppColors.brandTeal),
        ),
        // Public browse (2026-07-15) — see marketplace_landing_page.dart's
        // matching comment.
        error: (err, __) => Center(
          child: Text(
            'error_generic'.tr(),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<MarketplaceProduct> products,
    required List<MarketplaceCategory> categories,
    required bool hasMoreProducts,
    required bool showStoreName,
  }) {
    final lang = context.locale.languageCode;
    final categoryCounts = computeCategoryProductCounts(categories, products);

    var filtered = products;
    String pageTitle = widget.storeName ?? 'marketplace_tab_products'.tr();
    if (_categoryFilterKey != null) {
      final descendantKeys =
          descendantCategoryKeys(categories, _categoryFilterKey!);
      filtered = filtered
          .where(
              (p) => p.categoryKeys.any((key) => descendantKeys.contains(key)))
          .toList();
      final match =
          categories.where((c) => c.categoryKey == _categoryFilterKey).toList();
      if (match.isNotEmpty) {
        pageTitle = widget.storeName != null
            ? '${widget.storeName} · ${match.first.localizedName(lang)}'
            : match.first.localizedName(lang);
      }
    }
    if (_searchQuery.trim().length >= 2) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered
          .where((p) =>
              p.localizedName(lang).toLowerCase().contains(q) ||
              (p.brandName ?? '').toLowerCase().contains(q))
          .toList();
    }
    filtered = sortMarketplaceProducts(filtered, _sort, lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

        Widget grid = filtered.isEmpty
            ? Center(
                child: Text(
                  'marketplace_no_products_found'.tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: MarketplaceProductGrid(
                        products: filtered, showStoreName: showStoreName),
                  ),
                  if (hasMoreProducts) _LoadMoreButton(ref: ref),
                ],
              );

        Widget resultArea = Column(
          children: [
            _ResultHeader(
              count: filtered.length,
              sortLabel: _sort.l10nKey.tr(),
              showCategoriesButton: !isDesktop,
              onCategoriesTap: () =>
                  _openCategorySheetMobile(categories, categoryCounts),
              onSortTap: _openSort,
            ),
            Expanded(child: grid),
          ],
        );

        Widget body;
        if (isDesktop) {
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _sidebarWidth,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 560,
                    child: MarketplaceCategoryTreeNav(
                      categories: categories,
                      selectedCategoryKey: _categoryFilterKey,
                      productCountByCategoryKey: categoryCounts,
                      onSelect: (id) => setState(() => _categoryFilterKey = id),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: resultArea),
            ],
          );
        } else {
          body = resultArea;
        }

        Widget content = Column(
          children: [
            TrustyDrCurvedHeader(
              title: pageTitle,
              showBack: true,
              height: 120,
              trailing: const MarketplaceCartAction(compact: true),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MarketplaceSearchBar(
                hintText: 'marketplace_search_products'.tr(),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            if (_categoryFilterKey != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Chip(
                    label: Text(pageTitle),
                    onDeleted: () => setState(() => _categoryFilterKey = null),
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
            const SizedBox(height: 4),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 0),
                child: body,
              ),
            ),
          ],
        );
        if (constraints.maxWidth >= 768) {
          content = WebScaffoldContainer(child: content);
        }
        return content;
      },
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: OutlinedButton(
        onPressed: () =>
            ref.read(marketplaceProductsLimitProvider.notifier).loadMore(),
        style: OutlinedButton.styleFrom(
          foregroundColor: PatientAppColors.brandTeal,
          side: const BorderSide(color: PatientAppColors.brandTeal),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        ),
        child: Text('marketplace_load_more'.tr()),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.count,
    required this.sortLabel,
    required this.showCategoriesButton,
    required this.onCategoriesTap,
    required this.onSortTap,
  });

  final int count;
  final String sortLabel;
  final bool showCategoriesButton;
  final VoidCallback onCategoriesTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'marketplace_product_count'
                  .tr(namedArgs: {'count': count.toString()}),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          if (showCategoriesButton) ...[
            _HeaderChipButton(
              icon: Icons.category_outlined,
              label: 'marketplace_categories'.tr(),
              onTap: onCategoriesTap,
            ),
            const SizedBox(width: 8),
          ],
          _HeaderChipButton(
            icon: Icons.swap_vert_rounded,
            label: sortLabel,
            onTap: onSortTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderChipButton extends StatelessWidget {
  const _HeaderChipButton(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        constraints: const BoxConstraints(maxWidth: 140),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: PatientAppColors.brandTeal),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sentinel distinguishing "user tapped All Products" (clear filter) from
/// "sheet dismissed without a choice" (null) when popping the mobile
/// category bottom sheet.
class _CategoryNavCleared {}
