import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public Store Profile + Social Links (2026-08-05) — the shared contact/
/// social action-button set, extracted from the near-identical `addSocial`/
/// `actionButton` closures previously duplicated across
/// doctor_profile_v2.dart, pharmacy_provider_profile_page.dart, and
/// diagnostic_provider_profile_page.dart. Reused by both the Healthcare
/// Provider public profiles (call/email/social) and the standalone
/// Commerce Store page (call/whatsapp/email/social) — one widget, one
/// empty-state rule (a missing/invalid value produces NO button, never a
/// blank one), instead of a fourth copy-pasted implementation.
///
/// A single visual icon+label circle button — identical styling to what
/// every Provider profile page already rendered inline.
class SocialContactActionButton extends StatelessWidget {
  const SocialContactActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Builds the ordered list of contact/social action buttons — call,
/// WhatsApp, email, then Instagram/Facebook/TikTok/YouTube/Website.
///
/// Every value is independently optional; an absent/empty/invalid one is
/// simply skipped (never rendered as a disabled or blank button). [phone]
/// is additionally gated by [canCall] — mirrors Healthcare's own
/// `canCall` admin-controlled gate for Provider profiles; standalone
/// Commerce callers that already pre-gate every value server-side (see
/// trustydr-commerce/functions/src/organizations.ts's
/// publicBusinessProfileFromOrgDoc — phone is null unless the merchant
/// opted in) simply never need to pass [canCall] at all (defaults to
/// true, matching "the value itself already encodes whether it's public").
/// Social URLs must parse as a real http(s):// link, exactly the same
/// scheme check every existing Provider page already applied — a
/// malformed or non-http(s) stored value is dropped, not surfaced as a
/// broken button.
List<Widget> buildSocialContactActionButtons({
  String? phone,
  String? email,
  String? whatsapp,
  bool canCall = true,
  Map<String, dynamic>? socialLinks,
}) {
  final items = <Widget>[];

  void addUrlAction({
    required String? url,
    required Widget icon,
    required String labelKey,
    required Color color,
  }) {
    if (url == null) return;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    items.add(
      SocialContactActionButton(
        icon: icon,
        label: labelKey.tr(),
        color: color,
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      ),
    );
  }

  final trimmedPhone = phone?.trim() ?? '';
  if (canCall && trimmedPhone.isNotEmpty) {
    items.add(
      SocialContactActionButton(
        icon: Icon(Icons.call, color: PatientAppColors.statusConfirmed),
        label: 'call_now'.tr(),
        color: PatientAppColors.statusConfirmed,
        onTap: () => launchUrl(Uri.parse('tel:$trimmedPhone')),
      ),
    );
  }

  final trimmedWhatsapp = whatsapp?.trim() ?? '';
  if (trimmedWhatsapp.isNotEmpty) {
    final digitsOnly = trimmedWhatsapp.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digitsOnly.isNotEmpty) {
      items.add(
        SocialContactActionButton(
          icon: const FaIcon(FontAwesomeIcons.whatsapp,
              color: Color(0xFF25D366), size: 24),
          label: 'whatsapp_contact'.tr(),
          color: const Color(0xFF25D366),
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/$digitsOnly'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      );
    }
  }

  final trimmedEmail = email?.trim() ?? '';
  if (trimmedEmail.isNotEmpty) {
    items.add(
      SocialContactActionButton(
        icon: Icon(Icons.email_outlined, color: PatientAppColors.brandTeal),
        label: 'email_address'.tr(),
        color: PatientAppColors.brandTeal,
        onTap: () => launchUrl(Uri.parse('mailto:$trimmedEmail')),
      ),
    );
  }

  String? socialValue(String key) {
    final value = socialLinks?[key];
    return value is String ? value : null;
  }

  addUrlAction(
    url: socialValue('instagram'),
    icon: const FaIcon(FontAwesomeIcons.instagram,
        color: Color(0xFFE1306C), size: 24),
    labelKey: 'social_instagram',
    color: const Color(0xFFE1306C),
  );
  addUrlAction(
    url: socialValue('facebook'),
    icon: const FaIcon(FontAwesomeIcons.facebook,
        color: Color(0xFF1877F2), size: 24),
    labelKey: 'social_facebook',
    color: const Color(0xFF1877F2),
  );
  addUrlAction(
    url: socialValue('tiktok'),
    icon:
        const FaIcon(FontAwesomeIcons.tiktok, color: Colors.black87, size: 24),
    labelKey: 'social_tiktok',
    color: Colors.black87,
  );
  addUrlAction(
    url: socialValue('youtube'),
    icon: const FaIcon(FontAwesomeIcons.youtube,
        color: Color(0xFFFF0000), size: 24),
    labelKey: 'social_youtube',
    color: const Color(0xFFFF0000),
  );
  addUrlAction(
    url: socialValue('website'),
    icon: FaIcon(FontAwesomeIcons.globe,
        color: PatientAppColors.brandTeal, size: 24),
    labelKey: 'social_website',
    color: PatientAppColors.brandTeal,
  );

  return items;
}

/// Convenience wrapper for non-Sliver contexts (e.g. the standalone
/// Commerce Store page, a plain widget tree) — same `Wrap` layout
/// (centered, 16/12 spacing) Provider profile pages already use inside
/// their own `SliverToBoxAdapter`. Renders nothing at all (not even
/// padding) when there are no valid actions, so an empty section never
/// leaves a gap.
class SocialContactActionsRow extends StatelessWidget {
  const SocialContactActionsRow({
    super.key,
    this.phone,
    this.email,
    this.whatsapp,
    this.canCall = true,
    this.socialLinks,
  });

  final String? phone;
  final String? email;
  final String? whatsapp;
  final bool canCall;
  final Map<String, dynamic>? socialLinks;

  @override
  Widget build(BuildContext context) {
    final items = buildSocialContactActionButtons(
      phone: phone,
      email: email,
      whatsapp: whatsapp,
      canCall: canCall,
      socialLinks: socialLinks,
    );
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: items,
    );
  }
}
