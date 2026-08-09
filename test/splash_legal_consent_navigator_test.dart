// Regression test for the 2026-08-08 production incident: Patient users saw
// the red "Unable to save your response." error immediately after accepting
// v2 Terms/Privacy, even though production Firestore data confirmed both
// acceptAccountLegalDocument calls had already succeeded.
//
// Root cause (lib/pages/splashScreen.dart _route()): the `onAllAccepted`
// callback passed to LegalConsentGatePage closed over SplashScreen's own
// `context` and called `Navigator.of(context)` lazily, inside the closure.
// `pushReplacement` removes SplashScreen's route immediately, so by the time
// a user actually finishes reading/checking/submitting the consent form and
// the callback fires, that `context` refers to an already-deactivated
// Element. Looking up an ancestor through a deactivated context throws, and
// that exception propagated out of LegalConsentGatePage._onContinue()'s call
// to widget.onAllAccepted(), landing in its bare `catch (_)` -- which then
// showed the generic error message with no indication both writes had
// already succeeded.
//
// Fix: resolve the NavigatorState once, while `context` is still valid
// (before pushReplacement), and reuse that object inside the closure instead
// of performing a fresh BuildContext lookup later. This test isolates that
// exact mechanism -- push-replace away from a widget, then invoke a
// callback it handed to the new page well after settling -- without needing
// EasyLocalization or a mocked Firebase Functions backend, which the real
// SplashScreen/LegalConsentGatePage require.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'a callback capturing a NavigatorState resolved before pushReplacement '
    'navigates successfully even after the originating widget has been '
    'replaced and disposed, and after the callback fires much later',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _FakeSplash()));
      await tester.pump();

      // Mirrors SplashScreen -> LegalConsentGatePage: this disposes
      // _FakeSplash.
      await tester.tap(find.text('go-to-gate'));
      await tester.pumpAndSettle();
      expect(find.text('go-to-gate'), findsNothing);

      // Mirrors the real elapsed time a user spends on the consent form
      // before LegalConsentGatePage._onContinue() invokes onAllAccepted
      // after both backend accept calls have already resolved.
      await tester.tap(find.text('continue'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('bottom-bar'), findsOneWidget);
    },
  );
}

class _FakeSplash extends StatefulWidget {
  const _FakeSplash();
  @override
  State<_FakeSplash> createState() => _FakeSplashState();
}

class _FakeSplashState extends State<_FakeSplash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          child: const Text('go-to-gate'),
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => _FakeGate(
                  onAllAccepted: () {
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('bottom-bar')),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Stands in for LegalConsentGatePage: on "continue", invokes the
/// caller-supplied callback exactly the way _onContinue() invokes
/// widget.onAllAccepted() once both backend accept calls resolve.
class _FakeGate extends StatelessWidget {
  const _FakeGate({required this.onAllAccepted});
  final VoidCallback onAllAccepted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: onAllAccepted,
          child: const Text('continue'),
        ),
      ),
    );
  }
}
