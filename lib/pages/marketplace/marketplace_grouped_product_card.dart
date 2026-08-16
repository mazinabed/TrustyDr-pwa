import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_seller_offers_page.dart';

/// Marketplace Platform, Phase 2 — Multi-Seller Aggregated Discovery.
/// Product-first grouped result card: "Panadol Extra 24 Tablets — From
/// 4,750 IQD — 3 sellers". Deliberately mirrors MarketplaceProductCard's
/// exact visual language (image canvas, price treatment, card chrome) so
/// this reads as the same product family, not a new visual system — the
/// only structural difference is the store byline being replaced with a
/// seller-count pill, since a grouped card by definition has no single
/// store to attribute to.
///
/// Tapping opens [MarketplaceSellerOffersPage] — the existing per-store
/// product detail flow (cart/checkout, unchanged) is reached only after the
/// patient picks one specific seller there, never directly from this card.
///
/// Marketplace Platform Phase 5 (Sponsored/Promoted Monetization) — a
/// [StatefulWidget] (was [StatelessWidget]) purely so a sponsored card can
/// fire exactly one impression event per mount via [initState], and one
/// click event on tap. Both are fire-and-forget (see
/// [recordSponsoredEvent]'s own doc comment) and never affect layout,
/// navigation, price, or seller-count — the sponsored placement label is
/// the only visible change for a non-sponsored group.
class MarketplaceGroupedProductCard extends StatefulWidget {
  const MarketplaceGroupedProductCard({
    super.key,
    required this.group,
    required this.allProducts,
  });

  final GroupedMarketplaceProduct group;
  // The full cross-store product list already in memory
  // (MarketplaceBrowseData.products) — used to resolve each offer to its
  // real, complete MarketplaceProduct when the patient picks a seller, so
  // the existing MarketplaceProductDetailPage never needs a new
  // constructor path. See MarketplaceSellerOffersPage's own doc comment.
  final List<MarketplaceProduct> allProducts;

  @override
  State<MarketplaceGroupedProductCard> createState() =>
      _MarketplaceGroupedProductCardState();
}

class _MarketplaceGroupedProductCardState
    extends State<MarketplaceGroupedProductCard> {
  // The specific sponsored offer's placementId, if any — a group may have
  // more than one seller, only one of which is sponsored; this is always
  // the first sponsored offer found, matching how the "Sponsored" badge
  // itself represents the group as a whole rather than one price.
  String? get _sponsoredPlacementId {
    for (final offer in widget.group.offers) {
      if (offer.isSponsored && offer.sponsoredPlacementId != null) {
        return offer.sponsoredPlacementId;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final placementId = _sponsoredPlacementId;
    if (placementId != null) {
      recordSponsoredEvent(placementId: placementId, eventType: 'impression');
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final lang = context.locale.languageCode;
    final name =
        lang == 'ar' && group.nameAr.isNotEmpty ? group.nameAr : group.nameEn;
    final price = group.lowestPrice.toStringAsFixed(
      group.lowestPrice.truncateToDouble() == group.lowestPrice ? 0 : 2,
    );
    final currency = group.currencyName ?? '';

    return GestureDetector(
      onTap: () {
        final placementId = _sponsoredPlacementId;
        if (placementId != null) {
          recordSponsoredEvent(placementId: placementId, eventType: 'click');
        }
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 300),
            child: MarketplaceSellerOffersPage(
              group: group,
              allProducts: widget.allProducts,
            ),
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
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: const Color(0xFFF5F6F8),
                    padding: const EdgeInsets.all(10),
                    child: !(group.representativeImageUrl ?? '')
                            .startsWith('http')
                        ? Icon(
                            Icons.medication_outlined,
                            color: PatientAppColors.brandTeal
                                .withValues(alpha: 0.35),
                            size: 32,
                          )
                        : Image.network(
                            group.representativeImageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.medication_outlined,
                              color: PatientAppColors.brandTeal
                                  .withValues(alpha: 0.35),
                              size: 32,
                            ),
                          ),
                  ),
                ),
                // Marketplace Platform Phase 5 — clear, always-visible
                // sponsored-placement label. Purely visual: never affects
                // sort order (already decided server-side), price, or
                // seller-count; a group with isSponsored false renders
                // identically to before this phase.
                if (group.isSponsored)
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'marketplace_sponsored_label'.tr(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 5),
                  Text(
                    '${'marketplace_from_price_prefix'.tr()} $price $currency'
                        .trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 10,
                          color: Colors.black.withValues(alpha: 0.32)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          // Derived from the actual offers list, never the
                          // separately-carried group.sellerCount field —
                          // see MarketplaceSellerOffersPage's own identical
                          // fix for why these must never be allowed to
                          // diverge.
                          'marketplace_seller_count'.tr(
                              namedArgs: {'count': '${group.offers.length}'}),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: PatientAppColors.brandTeal
                                .withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
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
