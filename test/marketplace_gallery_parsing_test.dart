// Regression coverage for the Patient Marketplace product-details gallery
// (2026-07-18). parseGalleryImageUrls is the pure, extracted defensive
// parser MarketplaceProduct.fromMap uses — tested directly here, no
// Firebase/network dependency, matching this app's existing
// database_provider_test.dart convention of testing providers/parsing in
// isolation.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

void main() {
  group('parseGalleryImageUrls', () {
    test('parses 3 images, Primary first', () {
      final result = parseGalleryImageUrls(
        [
          'https://example.com/0.jpg',
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
        ],
        'https://example.com/0.jpg',
      );

      expect(result, [
        'https://example.com/0.jpg',
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]);
    });

    test('missing gallery key (null raw) falls back to [imageUrl]', () {
      final result = parseGalleryImageUrls(null, 'https://example.com/0.jpg');
      expect(result, ['https://example.com/0.jpg']);
    });

    test('missing gallery AND no imageUrl falls back to an empty list', () {
      expect(parseGalleryImageUrls(null, null), isEmpty);
      expect(parseGalleryImageUrls(null, ''), isEmpty);
    });

    test('non-list raw value falls back safely to [imageUrl]', () {
      final result =
          parseGalleryImageUrls('not a list', 'https://example.com/0.jpg');
      expect(result, ['https://example.com/0.jpg']);
    });

    test('removes blank/null entries', () {
      final result = parseGalleryImageUrls(
        [
          'https://example.com/0.jpg',
          '',
          null,
          '   ',
          'https://example.com/1.jpg'
        ],
        'https://example.com/0.jpg',
      );
      expect(result, [
        'https://example.com/0.jpg',
        'https://example.com/1.jpg',
      ]);
    });

    test('deduplicates while preserving order', () {
      final result = parseGalleryImageUrls(
        [
          'https://example.com/0.jpg',
          'https://example.com/1.jpg',
          'https://example.com/0.jpg',
        ],
        'https://example.com/0.jpg',
      );
      expect(result, [
        'https://example.com/0.jpg',
        'https://example.com/1.jpg',
      ]);
    });

    test('Primary (imageUrl) always appears first even if listed later in raw',
        () {
      final result = parseGalleryImageUrls(
        ['https://example.com/1.jpg', 'https://example.com/0.jpg'],
        'https://example.com/0.jpg',
      );
      expect(result.first, 'https://example.com/0.jpg');
    });

    test('caps at a maximum of 3 images', () {
      final result = parseGalleryImageUrls(
        [
          'https://example.com/0.jpg',
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
          'https://example.com/3.jpg',
        ],
        'https://example.com/0.jpg',
      );
      expect(result.length, 3);
    });

    test('handles a malformed gallery entry list without throwing', () {
      // Non-string entries never crash the parser (each is stringified via
      // toString(), same as any other entry) — the max-3 cap (already
      // covered by its own test above) is what ultimately decides which
      // entries survive when junk crowds out real ones, not a special
      // malformed-input code path.
      expect(
        () => parseGalleryImageUrls(
          [123, true, {}, 'https://example.com/1.jpg'],
          'https://example.com/0.jpg',
        ),
        returnsNormally,
      );
      final result = parseGalleryImageUrls(
        [123, 'https://example.com/1.jpg'],
        'https://example.com/0.jpg',
      );
      expect(result.contains('https://example.com/1.jpg'), isTrue);
    });
  });

  group('MarketplaceProduct.fromMap gallery parsing', () {
    test('legacy response with only imageUrl still yields a 1-entry gallery',
        () {
      final product = MarketplaceProduct.fromMap({
        'orgId': 'org1',
        'engineId': '35',
        'sku': 'SKU-1',
        'name_en': 'Test',
        'name_ar': 'اختبار',
        'imageUrl': 'https://example.com/legacy.jpg',
        // no galleryImageUrls key at all
      });
      expect(product.galleryImageUrls, ['https://example.com/legacy.jpg']);
    });

    test('current response with a full gallery parses all 3 entries', () {
      final product = MarketplaceProduct.fromMap({
        'orgId': 'org1',
        'engineId': '35',
        'sku': 'SKU-1',
        'name_en': 'Test',
        'name_ar': 'اختبار',
        'imageUrl': 'https://example.com/0.jpg',
        'galleryImageUrls': [
          'https://example.com/0.jpg',
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
        ],
      });
      expect(product.galleryImageUrls.length, 3);
      expect(product.galleryImageUrls.first, product.imageUrl);
    });

    test('no-image product has an empty gallery', () {
      final product = MarketplaceProduct.fromMap({
        'orgId': 'org1',
        'engineId': '35',
        'sku': 'SKU-1',
        'name_en': 'Test',
        'name_ar': 'اختبار',
      });
      expect(product.imageUrl, isNull);
      expect(product.galleryImageUrls, isEmpty);
    });
  });
}
