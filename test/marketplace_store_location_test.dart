import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

// Store-page location fix (2026-08-05) — localizedStoreLocation resolves a
// standalone Commerce store's raw provinceKey/cityEn (from
// MarketplaceStoreBranding, the Store-detail model) into a localized
// "City, Province" display string, using the SAME `cities` collection shape
// home.dart's own location selector already reads (province_key / name_en /
// lang.ar / lang.ku / subCities[en,ar,ku]).

final _citiesData = [
  {
    'province_key': 'wasit',
    'name_en': 'Wasit',
    'lang': {'ar': 'واسط', 'ku': 'واست'},
    'subCities': [
      {'en': 'Kut', 'ar': 'الكوت', 'ku': 'کوت'},
    ],
  },
];

void main() {
  group('localizedStoreLocation', () {
    test(
        '1. resolves "City, Province" in English from the live Demo Store shape',
        () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: 'wasit',
        cityEn: 'Kut',
        lang: 'en',
      );
      expect(result, 'Kut, Wasit');
    });

    test('2. resolves the Arabic province/city names for the ar locale', () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: 'wasit',
        cityEn: 'Kut',
        lang: 'ar',
      );
      expect(result, 'الكوت, واسط');
    });

    test('3. resolves the Kurdish province/city names for the ku locale', () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: 'wasit',
        cityEn: 'Kut',
        lang: 'ku',
      );
      expect(result, 'کوت, واست');
    });

    test(
        '4. null provinceKey (legacy Healthcare pharmacy store) resolves to null, never a raw code',
        () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: null,
        cityEn: null,
        lang: 'en',
      );
      expect(result, isNull);
    });

    test(
        '5. provinceKey with no matching cities doc resolves to null, never crashes',
        () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: 'unknown_province',
        cityEn: 'Kut',
        lang: 'en',
      );
      expect(result, isNull);
    });

    test('6. valid province but cityEn absent falls back to province-only', () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: 'wasit',
        cityEn: null,
        lang: 'en',
      );
      expect(result, 'Wasit');
    });

    test(
        '7. valid province but cityEn not found among subCities falls back to province-only',
        () {
      final result = localizedStoreLocation(
        citiesData: _citiesData,
        provinceKey: 'wasit',
        cityEn: 'NotARealCity',
        lang: 'en',
      );
      expect(result, 'Wasit');
    });

    test('8. empty citiesData (not yet loaded) resolves to null, never throws',
        () {
      final result = localizedStoreLocation(
        citiesData: const [],
        provinceKey: 'wasit',
        cityEn: 'Kut',
        lang: 'en',
      );
      expect(result, isNull);
    });
  });
}
