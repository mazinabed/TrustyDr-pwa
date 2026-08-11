import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/providers/marketplace_review_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_action.dart';
import 'package:trustydr/pages/marketplace/marketplace_cart_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_image_gallery.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_widgets.dart'
    show ensureMarketplaceLogin;
import 'package:trustydr/pages/marketplace/marketplace_write_review_sheet.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Product details (Patient Marketplace) — Milestone 5, Patient Product
/// Experience (2026-07-19 upgrade). The already-fetched [MarketplaceProduct]
/// (constructor param, same as before this upgrade — the browse-list
/// loading architecture is unchanged) still powers instant paint of title/
/// image/description/fallback price the moment this page opens. A NEW live
/// read, [marketplaceProductDetailProvider], additionally fetches this
/// ONE product's variants/descriptive attributes/current price+stock
/// directly from Odoo (never trusted from the ~15-minute Marketplace browse
/// cache — see marketplaceProductDetail.ts's own header for why a live read
/// exists specifically for this page) — once it resolves, IT becomes the
/// price/stock/variant authority; before that, the page still shows the
/// cached product's own price/availability so there's never a blank
/// price while loading.
///
/// Add to Cart is guest-allowed (Phase 1 rule: "Guests can browse and may
/// build a local cart") — no ensureMarketplaceLogin gate here. Only
/// checkout itself is auth-gated.
class MarketplaceProductDetailPage extends ConsumerStatefulWidget {
  const MarketplaceProductDetailPage({super.key, required this.product});

  final MarketplaceProduct product;

  @override
  ConsumerState<MarketplaceProductDetailPage> createState() =>
      _MarketplaceProductDetailPageState();
}

class _MarketplaceProductDetailPageState
    extends ConsumerState<MarketplaceProductDetailPage> {
  int _quantity = 1;

  /// attributeKey -> chosen valueKey, for variant-generating attributes
  /// only. Populated once the live detail loads: unambiguous values
  /// (every real variant shares them) are preselected automatically (the
  /// approved initial-selection rule); everything else starts empty,
  /// requiring an explicit patient choice before Add to Cart is enabled.
  /// Never guesses among multiple genuinely valid variants.
  final Map<String, String> _selections = {};
  bool _selectionsInitialized = false;

  // 2026-07-19 accordion refinement — Product Details and Description
  // start COLLAPSED on mobile (keeps the purchase workflow, and future
  // product-collection sections, closer to the top) but default EXPANDED
  // on desktop, where there's enough horizontal space that collapsing buys
  // nothing. Both are pure local presentation state: toggling either only
  // triggers a widget rebuild (setState), never touches
  // marketplaceProductDetailProvider — the live detail request is keyed
  // solely by (orgId, engineId), so opening/closing a section can never
  // cause a second network round trip.
  bool _specsExpanded = false;
  bool _descriptionExpanded = false;
  // Product Ratings & Reviews, Phase 5 (2026-08-10) — same collapse
  // convention as specs/description above: collapsed by default on
  // mobile, expanded on desktop.
  bool _reviewsExpanded = false;
  bool _expansionDefaultsApplied = false;

  void _applyExpansionDefaultsOnce(bool isDesktop) {
    if (_expansionDefaultsApplied) return;
    _expansionDefaultsApplied = true;
    if (isDesktop) {
      _specsExpanded = true;
      _descriptionExpanded = true;
      _reviewsExpanded = true;
    }
  }

  void _initializeSelectionsOnce(MarketplaceProductDetail detail) {
    if (_selectionsInitialized) return;
    _selectionsInitialized = true;
    _selections.addAll(detail.unambiguousSelections);
  }

  Future<void> _addToCart(MarketplaceProductDetail? detail) async {
    final lang = context.locale.languageCode;
    final storeName = widget.product.localizedStoreName(lang) ?? '';
    final notifier = ref.read(marketplaceCartProvider.notifier);

    MarketplaceProductVariant? resolvedVariant;
    if (detail != null && detail.hasVariants) {
      resolvedVariant = detail.resolveVariant(_selections);
      if (resolvedVariant == null) return; // guarded by the disabled button too
    }

    final variantLabel = resolvedVariant?.selections
        .map((s) => s.localizedValueName(lang))
        .where((v) => v.isNotEmpty)
        .join(', ');
    final resolvedPrice = resolvedVariant?.salePrice ?? detail?.listPrice;

    try {
      await notifier.addItem(
        product: widget.product,
        storeNameEn: widget.product.storeNameEn ?? storeName,
        storeNameAr: widget.product.storeNameAr ?? storeName,
        variantEngineId: resolvedVariant?.variantEngineId,
        variantLabel: (variantLabel ?? '').isEmpty ? null : variantLabel,
        resolvedPrice: resolvedPrice,
        quantity: _quantity,
      );
      _showAddedSnackBar();
    } on CartStoreConflictException catch (e) {
      if (!mounted) return;
      final currentName = lang == 'ar' && e.currentStoreNameAr.isNotEmpty
          ? e.currentStoreNameAr
          : e.currentStoreNameEn;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('marketplace_cart_switch_store_title'.tr()),
          content: Text('marketplace_cart_switch_store_body'
              .tr(namedArgs: {'store': currentName})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('marketplace_cart_switch_store_confirm'.tr()),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await notifier.replaceCartWith(
          product: widget.product,
          storeNameEn: widget.product.storeNameEn ?? storeName,
          storeNameAr: widget.product.storeNameAr ?? storeName,
          variantEngineId: resolvedVariant?.variantEngineId,
          variantLabel: (variantLabel ?? '').isEmpty ? null : variantLabel,
          resolvedPrice: resolvedPrice,
          quantity: _quantity,
        );
        _showAddedSnackBar();
      }
    }
  }

  void _showAddedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Expanded(child: Text('marketplace_added_to_cart'.tr())),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceCartPage()),
              ),
              child: Text(
                'marketplace_view_cart'.tr(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailParams = (
      orgId: widget.product.orgId,
      engineId: widget.product.engineId,
    );
    final detailAsync =
        ref.watch(marketplaceProductDetailProvider(detailParams));
    final detail = detailAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, __) => null,
    );
    final detailError = detailAsync.hasError ? detailAsync.error : null;
    if (detail != null) _initializeSelectionsOnce(detail);

    return Scaffold(
      backgroundColor: PatientAppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: BackButton(
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 4),
            child: MarketplaceCartAction(iconColor: Colors.black87),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            _applyExpansionDefaultsOnce(isDesktop);
            Widget content = _ProductDetailBody(
              product: widget.product,
              detail: detail,
              isLoadingDetail: detailAsync.isLoading && detail == null,
              detailError: detailError,
              isDesktop: isDesktop,
              selections: _selections,
              quantity: _quantity,
              specsExpanded: _specsExpanded,
              descriptionExpanded: _descriptionExpanded,
              reviewsExpanded: _reviewsExpanded,
              onSelectValue: (attributeKey, valueKey) => setState(() {
                if (_selections[attributeKey] == valueKey) {
                  _selections.remove(attributeKey);
                } else {
                  _selections[attributeKey] = valueKey;
                }
              }),
              onQuantityChanged: (q) => setState(() => _quantity = q),
              onToggleSpecs: () =>
                  setState(() => _specsExpanded = !_specsExpanded),
              onToggleDescription: () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
              onToggleReviews: () =>
                  setState(() => _reviewsExpanded = !_reviewsExpanded),
              onAddToCart: () => _addToCart(detail),
              // Explicit Retry (2026-07-19 fix) — never an automatic
              // background retry loop against a permanent error. Riverpod's
              // own invalidate re-runs the provider exactly once, on this
              // one explicit user action.
              onRetry: () => ref
                  .invalidate(marketplaceProductDetailProvider(detailParams)),
            );
            if (isDesktop) content = WebScaffoldContainer(child: content);
            return content;
          },
        ),
      ),
    );
  }
}

/// Marketplace order/inventory lifecycle audit (2026-08-10) — [maxQuantity]
/// is the live available-to-sell quantity (Odoo `free_qty`, the SAME field
/// `quoteMarketplaceCartForHealthcare`/`placeMarketplaceOrderForHealthcare`
/// validate against — see `_PurchasePanel`'s own doc comment on where this
/// value comes from) — null only while that live value genuinely isn't
/// known yet (detail still loading, no cached count exists to fall back
/// on), in which case the `+` button stays unbounded exactly as before
/// rather than blocking on stale/absent data. This is a UI-side courtesy
/// cap only — the backend quote/order-create call remains the actual,
/// final stock check regardless of what this widget allows.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    this.maxQuantity,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final double? maxQuantity;

  @override
  Widget build(BuildContext context) {
    final maxInt = maxQuantity?.floor();
    final atOrAboveMax = maxInt != null && quantity >= maxInt;

    // Kept as a plain fixed-height Container (unchanged from before this
    // cap existed) — the "Only N available" message is rendered by
    // _PurchasePanel itself, OUTSIDE this widget's own 46px height, so it
    // never disturbs the shared 48dp row this stepper sits in alongside
    // Add to Cart (see that Row's own doc comment on why the height is
    // fixed).
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: atOrAboveMax ? null : () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

/// The full page body — laid out as two columns on desktop (media left,
/// purchase column right, per the approved premium layout) or one stacked
/// column on mobile, in the exact required hierarchy: title first, then
/// media, then price/availability, then variant selection, then quantity +
/// Add to Cart, then descriptive specs, then description, then store info.
class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({
    required this.product,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.isDesktop,
    required this.selections,
    required this.quantity,
    required this.specsExpanded,
    required this.descriptionExpanded,
    required this.reviewsExpanded,
    required this.onSelectValue,
    required this.onQuantityChanged,
    required this.onToggleSpecs,
    required this.onToggleDescription,
    required this.onToggleReviews,
    required this.onAddToCart,
    required this.onRetry,
  });

  final MarketplaceProduct product;
  final MarketplaceProductDetail? detail;
  final bool isLoadingDetail;
  final Object? detailError;
  final bool isDesktop;
  final Map<String, String> selections;
  final int quantity;
  final bool specsExpanded;
  final bool descriptionExpanded;
  final bool reviewsExpanded;
  final void Function(String attributeKey, String valueKey) onSelectValue;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onToggleSpecs;
  final VoidCallback onToggleDescription;
  final VoidCallback onToggleReviews;
  final VoidCallback onAddToCart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final galleryImageUrls =
        product.galleryImageUrls.where((u) => u.startsWith('http')).toList();
    final name = product.localizedName(lang);
    final description = product.localizedDescription(lang);
    final categoryName = product.localizedCategoryName(lang);
    final storeName = product.localizedStoreName(lang);

    // 2026-07-19 width refinement — the square AspectRatio now lives
    // INSIDE MarketplaceProductImageGallery, wrapping only the main
    // preview (not the whole gallery+thumbnails column) — see that
    // widget's own header comment. _MediaColumn no longer needs (and must
    // not add back) an outer AspectRatio here; doing so would force the
    // preview AND the thumbnail strip together into one square, which is
    // exactly what was making the visible product photo narrower than the
    // available width.
    final gallery = _MediaColumn(imageUrls: galleryImageUrls);
    // Product Ratings & Reviews, Phase 5 (2026-08-10) — live summary once
    // the detail read loads, falling back to the cached card summary while
    // it's in flight — same "live overrides cache, never a blank value"
    // pattern already used for price/availability just below.
    final ratingAverage = detail?.ratingAverage ?? product.ratingAverage;
    final ratingCount = detail?.ratingCount ?? product.ratingCount;
    final header = _TitleHeader(
      name: name,
      brandName: product.brandName,
      categoryName: categoryName,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      onTapRating: onToggleReviews,
    );
    final purchase = _PurchasePanel(
      product: product,
      detail: detail,
      isLoadingDetail: isLoadingDetail,
      detailError: detailError,
      selections: selections,
      quantity: quantity,
      onSelectValue: onSelectValue,
      onQuantityChanged: onQuantityChanged,
      onAddToCart: onAddToCart,
      onRetry: onRetry,
    );
    final specs = _DescriptiveSpecsSection(
      detail: detail,
      expanded: specsExpanded,
      onToggle: onToggleSpecs,
    );
    final descriptionSection = _DescriptionSection(
      description: description,
      expanded: descriptionExpanded,
      onToggle: onToggleDescription,
    );
    final storeCard = _StoreInfoCard(product: product, storeName: storeName);
    // Product Ratings & Reviews, Phase 5 (2026-08-10) — placed after the
    // Description section and before "Sold by", matching the familiar
    // commerce pattern of reviews sitting alongside other purchase-
    // decision content rather than after store attribution.
    final reviewsSection = _ReviewsSection(
      orgId: product.orgId,
      engineId: product.engineId,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      expanded: reviewsExpanded,
      onToggle: onToggleReviews,
    );

    if (isDesktop) {
      // Description/specs get a comfortable reading width below the hero —
      // never stretched across the full browser width.
      const maxContentWidth = 720.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: gallery),
                const SizedBox(width: 40),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 20),
                      purchase,
                      const SizedBox(height: 24),
                      storeCard,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  specs,
                  const SizedBox(height: 12),
                  descriptionSection,
                  const SizedBox(height: 12),
                  reviewsSection,
                  // Future Collection Insertion Point (layout preparation
                  // only — see this file's own top-of-class doc comment).
                  // Similar Items / More From This Store / Related
                  // Categories sections belong here, as additional
                  // children of this same Column, once that milestone
                  // starts. No provider, query, or UI is added now.
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 16),
          gallery,
          const SizedBox(height: 24),
          purchase,
          const SizedBox(height: 20),
          specs,
          const SizedBox(height: 12),
          descriptionSection,
          const SizedBox(height: 12),
          reviewsSection,
          const SizedBox(height: 12),
          storeCard,
          // Future Collection Insertion Point (layout preparation only —
          // see this file's own top-of-class doc comment). Similar Items /
          // More From This Store / Related Categories sections belong
          // here, as additional children of this same Column, once that
          // milestone starts. No provider, query, or UI is added now —
          // this is purely the seam that lets them slot in later without
          // touching anything above.
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MediaColumn extends StatelessWidget {
  const _MediaColumn({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
      child: MarketplaceProductImageGallery(imageUrls: imageUrls),
    );
  }
}

/// Hierarchy position 1-2: title prominently at the very top, above the
/// media — never buried below the image. Supports multiline titles without
/// overflow (no maxLines/ellipsis on the name itself).
class _TitleHeader extends StatelessWidget {
  const _TitleHeader({
    required this.name,
    required this.brandName,
    required this.categoryName,
    required this.ratingAverage,
    required this.ratingCount,
    required this.onTapRating,
  });

  final String name;
  final String? brandName;
  final String? categoryName;
  final double ratingAverage;
  final int ratingCount;
  final VoidCallback onTapRating;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (brandName != null && brandName!.isNotEmpty) brandName!,
      if (categoryName != null && categoryName!.isNotEmpty) categoryName!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: PatientAppColors.darkNavy,
            height: 1.25,
          ),
        ),
        if (subtitleParts.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitleParts.join(' · '),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
        const SizedBox(height: 8),
        _RatingSummaryInline(
          ratingAverage: ratingAverage,
          ratingCount: ratingCount,
          onTap: onTapRating,
        ),
      ],
    );
  }
}

/// Compact rating summary near the product's main info (item 1 of the
/// Ratings & Reviews requirements) — small stars + average + count, tap to
/// jump to the full Ratings & Reviews section below. Renders a neutral "no
/// ratings yet" state rather than "0.0 (0)" when [ratingCount] is 0 — a
/// bare zero reads as broken, not as "nothing rated yet."
class _RatingSummaryInline extends StatelessWidget {
  const _RatingSummaryInline({
    required this.ratingAverage,
    required this.ratingCount,
    required this.onTap,
  });

  final double ratingAverage;
  final int ratingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StarRatingDisplay(rating: ratingAverage, size: 15),
            const SizedBox(width: 6),
            if (ratingCount > 0) ...[
              Text(
                ratingAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: PatientAppColors.darkNavy,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${'marketplace_reviews_count'.tr(namedArgs: {
                      'count': '$ratingCount'
                    })})',
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ] else
              Text(
                'marketplace_rating_no_ratings_yet'.tr(),
                style: const TextStyle(fontSize: 12.5, color: Colors.black45),
              ),
          ],
        ),
      ),
    );
  }
}

/// Read-only star display, shared by the inline summary, the Ratings &
/// Reviews section's own summary block, and every review card. [rating]
/// may be fractional (e.g. an average like 4.3) — each star fills
/// proportionally to how much of that star's value is covered, rather than
/// only ever rendering whole/empty stars, matching the precision an
/// average rating actually has.
class _StarRatingDisplay extends StatelessWidget {
  const _StarRatingDisplay({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        if (fill <= 0) {
          return Icon(Icons.star_border_rounded,
              size: size, color: Colors.amber);
        }
        if (fill >= 1) {
          return Icon(Icons.star_rounded, size: size, color: Colors.amber);
        }
        // Partial star (e.g. rating 4.3 -> the 5th star is 30% filled) —
        // a half-star icon is the closest built-in approximation; exact
        // fractional clipping isn't worth a custom painter for this.
        return Icon(Icons.star_half_rounded, size: size, color: Colors.amber);
      }),
    );
  }
}

/// Hierarchy positions 5-7: price + availability, variant selection,
/// quantity + Add to Cart — the operational heart of the page, kept
/// together in one clearly-bordered panel so the primary action stays
/// visually prominent rather than diffused across the page.
class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({
    required this.product,
    required this.detail,
    required this.isLoadingDetail,
    required this.detailError,
    required this.selections,
    required this.quantity,
    required this.onSelectValue,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.onRetry,
  });

  final MarketplaceProduct product;
  final MarketplaceProductDetail? detail;
  final bool isLoadingDetail;
  final Object? detailError;
  final Map<String, String> selections;
  final int quantity;
  final void Function(String attributeKey, String valueKey) onSelectValue;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // 2026-07-19 fix — a PERMANENT failed live read (detail is null AND an
    // error actually landed, not merely still loading) must never silently
    // fall back to the stale cached price as if it were current, and must
    // never keep spinning. Distinct, explicit error state with one Retry
    // action — see marketplaceProductDetailProvider's own retry policy for
    // why this state is reachable at all now (deterministic errors stop
    // auto-retrying immediately instead of looping forever).
    if (detail == null && detailError != null) {
      return _PurchasePanelError(error: detailError!, onRetry: onRetry);
    }

    final lang = context.locale.languageCode;
    final hasVariants = detail?.hasVariants ?? false;
    final resolvedVariant = hasVariants && detail != null
        ? detail!.resolveVariant(selections)
        : null;
    final needsSelection = hasVariants && resolvedVariant == null;

    // Price/availability authority: the resolved variant once one exists;
    // otherwise the live template-level detail once it has loaded; falling
    // back to the cached browse-card price only while the live read is
    // still in flight — never a blank price.
    final double price = resolvedVariant?.salePrice ??
        (needsSelection ? 0 : detail?.listPrice ?? product.displayPrice);
    final String currency = detail?.currencyName ?? product.currencyName ?? '';
    final String availabilityBadge = resolvedVariant?.availabilityBadge ??
        detail?.availabilityBadge ??
        product.availabilityBadge;
    final bool outOfStock = availabilityBadge == 'out_of_stock';
    final bool canAddToCart = !outOfStock && !needsSelection;
    // Marketplace order/inventory lifecycle audit (2026-08-10) — same live
    // authority chain as price/availability just above: the resolved
    // variant's own free_qty once one exists, otherwise the live
    // template-level detail's. Deliberately NO fallback to a cached value
    // (MarketplaceProduct carries no numeric quantity at all) — null here
    // means "not yet known," and _QuantityStepper leaves the + button
    // unbounded in that case rather than guessing.
    final double? maxQuantity =
        resolvedVariant?.quantityAvailable ?? detail?.quantityAvailable;
    final int? maxQuantityInt = maxQuantity?.floor();
    final bool atOrAboveMaxQuantity =
        maxQuantityInt != null && quantity >= maxQuantityInt;

    final priceText = price.toStringAsFixed(
      price.truncateToDouble() == price ? 0 : 2,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
        boxShadow: PatientAppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (needsSelection)
                Text(
                  'marketplace_select_options_prompt'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                )
              else
                Text(
                  '$priceText $currency'.trim(),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: PatientAppColors.brandTeal,
                  ),
                ),
              const SizedBox(width: 12),
              if (!needsSelection)
                _AvailabilityBadge(availabilityBadge: availabilityBadge),
              if (isLoadingDetail) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          // Variant-generating attribute pickers — only the attributes this
          // SPECIFIC product actually has, never the global catalog.
          if (detail != null)
            for (final attributeKey in detail!.variantAttributeKeys)
              _VariantAttributeSelector(
                attributeKey: attributeKey,
                options: detail!.optionsFor(attributeKey),
                selectedValueKey: selections[attributeKey],
                lang: lang,
                isValueAvailable: (valueKey) => detail!
                    .isValueAvailable(attributeKey, valueKey, selections),
                onSelect: (valueKey) => onSelectValue(attributeKey, valueKey),
              ),
          const SizedBox(height: 20),
          // 2026-07-19: both children share one 48dp-tall row (Material's
          // own minimum interactive dimension — matches IconButton's
          // internal minimum exactly, so nothing inside is ever squeezed
          // below what it needs) instead of two independently-sized fixed
          // boxes. The stepper is deliberately the quieter of the two
          // (thin neutral border, no fill) so the CTA reads as the one
          // dominant action rather than competing with it.
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (!outOfStock) ...[
                  _QuantityStepper(
                    quantity: quantity,
                    onChanged: onQuantityChanged,
                    maxQuantity: maxQuantity,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAddToCart
                          ? PatientAppColors.brandTeal
                          : Colors.grey[300],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(PatientAppColors.radiusMd),
                      ),
                    ),
                    onPressed: canAddToCart ? onAddToCart : null,
                    child: Text(
                      outOfStock
                          ? 'marketplace_availability_out_of_stock'.tr()
                          : 'marketplace_add_to_cart'.tr(),
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Marketplace order/inventory lifecycle audit (2026-08-10) — only
          // shown once the live available-to-sell quantity is known AND the
          // patient has actually reached it; rendered outside the fixed-
          // height Row above (see that Row's own doc comment) so it never
          // disturbs the stepper/CTA layout.
          if (!outOfStock &&
              maxQuantityInt != null &&
              maxQuantityInt > 0 &&
              atOrAboveMaxQuantity)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'marketplace_only_n_available'
                    .tr(namedArgs: {'count': '$maxQuantityInt'}),
                style: const TextStyle(fontSize: 11.5, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }
}

/// Permanent-failure state for the purchase panel — shown only once the
/// live detail read has genuinely failed (never merely still loading, and
/// never after Riverpod's own automatic retry, which the provider's retry
/// policy now stops immediately for deterministic errors). Title/image/
/// description remain visible above this (from the already-cached
/// [MarketplaceProduct]) — only the operational price/stock/Add-to-Cart
/// area is replaced, so incomplete data is never presented as if it were
/// fully loaded.
class _PurchasePanelError extends StatelessWidget {
  const _PurchasePanelError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNotFound = error is FirebaseFunctionsException &&
        (error as FirebaseFunctionsException).code == 'not-found';
    final message = isNotFound
        ? 'marketplace_product_not_found'.tr()
        : 'marketplace_product_detail_load_error'.tr();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
        boxShadow: PatientAppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  color: PatientAppColors.statusCancelled, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                ),
              ),
            ],
          ),
          if (!isNotFound) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PatientAppColors.brandTeal,
                  side: const BorderSide(color: PatientAppColors.brandTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(PatientAppColors.radiusMd),
                  ),
                ),
                child: Text('marketplace_retry'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.availabilityBadge});

  final String availabilityBadge;

  @override
  Widget build(BuildContext context) {
    final key = switch (availabilityBadge) {
      'low_stock' => 'marketplace_availability_low_stock',
      'out_of_stock' => 'marketplace_availability_out_of_stock',
      _ => 'marketplace_availability_in_stock',
    };
    final color = availabilityBadge == 'out_of_stock'
        ? PatientAppColors.statusCancelled
        : availabilityBadge == 'low_stock'
            ? PatientAppColors.statusWarning
            : PatientAppColors.statusConfirmed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PatientAppColors.radiusSm),
      ),
      child: Text(
        key.tr(),
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// One variant-generating attribute's picker row (e.g. "Size: [S] [M] [L]").
/// Selected value is visually obvious (filled/teal); an unavailable
/// combination (per [isValueAvailable]) is visibly disabled/struck rather
/// than silently absent — the patient can see the option exists but isn't
/// currently combinable, matching the "invalid combinations are disabled"
/// requirement.
class _VariantAttributeSelector extends StatelessWidget {
  const _VariantAttributeSelector({
    required this.attributeKey,
    required this.options,
    required this.selectedValueKey,
    required this.lang,
    required this.isValueAvailable,
    required this.onSelect,
  });

  final String attributeKey;
  final List<MarketplaceProductAttributeSelection> options;
  final String? selectedValueKey;
  final String lang;
  final bool Function(String valueKey) isValueAvailable;
  final void Function(String valueKey) onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final attributeLabel = options.first.localizedAttributeName(lang);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(attributeLabel,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final valueKey = option.valueKey;
              if (valueKey == null) return const SizedBox.shrink();
              final isSelected = selectedValueKey == valueKey;
              final isAvailable = isValueAvailable(valueKey);
              return _AttributeValueChip(
                label: option.localizedValueName(lang),
                selected: isSelected,
                enabled: isAvailable,
                onTap: isAvailable ? () => onSelect(valueKey) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AttributeValueChip extends StatelessWidget {
  const _AttributeValueChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? PatientAppColors.brandTeal
        : (enabled ? Colors.black26 : Colors.black12);
    final Color background = selected
        ? PatientAppColors.brandTeal.withValues(alpha: 0.12)
        : Colors.white;
    final Color textColor = !enabled
        ? Colors.black26
        : (selected ? PatientAppColors.brandTeal : Colors.black87);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
            decoration: enabled ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}

/// Reusable premium-commerce accordion section (2026-07-19) — shared by
/// Product Details and Description so both collapse/expand identically.
/// Deliberately lighter than the old always-expanded cards: no heavy
/// shadow-plus-large-padding card, just a white surface, a subtle divider
/// between header and body, and a chevron — closer to a commerce
/// accordion than a disconnected form block. The ENTIRE header row is the
/// tap target (not just the chevron), satisfying "entire section header
/// tappable" — via InkWell wrapping the full Row, not just an IconButton
/// on the arrow. Expansion state is exposed both visually (chevron
/// rotation) and semantically (`Semantics(toggled: expanded)` plus a
/// localized show/hide label used as this header's accessible name —
/// meaningful for screen readers and, on web, for keyboard users tabbing
/// through the page). Body height is always natural/unbounded
/// (AnimatedSize measures real content, never a fixed box) — the same
/// overflow-safety principle as everywhere else on this page.
///
/// Purely local presentation state: the caller's [expanded]/[onToggle]
/// never touch marketplaceProductDetailProvider, so opening/closing a
/// section is always a plain widget rebuild, never a second network
/// request.
class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    this.summary,
    required this.expanded,
    required this.onToggle,
    required this.body,
  });

  final String title;
  final String? summary;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
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
          Semantics(
            button: true,
            toggled: expanded,
            label: expanded
                ? 'marketplace_hide_details'.tr()
                : 'marketplace_show_details'.tr(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  // 48dp Material minimum touch target satisfied by this
                  // padding + text line height combined.
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            if (!expanded &&
                                summary != null &&
                                summary!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                summary!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12.5, color: Colors.black45),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: body,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// Hierarchy position 6: descriptive product specifications (Strength,
/// Dosage Form, Pack Count, Volume, Weight, ...) as a clean two-column
/// key/value list — never rendered as chips (those are reserved for
/// selectable variant values). Renders nothing at all when there are no
/// descriptive attributes, rather than an empty section heading. Collapsed
/// by default on mobile (see _MarketplaceProductDetailPageState's own
/// expansion-defaults logic) — the collapsed row shows a localized
/// specification count instead of every row.
class _DescriptiveSpecsSection extends StatelessWidget {
  const _DescriptiveSpecsSection({
    required this.detail,
    required this.expanded,
    required this.onToggle,
  });

  final MarketplaceProductDetail? detail;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final specs = detail?.descriptiveAttributes ?? const [];
    if (specs.isEmpty) return const SizedBox.shrink();
    final lang = context.locale.languageCode;

    return _CollapsibleSection(
      title: 'marketplace_product_details_section'.tr(),
      summary: 'marketplace_specifications_count'
          .tr(namedArgs: {'count': '${specs.length}'}),
      expanded: expanded,
      onToggle: onToggle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) const Divider(height: 16, color: Color(0xFFF0F0F0)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    specs[i].localizedAttributeName(lang),
                    style:
                        const TextStyle(fontSize: 13.5, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Text(
                    specs[i].localizedValueName(lang),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Hierarchy position 7: the merchant-provided localized description as a
/// single expandable accordion section — one expansion interaction only
/// (the section itself), never a nested "Show more/less" competing with
/// it. Collapsed by default on mobile, showing a short 1-line preview
/// under the title; expanded shows the complete text with preserved line
/// breaks. Renders nothing when there's no description, rather than an
/// empty heading.
class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  final String? description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = description ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return _CollapsibleSection(
      title: 'marketplace_product_description'.tr(),
      summary: text,
      expanded: expanded,
      onToggle: onToggle,
      body: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 14.5,
          color: Colors.black.withValues(alpha: 0.72),
          height: 1.7,
        ),
      ),
    );
  }
}

/// Hierarchy position 10: pharmacy/store information, reusing exactly the
/// existing store data already on [MarketplaceProduct] — no trust badges
/// added. Ratings & Reviews (Phase 5, 2026-08-10) is its own section
/// ([_ReviewsSection]), placed just above this one, not folded into it.
class _StoreInfoCard extends StatelessWidget {
  const _StoreInfoCard({required this.product, required this.storeName});

  final MarketplaceProduct product;
  final String? storeName;

  @override
  Widget build(BuildContext context) {
    if (storeName == null || storeName!.isEmpty) return const SizedBox.shrink();
    final providerId = product.orgId.replaceFirst(kPharmacyOrgIdPrefix, '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
        boxShadow: PatientAppColors.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PatientAppColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(PatientAppColors.radiusSm),
            ),
            child: const Icon(Icons.local_pharmacy_outlined,
                color: PatientAppColors.brandTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'marketplace_sold_by'.tr(),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                Text(
                  storeName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: providerId.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 400),
                        child: MarketplaceStorePage(
                          providerId: providerId,
                          orgId: product.orgId,
                          storeName: storeName!,
                        ),
                      ),
                    ),
            child: Text('marketplace_visit_store'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Hierarchy position 8-9 (Product Ratings & Reviews, Phase 5, 2026-08-10):
/// the full Ratings & Reviews section — summary, Write/Edit Review action,
/// and a paginated review list. A [_CollapsibleSection] like specs/
/// description above, for the same visual consistency. Never reproduces
/// Verified Purchase logic — the Write/Edit action is always offered to a
/// signed-in patient; the backend's own authoritative response (success or
/// a NOT_VERIFIED_PURCHASE failure) decides the outcome, shown via
/// [WriteReviewSheet]'s own error state.
class _ReviewsSection extends ConsumerStatefulWidget {
  const _ReviewsSection({
    required this.orgId,
    required this.engineId,
    required this.ratingAverage,
    required this.ratingCount,
    required this.expanded,
    required this.onToggle,
  });

  final String orgId;
  final String engineId;
  final double ratingAverage;
  final int ratingCount;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  ConsumerState<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<_ReviewsSection> {
  // Pagination is local widget state, not provider state — see
  // marketplace_review_providers.dart's own doc comment on
  // productReviewsProvider for why. Seeded once from the first-page
  // provider result; "Load More" appends directly.
  List<ProductReview>? _reviews;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _loadMoreError;

  void _seedFromFirstPage(List<ProductReview> firstPage) {
    if (_reviews != null) return; // seed exactly once
    _reviews = List.of(firstPage);
    _hasMore = firstPage.length >= kProductReviewsPageSize;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _reviews == null) return;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final next = await fetchMoreProductReviews(
        engineId: widget.engineId,
        offset: _reviews!.length,
      );
      if (!mounted) return;
      setState(() {
        _reviews!.addAll(next);
        _hasMore = next.length >= kProductReviewsPageSize;
        _loadingMore = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loadMoreError = err;
        _loadingMore = false;
      });
    }
  }

  /// Refreshes every read this section (and the page header's compact
  /// summary) depends on after a successful submit/edit/withdraw — never a
  /// local optimistic patch, since the backend-computed rating_avg/
  /// rating_count must come from Odoo itself, not be guessed client-side.
  void _refreshAfterChange() {
    setState(() {
      _reviews = null; // re-seed from a fresh first page
      _hasMore = true;
      _loadMoreError = null;
    });
    ref.invalidate(productReviewsProvider(widget.engineId));
    ref.invalidate(myProductReviewProvider(widget.engineId));
    ref.invalidate(marketplaceProductDetailProvider(
      (orgId: widget.orgId, engineId: widget.engineId),
    ));
  }

  Future<void> _openWriteSheet(ProductReview? existing) async {
    if (!await ensureMarketplaceLogin(context)) return;
    if (!mounted) return;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => WriteReviewSheet(
        engineId: widget.engineId,
        existingRating: existing?.rating,
        existingFeedback: existing?.feedback,
      ),
    );
    if (changed == true) _refreshAfterChange();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final myReviewAsync = ref.watch(myProductReviewProvider(widget.engineId));
    final myReview = myReviewAsync.when(
      data: (r) => r,
      loading: () => null,
      error: (_, __) => null,
    );

    return _CollapsibleSection(
      title: 'marketplace_reviews_section_title'.tr(),
      summary: widget.ratingCount > 0
          ? 'marketplace_reviews_count'
              .tr(namedArgs: {'count': '${widget.ratingCount}'})
          : 'marketplace_reviews_no_reviews_yet'.tr(),
      expanded: widget.expanded,
      onToggle: widget.onToggle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewsSummaryBlock(
            ratingAverage: widget.ratingAverage,
            ratingCount: widget.ratingCount,
          ),
          const SizedBox(height: 14),
          if (myReview != null)
            _MyReviewCard(
              review: myReview,
              lang: lang,
              onEdit: () => _openWriteSheet(myReview),
              onWithdraw: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title:
                        Text('marketplace_review_withdraw_confirm_title'.tr()),
                    content:
                        Text('marketplace_review_withdraw_confirm_body'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('marketplace_review_withdraw'.tr()),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                try {
                  await withdrawProductReview(
                    engineId: widget.engineId,
                    locale: lang,
                  );
                  if (!mounted) return;
                  _refreshAfterChange();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('marketplace_review_withdrawn_success'.tr()),
                  ));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('marketplace_review_generic_error'.tr()),
                  ));
                }
              },
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openWriteSheet(null),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('marketplace_write_review'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PatientAppColors.brandTeal,
                  side: const BorderSide(color: PatientAppColors.brandTeal),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          ref.watch(productReviewsProvider(widget.engineId)).when(
                data: (firstPage) {
                  _seedFromFirstPage(firstPage);
                  final others = (_reviews ?? firstPage)
                      .where((r) =>
                          myReview == null ||
                          r.reviewEngineId != myReview.reviewEngineId)
                      .toList();
                  if (others.isEmpty && myReview == null) {
                    return _ReviewsEmptyState();
                  }
                  if (others.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < others.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 20, color: Color(0xFFF0F0F0)),
                        _ReviewCard(review: others[i], lang: lang),
                      ],
                      if (_hasMore) ...[
                        const SizedBox(height: 12),
                        if (_loadMoreError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'marketplace_reviews_load_error'.tr(),
                              style: const TextStyle(
                                  fontSize: 12.5, color: Colors.red),
                            ),
                          ),
                        Center(
                          child: TextButton(
                            onPressed: _loadingMore ? null : _loadMore,
                            child: _loadingMore
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text('marketplace_reviews_load_more'.tr()),
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'marketplace_reviews_load_error'.tr(),
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Larger rating summary shown at the top of the expanded Ratings &
/// Reviews section body (distinct from the compact inline one in
/// [_TitleHeader] — same underlying numbers, different presentation for a
/// different position on the page).
class _ReviewsSummaryBlock extends StatelessWidget {
  const _ReviewsSummaryBlock({
    required this.ratingAverage,
    required this.ratingCount,
  });

  final double ratingAverage;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    if (ratingCount == 0) {
      return Text(
        'marketplace_reviews_be_first'.tr(),
        style: const TextStyle(fontSize: 13.5, color: Colors.black54),
      );
    }
    return Row(
      children: [
        Text(
          ratingAverage.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: PatientAppColors.darkNavy,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StarRatingDisplay(rating: ratingAverage, size: 18),
            const SizedBox(height: 2),
            Text(
              'marketplace_reviews_count'
                  .tr(namedArgs: {'count': '$ratingCount'}),
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'marketplace_reviews_no_reviews_yet'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'marketplace_reviews_be_first'.tr(),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// The signed-in patient's own review, shown above the general list with
/// Edit/Withdraw actions — deduplicated out of the general list below (see
/// _ReviewsSectionState.build's own filter) so it never appears twice.
class _MyReviewCard extends StatelessWidget {
  const _MyReviewCard({
    required this.review,
    required this.lang,
    required this.onEdit,
    required this.onWithdraw,
  });

  final ProductReview review;
  final String lang;
  final VoidCallback onEdit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PatientAppColors.brandTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
        border: Border.all(
            color: PatientAppColors.brandTeal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'marketplace_your_review'.tr(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text('marketplace_edit_review'.tr()),
              ),
              TextButton(
                onPressed: onWithdraw,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('marketplace_review_withdraw'.tr()),
              ),
            ],
          ),
          _StarRatingDisplay(rating: review.rating.toDouble(), size: 16),
          if (review.feedback != null && review.feedback!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.feedback!,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// One other patient's review — stars, optional feedback text, reviewer's
/// "First L." partial name (blank when the backend didn't resolve one —
/// never fabricated client-side), and the review date.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.lang});

  final ProductReview review;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final hasName = review.reviewerDisplayName.isNotEmpty;
    final dateText = review.createDate != null
        ? DateFormat.yMMMd(lang).format(review.createDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StarRatingDisplay(rating: review.rating.toDouble(), size: 15),
            const SizedBox(width: 8),
            if (hasName)
              Expanded(
                child: Text(
                  review.reviewerDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            if (dateText != null)
              Text(
                dateText,
                style: const TextStyle(fontSize: 11.5, color: Colors.black38),
              ),
          ],
        ),
        if (review.feedback != null && review.feedback!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            review.feedback!,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
        ],
      ],
    );
  }
}
