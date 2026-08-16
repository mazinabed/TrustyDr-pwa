// Marketplace Platform Phase 5 — Patient-visibility gap correction
// (2026-08-16). A live smoke test approved BOTH sponsored placement types
// end to end (submit -> admin approve -> active, confirmed against
// production data) but found neither ever became visible/ranked on any
// real Patient screen: MarketplaceStore/MarketplaceProduct never carried
// isSponsored at all, and the actual widgets a patient sees
// (MarketplaceStoreCard on Browse Stores, MarketplaceProductCard on the
// Products tab and single-store catalogs) rendered from those models
// directly, not from the Compare-Sellers-only groupedProducts structure
// Phase 5's original pass wired sponsorship into.
//
// These tests exercise the REAL widgets and the REAL sort function,
// reproducing the exact reported scenarios, not just the pure backend
// marking functions (see doctor_functions/tests/marketplace_grouping.test.js
// for those).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_card.dart';
import 'package:trustydr/pages/marketplace/marketplace_sort.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_card.dart';

// easy_localization's asset-backed translation lookup does not resolve in
// this VM `flutter test` harness (confirmed directly: the rendered Text
// widget's data is the raw, untranslated key, same fallback behavior
// easy_localization itself uses for a genuinely missing key) — a
// pre-existing property of this test environment, unrelated to this
// correction. Asserting on the key itself still proves exactly what these
// tests need: that the `if (isSponsored) ...` branch renders the
// sponsored-label widget if and only if isSponsored is true.
const _sponsoredLabelKey = 'marketplace_sponsored_label';

MarketplaceStore _store({required String orgId, bool isSponsored = false}) =>
    MarketplaceStore.fromMap({
      'providerId': 'provider_$orgId',
      'orgId': orgId,
      'facilityName_en': 'Store $orgId',
      'facilityName_ar': 'Store $orgId',
      'facilityName_ku': 'Store $orgId',
      'isSponsored': isSponsored,
      'sponsoredPlacementId': isSponsored ? 'placement_$orgId' : null,
    });

MarketplaceProduct _product({
  required String orgId,
  required String engineId,
  double displayPrice = 5000,
  bool isSponsored = false,
}) =>
    MarketplaceProduct.fromMap({
      'orgId': orgId,
      'engineId': engineId,
      'name_en': 'Product $orgId/$engineId',
      'name_ar': 'Product $orgId/$engineId',
      'displayPrice': displayPrice,
      'currencyName': 'IQD',
      'isSponsored': isSponsored,
      'sponsoredPlacementId': isSponsored ? 'placement_$orgId' : null,
    });

// Every card under test (MarketplaceStoreCard/MarketplaceProductCard) is
// ALWAYS rendered inside a bounded grid cell in production
// (SliverGridDelegateWithFixedCrossAxisCount's own mainAxisExtent) — both
// widgets rely on that bounded height internally (Expanded/LayoutBuilder).
// A bare Scaffold(body: ...) gives unbounded height and throws a real
// (unrelated-to-sponsorship) layout assertion, so this harness always
// wraps the pumped child in a SizedBox matching a realistic grid cell.
Future<void> _pumpLocalized(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      // Tapping a card navigates to MarketplaceStorePage/
      // MarketplaceProductDetailPage, both real ConsumerWidgets that read
      // several providers — no overrides needed for what these tests
      // actually assert (the tap must not crash mounting the destination
      // page; its own data-loading state is out of scope here).
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
          home: Scaffold(
            body: SizedBox(width: 220, height: 900, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('MarketplaceStoreCard — sponsored disclosure', () {
    testWidgets(
        'one sponsored store: shows the Sponsored label, no crash on mount (impression) or tap (click)',
        (tester) async {
      final store = _store(orgId: 'org_a', isSponsored: true);
      await _pumpLocalized(tester, MarketplaceStoreCard(store: store));

      expect(tester.takeException(), isNull);
      expect(find.text(_sponsoredLabelKey), findsOneWidget);

      await tester.tap(find.byType(MarketplaceStoreCard));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('one organic store: no Sponsored label anywhere on the card',
        (tester) async {
      final store = _store(orgId: 'org_b', isSponsored: false);
      await _pumpLocalized(tester, MarketplaceStoreCard(store: store));

      expect(tester.takeException(), isNull);
      expect(find.text(_sponsoredLabelKey), findsNothing);
    });
  });

  group('MarketplaceProductCard — sponsored disclosure', () {
    testWidgets(
        'one sponsored product: shows the Sponsored label, no crash on mount (impression) or tap (click)',
        (tester) async {
      final product =
          _product(orgId: 'org_a', engineId: '73', isSponsored: true);
      await _pumpLocalized(tester, MarketplaceProductCard(product: product));

      expect(tester.takeException(), isNull);
      expect(find.text(_sponsoredLabelKey), findsOneWidget);

      await tester.tap(find.byType(MarketplaceProductCard));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('one organic product: no Sponsored label anywhere on the card',
        (tester) async {
      final product =
          _product(orgId: 'org_b', engineId: '74', isSponsored: false);
      await _pumpLocalized(tester, MarketplaceProductCard(product: product));

      expect(tester.takeException(), isNull);
      expect(find.text(_sponsoredLabelKey), findsNothing);
    });

    testWidgets(
        'canonical product with two sellers, only one sponsors — the sponsored seller shows the label, the other does not',
        (tester) async {
      final sponsoredSeller =
          _product(orgId: 'org_a', engineId: 'engine_a', isSponsored: true);
      final organicSeller =
          _product(orgId: 'org_b', engineId: 'engine_b', isSponsored: false);

      await _pumpLocalized(
        tester,
        Column(
          children: [
            SizedBox(
                height: 300,
                child: MarketplaceProductCard(product: sponsoredSeller)),
            SizedBox(
                height: 300,
                child: MarketplaceProductCard(product: organicSeller)),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_sponsoredLabelKey), findsOneWidget);
    });
  });

  group('sortMarketplaceProducts (recommended) — real ranking behavior', () {
    testWidgets(
        'one sponsored product + one organic product: sponsored ranks first',
        (tester) async {
      final organic = _product(orgId: 'org_b', engineId: 'e_b');
      final sponsored =
          _product(orgId: 'org_a', engineId: 'e_a', isSponsored: true);

      final sorted = sortMarketplaceProducts(
          [organic, sponsored], MarketplaceProductSort.recommended, 'en');

      expect(sorted.first.orgId, 'org_a');
      expect(sorted.first.isSponsored, isTrue);
    });

    testWidgets('no sponsorship: ordering is unchanged from the input order',
        (tester) async {
      final a = _product(orgId: 'org_a', engineId: 'e_a');
      final b = _product(orgId: 'org_b', engineId: 'e_b');
      final c = _product(orgId: 'org_c', engineId: 'e_c');

      final sorted = sortMarketplaceProducts(
          [a, b, c], MarketplaceProductSort.recommended, 'en');

      expect(sorted.map((p) => p.orgId).toList(), ['org_a', 'org_b', 'org_c']);
    });
  });
}
