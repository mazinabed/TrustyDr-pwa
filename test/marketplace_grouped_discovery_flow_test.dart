// Marketplace Platform, Phase 2 — Multi-Seller Aggregated Discovery.
//
// Real widget-driven UI flow, mirroring marketplace_store_page_compiles_test.dart's
// EasyLocalization/ProviderScope pumping convention: tap a grouped product
// card -> see the seller offers list, cheapest first, with real seller
// names distinguishing two different sellers of the SAME product -> tap a
// seller offer -> assert navigation reaches the EXISTING
// MarketplaceProductDetailPage with the CORRECT resolved product (the
// existing purchase flow itself is untouched and out of scope here — only
// proving this feature hands off to it correctly).
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/pages/marketplace/marketplace_grouped_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_detail_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_seller_offers_page.dart';

/// Records the most recently pushed route WITHOUT requiring it to ever
/// build/lay out — didPush fires the instant Navigator.push installs the
/// route, before any frame renders its content. This is what lets this
/// test prove exactly which product a navigation carried without needing
/// MarketplaceProductDetailPage (existing, unmodified, real content, own
/// dedicated tests) to actually render in this minimal test harness.
class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
    super.didPush(route, previousRoute);
  }
}

MarketplaceProduct _fullProduct({
  required String orgId,
  required String engineId,
  required double price,
}) {
  return MarketplaceProduct(
    orgId: orgId,
    engineId: engineId,
    sku: 'SKU-$engineId',
    nameEn: 'Panadol Extra 24 Tablets',
    nameAr: 'بانادول اكسترا',
    descriptionEn: null,
    descriptionAr: null,
    brandName: 'GSK',
    categoryEngineIds: const [],
    categoryKeys: const ['medicines_analgesics'],
    categories: const [],
    categoryEngineId: null,
    categoryNameEn: null,
    categoryNameAr: null,
    displayPrice: price,
    currencyName: 'IQD',
    isFeatured: false,
    availabilityBadge: 'in_stock',
    imageUrl: null,
    galleryImageUrls: const [],
    storeNameEn: orgId,
    storeNameAr: null,
    storeNameKu: null,
    ratingAverage: 0,
    ratingCount: 0,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'END-TO-END: tap grouped card -> see two distinguishable sellers, cheapest first -> '
    'tap the cheaper seller -> navigates to the real product detail page for THAT seller',
    (tester) async {
      // Deliberately the default (larger) test canvas, not a narrow mobile
      // width — MarketplaceProductDetailPage is existing, unmodified code
      // with its own real content and its own dedicated tests; this test
      // only needs enough room for it to build without tripping unrelated
      // pre-existing narrow-width layout warnings in that page, which is
      // not what this test is checking (see the tap-navigation comment
      // below for the full reasoning).
      SharedPreferences.setMockInitialValues({});

      const group = GroupedMarketplaceProduct(
        canonicalId: 'canonical_panadol',
        nameEn: 'Panadol Extra 24 Tablets',
        nameAr: 'بانادول اكسترا',
        brandName: 'GSK',
        categoryKey: 'medicines_analgesics',
        representativeImageUrl: null,
        lowestPrice: 4750,
        currencyName: 'IQD',
        sellerCount: 2,
        offers: [
          MarketplaceProductOffer(
            orgId: 'org_b',
            engineId: 'engine_b1',
            storeNameEn: 'Baghdad Central Pharmacy',
            storeNameAr: null,
            storeNameKu: null,
            displayPrice: 4750,
            currencyName: 'IQD',
            availabilityBadge: 'in_stock',
            imageUrl: null,
          ),
          MarketplaceProductOffer(
            orgId: 'org_a',
            engineId: 'engine_a1',
            storeNameEn: 'Al Noor Pharmacy',
            storeNameAr: null,
            storeNameKu: null,
            displayPrice: 5000,
            currencyName: 'IQD',
            availabilityBadge: 'in_stock',
            imageUrl: null,
          ),
        ],
      );

      final allProducts = [
        _fullProduct(orgId: 'org_b', engineId: 'engine_b1', price: 4750),
        _fullProduct(orgId: 'org_a', engineId: 'engine_a1', price: 5000),
        // A THIRD, unrelated product with no canonical link — must never
        // appear anywhere in this flow.
        _fullProduct(orgId: 'org_z', engineId: 'engine_z1', price: 999),
      ];

      final observer = _RecordingNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Never resolves — this test never lets
            // MarketplaceProductDetailPage actually build (see below), so
            // its own live-data provider is never exercised either way.
            marketplaceProductDetailProvider.overrideWith(
                (ref, params) => Completer<MarketplaceProductDetail>().future),
          ],
          child: EasyLocalization(
            supportedLocales: const [
              Locale('ar'),
              Locale('ku', 'IQ'),
              Locale('en'),
            ],
            path: 'lib/l10n',
            fallbackLocale: const Locale('ar'),
            startLocale: const Locale('en'),
            saveLocale: false,
            child: MaterialApp(
              navigatorObservers: [observer],
              home: Scaffold(
                // Matches real usage exactly (marketplace_landing_page.dart's
                // "Compare Sellers" rail always wraps this card in a fixed-
                // width SizedBox, same as every other product card in this
                // app) — pumping it unconstrained is not how it's ever
                // actually placed.
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 148,
                    height: 250,
                    child: MarketplaceGroupedProductCard(
                      group: group,
                      allProducts: allProducts,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // The card itself shows "From 4,750 IQD" and "2 sellers" — never a
      // single store name (a grouped card has none).
      expect(find.textContaining('4750'), findsOneWidget);

      await tester.tap(find.byType(MarketplaceGroupedProductCard));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(MarketplaceSellerOffersPage), findsOneWidget);
      // Both sellers shown, distinguishable by name — the third, unrelated
      // product never appears here.
      expect(find.textContaining('Baghdad Central Pharmacy'), findsOneWidget);
      expect(find.textContaining('Al Noor Pharmacy'), findsOneWidget);

      // Cheapest-first order is trusted from the backend, not re-derived:
      // Baghdad Central Pharmacy (4750) must render above Al Noor (5000).
      final baghdadY =
          tester.getTopLeft(find.textContaining('Baghdad Central Pharmacy')).dy;
      final alNoorY =
          tester.getTopLeft(find.textContaining('Al Noor Pharmacy')).dy;
      expect(baghdadY, lessThan(alNoorY));

      // Tap the cheaper (first) seller offer. Deliberately inspect the
      // pushed ROUTE via the navigator observer rather than letting
      // MarketplaceProductDetailPage actually build/lay out —
      // didPush fires the instant Navigator.push installs the route,
      // before any frame renders it. MarketplaceProductDetailPage is
      // existing, unmodified code with its own real content and its own
      // dedicated tests; this test's job is only to prove which product
      // the navigation carried, not to re-verify that page's own layout
      // (which, given only a partial fake product and no live detail data,
      // is not something this minimal harness can render faithfully
      // anyway).
      await tester.tap(find.textContaining('Baghdad Central Pharmacy'));
      await tester.pump();

      final pushedRoute = observer.lastPushed;
      expect(pushedRoute, isNotNull);
      expect(pushedRoute, isA<PageTransition<dynamic>>());
      final pushedWidget = (pushedRoute as PageTransition).child;
      expect(pushedWidget, isA<MarketplaceProductDetailPage>());
      final detailPage = pushedWidget as MarketplaceProductDetailPage;
      // The EXACT seller the patient tapped — never the cheapest by
      // assumption, never the first in allProducts, never hand-picked by
      // this test; resolved live from the tapped offer's own ids.
      expect(detailPage.product.orgId, 'org_b');
      expect(detailPage.product.engineId, 'engine_b1');
      expect(detailPage.product.displayPrice, 4750);
    },
  );
}
