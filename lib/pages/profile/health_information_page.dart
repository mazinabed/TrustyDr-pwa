import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/health_profile_controller.dart';
import 'package:trustydr/core/providers/health_profile_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_health_profile.dart';

class HealthInformationPage extends ConsumerStatefulWidget {
  const HealthInformationPage({super.key});

  @override
  ConsumerState<HealthInformationPage> createState() =>
      _HealthInformationPageState();
}

class _HealthInformationPageState extends ConsumerState<HealthInformationPage> {
  DateTime? _dateOfBirth;
  String? _gender;
  String? _bloodType;
  List<String> _allergies = [];
  List<String> _conditions = [];
  List<String> _medications = [];

  final _allergyCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _medicationCtrl = TextEditingController();

  bool _initialized = false;
  bool _profileExists = false;
  bool _isEditing = false;

  // Snapshot taken when entering edit mode — restored on cancel.
  DateTime? _editEntryDob;
  String? _editEntryGender;
  String? _editEntryBloodType;
  List<String> _editEntryAllergies = [];
  List<String> _editEntryConditions = [];
  List<String> _editEntryMedications = [];

  static const _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const _genders = ['male', 'female'];

  @override
  void dispose() {
    _allergyCtrl.dispose();
    _conditionCtrl.dispose();
    _medicationCtrl.dispose();
    super.dispose();
  }

  void _addItem(TextEditingController ctrl, List<String> list) {
    final text = ctrl.text.trim();
    if (text.isEmpty || list.length >= 10) return;
    setState(() {
      list.add(text);
      ctrl.clear();
    });
  }

  void _removeItem(List<String> list, int index) {
    setState(() => list.removeAt(index));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profile = PatientHealthProfile(
      patientId: uid,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      bloodType: _bloodType,
      allergies: _allergies.isEmpty ? null : List.from(_allergies),
      chronicConditions: _conditions.isEmpty ? null : List.from(_conditions),
      currentMedications: _medications.isEmpty ? null : List.from(_medications),
    );

    await ref
        .read(healthProfileControllerProvider.notifier)
        .save(profile, exists: _profileExists);

    if (!mounted) return;
    final controllerState = ref.read(healthProfileControllerProvider);
    if (!controllerState.hasError) {
      setState(() {
        _profileExists = true;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('health.saved'))),
      );
    }
  }

  void _enterEditMode() {
    setState(() {
      _editEntryDob = _dateOfBirth;
      _editEntryGender = _gender;
      _editEntryBloodType = _bloodType;
      _editEntryAllergies = List.from(_allergies);
      _editEntryConditions = List.from(_conditions);
      _editEntryMedications = List.from(_medications);
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _dateOfBirth = _editEntryDob;
      _gender = _editEntryGender;
      _bloodType = _editEntryBloodType;
      _allergies = List.from(_editEntryAllergies);
      _conditions = List.from(_editEntryConditions);
      _medications = List.from(_editEntryMedications);
      _allergyCtrl.clear();
      _conditionCtrl.clear();
      _medicationCtrl.clear();
      _isEditing = false;
    });
  }

  void _initFromProfile(PatientHealthProfile? profile) {
    if (_initialized) return;
    setState(() {
      _initialized = true;
      _profileExists = profile != null;
      if (profile != null) {
        _dateOfBirth = profile.dateOfBirth;
        _gender = profile.gender;
        _bloodType = profile.bloodType;
        _allergies = List.from(profile.allergies ?? []);
        _conditions = List.from(profile.chronicConditions ?? []);
        _medications = List.from(profile.currentMedications ?? []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final profileAsync = ref.watch(healthProfileProvider(uid));
    final isSaving = ref.watch(healthProfileControllerProvider).isLoading;

    // Initialize exactly once from the first resolved state.
    //
    // ref.listen only fires on *transitions*, so if healthProfileProvider is
    // already in AsyncData when this page opens (kept alive by _HealthInfoSectionCard
    // on the profile screen), the listener would never fire and the spinner
    // would loop forever. Using whenOrNull on every build() while !_initialized
    // handles both cases:
    //   (a) provider already in AsyncData — fires callback on next frame
    //   (b) provider transitions AsyncLoading → AsyncData — rebuild triggers
    //       this block again and fires the callback
    // AsyncError is treated as "no profile" so the user can still edit.
    if (!_initialized) {
      profileAsync.whenOrNull(
        data: (profile) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _initialized) return;
            _initFromProfile(profile);
          });
        },
        error: (_, __) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _initialized) return;
            setState(() => _initialized = true);
          });
        },
      );

      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(tr('health.title')),
          backgroundColor: Colors.white,
          foregroundColor: PatientAppColors.darkNavy,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final appBar = AppBar(
      title: Text(tr('health.title')),
      backgroundColor: Colors.white,
      foregroundColor: PatientAppColors.darkNavy,
      elevation: 0,
    );

    // ── Summary view (default) ───────────────────────────────────────────────
    if (!_isEditing) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: appBar,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _optionalBanner(),
              const SizedBox(height: 12),
              _savedSummaryCard(
                  profileAsync.maybeWhen(data: (p) => p, orElse: () => null)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _enterEditMode,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    tr('health.edit_button'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PatientAppColors.brandTeal,
                    side: const BorderSide(color: PatientAppColors.brandTeal),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    // ── Edit view ────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: appBar,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(tr('health.date_of_birth')),
            _dobField(),
            const SizedBox(height: 16),
            _fieldLabel(tr('health.gender')),
            _genderChips(),
            const SizedBox(height: 16),
            _fieldLabel(tr('health.blood_type')),
            _bloodTypeDropdown(),
            const SizedBox(height: 20),
            _fieldLabel(tr('health.allergies')),
            _listInput(_allergyCtrl, _allergies, tr('health.allergies_hint'),
                () => _addItem(_allergyCtrl, _allergies)),
            _chipList(_allergies),
            const SizedBox(height: 16),
            _fieldLabel(tr('health.conditions')),
            _listInput(
                _conditionCtrl,
                _conditions,
                tr('health.conditions_hint'),
                () => _addItem(_conditionCtrl, _conditions)),
            _chipList(_conditions),
            const SizedBox(height: 16),
            _fieldLabel(tr('health.medications')),
            _listInput(
                _medicationCtrl,
                _medications,
                tr('health.medications_hint'),
                () => _addItem(_medicationCtrl, _medications)),
            _chipList(_medications),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientAppColors.brandTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        tr('health.save'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isSaving ? null : _cancelEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PatientAppColors.darkNavy,
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(tr('health.cancel')),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _optionalBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PatientAppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: PatientAppColors.brandTeal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: PatientAppColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('health.optional_note'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: PatientAppColors.darkNavy,
        ),
      ),
    );
  }

  Widget _dobField() {
    final fmt = DateFormat('dd / MM / yyyy');
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: PatientAppColors.brandTeal),
            const SizedBox(width: 10),
            Text(
              _dateOfBirth != null
                  ? fmt.format(_dateOfBirth!)
                  : tr('health.date_of_birth'),
              style: TextStyle(
                fontSize: 14,
                color: _dateOfBirth != null
                    ? PatientAppColors.darkNavy
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChips() {
    return Wrap(
      spacing: 8,
      children: _genders.map((g) {
        final selected = _gender == g;
        return ChoiceChip(
          label: Text(tr('health.gender_$g')),
          selected: selected,
          onSelected: (_) => setState(() => _gender = g),
          selectedColor: PatientAppColors.brandTeal.withValues(alpha: 0.18),
          labelStyle: TextStyle(
            color: selected ? PatientAppColors.brandTeal : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }

  Widget _bloodTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _bloodType,
          hint: Text(
            tr('health.blood_type'),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          isExpanded: true,
          items: _bloodTypes
              .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
              .toList(),
          onChanged: (v) => setState(() => _bloodType = v),
        ),
      ),
    );
  }

  Widget _listInput(TextEditingController ctrl, List<String> list, String hint,
      VoidCallback onAdd) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatientAppColors.brandTeal),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: list.length >= 10 ? null : onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: PatientAppColors.brandTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(tr('health.add')),
        ),
      ],
    );
  }

  Widget _chipList(List<String> items) {
    if (items.isEmpty) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.asMap().entries.map((e) {
          return Chip(
            label: Text(e.value, style: const TextStyle(fontSize: 13)),
            onDeleted: () => _removeItem(items, e.key),
            deleteIconColor: Colors.grey.shade600,
            backgroundColor: Colors.grey.shade100,
          );
        }).toList(),
      ),
    );
  }

  // ── Saved summary card ─────────────────────────────────────────────────────

  Widget _savedSummaryCard(PatientHealthProfile? profile) {
    final fmt = DateFormat('dd / MM / yyyy');
    final dob = profile?.dateOfBirth;
    final gender = profile?.gender;
    final bloodType = profile?.bloodType;
    final allergies = profile?.allergies ?? [];
    final conditions = profile?.chronicConditions ?? [];
    final medications = profile?.currentMedications ?? [];

    final hasAny = dob != null ||
        gender != null ||
        bloodType != null ||
        allergies.isNotEmpty ||
        conditions.isNotEmpty ||
        medications.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasAny
            ? PatientAppColors.brandTeal.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAny
              ? PatientAppColors.brandTeal.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: hasAny
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dob != null || gender != null || bloodType != null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (dob != null) _summaryPill(fmt.format(dob)),
                      if (gender != null)
                        _summaryPill(tr('health.gender_$gender')),
                      if (bloodType != null) _summaryPill(bloodType),
                    ],
                  ),
                if (allergies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _summarySection(
                      tr('health.allergies'), allergies, Colors.red.shade700),
                ],
                if (conditions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _summarySection(tr('health.conditions'), conditions,
                      Colors.orange.shade700),
                ],
                if (medications.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _summarySection(tr('health.medications'), medications,
                      Colors.blue.shade700),
                ],
              ],
            )
          : Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  tr('health.no_info_saved'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _summarySection(String label, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 4,
          runSpacing: 3,
          children: items
              .map(
                (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
