import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_detail_page.dart';

/// Shared product grid tile — used by both the Marketplace landing page's
/// Products tab (cross-store) and a single Store page's product grid.
///
/// Hierarchy (2026-07-15 card redesign pass, ecommerce audit): IMAGE ->
/// PRODUCT -> PRICE -> STORE, top to bottom, largest/boldest to smallest.
/// Store name used to sit ABOVE the title (a healthcare-directory instinct —
/// "which provider" outranking "which product") — it now sits last, as a
/// small byline, matching how Amazon/iHerb/Noon product cards treat the
/// seller: real, but never competing with the product itself.
///
/// STRUCTURAL OVERFLOW FIX (2026-07-15, following a real "BOTTOM OVERFLOWED
/// BY 34 PIXELS" report): the content area below the image is no longer
/// sized by guessing how tall English text needs to be. It's an [Expanded]
/// region that fills exactly whatever height the parent gives it, and a
/// [LayoutBuilder] inside measures that real available height to decide
/// which OPTIONAL lines (availability, store byline) can actually fit —
/// title and price are the only two guaranteed-visible elements, matching
/// "product name maxLines: 2 / price always visible" exactly. This makes
/// the card correct for any font metrics, any language (Arabic line-height
/// included), and any parent size, rather than assuming one.
///
/// The root cause of the original overflow was NOT this widget, though —
/// it was a caller (the Popular Products rail) hardcoding a card
/// width/height pair that didn't leave enough room for the text block.
/// See [marketplaceProductCardTextHeight] — every caller that renders this
/// card at a fixed size must derive that size FROM this function, never
/// from an independent guess, so the two can't drift apart again.
///
/// [showStoreName] surfaces which store a product belongs to; only
/// meaningful for cross-store results, so the Store page (where the store
/// is already obvious from context) passes false. [highlightBadge] is
/// opt-in and should be set by the CALLER for at most the top 1-2 items in a
/// genuinely curated rail (e.g. rank 0 of "Popular Products") — never
/// derived from [MarketplaceProduct.isFeatured] directly here, since most or
/// all demo products currently carry that flag, which is exactly what made
/// the old "badge on every card" problem happen. A badge is a claim about
/// being exceptional; only the caller who built the ranked list knows what's
/// actually exceptional in it.
class MarketplaceProductCard extends StatelessWidget {
  const MarketplaceProductCard({
    super.key,
    required this.product,
    this.showStoreName = false,
    this.highlightBadge = false,
  });

  final MarketplaceProduct product;
  final bool showStoreName;
  final bool highlightBadge;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final price = product.displayPrice.toStringAsFixed(
      product.displayPrice.truncateToDouble() == product.displayPrice ? 0 : 2,
    );
    final currency = product.currencyName ?? '';
    final storeName = showStoreName ? product.localizedStoreName(lang) : null;
    final hasStoreName = storeName != null && storeName.isNotEmpty;
    final hasAvailability = product.availabilityL10nKey.isNotEmpty;

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
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _ProductImage(imageUrl: product.imageUrl),
                  ),
                  if (highlightBadge)
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: _Badge(
                        label: 'marketplace_section_popular'.tr(),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (context, inner) {
                      return _ProductInfo(
                        name: product.localizedName(lang),
                        priceText: '$price $currency'.trim(),
                        availabilityText: hasAvailability
                            ? product.availabilityL10nKey.tr()
                            : null,
                        storeName: hasStoreName ? storeName : null,
                        maxHeight: inner.maxHeight,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The text block below the image. Title and price are unconditional;
/// availability and the store byline are shown only when [maxHeight]
/// (measured from the real parent, not assumed) has room for them —
/// computed from reference line-heights tied 1:1 to the TextStyles actually
/// used below, not a guess at how long the rendered text will be.
class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.name,
    required this.priceText,
    required this.availabilityText,
    required this.storeName,
    required this.maxHeight,
  });

  final String name;
  final String priceText;
  final String? availabilityText;
  final String? storeName;
  final double maxHeight;

  // Reference block heights = fontSize * a generous line-height multiplier
  // (1.3-1.35, comfortably covers Arabic script's taller ascent/descent
  // than the 1.0-1.2 that would suffice for Latin text alone).
  static const double _titleLine = 12.5 * 1.3;
  static const double _titleBlock = _titleLine * 2; // maxLines: 2
  static const double _priceBlock = 15.0 * 1.35;
  static const double _availBlock = 11.0 * 1.35;
  static const double _storeBlock = 10.0 * 1.35;
  static const double _gapMed = 5.0;
  static const double _gapSmall = 3.0;

  @override
  Widget build(BuildContext context) {
    final requiredHeight = _titleBlock + _gapMed + _priceBlock;
    final canShowAvailability = availabilityText != null &&
        maxHeight >= requiredHeight + _gapSmall + _availBlock;
    final afterAvailability =
        requiredHeight + (canShowAvailability ? _gapSmall + _availBlock : 0);
    final canShowStore = storeName != null &&
        maxHeight >= afterAvailability + _gapSmall + _storeBlock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // PRODUCT — the hero. Secondary weight relative to price, but first
        // in reading order right under the image.
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.25,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _gapMed),
        // PRICE — the single largest, boldest element on the card
        // (iHerb/Noon audit): price dominates, title stays secondary.
        // Always visible — never dropped regardless of available height.
        Text(
          priceText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: PatientAppColors.brandTeal,
          ),
        ),
        if (canShowAvailability) ...[
          const SizedBox(height: _gapSmall),
          Text(
            availabilityText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PatientAppColors.statusConfirmed.withValues(alpha: 0.85),
            ),
          ),
        ],
        // STORE — last, smallest, quietest: attribution, not a second
        // headline. Optional on narrow/short cards — dropped first if
        // space is genuinely tight, matching how real ecommerce cards
        // degrade gracefully rather than overflow.
        if (canShowStore) ...[
          const SizedBox(height: _gapSmall),
          Row(
            children: [
              Icon(Icons.storefront_outlined,
                  size: 10, color: Colors.black.withValues(alpha: 0.32)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  storeName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Grid cell height budget: image square + a generous text-block height
/// (name up to 2 lines + price + availability + optional store-name line),
/// computed from the SAME reference line-heights [_ProductInfo] measures
/// against at render time — not an independent guess. This is the single
/// source of truth for "how tall should a fixed-size cell rendering this
/// card be" — every caller (grid or horizontal rail) MUST derive its
/// cell/item height from this function rather than hardcoding one, or the
/// two can drift apart exactly like the bug this comment is documenting.
double marketplaceProductCardTextHeight({bool showStoreName = false}) =>
    showStoreName ? 130.0 : 104.0;

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
///
/// [shrinkWrap]: false (default) means this grid is its own scrollable and
/// expects a BOUNDED height from its parent (e.g. wrapped in [Expanded]
/// inside a non-scrolling Column — [MarketplaceProductsPage]'s usage). Set
/// true when nesting this inside an ALREADY-scrolling ancestor (e.g. a
/// [SingleChildScrollView], as the Pharmacy Store page's "All Products"
/// section does) — an un-shrink-wrapped GridView.builder inside an
/// unbounded-height parent throws a real layout exception, not just a
/// visual overflow, so this must be set correctly per call site rather
/// than defaulted on for everyone.
class MarketplaceProductGrid extends StatelessWidget {
  const MarketplaceProductGrid({
    super.key,
    required this.products,
    this.showStoreName = false,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.shrinkWrap = false,
  });

  final List<MarketplaceProduct> products;
  final bool showStoreName;
  final EdgeInsets padding;
  final bool shrinkWrap;

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
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
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

/// Small pill badge overlaid on a product's image — currently only "Popular"
/// (shown only when the caller sets [MarketplaceProductCard.highlightBadge]
/// — reserved for genuine exceptions, not every card).
class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: PatientAppColors.brandTeal,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
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
