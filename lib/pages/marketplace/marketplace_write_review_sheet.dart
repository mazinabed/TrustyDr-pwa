// Product Ratings & Reviews, Phase 5 (2026-08-10) — the Write/Edit Review
// bottom sheet. Interactive star input styled after the app's existing
// doctor-review star widget (write_review_page.dart) for visual
// consistency, but wired to the callable-based marketplace review path
// (never Firestore directly, unlike that older feature) and using the
// flat marketplace_-prefixed l10n keys, not the older dotted review.*
// namespace.
//
// Never reproduces Verified Purchase logic — Submit always attempts the
// call; a NOT_VERIFIED_PURCHASE failure from the backend is shown as an
// inline error state here, exactly as the backend phrased it (falling
// back to a localized generic message only if the backend sent none).
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/providers/marketplace_review_providers.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

/// Pure, testable mapping from a submitProductReview failure to the l10n
/// KEY to show (never the translated string — this stays widget-free so
/// test/marketplace_review_error_mapping_test.dart can assert on it
/// directly, no widget pump needed, same convention as
/// marketplace_gallery_parsing_test.dart's isolated pure-function tests).
/// Deliberately never surfaces the backend's raw English `e.message` for a
/// KNOWN code — this app is fully localized EN/AR/KU, and showing English
/// backend text to an Arabic/Kurdish patient would defeat that; a known
/// code always maps to a localized key.
String reviewSubmitErrorL10nKey(FirebaseFunctionsException e) {
  final details = e.details;
  final code = (details is Map) ? details['code'] : null;
  if (code == 'not_verified_purchase') {
    return 'marketplace_review_not_verified_purchase';
  }
  if (code == 'invalid_rating_value') {
    return 'marketplace_review_invalid_rating';
  }
  return 'marketplace_review_generic_error';
}

class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.engineId,
    this.existingRating,
    this.existingFeedback,
    this.submitOverride,
  });

  final String engineId;

  /// Non-null when editing an already-submitted review — pre-fills the
  /// stars/text and changes the submit button's label/wording, but goes
  /// through the exact same upsert call either way (Phase 1's
  /// upsertProductReview is find-or-create by construction, so this sheet
  /// never needs to know or branch on "is this a create or an update").
  final int? existingRating;
  final String? existingFeedback;

  /// Test-only seam — defaults to the real [submitProductReview]. This
  /// repo has no existing mocking layer for Cloud Functions callables
  /// (confirmed during Phase 5 audit — no fake_cloud_functions dependency,
  /// no precedent anywhere), so a widget test cannot otherwise exercise
  /// the success/loading/double-tap-guard states deterministically without
  /// a live Firebase connection. Never used by production code, which
  /// always takes the default.
  final Future<void> Function({
    required String engineId,
    required int rating,
    String? feedback,
    required String locale,
  })? submitOverride;

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  late int _rating = widget.existingRating ?? 0;
  late final TextEditingController _feedbackController =
      TextEditingController(text: widget.existingFeedback ?? '');
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingRating != null;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      setState(() =>
          _errorMessage = 'marketplace_review_select_rating_required'.tr());
      return;
    }
    // Guards against a double-tap firing two in-flight submits — the
    // button itself is also disabled while _submitting is true, but this
    // is the actual source-of-truth guard (see the button's onPressed).
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final lang = context.locale.languageCode;
    final submit = widget.submitOverride ?? submitProductReview;
    try {
      await submit(
        engineId: widget.engineId,
        rating: _rating,
        feedback: _feedbackController.text,
        locale: lang,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'marketplace_review_updated_success'.tr()
            : 'marketplace_review_submitted_success'.tr()),
      ));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = reviewSubmitErrorL10nKey(e).tr();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'marketplace_review_generic_error'.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing
                ? 'marketplace_edit_review'.tr()
                : 'marketplace_write_review'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Text(
            'marketplace_review_rating_label'.tr(),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Center(
            child: Wrap(
              spacing: 4,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 34,
                  ),
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _rating = starIndex;
                            _errorMessage = null;
                          }),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            enabled: !_submitting,
            maxLines: 4,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: 'marketplace_review_feedback_hint'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: PatientAppColors.brandTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    _isEditing
                        ? 'marketplace_review_update'.tr()
                        : 'marketplace_review_submit'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
