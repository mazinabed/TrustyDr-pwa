import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_page.dart';

/// Ecommerce-storefront-style store card — shared by the Marketplace landing
/// page's "Stores Near You" section and the full Stores browse page. Never
/// falls back to medical/provider imagery (e.g. a stethoscope icon) — a
/// missing logo gets a neutral storefront icon instead, since this is a
/// shopping surface, not a clinical directory.
class MarketplaceStoreCard extends StatelessWidget {
  const MarketplaceStoreCard({
    super.key,
    required this.store,
    this.categorySummary,
  });

  final MarketplaceStore store;
  final String? categorySummary;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final name = store.localizedName(lang);
    final city = store.localizedCity(lang);
    final imageUrl = (store.featuredImageUrl ?? store.imageUrl ?? '').trim();

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
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StoreLogo(imageUrl: imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (city.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: Colors.black38),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (categorySummary != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      categorySummary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.black38),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PatientAppColors.brandTeal
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'marketplace_product_count'.tr(
                            namedArgs: {'count': store.productCount.toString()},
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PatientAppColors.brandTeal,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'marketplace_visit_store'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: PatientAppColors.brandTeal,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: PatientAppColors.brandTeal),
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

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final isNetwork = imageUrl.startsWith('http');
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: PatientAppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: isNetwork
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.storefront_rounded,
      color: PatientAppColors.brandTeal.withValues(alpha: 0.5),
      size: 28,
    );
  }
}
