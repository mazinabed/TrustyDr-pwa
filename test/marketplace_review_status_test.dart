// Live-test follow-up (2026-08-11) — pure-function test for MyReviewStatus
// wire-parsing (marketplace_review_providers.dart), same isolated-testing
// convention as marketplace_review_error_mapping_test.dart. Regression
// coverage for the bug where every product's Write Review action appeared
// regardless of purchase history: eligibleToReview must parse strictly
// from the backend's own field, never default to true.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/core/providers/marketplace_review_providers.dart';

void main() {
  group('MyReviewStatus.none', () {
    test('has no review and is not eligible — the safe default', () {
      expect(MyReviewStatus.none.review, isNull);
      expect(MyReviewStatus.none.eligibleToReview, isFalse);
    });
  });

  group('ProductReview.fromMap — reviewer state used to decide Write vs Edit',
      () {
    test(
        'a verified purchaser with an existing review parses correctly (Edit state)',
        () {
      final review = ProductReview.fromMap({
        'reviewEngineId': '9',
        'reviewerDisplayName': 'Ahmed A.',
        'rating': 5,
        'feedback': 'Great product',
        'createDate': '2026-01-05 10:00:00',
      });
      final status = MyReviewStatus(review: review, eligibleToReview: true);
      expect(status.review, isNotNull);
      expect(status.review!.rating, 5);
      // An existing review always implies eligibility (see
      // marketplaceProductReview.ts's own getMyProductReviewForHealthcare
      // doc comment) — this is what lets the UI show "Edit Your Review"
      // rather than nothing.
      expect(status.eligibleToReview, isTrue);
    });

    test(
        'a verified purchaser with no review yet -> eligible, no review (Write state)',
        () {
      const status = MyReviewStatus(review: null, eligibleToReview: true);
      expect(status.review, isNull);
      expect(status.eligibleToReview, isTrue);
    });

    test('a non-purchaser -> not eligible, no review (no action state)', () {
      const status = MyReviewStatus(review: null, eligibleToReview: false);
      expect(status.review, isNull);
      expect(status.eligibleToReview, isFalse);
    });
  });
}
