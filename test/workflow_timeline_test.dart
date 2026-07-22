import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/widgets/workflow_timeline.dart';

void main() {
  const steps = [
    WorkflowTimelineStep(key: 'accepted', label: 'Accepted'),
    WorkflowTimelineStep(key: 'preparing', label: 'Preparing'),
    WorkflowTimelineStep(key: 'outForDelivery', label: 'Out for delivery'),
    WorkflowTimelineStep(key: 'completed', label: 'Completed'),
  ];

  testWidgets('renders every step label for the happy path', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WorkflowTimeline(steps: steps, currentStage: 'preparing'),
      ),
    ));

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Out for delivery'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    // 'preparing' is the current stage -> exactly one check icon for the
    // one earlier, already-done stage ('accepted').
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks every earlier stage done when the entity has completed',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WorkflowTimeline(steps: steps, currentStage: 'completed'),
      ),
    ));

    // accepted, preparing, outForDelivery are all "done" (before completed).
    expect(find.byIcon(Icons.check), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a single terminal row instead of the stepper',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WorkflowTimeline(terminalLabel: 'Delivery attempt failed'),
      ),
    ));

    expect(find.text('Delivery attempt failed'), findsOneWidget);
    // None of the happy-path step labels should render at all.
    expect(find.text('Accepted'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('asserts exactly one of currentStage/terminalLabel is provided', () {
    // Not `const` here on purpose: a const invocation of a failing assert
    // is a compile-time error (uncatchable), not a runtime AssertionError --
    // this needs genuine runtime construction to observe the throw.
    expect(
      () => WorkflowTimeline(steps: steps),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => WorkflowTimeline(
        steps: steps,
        currentStage: 'preparing',
        terminalLabel: 'Cancelled',
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
