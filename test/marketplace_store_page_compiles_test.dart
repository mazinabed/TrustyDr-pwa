// Regression test (2026-08-08) — proves MarketplaceStorePage compiles and
// pumps successfully under the plain VM `flutter test` platform.
//
// Before this checkpoint, ANY test importing marketplace_store_page.dart
// or marketplace_widgets.dart failed to even COMPILE: both transitively
// import home.dart (via marketplace_widgets.dart's
// ensureMarketplaceLogin -> LoginScreen -> ... -> bottom_bar.dart ->
// screens.dart -> home.dart), which imported
// lib/widgets/pwa_install_banner.dart directly with `dart:html` and
// `dart:js_interop` — libraries the VM test platform doesn't have. Fixed
// by isolating those calls behind lib/utils/pwa_install_platform.dart's
// conditional export (same pattern as this app's existing
// web_location.dart/web_reload.dart), which resolves to a plain-Dart stub
// on the VM instead of pulling in dart:html at all. See that file's own
// header comment for the full explanation; no runtime behavior changed,
// only where the platform-specific code lives.
//
// Fixing the compile blocker immediately surfaced a SECOND, real, latent
// bug this test also guards against: marketplace_widgets.dart's
// MarketplaceStoreHeader used a negative top Padding
// (EdgeInsets.fromLTRB(16, -22, 16, 0)) to pull the logo over the banner's
// bottom edge — which violates Flutter's own
// Padding.padding.isNonNegative debug assertion. That assertion is
// stripped in `flutter build web`'s release mode, and no test had ever
// been able to compile this widget before, so the bug shipped silently.
// Fixed (see marketplace_widgets.dart's own comment) by using a small
// non-negative gap instead.
//
// This test's OWN job is narrower than a full UX test: it exists to catch
// a regression of BOTH fixes above (e.g. someone reintroducing a direct
// dart:html import, or a negative EdgeInsets, anywhere in this widget's
// tree), not to re-verify Store-page UX already covered by
// marketplace_store_info_sheet_test.dart/social_contact_links_test.dart.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';
import 'package:trustydr/pages/marketplace/marketplace_store_page.dart';
import 'package:trustydr/pages/marketplace/marketplace_widgets.dart';

void main() {
  // _StoreBody.build()'s first line is `context.locale.languageCode` —
  // easy_localization's `context.locale` getter is a force-unwrap
  // (`EasyLocalization.of(this)!.locale`), so any widget tree that reaches
  // _StoreBody without an EasyLocalization ancestor throws exactly a
  // "Null check operator used on a null value" TypeError. main.dart always
  // provides one (see its runApp call); this wrapper mirrors that same
  // supportedLocales/path/fallbackLocale/startLocale configuration so the
  // test exercises the real widget tree instead of a stand-in.
  setUpAll(() async {
    // ensureInitialized() reads the saved locale via SharedPreferences
    // internally, so the mock must be in place before this call, not just
    // before pumpWidget.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'MarketplaceStorePage compiles and pumps cleanly on the VM test platform (dart:html regression guard)',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;

      SharedPreferences.setMockInitialValues({});

      final catalog = MarketplaceCatalog(
        products: const [],
        categories: const [],
        store: MarketplaceStoreBranding.fromMap(const {}),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketplaceCatalogProvider
                .overrideWith((ref, orgId) async => catalog),
            citiesLookupProvider.overrideWith((ref) async => const []),
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
            child: const MaterialApp(
              home: MarketplaceStorePage(
                providerId: 'p1',
                orgId: 'org_1',
                storeName: 'Demo Store',
              ),
            ),
          ),
        ),
      );
      // EasyLocalization's own delegate load is async — give it a frame
      // before pumping the rest of the tree, same as easy_localization's
      // own widget tests do.
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('Demo Store'), findsOneWidget);
    },
  );

  testWidgets(
    'MarketplaceStoreHeader compiles and pumps cleanly on the VM test platform (negative-padding regression guard)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MarketplaceStoreHeader(
                storeName: 'Demo Store',
                businessType: 'Retailer',
                city: 'Kut, Wasit',
                tagline: 'Great products at fair prices',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Demo Store'), findsOneWidget);
    },
  );
}
