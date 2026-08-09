import 'package:flutter/material.dart';

import 'package:trustydr/pages/bottom_bar.dart';
import 'package:trustydr/pages/login_signup/legal_consent_gate_page.dart';
import 'package:trustydr/services/legal_consent_service.dart';

/// Legal Consent Modernization (Patient app, v2 rollout) — shared
/// post-authentication routing helper.
///
/// Production testing (2026-08-08/09) found that a RETURNING patient
/// correctly went through the new v2 legal-status check
/// (SplashScreen._route(), which calls getAccountLegalStatus()), but every
/// NEW-signup completion path — phone/OTP verification, Google/Apple
/// sign-in, email/password registration — instead called the OLD v1
/// DatabaseService.needsLegalAcceptanceFor()/ConsentScreen flow directly,
/// entirely bypassing SplashScreen and therefore the v2 check, because
/// those flows finish while the app is already running (they never
/// revisit the SplashScreen widget, which only ever mounts once, at cold
/// start). This helper centralizes the v2 check-and-route decision so
/// every authenticated entry point — cold start AND every signup
/// completion — runs the exact same logic, instead of each call site
/// duplicating (and silently diverging from) it.
class LegalConsentRouter {
  const LegalConsentRouter._();

  /// Runs the v2 account-legal-status check for the current authenticated
  /// user and navigates accordingly: to [LegalConsentGatePage] if any
  /// document is stale/missing, otherwise straight to [BottomBar]. Clears
  /// the entire navigation stack either way (pushAndRemoveUntil), matching
  /// the existing signup/login flows' own convention of never leaving a
  /// signed-out screen reachable via back-navigation after authenticating.
  ///
  /// Resolves the NavigatorState ONCE, before any await, and reuses that
  /// object for every navigation this call makes — never re-looks-up
  /// Navigator.of() via [context] after an async gap. That lazy-lookup
  /// pattern is exactly what caused the 2026-08-08 "Unable to save your
  /// response" production incident (see splashScreen.dart's own fix
  /// comment for the full root-cause writeup) — a callback invoked long
  /// after its originating widget had already been replaced/disposed threw
  /// when it tried to look up an ancestor through a deactivated context.
  static Future<void> routeAfterAuth(BuildContext context) async {
    final navigator = Navigator.of(context);

    AccountLegalStatus? status;
    try {
      status = await LegalConsentService.instance.getAccountLegalStatus();
    } catch (_) {
      // Fail closed: a failed status check must never silently fall
      // through to BottomBar. Retry once after a short delay rather than
      // permanently stranding a legitimate user on a transient network
      // blip — same discipline as SplashScreen._route().
      await Future.delayed(const Duration(seconds: 2));
      try {
        status = await LegalConsentService.instance.getAccountLegalStatus();
      } catch (_) {
        if (!context.mounted) return;
        _showRetryDialog(context);
        return;
      }
    }

    if (!status.isFullyCurrent) {
      navigator.pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LegalConsentGatePage(
            status: status!,
            onAllAccepted: () {
              navigator.pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const BottomBar(),
                  transitionsBuilder: (_, a, __, c) =>
                      FadeTransition(opacity: a, child: c),
                ),
                (route) => false,
              );
            },
          ),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
        (route) => false,
      );
      return;
    }

    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const BottomBar(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
      (route) => false,
    );
  }

  static void _showRetryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Connection issue'),
        content: const Text(
          "We couldn't verify your account status. Please check your internet connection.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              routeAfterAuth(context);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
