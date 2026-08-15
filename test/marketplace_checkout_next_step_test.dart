// Marketplace Platform, Phase 3 — Multi-Seller Cart + Split Checkout.
//
// Pure unit tests for resolveNextCheckoutStep — the decision of what
// happens immediately after ONE seller's order is placed, kept separate
// from the actual Cloud Functions call for the same reason
// resolveUnavailableCartEntries is (see marketplace_checkout_page.dart's
// own doc comment on resolveNextCheckoutStep, and
// marketplace_write_review_sheet_test.dart's header: this repo has no
// mocking layer for live Cloud Functions callables).
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/pages/marketplace/marketplace_checkout_page.dart';

void main() {
  group('resolveNextCheckoutStep', () {
    test(
        'an ordinary single-seller checkout (no remaining sellers, nothing '
        'placed yet) finishes as a single order', () {
      final step = resolveNextCheckoutStep(
        justPlacedOrderId: 'order_1',
        remainingSellerOrgIds: const [],
        previouslyPlacedOrderIds: const [],
      );
      expect(step, isA<FinishSingleOrder>());
      expect((step as FinishSingleOrder).orderId, 'order_1');
    });

    test(
        'the FIRST of a 3-seller checkout continues to the next seller, '
        'carrying its own orderId forward as placed', () {
      final step = resolveNextCheckoutStep(
        justPlacedOrderId: 'order_1',
        remainingSellerOrgIds: const ['org_b', 'org_c'],
        previouslyPlacedOrderIds: const [],
      );
      expect(step, isA<ContinueToNextSeller>());
      final continueStep = step as ContinueToNextSeller;
      expect(continueStep.nextOrgId, 'org_b');
      expect(continueStep.remainingSellerOrgIds, ['org_c']);
      expect(continueStep.placedOrderIds, ['order_1']);
    });

    test(
        'the MIDDLE of a 3-seller checkout continues again, accumulating '
        'BOTH prior orderIds, never dropping the first', () {
      final step = resolveNextCheckoutStep(
        justPlacedOrderId: 'order_2',
        remainingSellerOrgIds: const ['org_c'],
        previouslyPlacedOrderIds: const ['order_1'],
      );
      expect(step, isA<ContinueToNextSeller>());
      final continueStep = step as ContinueToNextSeller;
      expect(continueStep.nextOrgId, 'org_c');
      expect(continueStep.remainingSellerOrgIds, isEmpty);
      expect(continueStep.placedOrderIds, ['order_1', 'order_2']);
    });

    test(
        'the LAST of a multi-seller checkout finishes as a multi-order '
        'summary with every orderId placed across the whole attempt', () {
      final step = resolveNextCheckoutStep(
        justPlacedOrderId: 'order_3',
        remainingSellerOrgIds: const [],
        previouslyPlacedOrderIds: const ['order_1', 'order_2'],
      );
      expect(step, isA<FinishMultiOrder>());
      expect((step as FinishMultiOrder).orderIds,
          ['order_1', 'order_2', 'order_3']);
    });

    test(
        'the LAST of a two-seller checkout finishes as a multi-order '
        'summary (2 orders), never mistaken for a single order', () {
      final step = resolveNextCheckoutStep(
        justPlacedOrderId: 'order_2',
        remainingSellerOrgIds: const [],
        previouslyPlacedOrderIds: const ['order_1'],
      );
      expect(step, isA<FinishMultiOrder>());
      expect((step as FinishMultiOrder).orderIds, ['order_1', 'order_2']);
    });
  });
}
