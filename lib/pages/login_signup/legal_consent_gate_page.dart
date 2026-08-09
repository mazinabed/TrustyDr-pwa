import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/services/legal_consent_service.dart';
import 'package:trustydr/widgets/legal_document_viewer.dart';

/// Legal Consent Modernization (Patient app, v2 rollout).
///
/// Replaces the old flat single-flag consent screen for the account-level
/// gate: shown whenever getAccountLegalStatus reports that Terms and/or
/// Privacy is not current for this account — a brand-new signup (nothing
/// accepted at all), a returning user whose old v1-era flat
/// legalAccepted/legalVersion never satisfies the new per-document v2
/// requirement, or an existing v2-current user after a later version bump.
/// Only the documents actually reported `current: false` are shown and
/// require a checkbox + individual acceptAccountLegalDocument call — a
/// user who is already current on Privacy but stale on Terms alone (e.g.
/// after a Terms-only version bump) is not asked to re-accept Privacy.
///
/// This page performs no navigation itself on success — the caller (see
/// splashScreen.dart) re-checks status and proceeds once every previously
/// non-current document has been accepted.
class LegalConsentGatePage extends StatefulWidget {
  const LegalConsentGatePage({
    super.key,
    required this.status,
    required this.onAllAccepted,
  });

  final AccountLegalStatus status;
  final VoidCallback onAllAccepted;

  @override
  State<LegalConsentGatePage> createState() => _LegalConsentGatePageState();
}

class _LegalConsentGatePageState extends State<LegalConsentGatePage> {
  late final bool _needsTerms = !widget.status.terms.current;
  late final bool _needsPrivacy = !widget.status.privacy.current;
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _saving = false;
  String? _error;

  bool get _canContinue {
    final termsOk = !_needsTerms || _termsChecked;
    final privacyOk = !_needsPrivacy || _privacyChecked;
    return termsOk && privacyOk;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(fixPadding * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'legal_v2_gate_title'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'legal_v2_gate_description'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (_needsTerms)
                _documentBlock(
                  viewLabel: 'legal_v2_view_terms'.tr(),
                  checkboxLabel: 'legal_v2_accept_terms_checkbox'.tr(),
                  version: widget.status.terms.version,
                  documentKey: 'patient_terms',
                  checked: _termsChecked,
                  onChanged: (v) => setState(() => _termsChecked = v ?? false),
                ),
              if (_needsTerms) const SizedBox(height: 16),
              if (_needsPrivacy)
                _documentBlock(
                  viewLabel: 'legal_v2_view_privacy'.tr(),
                  checkboxLabel: 'legal_v2_accept_privacy_checkbox'.tr(),
                  version: widget.status.privacy.version,
                  documentKey: 'privacy',
                  checked: _privacyChecked,
                  onChanged: (v) =>
                      setState(() => _privacyChecked = v ?? false),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: (!_canContinue || _saving) ? null : _onContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('legal_v2_continue'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentBlock({
    required String viewLabel,
    required String checkboxLabel,
    required String version,
    required String documentKey,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => showLegalDocument(
            context,
            title: viewLabel,
            documentKey: documentKey,
            version: version,
          ),
          icon: const Icon(Icons.description_outlined),
          label: Text(viewLabel),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: onChanged),
            Expanded(
              child: Text(
                checkboxLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onContinue() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final locale = context.locale.languageCode;
      if (_needsTerms) {
        await LegalConsentService.instance.acceptAccountLegalDocument(
          documentType: 'terms',
          locale: locale,
        );
      }
      if (_needsPrivacy) {
        await LegalConsentService.instance.acceptAccountLegalDocument(
          documentType: 'privacy',
          locale: locale,
        );
      }
      if (!mounted) return;
      widget.onAllAccepted();
    } catch (e) {
      // Both backend accept calls run before this point, so anything caught
      // here either failed a write or (the confirmed 2026-08-08 production
      // incident) threw inside onAllAccepted's navigation despite both
      // writes having already succeeded -- see splashScreen.dart's
      // NavigatorState-capture fix. debugPrint (not silent) so a future
      // regression is visible in the console instead of only showing the
      // generic UI message with zero trace of what actually happened.
      debugPrint('[legal-consent] _onContinue failed: ${e.runtimeType}: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'legal_v2_error_saving_consent'.tr();
        });
      }
    }
  }
}
