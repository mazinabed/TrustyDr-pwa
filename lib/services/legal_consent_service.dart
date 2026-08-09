import 'package:cloud_functions/cloud_functions.dart';

/// Legal Consent Modernization (Patient app, v2 rollout).
///
/// Thin wrapper around the account-level legal callables
/// (doctor_functions/functions/legal/legalConsent.js) — never computes or
/// caches a version/acceptance decision client-side. Every call reads the
/// server-authoritative state fresh; `current` is always what the server
/// says it is at the moment of the call, matching the same discipline the
/// backend itself uses (server-authoritative version, append-only
/// history, client never supplies accepted/version/timestamp).
///
/// Document-selection redesign (2026-08-08): the backend now distinguishes
/// "patientTerms" from "providerTerms" — the SAME authenticated uid can be
/// a Patient here AND a Provider in doctor_portal at once, so the choice
/// can no longer come from a mutable, account-global users/{uid}.role
/// field (see legalConsent.js's own header comment for the full
/// rationale). TrustyDr-pwa is unconditionally a Patient-context app, so
/// this service always requests "patientTerms" — it never inspects
/// role and never has a reason to request "providerTerms".
class LegalDocumentStatus {
  const LegalDocumentStatus({required this.current, required this.version});

  final bool current;
  final String version;

  factory LegalDocumentStatus.fromMap(Map<dynamic, dynamic> map) {
    return LegalDocumentStatus(
      current: map['current'] == true,
      version: (map['version'] ?? '').toString(),
    );
  }
}

class AccountLegalStatus {
  const AccountLegalStatus({required this.patientTerms, required this.privacy});

  final LegalDocumentStatus patientTerms;
  final LegalDocumentStatus privacy;

  bool get isFullyCurrent => patientTerms.current && privacy.current;

  factory AccountLegalStatus.fromResult(Map<dynamic, dynamic> result) {
    final status = (result['status'] as Map).cast<String, dynamic>();
    return AccountLegalStatus(
      patientTerms: LegalDocumentStatus.fromMap(
        (status['patientTerms'] as Map).cast<String, dynamic>(),
      ),
      privacy: LegalDocumentStatus.fromMap(
        (status['privacy'] as Map).cast<String, dynamic>(),
      ),
    );
  }
}

class LegalConsentService {
  LegalConsentService._();
  static final LegalConsentService instance = LegalConsentService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Resolved fresh from the server on every call — never cached across
  /// app sessions, so a version bump takes effect the next time this is
  /// called (app cold start), not only at signup.
  Future<AccountLegalStatus> getAccountLegalStatus() async {
    final callable = _functions.httpsCallable('getAccountLegalStatus');
    final result = await callable.call<Map<dynamic, dynamic>>();
    return AccountLegalStatus.fromResult(result.data);
  }

  /// Accepts Patient Terms. The server resolves the current version and
  /// stamps the timestamp itself — this call never supplies either.
  Future<void> acceptPatientTerms({required String locale}) async {
    await _accept(documentType: 'patientTerms', locale: locale);
  }

  /// Accepts the shared Healthcare Privacy Policy.
  Future<void> acceptPrivacy({required String locale}) async {
    await _accept(documentType: 'privacy', locale: locale);
  }

  Future<void> _accept({
    required String documentType,
    required String locale,
  }) async {
    final callable = _functions.httpsCallable('acceptAccountLegalDocument');
    await callable.call<Map<dynamic, dynamic>>({
      'documentType': documentType,
      'locale': locale,
    });
  }
}
