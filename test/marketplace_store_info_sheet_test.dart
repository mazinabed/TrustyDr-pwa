// Store header compaction (2026-08-07) — coverage for the "See Store Info"
// bottom sheet and its storeHasDetailedInfo() gate. No Firebase dependency:
// MarketplaceStoreBranding is a plain model and showStoreInfoSheet only
// needs a BuildContext, so this pumps a minimal MaterialApp harness rather
// than the full MarketplaceStorePage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_info_sheet.dart';

Future<void> _pumpAndOpenSheet(
  WidgetTester tester, {
  required MarketplaceStoreBranding? store,
  String? resolvedLocation,
  String? description,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
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

  group('Store Info sheet content', () {
    testWidgets('renders only the sub-sections that have data', (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'phone': '07800000007',
        'streetAddress': '123 Demo Street',
      });
      await _pumpAndOpenSheet(
        tester,
        store: store,
        resolvedLocation: 'Kut, Wasit',
        description: 'A great local shop',
      );

      // Sub-section headings resolve via .tr() — this test suite has no
      // EasyLocalization wrapper (matching this app's existing test
      // convention of asserting structure/data, not translated strings),
      // so an uninitialized .tr() call simply echoes its own key back.
      expect(find.text('marketplace_store_info_about'), findsOneWidget);
      expect(find.text('A great local shop'), findsOneWidget);
      expect(find.text('marketplace_store_info_location'), findsOneWidget);
      expect(find.text('123 Demo Street'), findsOneWidget);
      expect(find.text('Kut, Wasit'), findsOneWidget);
      expect(find.text('marketplace_store_contact_section'), findsOneWidget);
      // No social/website data was supplied — Online never renders.
      expect(find.text('marketplace_store_social_section'), findsNothing);
    });

    testWidgets('an empty store renders no sub-sections at all',
        (tester) async {
      await _pumpAndOpenSheet(tester,
          store: null, resolvedLocation: null, description: null);

      expect(find.text('marketplace_store_info_about'), findsNothing);
      expect(find.text('marketplace_store_info_location'), findsNothing);
      expect(find.text('marketplace_store_contact_section'), findsNothing);
      expect(find.text('marketplace_store_social_section'), findsNothing);
      // The sheet title itself still renders (an intentionally reachable,
      // if empty, sheet is a caller bug elsewhere — storeHasDetailedInfo
      // is what prevents ever reaching this state from the Store page).
      expect(find.text('marketplace_store_info_title'), findsOneWidget);
    });

    testWidgets(
        'locationNotes renders alongside street address and resolved city',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'streetAddress': '123 Demo Street',
        'locationNotes': 'Near the market',
      });
      await _pumpAndOpenSheet(
        tester,
        store: store,
        resolvedLocation: 'Kut, Wasit',
        description: null,
      );

      expect(find.text('123 Demo Street'), findsOneWidget);
      expect(find.text('Kut, Wasit'), findsOneWidget);
      expect(find.text('Near the market'), findsOneWidget);
    });

    testWidgets(
        'website merges into the Online sub-section alongside socialLinks',
        (tester) async {
      final store = MarketplaceStoreBranding.fromMap({
        'website': 'https://example.com',
        'socialLinks': {'instagram': 'https://instagram.com/demostore'},
      });
      await _pumpAndOpenSheet(tester,
          store: store, resolvedLocation: null, description: null);

      expect(find.text('marketplace_store_social_section'), findsOneWidget);
    });
  });
}
