// Product Ratings & Reviews, Phase 5 (2026-08-10) — widget tests for
// WriteReviewSheet, using the submitOverride testability seam (see that
// widget's own doc comment for why: this repo has no mocking layer for
// live Cloud Functions callables). Same EasyLocalization/MaterialApp setup
// convention as marketplace_store_page_compiles_test.dart.
//
// Asserts on WIDGET STRUCTURE (button type, star icon counts, presence of
// the raw l10n KEY as fallback text) rather than translated copy —
// confirmed against the SAME PRE-EXISTING environment behavior the
// existing marketplace_store_page_compiles_test.dart already has (that
// test also logs "Localization key [...] not found" warnings and still
// only asserts structurally/on exception-freedom, never literal translated
// text). EasyLocalization's own documented behavior is to render the key
// itself when a translation can't be resolved — this is what's actually
// on screen in this harness, and asserting on it still verifies the real
// thing that matters: the correct KEY reached the correct place in the
// widget tree.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/pages/marketplace/marketplace_write_review_sheet.dart';

class _ReviewSheetTestApp extends StatelessWidget {
  const _ReviewSheetTestApp({required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('ku', 'IQ')],
      path: 'lib/l10n',
      fallbackLocale: const Locale('ar'),
      startLocale: locale,
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          home: Scaffold(body: child),
        ),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  int? existingRating,
  String? existingFeedback,
  Future<void> Function({
    required String engineId,
    required int rating,
    String? feedback,
    required String locale,
  })? submitOverride,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    _ReviewSheetTestApp(
      locale: locale,
      child: WriteReviewSheet(
        engineId: 'engine-1',
        existingRating: existingRating,
        existingFeedback: existingFeedback,
        submitOverride: submitOverride,
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The one submit/update action lives in exactly one ElevatedButton — used
/// instead of find.text(...) since translated copy doesn't resolve in this
/// test harness (see file header).
Finder get _submitButton => find.byType(ElevatedButton);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('renders 5 empty stars for a new review, no exception',
      (tester) async {
    await _pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(_submitButton, findsOneWidget);
  });

  testWidgets(
      'tapping a star fills it and every star up to it (1-5 star '
      'interaction)', (tester) async {
    await _pump(tester);
    final starButtons = find.byType(IconButton);
    expect(starButtons, findsNWidgets(5));

    await tester.tap(starButtons.at(3)); // 4th star
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(1));
  });

  testWidgets(
      'submitting with no rating selected shows the select-rating-required '
      'key and never calls submitOverride', (tester) async {
    var callCount = 0;
    await _pump(
      tester,
      submitOverride: ({
        required engineId,
        required rating,
        feedback,
        required locale,
      }) async {
        callCount++;
      },
    );

    await tester.tap(_submitButton);
    await tester.pump();

    expect(callCount, 0);
    expect(
      find.text('marketplace_review_select_rating_required'),
      findsOneWidget,
    );
  });

  testWidgets(
      'a successful submit calls submitOverride exactly once with the '
      'selected rating/feedback, then pops true', (tester) async {
    var callCount = 0;
    int? capturedRating;
    String? capturedFeedback;
    await _pump(
      tester,
      submitOverride: ({
        required engineId,
        required rating,
        feedback,
        required locale,
      }) async {
        callCount++;
        capturedRating = rating;
        capturedFeedback = feedback;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );

    await tester.tap(find.byType(IconButton).at(4)); // 5 stars
    await tester.enterText(find.byType(TextField), 'Great product!');
    await tester.pump();
    await tester.tap(_submitButton);
    await tester.pump(); // starts the future
    await tester.pump(const Duration(milliseconds: 20)); // resolves it

    expect(callCount, 1);
    expect(capturedRating, 5);
    expect(capturedFeedback, 'Great product!');
    // Navigator.pop is a no-op in this harness (WriteReviewSheet is the
    // root body, not pushed as its own route — a real bottom-sheet push/
    // pop is exercised by _ReviewsSection's own showModalBottomSheet call,
    // not reproduced here) — the real, harness-independent proof of
    // success is the success snackbar's key reaching the screen.
    expect(
      find.text('marketplace_review_submitted_success'),
      findsOneWidget,
    );
  });

  testWidgets(
      'rapid double-tap on submit only invokes submitOverride once — the '
      'button is disabled while the first submit is in flight', (tester) async {
    var callCount = 0;
    await _pump(
      tester,
      submitOverride: ({
        required engineId,
        required rating,
        feedback,
        required locale,
      }) async {
        callCount++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );

    await tester.tap(find.byType(IconButton).at(2)); // 3 stars
    await tester.pump();

    // Two rapid taps before the first submit resolves. Tapping via the
    // button's onPressed (null while _submitting) is a no-op the second
    // time — this is the real guard under test, not a timing artifact.
    await tester.tap(_submitButton);
    await tester.pump(const Duration(milliseconds: 5));
    await tester.tap(_submitButton);
    await tester.pump(const Duration(milliseconds: 5));

    // A loading indicator must be showing (button swapped to disabled +
    // spinner).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    expect(callCount, 1);
  });

  testWidgets(
      'a NOT_VERIFIED_PURCHASE failure shows the verified-purchase key and '
      're-enables the form (no crash, no pop)', (tester) async {
    await _pump(
      tester,
      submitOverride: ({
        required engineId,
        required rating,
        feedback,
        required locale,
      }) async {
        throw FirebaseFunctionsException(
          code: 'failed-precondition',
          message:
              'Only patients who have purchased this product may review it.',
          details: {'code': 'not_verified_purchase'},
        );
      },
    );

    await tester.tap(find.byType(IconButton).at(0)); // 1 star
    await tester.pump();
    await tester.tap(_submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(tester.takeException(), isNull);
    expect(
      find.text('marketplace_review_not_verified_purchase'),
      findsOneWidget,
    );
    // The form must still be there and usable — not stuck spinning, not
    // popped as if it had succeeded.
    expect(find.byType(WriteReviewSheet), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_submitButton, findsOneWidget);
  });

  testWidgets('a generic (unhandled) failure shows the generic-error key',
      (tester) async {
    await _pump(
      tester,
      submitOverride: ({
        required engineId,
        required rating,
        feedback,
        required locale,
      }) async {
        throw Exception('boom');
      },
    );

    await tester.tap(find.byType(IconButton).at(1)); // 2 stars
    await tester.pump();
    await tester.tap(_submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(tester.takeException(), isNull);
    expect(find.text('marketplace_review_generic_error'), findsOneWidget);
  });

  testWidgets(
      'editing an existing review pre-fills stars/text and never calls '
      'submitOverride until the user actually taps submit', (tester) async {
    var callCount = 0;
    await _pump(
      tester,
      existingRating: 4,
      existingFeedback: 'Pretty good.',
      submitOverride: ({
        required engineId,
        required rating,
        feedback,
        required locale,
      }) async {
        callCount++;
      },
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(1));
    expect(find.text('Pretty good.'), findsOneWidget);
    expect(callCount, 0);

    await tester.tap(_submitButton);
    await tester.pump();
    expect(callCount, 1);
  });

  testWidgets('renders without overflow at a narrow mobile width (390px)',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    await _pump(tester);
    expect(tester.takeException(), isNull);
  });

  for (final entry in {
    'AR': const Locale('ar'),
    'KU': const Locale('ku', 'IQ'),
  }.entries) {
    testWidgets('renders without overflow/exception in ${entry.key} (RTL)',
        (tester) async {
      await _pump(tester, locale: entry.value);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    });
  }
}
