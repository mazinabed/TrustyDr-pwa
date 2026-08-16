import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

enum MarketplaceProductSort {
  recommended,
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc
}

extension MarketplaceProductSortL10n on MarketplaceProductSort {
  String get l10nKey {
    switch (this) {
      case MarketplaceProductSort.recommended:
        return 'marketplace_sort_recommended';
      case MarketplaceProductSort.nameAsc:
        return 'marketplace_sort_name_asc';
      case MarketplaceProductSort.nameDesc:
        return 'marketplace_sort_name_desc';
      case MarketplaceProductSort.priceAsc:
        return 'marketplace_sort_price_asc';
      case MarketplaceProductSort.priceDesc:
        return 'marketplace_sort_price_desc';
    }
  }
}

List<MarketplaceProduct> sortMarketplaceProducts(
  List<MarketplaceProduct> products,
  MarketplaceProductSort sort,
  String lang,
) {
  final list = List.of(products);
  switch (sort) {
    case MarketplaceProductSort.recommended:
      // Marketplace Platform Phase 5 — Patient-visibility gap correction
      // (2026-08-16). isSponsored is a NEW leading tiebreak, ahead of the
      // existing isFeatured one below it — additive only: when nothing in
      // the list is sponsored, sponsoredDiff is always 0 for every pair and
      // this falls straight through to the exact pre-existing isFeatured
      // comparator, unchanged.
      list.sort((a, b) {
        final sponsoredDiff = (b.isSponsored ? 1 : 0) - (a.isSponsored ? 1 : 0);
        if (sponsoredDiff != 0) return sponsoredDiff;
        return (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
      });
      break;
    case MarketplaceProductSort.nameAsc:
      list.sort(
          (a, b) => a.localizedName(lang).compareTo(b.localizedName(lang)));
      break;
    case MarketplaceProductSort.nameDesc:
      list.sort(
          (a, b) => b.localizedName(lang).compareTo(a.localizedName(lang)));
      break;
    case MarketplaceProductSort.priceAsc:
      list.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      break;
    case MarketplaceProductSort.priceDesc:
      list.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
      break;
  }
  return list;
}

/// Opens a bottom sheet with the 5 browse-only sort options. RTL-safe via
/// ambient Directionality (no hardcoded alignment).
Future<MarketplaceProductSort?> showMarketplaceSortSheet(
  BuildContext context,
  MarketplaceProductSort current,
) {
  return showModalBottomSheet<MarketplaceProductSort>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'marketplace_sort_by'.tr(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            for (final option in MarketplaceProductSort.values)
              ListTile(
                title: Text(option.l10nKey.tr()),
                trailing: option == current
                    ? const Icon(Icons.check_rounded,
                        color: PatientAppColors.brandTeal)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
