import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

/// Image gallery for the Patient Marketplace product detail page. Large
/// selected-image preview plus a tappable thumbnail strip when more than
/// one image exists — Primary first, matching
/// [MarketplaceProduct.galleryImageUrls]'s own ordering contract. Pure UI,
/// no Firebase dependency beyond the standard [Image.network] itself, so
/// it's directly widget-testable in isolation. No editing controls
/// anywhere — this widget only ever selects which already-loaded image is
/// shown large, it never mutates data.
///
/// Never used by product cards (those keep loading only the Primary image
/// via a plain `Image.network` — see marketplace_product_card.dart) — this
/// widget is deliberately only wired into the product detail page.
///
/// 2026-07-19 width/structure refinement: the square [AspectRatio] now
/// wraps ONLY the main preview, not the whole gallery-plus-thumbnails
/// column — the thumbnail strip is a separate, naturally-sized sibling
/// below it. This is both what makes the preview usably wide (no shared
/// fixed box being split between the image and the thumbnail row beneath
/// it) and what keeps this widget free of any Expanded/flexible-sizing
/// inside a constrained parent (the exact class of layout that caused a
/// prior RenderFlex overflow) — every dimension here is either a plain
/// aspect ratio derived from available width, or natural content height.
class MarketplaceProductImageGallery extends StatefulWidget {
  const MarketplaceProductImageGallery({super.key, required this.imageUrls});

  /// Ordered, Primary-first, already deduplicated and capped at 3 — see
  /// [parseGalleryImageUrls]. An empty list means "no images"; this widget
  /// then renders the same placeholder the single-image page used before.
  final List<String> imageUrls;

  @override
  State<MarketplaceProductImageGallery> createState() =>
      _MarketplaceProductImageGalleryState();
}

class _MarketplaceProductImageGalleryState
    extends State<MarketplaceProductImageGallery> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant MarketplaceProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to Primary whenever the actual image set changes — never keep
    // a selection pointing at an image that may no longer be the same one.
    if (!listEquals(oldWidget.imageUrls, widget.imageUrls)) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return AspectRatio(aspectRatio: 1, child: _placeholder());
    }
    final selectedIndex = _selectedIndex.clamp(0, widget.imageUrls.length - 1);
    final selectedUrl = widget.imageUrls[selectedIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(aspectRatio: 1, child: _preview(selectedUrl)),
        // Never reserve thumbnail space for a single-image product — the
        // strip is entirely absent, not an empty placeholder row.
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          _thumbnailStrip(selectedIndex),
        ],
      ],
    );
  }

  Widget _preview(String url) {
    // 2026-07-19 width fix — this padding was previously 24 on every side,
    // which (stacked on top of the page's own outer padding) was the exact
    // "too much empty space around the image" defect: it shrank the actual
    // visible product photo to well under the available media width. 10
    // is enough breathing room against the rounded corners without eating
    // the width the image should actually use — the product photo itself
    // still renders via BoxFit.contain, so its own aspect ratio is always
    // fully preserved regardless of this container being a fixed square.
    return Container(
      key: ValueKey('marketplace-gallery-preview-$url'),
      color: const Color(0xFFF5F6F8),
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        // Reuses whatever resolution the network image actually is
        // (Odoo's own image_512, already the largest source this
        // projection carries — see marketplace_providers.dart) — no
        // artificial upscaling filter requested here, Flutter's default
        // sampling already renders it at exactly the container's real
        // pixel size.
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: PatientAppColors.brandTeal.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.medication_outlined,
          color: PatientAppColors.brandTeal.withValues(alpha: 0.4),
          size: 64,
        ),
      ),
    );
  }

  Widget _thumbnailStrip(int selectedIndex) {
    // Plain horizontal ListView — direction-aware via ambient
    // Directionality with no hardcoded TextDirection, so it mirrors
    // correctly under RTL (Arabic/Kurdish) without special-casing; Primary
    // always stays imageUrls[0] regardless of visual (mirrored) direction,
    // since selection is index-based, not position-based. No horizontal
    // padding here beyond the separator spacing — the strip aligns with
    // the preview's own edges (both sit inside the same page padding from
    // the caller), rather than the previous extra 20px inset that made the
    // thumbnails feel disconnected from the image above them.
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          final isSelected = index == selectedIndex;
          return GestureDetector(
            key: ValueKey('marketplace-gallery-thumb-$url'),
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
                border: Border.all(
                  color:
                      isSelected ? PatientAppColors.brandTeal : Colors.black12,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PatientAppColors.radiusSm),
                child: Container(
                  color: const Color(0xFFF5F6F8),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: PatientAppColors.brandTeal.withValues(alpha: 0.06),
                      child: Icon(
                        Icons.medication_outlined,
                        color:
                            PatientAppColors.brandTeal.withValues(alpha: 0.4),
                        size: 20,
                      ),
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
