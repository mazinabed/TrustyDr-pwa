import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/widgets/center_action_grid.dart';

// Regression test for the mobile-only +58px grid height bug: GridView (via
// BoxScrollView) auto-absorbs MediaQuery.of(context).padding into a
// SliverPadding whenever its own `padding` is left unset. On a device that
// reports non-zero top/bottom safe-area padding (status bar + gesture nav
// inset), the previously-unset `padding` on the nested GridView.builder
// silently added that inset a second time as extra height, on top of the
// fixed mainAxisExtent-based row math. Desktop web typically reports zero
// MediaQuery.padding, which is why the bug was invisible there.
void main() {
  List<ActionItem> buildItems() => [
        ActionItem(
            icon: Icons.calendar_month_outlined,
            label: 'My Appointments',
            onTap: () {}),
        ActionItem(
            icon: Icons.people_outline, label: 'My Doctors', onTap: () {}),
        ActionItem(
            icon: Icons.local_hospital, label: 'Medical Centers', onTap: () {}),
        ActionItem(
            icon: Icons.category_outlined, label: 'Specialties', onTap: () {}),
        ActionItem(icon: Icons.biotech_outlined, label: 'Labs', onTap: () {}),
        ActionItem(
            icon: Icons.local_pharmacy_outlined,
            label: 'Pharmacies',
            onTap: () {}),
        ActionItem(
            icon: Icons.science_outlined, label: 'My Results', onTap: () {}),
        ActionItem(
            icon: Icons.medication_outlined,
            label: 'My Prescriptions',
            onTap: () {}),
      ];

  // 2 rows * 92px tile height + 1 * 8px row spacing = 192px, fixed by
  // mainAxisExtent regardless of width or safe-area padding.
  const expectedGridHeight = 192.0;

  Future<double> pumpAndMeasure(
    WidgetTester tester, {
    required double width,
    required EdgeInsets mediaQueryPadding,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          padding: mediaQueryPadding,
        ),
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: EdgeInsets.zero,
              children: [CenterActionGrid(items: buildItems())],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final gridFinder = find.byType(CenterActionGrid);
    return (tester.renderObject(gridFinder) as RenderBox).size.height;
  }

  testWidgets(
      'mobile width with non-zero safe-area padding does not inflate grid height',
      (tester) async {
    final height = await pumpAndMeasure(
      tester,
      width: 400,
      // Matches the real reproduction case: ~58px combined top+bottom inset
      // (e.g. a phone status bar + gesture-nav home indicator).
      mediaQueryPadding: const EdgeInsets.only(top: 34, bottom: 24),
    );
    expect(height, expectedGridHeight);
  });

  testWidgets('desktop width with zero safe-area padding is unaffected',
      (tester) async {
    final height = await pumpAndMeasure(
      tester,
      width: 1017,
      mediaQueryPadding: EdgeInsets.zero,
    );
    expect(height, expectedGridHeight);
  });

  testWidgets('mobile width with zero safe-area padding matches too',
      (tester) async {
    final height = await pumpAndMeasure(
      tester,
      width: 400,
      mediaQueryPadding: EdgeInsets.zero,
    );
    expect(height, expectedGridHeight);
  });
}
