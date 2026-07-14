import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_detail_page.dart';

/// Shared product grid tile — used by both the Marketplace landing page's
/// Products tab (cross-store) and a single Store page's product grid.
/// [showStoreName] surfaces which store a product belongs to; only
/// meaningful for cross-store results, so the Store page (where the store
/// is already obvious from context) passes false.
class MarketplaceProductCard extends StatelessWidget {
  const MarketplaceProductCard({
    super.key,
    required this.product,
    this.showStoreName = false,
  });

  final MarketplaceProduct product;
  final bool showStoreName;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final price = product.displayPrice.toStringAsFixed(
      product.displayPrice.truncateToDouble() == product.displayPrice ? 0 : 2,
    );
    final currency = product.currencyName ?? '';
    final storeName = showStoreName ? product.localizedStoreName(lang) : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 300),
            child: MarketplaceProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _ProductImage(imageUrl: product.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (storeName != null && storeName.isNotEmpty) ...[
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color:
                            PatientAppColors.brandTeal.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    product.localizedName(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$price $currency'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                  if (product.availabilityL10nKey.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.availabilityL10nKey.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PatientAppColors.statusConfirmed
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid cell height budget: image square + a fixed, generous text-block
/// height (name up to 2 lines + price + availability + optional store-name
/// line) instead of a guessed aspect ratio — guarantees the content always
/// fits regardless of font metrics or language, so it can never
/// RenderFlex-overflow. Callers building a GridView should compute
/// `cellWidth + kMarketplaceProductCardTextHeight(showStoreName)`.
double marketplaceProductCardTextHeight({bool showStoreName = false}) =>
    showStoreName ? 118.0 : 100.0;

/// Column count for a given available width — 2 columns on mobile, scaling
/// up on tablet/desktop so wide screens aren't left with a narrow phone-
/// width column of stretched cards.
int marketplaceGridColumnCount(double width) {
  if (width >= 1400) return 5;
  if (width >= 1000) return 4;
  if (width >= 640) return 3;
  return 2;
}

/// Shared responsive product grid — computes column count and a
/// mathematically-safe cell height from the real available width, so it
/// never overflows regardless of font metrics/language and never leaves
/// wide screens stuck at a phone-narrow column count.
class MarketplaceProductGrid extends StatelessWidget {
  const MarketplaceProductGrid({
    super.key,
    required this.products,
    this.showStoreName = false,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  final List<MarketplaceProduct> products;
  final bool showStoreName;
  final EdgeInsets padding;

  static const double _spacing = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = marketplaceGridColumnCount(constraints.maxWidth);
        final cellWidth = (constraints.maxWidth -
                padding.horizontal -
                _spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        final mainAxisExtent = cellWidth +
            marketplaceProductCardTextHeight(showStoreName: showStoreName);

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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

/// Standard ecommerce product-image canvas: neutral background fill (never
/// transparent/white-on-white), the image fully visible via [BoxFit.contain]
/// (never [BoxFit.cover] — a real product photo is rarely pre-cropped to a
/// square, and `cover` would cut off packaging/edges the moment a non-square
/// photo is uploaded), with padding so the image doesn't touch the card
/// edges. A missing/failed image gets a neutral medicine-outline icon on the
/// same background, never a jarring blank tile.
class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    return Container(
      color: const Color(0xFFF5F6F8),
      padding: const EdgeInsets.all(10),
      child: !url.startsWith('http')
          ? _placeholder()
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return Icon(
      Icons.medication_outlined,
      color: PatientAppColors.brandTeal.withValues(alpha: 0.35),
      size: 32,
    );
  }
}
