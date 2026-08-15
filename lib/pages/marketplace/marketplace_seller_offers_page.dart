import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_detail_page.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

/// Marketplace Platform, Phase 2 — Multi-Seller Aggregated Discovery.
/// "Seller B — 4,750, Seller A — 5,000, Seller C — 5,250" — the offers list
/// a [MarketplaceGroupedProductCard] opens into. Already sorted
/// cheapest-first by the backend (never re-sorted here).
///
/// Selecting a seller does NOT invent a new purchase path: it resolves the
/// offer back to its real, already-loaded [MarketplaceProduct] (from
/// [allProducts] — every grouped offer's underlying listing is guaranteed
/// present there, since Phase 2's backend only ever ADDS `groupedProducts`
/// alongside the existing `products` list, never removes anything from it)
/// and opens the EXACT existing [MarketplaceProductDetailPage] used
/// everywhere else in the app. Cart, checkout, and the detail page itself
/// are completely untouched by this feature.
class MarketplaceSellerOffersPage extends StatelessWidget {
  const MarketplaceSellerOffersPage({
    super.key,
    required this.group,
    required this.allProducts,
  });

  final GroupedMarketplaceProduct group;
  final List<MarketplaceProduct> allProducts;

  MarketplaceProduct? _resolveProduct(MarketplaceProductOffer offer) {
    for (final p in allProducts) {
      if (p.orgId == offer.orgId && p.engineId == offer.engineId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final name =
        lang == 'ar' && group.nameAr.isNotEmpty ? group.nameAr : group.nameEn;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'marketplace_compare_sellers_title'.tr(),
                showBack: true,
                height: 100,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    // Derived from the actual rendered offers list, never
                    // the separately-carried group.sellerCount field — the
                    // count shown must always match what the patient can
                    // actually see and tap below.
                    'marketplace_seller_count'
                        .tr(namedArgs: {'count': '${group.offers.length}'}),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: group.offers.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final offer = group.offers[i];
                    final product = _resolveProduct(offer);
                    return _SellerOfferTile(
                      offer: offer,
                      lang: lang,
                      // A missing match is defensive-only (should not
                      // happen — see this file's own doc comment) —
                      // disabled rather than crashing or navigating with
                      // incomplete data.
                      onTap: product == null
                          ? null
                          : () => Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: MarketplaceProductDetailPage(
                                      product: product),
                                ),
                              ),
                    );
                  },
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

class _SellerOfferTile extends StatelessWidget {
  const _SellerOfferTile({
    required this.offer,
    required this.lang,
    required this.onTap,
  });

  final MarketplaceProductOffer offer;
  final String lang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final storeName = lang == 'ar' && (offer.storeNameAr ?? '').isNotEmpty
        ? offer.storeNameAr!
        : lang == 'ku' && (offer.storeNameKu ?? '').isNotEmpty
            ? offer.storeNameKu!
            : (offer.storeNameEn ??
                offer.storeNameAr ??
                offer.storeNameKu ??
                '');
    final price = offer.displayPrice.toStringAsFixed(
      offer.displayPrice.truncateToDouble() == offer.displayPrice ? 0 : 2,
    );
    final currency = offer.currencyName ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: !(offer.imageUrl ?? '').startsWith('http')
                    ? Icon(Icons.storefront_outlined,
                        color:
                            PatientAppColors.brandTeal.withValues(alpha: 0.4))
                    : Image.network(
                        offer.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.storefront_outlined,
                          color:
                              PatientAppColors.brandTeal.withValues(alpha: 0.4),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storeName.isEmpty ? '—' : storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (offer.availabilityL10nKey.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        offer.availabilityL10nKey.tr(),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$price $currency'.trim(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: PatientAppColors.brandTeal,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.black.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
