// Checkout/Inventory mismatch fix (2026-07-20) — regression coverage for
// resolveUnavailableCartEntries, the pure correlation/reason-mapping core
// behind buildUnavailableItemsMessage (kept .tr()-free specifically so it's
// testable here without a live EasyLocalization context — see that
// function's own doc comment in marketplace_checkout_page.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_cart_provider.dart';
import 'package:trustydr/pages/marketplace/marketplace_checkout_page.dart';

CartItem _item({
  required String productEngineId,
  String? variantEngineId,
  String nameEn = 'Paracetamol',
  String nameAr = 'باراسيتامول',
}) {
  return CartItem(
    productEngineId: productEngineId,
    variantEngineId: variantEngineId,
    variantLabel: null,
    nameEn: nameEn,
    nameAr: nameAr,
    displayPrice: 5000,
    currencyName: 'IQD',
    imageUrl: null,
    quantity: 3,
  );
}

void main() {
  group('resolveUnavailableCartEntries', () {
    test('insufficient_stock carries requested/available quantities through',
        () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {
            'productEngineId': '10',
            'variantEngineId': null,
            'reason': 'insufficient_stock',
            'requestedQuantity': 5,
            'availableQuantity': 2,
          },
        ],
        lang: 'en',
      );
      expect(entries, hasLength(1));
      expect(entries.first.reason, UnavailableReason.insufficientStock);
      expect(entries.first.productName, 'Paracetamol');
      expect(entries.first.requestedQuantity, 5);
      expect(entries.first.availableQuantity, 2);
    });

    test(
        'insufficient_stock without quantities (older backend) still resolves the product',
        () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {'productEngineId': '10', 'reason': 'insufficient_stock'},
        ],
        lang: 'en',
      );
      expect(entries.first.reason, UnavailableReason.insufficientStock);
      expect(entries.first.requestedQuantity, isNull);
      expect(entries.first.availableQuantity, isNull);
    });

    test('resolves Arabic name when lang is ar', () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {'productEngineId': '10', 'reason': 'not_found'},
        ],
        lang: 'ar',
      );
      expect(entries.first.productName, 'باراسيتامول');
      expect(entries.first.reason, UnavailableReason.notFound);
    });

    test(
        'two cart lines sharing a template but different variants correlate independently',
        () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [
          _item(
              productEngineId: '10',
              variantEngineId: '101',
              nameEn: 'Vitamin C - Orange'),
          _item(
              productEngineId: '10',
              variantEngineId: '102',
              nameEn: 'Vitamin C - Lemon'),
        ],
        unavailable: [
          {
            'productEngineId': '10',
            'variantEngineId': '102',
            'reason': 'insufficient_stock',
            'requestedQuantity': 4,
            'availableQuantity': 0,
          },
        ],
        lang: 'en',
      );
      expect(entries, hasLength(1));
      // The FAILED variant (102, Lemon) must be named, never the unrelated
      // sibling variant (101, Orange) that shares the same template.
      expect(entries.first.productName, 'Vitamin C - Lemon');
    });

    test('unrecognized reason string maps to unknown, never crashes', () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {'productEngineId': '10', 'reason': 'some_future_reason'},
        ],
        lang: 'en',
      );
      expect(entries.first.reason, UnavailableReason.unknown);
    });

    test(
        'a product not found in the cart resolves to an empty productName, not a crash',
        () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {'productEngineId': '999', 'reason': 'insufficient_stock'},
        ],
        lang: 'en',
      );
      expect(entries.first.productName, isEmpty);
    });

    test('non-map entries in the unavailable list are skipped safely', () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: ['not a map', 42, null],
        lang: 'en',
      );
      expect(entries, isEmpty);
    });

    test('empty unavailable list resolves to no entries', () {
      final entries = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: const [],
        lang: 'en',
      );
      expect(entries, isEmpty);
    });

    test('wrong_store and unpublished reasons are correctly mapped', () {
      final wrongStore = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {'productEngineId': '10', 'reason': 'wrong_store'},
        ],
        lang: 'en',
      );
      expect(wrongStore.first.reason, UnavailableReason.wrongStore);

      final unpublished = resolveUnavailableCartEntries(
        cartItems: [_item(productEngineId: '10')],
        unavailable: [
          {'productEngineId': '10', 'reason': 'unpublished'},
        ],
        lang: 'en',
      );
      expect(unpublished.first.reason, UnavailableReason.unpublished);
    });
  });
}
