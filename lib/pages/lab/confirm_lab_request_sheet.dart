import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/core/utils/patient_identity_validator.dart';
import 'package:trustydr/data/services/lab_request_service.dart';
import 'package:trustydr/models/relationship_option.dart';

class ConfirmLabRequestSheet extends StatefulWidget {
  const ConfirmLabRequestSheet({
    super.key,
    required this.labId,
    required this.centerId,
    required this.facilityName,
    required this.imageUrl,
    required this.scheduleId,
    required this.slotId,
    required this.slotStartAt,
    required this.slotDurationMinutes,
    required this.date,
    required this.slotLabel,
    // serviceGroup: the provider's serviceGroup key ('laboratory' / 'imaging').
    // Written as serviceCategory in Firestore so the portal resolves
    // 'clinical_requests.category_laboratory' correctly.
    required this.serviceGroup,
    // specialtyId: the specialties collection doc ID selected by the patient.
    // Snapshotted into subTypeItems so localized names display without joins.
    required this.specialtyId,
    required this.serviceNameEn,
    required this.serviceNameAr,
    required this.serviceNameKu,
    this.providerNameEn = '',
    this.providerNameAr = '',
    this.providerNameKu = '',
    this.providerAddress = '',
    this.providerImage = '',
    this.providerPhone = '',
  });

  final String labId;
  final String centerId;
  final String facilityName;
  final String imageUrl;
  final String scheduleId;
  final String slotId;
  final DateTime slotStartAt;
  final int slotDurationMinutes;
  final DateTime date;
  final String slotLabel;
  final String serviceGroup;
  final String specialtyId;
  final String serviceNameEn;
  final String serviceNameAr;
  final String serviceNameKu;
  final String providerNameEn;
  final String providerNameAr;
  final String providerNameKu;
  final String providerAddress;
  final String providerImage;
  final String providerPhone;

  @override
  State<ConfirmLabRequestSheet> createState() => _ConfirmLabRequestSheetState();
}

class _ConfirmLabRequestSheetState extends State<ConfirmLabRequestSheet> {
  final _auth = FirebaseAuth.instance;

  bool _forSelf = true;
  final _patientNameCtrl = TextEditingController();
  String? _selectedRelationshipKey;
  final _notesCtrl = TextEditingController();

  bool _submitting = false;
  bool _profileNameChecked = false;
  bool _profileNameMissing = false;
  String? _duplicateError;

  @override
  void initState() {
    super.initState();
    _checkProfileName();
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkProfileName() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final name =
          snap.data()?['name'] ?? snap.data()?['username'] ?? user.displayName;
      if (!mounted) return;
      setState(() {
        _profileNameMissing =
            !(name is String && PatientIdentityValidator.isValidName(name));
        _profileNameChecked = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _profileNameChecked = true);
    }
  }

  String get _localizedServiceName {
    final lang = context.locale.languageCode;
    if (lang == 'ar' && widget.serviceNameAr.isNotEmpty) {
      return widget.serviceNameAr;
    }
    if (lang == 'ku' && widget.serviceNameKu.isNotEmpty) {
      return widget.serviceNameKu;
    }
    return widget.serviceNameEn;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _submitting = true;
      _duplicateError = null;
    });

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profileName = userSnap.data()?['name'] ??
          userSnap.data()?['username'] ??
          user.displayName;

      if (!mounted) return;

      if (!PatientIdentityValidator.isValidName(profileName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('booking.profile_name_missing'.tr())),
        );
        return;
      }

      if (!_forSelf &&
          (!PatientIdentityValidator.isValidName(_patientNameCtrl.text) ||
              _selectedRelationshipKey == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('patient_info_required'.tr())),
        );
        return;
      }

      final rawPhone =
          (userSnap.data()?['phoneNumber'] as String?)?.trim() ?? '';
      final resolvedPhone =
          rawPhone.isNotEmpty ? rawPhone : (user.phoneNumber ?? '');

      final resolvedPatientName =
          _forSelf ? profileName as String : _patientNameCtrl.text.trim();

      final patientIdentityKey = _forSelf
          ? 'self'
          : 'family:${_selectedRelationshipKey ?? 'other'}:${resolvedPatientName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')}';

      final baghdadLocal =
          widget.slotStartAt.toUtc().add(const Duration(hours: 3));
      final dateKey =
          '${baghdadLocal.year}-${baghdadLocal.month.toString().padLeft(2, '0')}-${baghdadLocal.day.toString().padLeft(2, '0')}';

      final isDuplicate = await _hasDuplicateDiagnosticRequest(
        patientId: user.uid,
        patientIdentityKey: patientIdentityKey,
        dateKey: dateKey,
      );
      if (!mounted) return;
      if (isDuplicate) {
        setState(() => _duplicateError = 'lab_booking.duplicate_booking'.tr());
        return;
      }

      await LabRequestService.createScheduledRequest(
        labId: widget.labId,
        centerId: widget.centerId,
        slotId: widget.slotId,
        scheduleId: widget.scheduleId,
        slotStartAt: widget.slotStartAt,
        serviceGroup: widget.serviceGroup,
        specialtyId: widget.specialtyId,
        serviceNameEn: widget.serviceNameEn,
        serviceNameAr: widget.serviceNameAr,
        serviceNameKu: widget.serviceNameKu,
        patientId: user.uid,
        patientName: resolvedPatientName,
        patientIdentityKey: patientIdentityKey,
        patientPhone: resolvedPhone,
        instructions: _notesCtrl.text.trim(),
        providerNameEn: widget.providerNameEn,
        providerNameAr: widget.providerNameAr,
        providerNameKu: widget.providerNameKu,
        providerAddress: widget.providerAddress,
        providerImage: widget.providerImage,
        providerPhone: widget.providerPhone,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      final msg = err.contains('SLOT_ALREADY_BOOKED')
          ? 'slot_full_pick_another'.tr()
          : 'error_generic'.tr();
      if (err.contains('SLOT_ALREADY_BOOKED')) {
        setState(() => _duplicateError = msg);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _hasDuplicateDiagnosticRequest({
    required String patientId,
    required String patientIdentityKey,
    required String dateKey,
  }) async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('clinical_requests')
          .where('patientId', isEqualTo: patientId)
          .where('patientIdentityKey', isEqualTo: patientIdentityKey)
          .where('source', isEqualTo: 'scheduled')
          .where('createdByRole', isEqualTo: 'patient')
          .where('dateKey', isEqualTo: dateKey)
          .where('partnerStatus',
              whereIn: ['pendingApproval', 'scheduled', 'checkedIn'])
          .limit(1)
          .get();
      return qs.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final formattedDate = DateFormat.yMMMEd(locale).format(widget.slotStartAt);

    return Directionality(
      textDirection: Directionality.of(context),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.75,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            children: [
              // ── Provider header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          PatientAppColors.brandTeal.withValues(alpha: 0.1),
                      backgroundImage: widget.imageUrl.isNotEmpty
                          ? NetworkImage(widget.imageUrl)
                          : null,
                      child: widget.imageUrl.isEmpty
                          ? Icon(Icons.biotech_rounded,
                              color: PatientAppColors.brandTeal)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.facilityName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _localizedServiceName,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: PatientAppColors.brandTeal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Date / time card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: PatientAppColors.brandTeal.withValues(alpha: 0.07),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: PatientAppColors.brandTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$formattedDate  •  ${widget.slotLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      'minutes_short'
                          .tr(args: [widget.slotDurationMinutes.toString()]),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Profile name warning ──────────────────────────────────────
              if (_profileNameChecked && _profileNameMissing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'booking.profile_name_missing'.tr(),
                          style: TextStyle(
                              fontSize: 13, color: Colors.orange.shade800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('booking.go_to_profile'.tr()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Who is this for ──────────────────────────────────────────
              Text(
                'who_is_this_for'.tr(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: Text('self'.tr()),
                    selected: _forSelf,
                    onSelected: (_) => setState(() {
                      _forSelf = true;
                      _duplicateError = null;
                    }),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text('someone_else'.tr()),
                    selected: !_forSelf,
                    onSelected: (_) => setState(() {
                      _forSelf = false;
                      _duplicateError = null;
                    }),
                  ),
                ],
              ),

              if (!_forSelf) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _patientNameCtrl,
                  onChanged: (_) => setState(() => _duplicateError = null),
                  decoration: InputDecoration(
                    labelText: 'patient_full_name'.tr(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRelationshipKey,
                  decoration: InputDecoration(
                    labelText: 'relationship'.tr(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  items: RelationshipOption.options.map((o) {
                    return DropdownMenuItem(
                        value: o.key, child: Text(o.localizedLabel));
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedRelationshipKey = v;
                    _duplicateError = null;
                  }),
                ),
              ],

              const SizedBox(height: 20),

              // ── Notes ────────────────────────────────────────────────────
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'additional_notes_optional'.tr(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 24),

              // ── Duplicate / slot error banner ────────────────────────────
              if (_duplicateError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _duplicateError!,
                          style: TextStyle(
                              fontSize: 13, color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Submit button ────────────────────────────────────────────
              ElevatedButton(
                onPressed:
                    (_submitting || _profileNameMissing) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientAppColors.brandTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'lab_booking.confirm_submit'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'secure_booking'.tr(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
