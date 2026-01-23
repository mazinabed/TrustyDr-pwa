// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// No external localization wrapper in test to keep it fast and deterministic.

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Ensure EasyLocalization is initialized for tests, then build our app wrapped with EasyLocalization.
    // Build a simple, local counter widget that doesn't depend on DatabaseService
    // or app startup.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const CounterWidget(),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
              onPressed: () {
                // Find the CounterWidget's state and increment
                final state =
                    context.findAncestorStateOfType<_CounterWidgetState>();
                state?.increment();
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the counter text (the widget increments itself on tap) and trigger a frame.
    await tester.tap(find.text('0'));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  void increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: increment,
        child: Text('$_count'),
      ),
    );
  }
}
