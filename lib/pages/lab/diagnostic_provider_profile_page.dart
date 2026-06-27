import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trustydr/core/providers/provider_catalog_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/lab/lab_time_slot_page.dart';
import 'package:trustydr/widget/doctor_avatar.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public profile page for a lab or imaging provider.
/// Reads from [public_diagnostic_providers/{providerId}] — a safe, sanitized
/// projection. Booking navigates to [LabTimeSlotPage].
class DiagnosticProviderProfilePage extends ConsumerWidget {
  const DiagnosticProviderProfilePage({super.key, required this.providerId});

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
                .collection('public_diagnostic_providers')
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
              return _ProfileBody(data: d);
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

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.data});

  final Map<String, dynamic> data;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  ProviderCatalogService? _selectedService;

  String _loc(Map<String, dynamic> d, String prefix, String lang) {
    if (lang == 'ar') {
      final v = d['${prefix}_ar']?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    if (lang == 'ku') {
      final v = d['${prefix}_ku']?.toString() ?? '';
      if (v.isNotEmpty) return v;
    }
    return d['${prefix}_en']?.toString() ?? d[prefix]?.toString() ?? '';
  }

  String _kindLabel(String kind, String lang) {
    if (kind == 'imaging') {
      if (lang == 'ar') return 'تصوير طبي';
      if (lang == 'ku') return 'وێنەکێشانی پزیشکی';
      return 'Medical Imaging';
    }
    if (lang == 'ar') return 'مختبر طبي';
    if (lang == 'ku') return 'تاقیگەی پزیشکی';
    return 'Clinical Laboratory';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final lang = context.locale.languageCode;

    final facilityName = _loc(d, 'facilityName', lang);
    final specialtyLabel = _loc(d, 'specialty', lang);
    final address = (d['facilityAddress'] ?? '').toString();
    final city = _loc(d, 'city', lang);
    final province = _loc(d, 'province', lang);
    final providerKind = (d['providerKind'] ?? 'laboratory').toString();
    final serviceGroup = (d['serviceGroup'] ?? providerKind).toString();
    final serviceCount = (d['serviceCount'] ?? 0) as int;
    final phone = d['phone']?.toString() ?? '';
    final imageUrl = d['imageUrl']?.toString() ?? '';
    final centerId = (d['centerId'] ?? '').toString();

    final locationParts = [city, province].where((s) => s.isNotEmpty).toList();
    final locationLine = locationParts.join(', ');

    // Provider service catalog — reads diagnostic_providers/{id}/services
    // filtered to isActive + onlineBookingEnabled + not archived.
    final providerId = (widget.data['providerId'] ?? '').toString();
    final catalogAsync = ref.watch(providerCatalogProvider(providerId));

    final canBook = _selectedService != null && centerId.isNotEmpty;

    // ── Contact / social row items ─────────────────────────────────────────────
    final showSocial = d['showSocialLinks'] == true;
    final rawSocial = d['socialLinks'];
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

    return CustomScrollView(
      slivers: [
        // ── Header ───────────────────────────────────────────────────────────
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
                    if (specialtyLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        specialtyLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderBadge(
                          label: _kindLabel(providerKind, lang),
                          icon: providerKind == 'imaging'
                              ? Icons.image_search_rounded
                              : Icons.biotech_rounded,
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

        // ── Quick contact / social row (call + social platforms) ─────────────
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

        // ── Provider info card ────────────────────────────────────────────────
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

        // ── Services card ─────────────────────────────────────────────────────
        if (serviceCount > 0)
          SliverToBoxAdapter(
            child: _ModernCard(
              title: 'services_available'.tr(),
              icon: Icons.medical_services_rounded,
              child: Text(
                '$serviceCount',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: PatientAppColors.brandTeal,
                ),
              ),
            ),
          ),

        // ── Booking CTA card ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ModernCard(
            title: 'book_appointment'.tr(),
            icon: Icons.calendar_month_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service picker — loaded from provider catalog
                catalogAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: PatientAppColors.brandTeal),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (services) {
                    if (services.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'lab_booking.no_online_services'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'lab_booking.select_service'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: services.map((svc) {
                            final isSelected = _selectedService?.id == svc.id;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedService = svc),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? PatientAppColors.brandTeal
                                      : PatientAppColors.brandTeal
                                          .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: PatientAppColors.brandTeal
                                        .withValues(
                                            alpha: isSelected ? 1 : 0.3),
                                  ),
                                ),
                                child: Text(
                                  svc.name(lang),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : PatientAppColors.brandTeal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                ElevatedButton.icon(
                  onPressed: canBook
                      ? () {
                          final svc = _selectedService!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LabTimeSlotPage(
                                labId: providerId,
                                centerId: centerId,
                                facilityName: facilityName,
                                imageUrl: imageUrl,
                                serviceGroup: serviceGroup,
                                specialtyId: svc.id,
                                serviceNameEn: svc.nameEn,
                                serviceNameAr: svc.nameAr,
                                serviceNameKu: svc.nameKu,
                                serviceId: svc.id,
                                subcategory: svc.subcategory,
                                estimatedDurationMinutes:
                                    svc.estimatedDurationMinutes,
                                price: svc.price,
                                providerNameEn:
                                    widget.data['facilityName_en']
                                            ?.toString() ??
                                        facilityName,
                                providerNameAr:
                                    widget.data['facilityName_ar']
                                            ?.toString() ??
                                        facilityName,
                                providerNameKu:
                                    widget.data['facilityName_ku']
                                            ?.toString() ??
                                        facilityName,
                                providerAddress:
                                    (widget.data['facilityAddress'] ?? '')
                                        .toString(),
                                providerImage: imageUrl,
                                providerPhone: phone,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text('book_appointment'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: PatientAppColors.brandTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        PatientAppColors.brandTeal.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (!canBook &&
                    (catalogAsync.asData?.value.isNotEmpty ?? false) &&
                    _selectedService == null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'lab_booking.select_service_hint'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ],
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
