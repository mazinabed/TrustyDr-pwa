// Widget regression coverage for the Patient Marketplace product-details
// gallery (2026-07-18) — completes the "Patient App details page still
// shows only one image" fix. MarketplaceProductImageGallery has zero
// Firebase/network dependency beyond the standard Image.network widget
// itself, so it's tested directly here with real widget interaction.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/pages/marketplace/marketplace_product_image_gallery.dart';

const _three = [
  'https://example.com/0.jpg',
  'https://example.com/1.jpg',
  'https://example.com/2.jpg',
];

Future<void> _pump(
  WidgetTester tester,
  List<String> imageUrls, {
  TextDirection direction = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: SizedBox(
            height: 300,
            child: MarketplaceProductImageGallery(imageUrls: imageUrls),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('MarketplaceProductImageGallery', () {
    testWidgets('three images render three thumbnails', (tester) async {
      await _pump(tester, _three);

      for (final url in _three) {
        expect(find.byKey(ValueKey('marketplace-gallery-thumb-$url')),
            findsOneWidget);
      }
    });

    testWidgets('initial preview is Primary (imageUrls[0])', (tester) async {
      await _pump(tester, _three);

      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-preview-https://example.com/0.jpg')),
        findsOneWidget,
      );
    });

    testWidgets('tapping a thumbnail changes the preview', (tester) async {
      await _pump(tester, _three);

      await tester.tap(find.byKey(const ValueKey(
          'marketplace-gallery-thumb-https://example.com/1.jpg')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-preview-https://example.com/1.jpg')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-preview-https://example.com/0.jpg')),
        findsNothing,
      );
    });

    testWidgets('one image hides the thumbnail strip', (tester) async {
      await _pump(tester, const ['https://example.com/0.jpg']);

      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-preview-https://example.com/0.jpg')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-thumb-https://example.com/0.jpg')),
        findsNothing,
      );
    });

    testWidgets('no images shows the placeholder icon, no Image widget',
        (tester) async {
      await _pump(tester, const []);

      expect(find.byType(MarketplaceProductImageGallery), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    });

    testWidgets(
        'RTL rendering does not reverse Primary ordering — imageUrls[0] is still the initial preview',
        (tester) async {
      await _pump(tester, _three, direction: TextDirection.rtl);

      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-preview-https://example.com/0.jpg')),
        findsOneWidget,
      );

      // Selection is index-based, not position-based — tapping the SAME
      // logical thumbnail (by key/URL) still selects the same image
      // regardless of which visual side it's mirrored to.
      await tester.tap(find.byKey(const ValueKey(
          'marketplace-gallery-thumb-https://example.com/2.jpg')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey(
            'marketplace-gallery-preview-https://example.com/2.jpg')),
        findsOneWidget,
      );
    });
  });
}
