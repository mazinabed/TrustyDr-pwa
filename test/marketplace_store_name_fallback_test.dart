// Standalone Patient Marketplace Discovery, Stage 1 (2026-08-04) —
// MarketplaceStore.fromMap's name fallback. Commerce's Organization schema
// has a single `name` field, never the localized facilityName_en/ar/ku
// triplet Healthcare pharmacy documents provide — this fallback lets a
// standalone Commerce store's response include a plain `name` and still
// populate all three localized fields, WITHOUT ever affecting a Healthcare
// pharmacy response that already sends real, distinct facilityName_en/ar/ku
// values. Pure parsing test, no Firebase/network dependency, matching this
// app's existing marketplace_gallery_parsing_test.dart convention.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

void main() {
  group('MarketplaceStore.fromMap name fallback', () {
    test(
      '11. a standalone Commerce store with only `name` (no facilityName_*) '
      'falls back to that single name for all three localized fields',
      () {
        final store = MarketplaceStore.fromMap({
          'providerId': 'org123',
          'orgId': 'org123',
          'name': 'Sample City Retailer',
          'productCount': 3,
        });

        expect(store.facilityNameEn, 'Sample City Retailer');
        expect(store.facilityNameAr, 'Sample City Retailer');
        expect(store.facilityNameKu, 'Sample City Retailer');
        expect(store.localizedName('en'), 'Sample City Retailer');
        expect(store.localizedName('ar'), 'Sample City Retailer');
      },
    );

    test(
      '12. an existing Healthcare pharmacy response with real localized '
      'facilityName_en/ar/ku is completely unaffected by the fallback — '
      'even when a `name` field happens to also be present',
      () {
        final store = MarketplaceStore.fromMap({
          'providerId': 'hc_pharmacy_uid1',
          'orgId': 'hc_pharmacy_uid1',
          'facilityName_en': 'Al Noor Pharmacy',
          'facilityName_ar': 'صيدلية النور',
          'facilityName_ku': 'دەرمانخانەی نوور',
          // A Healthcare pharmacy response never actually sends `name`, but
          // even if it did, real localized values must always win.
          'name': 'Should Never Be Used',
          'productCount': 10,
        });

        expect(store.facilityNameEn, 'Al Noor Pharmacy');
        expect(store.facilityNameAr, 'صيدلية النور');
        expect(store.facilityNameKu, 'دەرمانخانەی نوور');
      },
    );

    test(
      'a partial localized set (e.g. only facilityName_en present) falls '
      'back to `name` ONLY for the missing ones, never overwriting the '
      'one real localized value that IS present',
      () {
        final store = MarketplaceStore.fromMap({
          'providerId': 'org456',
          'orgId': 'org456',
          'facilityName_en': 'Real English Name',
          'name': 'Fallback Name',
          'productCount': 1,
        });

        expect(store.facilityNameEn, 'Real English Name');
        expect(store.facilityNameAr, 'Fallback Name');
        expect(store.facilityNameKu, 'Fallback Name');
      },
    );

    test(
        'no `name` and no facilityName_* at all falls back to empty string, never crashes',
        () {
      final store = MarketplaceStore.fromMap({
        'providerId': 'org789',
        'orgId': 'org789',
        'productCount': 0,
      });

      expect(store.facilityNameEn, '');
      expect(store.facilityNameAr, '');
      expect(store.facilityNameKu, '');
    });

    test(
        'a blank/whitespace-only facilityName_en falls back to `name`, not the blank value',
        () {
      final store = MarketplaceStore.fromMap({
        'providerId': 'org999',
        'orgId': 'org999',
        'facilityName_en': '   ',
        'name': 'Trimmed Fallback',
        'productCount': 0,
      });

      expect(store.facilityNameEn, 'Trimmed Fallback');
    });
  });
}
