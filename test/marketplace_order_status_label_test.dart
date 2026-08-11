// Marketplace order/inventory lifecycle audit (2026-08-10) — permanent
// regression test for marketplaceOrderStatusLabelKey, the shared function
// that replaced two independent, identically-broken private copies (the
// root cause of "Patient order status stays stale after merchant action" —
// see marketplace_providers.dart's own doc comment on this function).
// Pure-function test, no widget pump needed — same isolated-testing
// convention as marketplace_gallery_parsing_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_providers.dart';

void main() {
  group('marketplaceOrderStatusLabelKey — pre-fulfillment localStatus', () {
    test('pending', () {
      expect(marketplaceOrderStatusLabelKey('pending', ''),
          'marketplace_order_status_pending');
    });
    test('failed', () {
      expect(marketplaceOrderStatusLabelKey('failed', ''),
          'marketplace_order_status_failed');
    });
    test(
        'cancelled — localStatus wins even if fulfillmentStatus is set '
        '(a cancelled order is cancelled regardless of prior progress)', () {
      expect(marketplaceOrderStatusLabelKey('cancelled', 'preparing'),
          'marketplace_order_status_cancelled');
    });
  });

  group(
      'marketplaceOrderStatusLabelKey — the actual bug: confirmed + '
      'fulfillmentStatus must reflect merchant actions', () {
    test(
        'confirmed + new (merchant has not acted yet) -> preparing '
        '(matches the previous default, no regression)', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'new'),
          'marketplace_order_status_preparing');
    });
    test(
        'confirmed + accepted -> the accepted stage label (THE bug: '
        'this used to render "Preparing" forever)', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'accepted'),
          'marketplace_order_stage_accepted');
    });
    test('confirmed + preparing -> preparing stage', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'preparing'),
          'marketplace_order_stage_preparing');
    });
    test('confirmed + readyForPickup -> ready-for-pickup stage', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'readyForPickup'),
          'marketplace_order_stage_ready_for_pickup');
    });
    test(
        'confirmed + readyForDelivery -> grouped with out-for-delivery '
        '(no distinct label; not yet independently patient-actionable)', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'readyForDelivery'),
          'marketplace_order_stage_out_for_delivery');
    });
    test('confirmed + outForDelivery -> out-for-delivery stage', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'outForDelivery'),
          'marketplace_order_stage_out_for_delivery');
    });
    test('confirmed + completed -> the completed label', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'completed'),
          'marketplace_order_status_completed');
    });
    test('confirmed + rejected -> rejected stage', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'rejected'),
          'marketplace_order_stage_rejected');
    });
    test('confirmed + deliveryFailed -> delivery-failed stage', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', 'deliveryFailed'),
          'marketplace_order_stage_delivery_failed');
    });
    test(
        'confirmed + unrecognized/empty fulfillmentStatus -> preparing '
        '(safe fallback, never throws)', () {
      expect(marketplaceOrderStatusLabelKey('confirmed', ''),
          'marketplace_order_status_preparing');
      expect(marketplaceOrderStatusLabelKey('confirmed', 'somethingUnknown'),
          'marketplace_order_status_preparing');
    });
  });
}
