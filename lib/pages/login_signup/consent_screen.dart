import 'package:trustydr/pages/legal_disclaimer_page.dart';
import 'package:trustydr/pages/privacy_policy_page.dart';
import 'package:trustydr/pages/terms_conditions_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/services/database_service.dart';
import 'package:trustydr/pages/bottom_bar.dart';
import 'package:trustydr/pages/profile/link_phone_screen.dart';

// Legal pages (EXISTING — DO NOT CHANGE)

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

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

              /// 🔷 Title
              Text(
                'consent_title'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              /// 📝 Subtitle
              Text(
                'consent_description'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 24),

              /// 📄 Legal links
              _legalButton(
                context,
                icon: Icons.description_outlined,
                label: 'terms.title'.tr(),
                page: const TermsConditionsPage(),
              ),

              const SizedBox(height: 12),

              _legalButton(
                context,
                icon: Icons.lock_outline,
                label: 'privacy.title'.tr(),
                page: const PrivacyPolicyPage(),
              ),

              const SizedBox(height: 12),

              _legalButton(
                context,
                icon: Icons.gavel_outlined,
                label: 'legal.title'.tr(),
                page: const LegalDisclaimerPage(),
              ),

              const Spacer(),

              /// ✅ Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: (v) {
                      setState(() => _accepted = v ?? false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'consent_checkbox'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// ▶️ Agree & Continue
              ElevatedButton(
                onPressed: (!_accepted || _saving) ? null : _onAccept,
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
                    : Text('consent_continue'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ▶️ User accepts legal terms
  Future<void> _onAccept() async {
    final user = _user;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await DatabaseService.instance.markLegalAccepted(uid: user.uid);

      if (!mounted) return;

      final hasPhone = user.providerData.any((p) => p.providerId == 'phone');

      if (!hasPhone) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LinkPhoneScreen(navigateToHomeOnSuccess: true),
          ),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomBar()),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// 📄 Open legal page in modal bottom sheet
  void _openLegalModal(BuildContext context, Widget page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: page,
      ),
    );
  }

  Widget _legalButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget page,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _openLegalModal(context, page),
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
