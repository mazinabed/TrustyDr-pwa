import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_page.dart';

/// Storefront card — DoorDash/Instacart shop-card anatomy (2026-07-15 card
/// redesign pass), not a healthcare-provider list row. A cover banner
/// (Store Branding V1, 2026-07-22: store.bannerUrl — the merchant's own
/// uploaded cover image, or a brand-teal gradient if none is set) with the
/// store's logo (store.logoUrl) overlaid at the seam is what makes this
/// read as "enter this shop" rather than "here is a business" — a plain
/// logo-plus-text row (the previous version) reads as a directory entry no
/// matter how the text underneath it is styled. Never falls back to
/// medical/provider imagery (e.g. a stethoscope icon) or to a sampled
/// product photo — a missing image gets a neutral storefront icon/gradient
/// instead, since this is a shopping surface, not a clinical directory.
///
/// The verified badge is NOT a new per-store field — every store that can
/// ever appear in this feed already passed the existing
/// public_pharmacy_providers eligibility gate (active + verified pharmacy
/// provider) before Marketplace Sync ever wrote it, so "listed here" and
/// "verified" are the same condition. The badge surfaces that existing
/// guarantee, it doesn't introduce a new one.
///
/// City/address is shown as small metadata under the name — never as the
/// section's organizing idea (see marketplace_landing_page.dart's
/// "Featured Stores" section, not "Nearby Stores") since real numeric
/// distance isn't in the data model today and isn't fabricated here.
class MarketplaceStoreCard extends StatelessWidget {
  const MarketplaceStoreCard({
    super.key,
    required this.store,
    this.categorySummary,
    this.categoryCount,
  });

  final MarketplaceStore store;
  final String? categorySummary;
  final int? categoryCount;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final name = store.localizedName(lang);
    final city = store.localizedCity(lang);
    // Store Branding V1 (2026-07-22) — real, merchant-uploaded
    // logoUrl/bannerUrl only. Never falls back to store.imageUrl (a
    // Healthcare-side provider-profile photo) or store.featuredImageUrl
    // (the old sampled-product-image leak, now always null) — an absent
    // value goes straight to MarketplaceBannerGradient/MarketplaceLogoFallback.
    final bannerUrl = (store.bannerUrl ?? '').trim();
    final logoUrl = (store.logoUrl ?? '').trim();
    final tagline = store.localizedTagline(lang);
    final description = store.localizedDescription(lang);
    final tags = (categorySummary ?? '')
        .split(' · ')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(2)
        .toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 400),
            child: MarketplaceStorePage(
              providerId: store.providerId,
              orgId: store.orgId,
              storeName: name,
              bannerUrl: bannerUrl,
              logoUrl: logoUrl,
              city: city,
              tagline: tagline,
              description: description,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StoreBanner(bannerUrl: bannerUrl, logoUrl: logoUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'marketplace_verified_pharmacy'.tr(),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: PatientAppColors.brandTeal,
                        ),
                      ),
                    ],
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded,
                            size: 12, color: Colors.black38),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, color: Colors.black45),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (tags.isNotEmpty || (categoryCount ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        ...tags.map((t) => _Tag(label: t)),
                        _Tag(
                          label: 'marketplace_product_count'.tr(
                            namedArgs: {
                              'count': store.productCount.toString(),
                            },
                          ),
                          emphasized: true,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 400),
                            child: MarketplaceStorePage(
                              providerId: store.providerId,
                              orgId: store.orgId,
                              storeName: name,
                              bannerUrl: bannerUrl,
                              logoUrl: logoUrl,
                              city: city,
                              tagline: tagline,
                              description: description,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PatientAppColors.brandTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        'marketplace_visit_store'.tr(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: emphasized
            ? PatientAppColors.brandTeal.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: emphasized ? PatientAppColors.brandTeal : Colors.black54,
        ),
      ),
    );
  }
}

/// Cover-banner + overlapping logo — the anatomy that makes a card read as
/// "shop" rather than "listing." [bannerUrl] is the store's own featured
/// image when set; otherwise a brand-teal gradient stands in (never a blank
/// or a clinical icon) so every card still has real visual presence.
class _StoreBanner extends StatelessWidget {
  const _StoreBanner({required this.bannerUrl, required this.logoUrl});

  final String bannerUrl;
  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: bannerUrl.startsWith('http')
                ? Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const MarketplaceBannerGradient(),
                  )
                : const MarketplaceBannerGradient(),
          ),
          PositionedDirectional(
            start: 12,
            bottom: -16,
            child: Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: logoUrl.startsWith('http')
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const MarketplaceLogoFallback(),
                    )
                  : const MarketplaceLogoFallback(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared storefront banner fallback (Marketplace Design System) — used
/// wherever a store's cover image is missing, both on this card and on
/// [MarketplaceStoreHeader] (marketplace_widgets.dart). Public/reusable
/// rather than redefined per widget.
class MarketplaceBannerGradient extends StatelessWidget {
  const MarketplaceBannerGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PatientAppColors.brandTeal,
            PatientAppColors.brandTeal.withValues(alpha: 0.65),
          ],
        ),
      ),
    );
  }
}

class MarketplaceLogoFallback extends StatelessWidget {
  const MarketplaceLogoFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PatientAppColors.brandTeal.withValues(alpha: 0.10),
      child: Icon(
        Icons.storefront_rounded,
        color: PatientAppColors.brandTeal.withValues(alpha: 0.6),
        size: 20,
      ),
    );
  }
}
