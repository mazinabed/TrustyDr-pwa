// Store Info sheet (2026-08-07, redesigned 2026-08-08) — coverage for
// showStoreInfoSheet, its content-density adaptation (no section headings,
// icon-prefixed rows only), and storeHasDetailedInfo() gate. No Firebase
// dependency: MarketplaceStoreBranding is a plain model and
// showStoreInfoSheet only needs a BuildContext, so this pumps a minimal
// MaterialApp harness rather than the full MarketplaceStorePage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_info_sheet.dart';

Future<void> _pumpAndOpenSheet(
  WidgetTester tester, {
  required MarketplaceStoreBranding? store,
  String? resolvedLocation,
  String? description,
  Size screenSize = const Size(390, 844),
  TextDirection textDirection = TextDirection.ltr,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showStoreInfoSheet(
                  context: context,
                  store: store,
                  resolvedLocation: resolvedLocation,
                  description: description,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('storeHasDetailedInfo', () {
    test('everything empty resolves to false — no dead-end trigger', () {
      expect(
        storeHasDetailedInfo(
            store: null, resolvedLocation: null, description: null),
        isFalse,
      );
    });

    test('a description alone is enough to resolve true', () {
      expect(
        storeHasDetailedInfo(
            store: null, resolvedLocation: null, description: 'A great shop'),
        isTrue,
      );
    });

    test('a resolved location alone is enough to resolve true', () {
      expect(
        storeHasDetailedInfo(
            store: null, resolvedLocation: 'Kut, Wasit', description: null),
        isTrue,
      );
    });

    test('store contact/social data alone is enough to resolve true', () {
      final store = MarketplaceStoreBranding.fromMap({'phone': '07800000007'});
      expect(
        storeHasDetailedInfo(
            store: store, resolvedLocation: null, description: null),
        isTrue,
      );
    });
  });

  group('Store Info sheet — content-density adaptation (2026-08-08)', () {
    testWidgets(
        'only address (Demo Store live scenario, minus social) renders just that row',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'streetAddress': '123 Demo Street',
        'locationNotes': 'This is a testing store',
      });
      await _pumpAndOpenSheet(
        tester,
        store: store,
        resolvedLocation: 'Kut, Wasit',
        description: null,
      );

      expect(find.text('123 Demo Street'), findsOneWidget);
      expect(find.text('Kut, Wasit'), findsOneWidget);
      expect(find.text('This is a testing store'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      // No section headings anywhere — content density adapts, sparse
      // data never gets the full About/Location/Contact/Online template.
      expect(find.text('marketplace_store_info_location'), findsNothing);
      expect(find.text('marketplace_store_info_about'), findsNothing);
    });

    testWidgets('only one social link renders just that one row, no heading',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'socialLinks': {'instagram': 'https://instagram.com/demostore'},
      });
      await _pumpAndOpenSheet(tester,
          store: store, resolvedLocation: null, description: null);

      expect(find.text('social_instagram'), findsOneWidget);
      expect(find.text('marketplace_store_social_section'), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets(
        'address + one social link together render exactly those two rows',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'streetAddress': '123 Demo Street',
        'socialLinks': {'instagram': 'https://instagram.com/demostore'},
      });
      await _pumpAndOpenSheet(
        tester,
        store: store,
        resolvedLocation: 'Kut, Wasit',
        description: null,
      );

      expect(find.text('123 Demo Street'), findsOneWidget);
      expect(find.text('social_instagram'), findsOneWidget);
    });

    testWidgets(
        'full contact/social/profile information renders every populated row',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'phone': '07800000007',
        'whatsapp': '07800000008',
        'email': 'owner@example.com',
        'website': 'https://example.com',
        'streetAddress': '123 Demo Street',
        'locationNotes': 'Near the market',
        'socialLinks': {
          'instagram': 'https://instagram.com/demostore',
          'facebook': 'https://facebook.com/demostore',
        },
      });
      await _pumpAndOpenSheet(
        tester,
        store: store,
        resolvedLocation: 'Kut, Wasit',
        description: 'A great local shop for all your needs.',
      );

      expect(
          find.text('A great local shop for all your needs.'), findsOneWidget);
      expect(find.text('123 Demo Street'), findsOneWidget);
      expect(find.text('call_now'), findsOneWidget);
      expect(find.text('whatsapp_contact'), findsOneWidget);
      expect(find.text('email_address'), findsOneWidget);
      expect(find.text('social_website'), findsOneWidget);
      expect(find.text('social_instagram'), findsOneWidget);
      expect(find.text('social_facebook'), findsOneWidget);
    });

    testWidgets(
        'a very long description scrolls internally rather than growing the sheet unbounded',
        (tester) async {
      final longDescription = 'A ' * 400; // long enough to exceed maxHeight
      await _pumpAndOpenSheet(
        tester,
        store: MarketplaceStoreBranding.fromMap(const {}),
        resolvedLocation: null,
        description: longDescription,
      );

      expect(tester.takeException(), isNull);
      // The scrollable region exists — long content is handled via
      // scrolling, never by growing the sheet past its maxHeight cap.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets(
        'an empty store renders no content rows, only the title and close button',
        (tester) async {
      await _pumpAndOpenSheet(tester,
          store: null, resolvedLocation: null, description: null);

      expect(find.text('marketplace_store_info_title'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      expect(find.byIcon(Icons.storefront_outlined), findsNothing);
    });

    testWidgets(
        'renders correctly under Arabic RTL — no exceptions, content-sized',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'streetAddress': '123 شارع تجريبي',
        'socialLinks': {'instagram': 'https://instagram.com/demostore'},
      });
      await _pumpAndOpenSheet(
        tester,
        store: store,
        resolvedLocation: 'الكوت، واسط',
        description: null,
        textDirection: TextDirection.rtl,
        screenSize: const Size(360, 780),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('123 شارع تجريبي'), findsOneWidget);
      expect(find.text('الكوت، واسط'), findsOneWidget);
      final sheetHeight =
          tester.getSize(find.byType(SingleChildScrollView)).height;
      expect(sheetHeight, lessThan(300));
    });
  });

  group('Store Info sheet — interaction (2026-08-08)', () {
    testWidgets('has a visible close (X) button that dismisses the sheet',
        (tester) async {
      await _pumpAndOpenSheet(
        tester,
        store: MarketplaceStoreBranding.fromMap({'phone': '07800000007'}),
        resolvedLocation: null,
        description: null,
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('marketplace_store_info_title'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets(
        'the sheet is content-sized, not full-screen, for sparse data on a narrow mobile viewport',
        (tester) async {
      await _pumpAndOpenSheet(
        tester,
        store: MarketplaceStoreBranding.fromMap({
          'streetAddress': '123 Demo Street',
          'socialLinks': {'instagram': 'https://instagram.com/demostore'},
        }),
        resolvedLocation: 'Kut, Wasit',
        description: null,
        screenSize: const Size(360, 780),
      );

      final sheetHeight =
          tester.getSize(find.byType(SingleChildScrollView)).height;
      // Content-sized: the scrollable region for a handful of short lines
      // must be a small fraction of the 780-tall viewport, not the
      // near-full-screen sheet the pre-fix Center(no heightFactor) bug
      // produced.
      expect(sheetHeight, lessThan(300));
    });
  });
}
