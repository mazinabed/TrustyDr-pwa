import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_category_utils.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';

/// Milestone 5 (Marketplace Home / Pharmacy Store Home upgrade, 2026-07-19)
/// — the ONE reusable category-collection surface both pages render N of.
/// Deliberately generic: it receives a title, a small product sample, a
/// count, and a "See All" action — it has no idea whether that data came
/// from the global featured-category set (Marketplace Home), one
/// pharmacy's own catalog (Pharmacy Store Home), or (later, NOT built now)
/// a seasonal/sponsored/recommendation source. Adding a future source is
/// purely a caller-side concern — this widget never changes for it.
///
/// Visual language matches the Product Details page's own accordion cards
/// (`_CollapsibleSection`) rather than the old heavier "MarketplaceSection"
/// card: white surface, modest rounded corners, no heavy shadow, a clear
/// title + See All row. The product grid itself is a plain 2-column,
/// non-scrolling `Wrap`-free grid capped at whatever [collection] already
/// sampled (1-4 items) — never padded with empty placeholder cells to force
/// a complete 2x2, and never re-fetches anything: [collection] is built
/// once, client-side, from data the caller already has in memory (see
/// [buildCategoryCollections]).
class CommerceCollectionSection extends StatelessWidget {
  const CommerceCollectionSection({
    super.key,
    required this.collection,
    required this.showStoreName,
    required this.onViewAll,
    this.viewAllLabel,
  });

  final MarketplaceCategoryCollection collection;
  // Home shows the pharmacy name subtly on each card (cross-store context,
  // avoids ambiguity); Store Home never does (already obvious which store
  // this is) — same [MarketplaceProductCard.showStoreName] toggle every
  // other product surface in this app already uses, not a new concept.
  final bool showStoreName;
  final VoidCallback onViewAll;
  // Defaults to the generic "See All" — Pharmacy Store Home overrides this
  // to "See All From This Pharmacy" (marketplace_view_all_from_store),
  // matching the approved Store Home wording without this widget itself
  // needing to know which caller it is.
  final String? viewAllLabel;

  @override
  Widget build(BuildContext context) {
    final products = collection.sampleProducts;
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    collection.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        viewAllLabel ?? 'marketplace_view_all'.tr(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: PatientAppColors.brandTeal,
                        ),
                      ),
                      // This glyph always literally points right — under
                      // RTL, a "forward/more" affordance should point left
                      // instead. Picked from the current locale (Arabic/
                      // Kurdish are this app's only RTL locales — the same
                      // source of truth main.dart's own top-level RTL
                      // switch uses), never automatic icon mirroring.
                      Icon(
                        _isRtlLang(context.locale.languageCode)
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 16,
                        color: PatientAppColors.brandTeal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: _CompactProductGrid(
              products: products,
              showStoreName: showStoreName,
            ),
          ),
        ],
      ),
    );
  }
}

/// This app's own RTL source of truth (matches main.dart's top-level
/// Directionality switch exactly) — Arabic and Kurdish are the only RTL
/// locales; everything else (English) is LTR.
bool _isRtlLang(String lang) => lang == 'ar' || lang == 'ku';

/// Always exactly 2 columns regardless of screen width — this is a small
/// PREVIEW grid inside an already width-constrained collection card, not
/// the main browse grid ([MarketplaceProductGrid] is the responsive
/// 2-5-column widget for that; reused here for the tile itself, just not
/// for its column-count logic). Natural row count for 1-4 products: 1
/// product is a single tile (no forced second empty cell), 3 products
/// leave the fourth cell empty-but-unfilled by nothing (GridView simply
/// has 3 children, no placeholder).
class _CompactProductGrid extends StatelessWidget {
  const _CompactProductGrid(
      {required this.products, required this.showStoreName});

  final List<MarketplaceProduct> products;
  final bool showStoreName;

  static const int _columns = 2;
  static const double _spacing = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - _spacing * (_columns - 1)) / _columns;
        final mainAxisExtent = cellWidth +
            marketplaceProductCardTextHeight(showStoreName: showStoreName);

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => MarketplaceProductCard(
            product: products[i],
            showStoreName: showStoreName,
          ),
        );
      },
    );
  }
}

/// How many collection cards share a row at a given available width — the
/// section-level analogue of [marketplaceGridColumnCount] (which governs
/// PRODUCT columns inside the full browse grid). Approximate breakpoints
/// per the approved responsive direction: ~3-4 across large desktop, ~2
/// across tablet, 1 per row on mobile. Width-derived, never a device-name
/// or fixed-browser-width assumption.
int marketplaceCollectionColumnCount(double width) {
  if (width >= 1400) return 4;
  if (width >= 1000) return 3;
  if (width >= 700) return 2;
  return 1;
}

/// Lays out a list of collection sections in a responsive multi-column
/// wrap — 1 per row on mobile, up to 4 across on large desktop (see
/// [marketplaceCollectionColumnCount]). A plain [Wrap] rather than a
/// [GridView] because collection cards are NOT uniform height (a
/// 1-product category card is shorter than a 4-product one) — a Wrap lets
/// each row's cards size to their own natural content height instead of
/// forcing every card in a row to match the tallest, which is exactly the
/// kind of fixed/forced sizing this whole page redesign has been moving
/// away from.
class CommerceCollectionGrid extends StatelessWidget {
  const CommerceCollectionGrid({super.key, required this.children});

  final List<Widget> children;

  static const double _spacing = 14.0;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = marketplaceCollectionColumnCount(constraints.maxWidth);
        if (columns <= 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: _spacing),
                children[i],
              ],
            ],
          );
        }
        final cellWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final child in children)
              SizedBox(width: cellWidth, child: child),
          ],
        );
      },
    );
  }
}
