import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widget/doctor_avatar.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public profile page for a pharmacy provider.
/// Reads from [public_pharmacy_providers/{providerId}] — a safe, sanitized
/// projection written by the syncPublicPharmacyProvider Cloud Function.
class PharmacyProviderProfilePage extends ConsumerWidget {
  const PharmacyProviderProfilePage({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content =
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('public_pharmacy_providers')
                .doc(providerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: PatientAppColors.brandTeal,
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'error_generic'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              final d = snapshot.data!.data()!;
              return _PharmacyProfileBody(data: d);
            },
          );

          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }
}

// ─── Profile body ─────────────────────────────────────────────────────────────

class _PharmacyProfileBody extends StatelessWidget {
  const _PharmacyProfileBody({required this.data});

  final Map<String, dynamic> data;

  String _loc(String prefix, String lang) {
    if (lang == 'ar') {
      final v = data['${prefix}_ar']?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    if (lang == 'ku') {
      final v = data['${prefix}_ku']?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    return data['${prefix}_en']?.toString() ?? data[prefix]?.toString() ?? '';
  }

  String _dayName(String key, String lang) {
    const en = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };
    const ar = {
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',
      'saturday': 'السبت',
      'sunday': 'الأحد',
    };
    const ku = {
      'monday': 'دووشەممە',
      'tuesday': 'سێشەممە',
      'wednesday': 'چوارشەممە',
      'thursday': 'پێنجشەممە',
      'friday': 'هەینی',
      'saturday': 'شەممە',
      'sunday': 'یەکشەممە',
    };
    if (lang == 'ar') return ar[key] ?? key;
    if (lang == 'ku') return ku[key] ?? key;
    return en[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    final facilityName = _loc('facilityName', lang);
    final address = (data['facilityAddress'] ?? '').toString();
    final city = _loc('city', lang);
    final province = _loc('province', lang);
    final phone = data['phone']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';

    final locationParts = [city, province].where((s) => s.isNotEmpty).toList();
    final locationLine = locationParts.join(', ');

    // Social links
    final showSocial = data['showSocialLinks'] == true;
    final rawSocial = data['socialLinks'];
    final Map<String, String> socialLinks = (showSocial && rawSocial is Map)
        ? Map<String, String>.fromEntries(rawSocial.entries
            .where((e) =>
                e.value is String && (e.value as String).trim().isNotEmpty)
            .map((e) => MapEntry(e.key.toString(), (e.value as String).trim())))
        : {};

    Widget contactBtn(
        Widget icon, String label, Color color, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
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
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    final contactItems = <Widget>[];

    if (phone.isNotEmpty) {
      contactItems.add(contactBtn(
        const Icon(Icons.call, color: PatientAppColors.statusConfirmed),
        'call_now'.tr(),
        PatientAppColors.statusConfirmed,
        () => launchUrl(Uri.parse('tel:$phone')),
      ));
    }

    void addSocial(String key, IconData faIcon, String labelKey, Color color) {
      final url = socialLinks[key];
      if (url == null) return;
      final uri = Uri.tryParse(url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return;
      }
      contactItems.add(contactBtn(
        FaIcon(faIcon, color: color, size: 24),
        labelKey.tr(),
        color,
        () => launchUrl(uri, mode: LaunchMode.externalApplication),
      ));
    }

    addSocial('instagram', FontAwesomeIcons.instagram, 'social_instagram',
        const Color(0xFFE1306C));
    addSocial('facebook', FontAwesomeIcons.facebook, 'social_facebook',
        const Color(0xFF1877F2));
    addSocial(
        'tiktok', FontAwesomeIcons.tiktok, 'social_tiktok', Colors.black87);
    addSocial('youtube', FontAwesomeIcons.youtube, 'social_youtube',
        const Color(0xFFFF0000));
    addSocial('website', FontAwesomeIcons.globe, 'social_website',
        PatientAppColors.brandTeal);

    // Operation hours
    final rawHours = data['operationHours'];
    final Map<String, dynamic>? operationHours =
        rawHours is Map ? Map<String, dynamic>.from(rawHours) : null;

    const dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return CustomScrollView(
      slivers: [
        // ── Header ─────────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: PatientAppColors.brandTeal,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: PatientAppColors.brandGradient,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    DoctorAvatar(imageUrl: imageUrl, size: 88),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        facilityName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderBadge(
                          label: 'pharmacy'.tr(),
                          icon: Icons.local_pharmacy_rounded,
                        ),
                        const SizedBox(width: 8),
                        _HeaderBadge(
                          label: 'verified'.tr(),
                          icon: Icons.verified_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Quick contact / social row ──────────────────────────────────────
        if (contactItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: contactItems,
              ),
            ),
          ),

        // ── Provider info card ──────────────────────────────────────────────
        if (address.isNotEmpty || locationLine.isNotEmpty)
          SliverToBoxAdapter(
            child: _ModernCard(
              title: 'provider_info'.tr(),
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  if (address.isNotEmpty)
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      text: address,
                    ),
                  if (address.isNotEmpty && locationLine.isNotEmpty)
                    const Divider(height: 1, indent: 28, endIndent: 0),
                  if (locationLine.isNotEmpty)
                    _InfoRow(
                      icon: Icons.map_rounded,
                      text: locationLine,
                    ),
                ],
              ),
            ),
          ),

        // ── Operation hours card ────────────────────────────────────────────
        if (operationHours != null && operationHours.isNotEmpty)
          SliverToBoxAdapter(
            child: _ModernCard(
              title: 'pharmacy_operation_hours'.tr(),
              icon: Icons.access_time_rounded,
              child: Column(
                children: dayOrder.map((day) {
                  final entry = operationHours[day];
                  final isOpen = entry is Map && entry['isOpen'] == true;
                  final open =
                      entry is Map ? (entry['open']?.toString() ?? '') : '';
                  final close =
                      entry is Map ? (entry['close']?.toString() ?? '') : '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _dayName(day, lang),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: isOpen
                              ? Text(
                                  '$open – $close',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: PatientAppColors.brandTeal,
                                  ),
                                )
                              : Text(
                                  'pharmacy_closed'.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ─── Utility widgets ──────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  const _ModernCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PatientAppColors.brandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: PatientAppColors.brandTeal, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: PatientAppColors.brandTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
