import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

/// Read-only image gallery for the Patient Marketplace product detail page
/// (2026-07-18). Large selected-image preview plus a tappable thumbnail
/// strip when more than one image exists — Primary first, matching
/// [MarketplaceProduct.galleryImageUrls]'s own ordering contract. Pure UI,
/// no Firebase dependency beyond the standard [Image.network] itself, so
/// it's directly widget-testable in isolation. No editing controls
/// anywhere — this widget only ever selects which already-loaded image is
/// shown large, it never mutates data.
///
/// Never used by product cards (those keep loading only the Primary image
/// via a plain `Image.network` — see marketplace_product_card.dart) — this
/// widget is deliberately only wired into the product detail page.
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
    if (widget.imageUrls.isEmpty) return _placeholder();
    final selectedIndex = _selectedIndex.clamp(0, widget.imageUrls.length - 1);
    final selectedUrl = widget.imageUrls[selectedIndex];

    return Column(
      children: [
        Expanded(child: _preview(selectedUrl)),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 8),
          _thumbnailStrip(selectedIndex),
        ],
      ],
    );
  }

  Widget _preview(String url) {
    return Container(
      key: ValueKey('marketplace-gallery-preview-$url'),
      color: const Color(0xFFF5F6F8),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.contain,
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
    // since selection is index-based, not position-based.
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = widget.imageUrls[index];
          final isSelected = index == selectedIndex;
          return GestureDetector(
            key: ValueKey('marketplace-gallery-thumb-$url'),
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? PatientAppColors.brandTeal
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: PatientAppColors.brandTeal.withValues(alpha: 0.06),
                    child: Icon(
                      Icons.medication_outlined,
                      color: PatientAppColors.brandTeal.withValues(alpha: 0.4),
                      size: 20,
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
