import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/home_address_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/data/services/profile_service.dart';

/// Allows the patient to add or edit their home address.
///
/// Writes to [users/{uid}.homeAddress] as a nested map:
///   { province, city, full, note }
///
/// Used by [ConfirmLabRequestSheet] when a home-visit lab service is selected.
class HomeAddressPage extends ConsumerStatefulWidget {
  const HomeAddressPage({super.key});

  @override
  ConsumerState<HomeAddressPage> createState() => _HomeAddressPageState();
}

class _HomeAddressPageState extends ConsumerState<HomeAddressPage> {
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _fullCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _fullCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _prefillFrom(HomeAddress? addr) {
    if (_loaded || addr == null) return;
    _loaded = true;
    _provinceCtrl.text = addr.province;
    _cityCtrl.text = addr.city;
    _fullCtrl.text = addr.full;
    _noteCtrl.text = addr.note;
  }

  Future<void> _save() async {
    final province = _provinceCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final full = _fullCtrl.text.trim();

    if (province.isEmpty || city.isEmpty || full.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('home_address.required_fields_error'.tr())),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).upsertUser(uid, {
        'homeAddress': {
          'province': province,
          'city': city,
          'full': full,
          'note': _noteCtrl.text.trim(),
        },
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addrAsync = ref.watch(homeAddressProvider);
    addrAsync.whenData(_prefillFrom);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'home_address.title'.tr(),
          style: const TextStyle(
            color: PatientAppColors.brandIndigo,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: PatientAppColors.brandIndigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'home_address.subtitle'.tr(),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _field(
              controller: _provinceCtrl,
              label: 'home_address.province'.tr(),
              icon: Icons.map_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _cityCtrl,
              label: 'home_address.city'.tr(),
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _fullCtrl,
              label: 'home_address.full_address'.tr(),
              icon: Icons.home_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _noteCtrl,
              label: 'home_address.note'.tr(),
              icon: Icons.note_alt_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientAppColors.brandIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'home_address.save'.tr(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: PatientAppColors.brandIndigo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: PatientAppColors.brandIndigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
