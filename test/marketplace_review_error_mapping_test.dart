// Product Ratings & Reviews, Phase 5 (2026-08-10) — pure-function test for
// reviewSubmitErrorL10nKey, same isolated-testing convention as
// marketplace_gallery_parsing_test.dart (no widget pump needed).
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/pages/marketplace/marketplace_write_review_sheet.dart';

void main() {
  group('reviewSubmitErrorL10nKey', () {
    test('NOT_VERIFIED_PURCHASE maps to the verified-purchase key', () {
      final e = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Only patients who have purchased this product may review it.',
        details: {'code': 'not_verified_purchase'},
      );
      expect(
        reviewSubmitErrorL10nKey(e),
        'marketplace_review_not_verified_purchase',
      );
    });

    test('INVALID_RATING_VALUE maps to the invalid-rating key', () {
      final e = FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'Rating must be an integer from 1 to 5.',
        details: {'code': 'invalid_rating_value'},
      );
      expect(reviewSubmitErrorL10nKey(e), 'marketplace_review_invalid_rating');
    });

    test(
        'an unrecognized code maps to the generic error key, never leaks '
        'raw backend text', () {
      final e = FirebaseFunctionsException(
        code: 'internal',
        message: 'Some unexpected backend failure detail.',
        details: {'code': 'something_unexpected'},
      );
      expect(reviewSubmitErrorL10nKey(e), 'marketplace_review_generic_error');
    });

    test(
        'missing/non-map details maps to the generic error key, never '
        'throws', () {
      final e = FirebaseFunctionsException(code: 'internal', message: 'x');
      expect(reviewSubmitErrorL10nKey(e), 'marketplace_review_generic_error');
    });
  });
}
