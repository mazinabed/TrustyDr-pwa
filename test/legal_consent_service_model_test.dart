// Regression coverage for the 2026-08-09 patientTerms/providerTerms split
// (see doctor_functions/functions/legal/legalConsent.js's own header
// comment for the full architecture rationale). TrustyDr-pwa is
// unconditionally a Patient-context app: AccountLegalStatus.fromResult
// must parse the backend's "patientTerms" key, never "terms" (the retired,
// ambiguous pre-split key) and never "providerTerms" (a different app's
// document). isFullyCurrent must only ever depend on patientTerms +
// privacy.
import 'package:flutter_test/flutter_test.dart';
import 'package:trustydr/services/legal_consent_service.dart';

void main() {
  group('AccountLegalStatus.fromResult (patientTerms/providerTerms split)', () {
    test('parses patientTerms and privacy from the new backend shape', () {
      final status = AccountLegalStatus.fromResult({
        'status': {
          'patientTerms': {'current': true, 'version': 'v2'},
          'providerTerms': {'current': false, 'version': 'v2'},
          'privacy': {'current': true, 'version': 'v2'},
        },
      });

      expect(status.patientTerms.current, isTrue);
      expect(status.patientTerms.version, 'v2');
      expect(status.privacy.current, isTrue);
    });

    test(
        'isFullyCurrent depends only on patientTerms + privacy, never '
        'providerTerms (a Patient-app account must never be blocked or '
        'silently satisfied by the OTHER app\'s document)', () {
      final providerCurrentButPatientStale = AccountLegalStatus.fromResult({
        'status': {
          'patientTerms': {'current': false, 'version': 'v2'},
          'providerTerms': {'current': true, 'version': 'v2'},
          'privacy': {'current': true, 'version': 'v2'},
        },
      });
      expect(providerCurrentButPatientStale.isFullyCurrent, isFalse);

      final patientCurrentProviderStale = AccountLegalStatus.fromResult({
        'status': {
          'patientTerms': {'current': true, 'version': 'v2'},
          'providerTerms': {'current': false, 'version': 'v2'},
          'privacy': {'current': true, 'version': 'v2'},
        },
      });
      expect(patientCurrentProviderStale.isFullyCurrent, isTrue);
    });

    test('a stale-everything status (fresh account) is not fully current', () {
      final status = AccountLegalStatus.fromResult({
        'status': {
          'patientTerms': {'current': false, 'version': 'v2'},
          'providerTerms': {'current': false, 'version': 'v2'},
          'privacy': {'current': false, 'version': 'v2'},
        },
      });
      expect(status.isFullyCurrent, isFalse);
    });
  });

  group('LegalDocumentStatus.fromMap', () {
    test('treats a missing version as an empty string, not null', () {
      final doc = LegalDocumentStatus.fromMap({'current': false});
      expect(doc.version, '');
      expect(doc.current, isFalse);
    });

    test('current is strictly bool-typed (only literal true counts)', () {
      expect(LegalDocumentStatus.fromMap({'current': 'true'}).current, isFalse);
      expect(LegalDocumentStatus.fromMap({'current': true}).current, isTrue);
    });
  });
}
