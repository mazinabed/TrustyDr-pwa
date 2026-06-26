import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/doctor_streams_provider.dart';
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
  String? _selectedServiceKey;
  String _selectedServiceNameEn = '';
  String _selectedServiceNameAr = '';
  String _selectedServiceNameKu = '';

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

  String _specialtyDisplayName(Map<String, dynamic> data, String lang) {
    final langMap = (data['lang'] ?? {}) as Map<String, dynamic>?;
    if (lang == 'ar' && (langMap?['ar'] ?? '').toString().isNotEmpty) {
      return langMap!['ar'];
    }
    if (lang == 'ku' && (langMap?['ku'] ?? '').toString().isNotEmpty) {
      return langMap!['ku'];
    }
    return (data['name_en'] ?? '').toString();
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

    // Service category chips — filtered from specialties by provider's serviceGroup
    final specialtiesAsync = ref.watch(specialtiesStreamProvider);
    final serviceChips = specialtiesAsync.when(
      data: (snap) => snap.docs.where((doc) {
        final sg = (doc.data()['serviceGroup'] ?? '').toString();
        return sg == serviceGroup;
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );

    final canBook = _selectedServiceKey != null && centerId.isNotEmpty;

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

        // ── Phone action button ───────────────────────────────────────────────
        if (phone.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    iconWidget: const Icon(
                      Icons.call,
                      color: PatientAppColors.statusConfirmed,
                    ),
                    label: 'call_now'.tr(),
                    color: PatientAppColors.statusConfirmed,
                    onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  ),
                ],
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
                // Service category picker
                if (serviceChips.isNotEmpty) ...[
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
                    children: serviceChips.map((doc) {
                      final docData = doc.data();
                      final displayName = _specialtyDisplayName(docData, lang);
                      final isSelected = _selectedServiceKey == doc.id;
                      return GestureDetector(
                        onTap: () {
                          final langMap =
                              (docData['lang'] ?? {}) as Map<String, dynamic>?;
                          setState(() {
                            _selectedServiceKey = doc.id;
                            _selectedServiceNameEn =
                                (docData['name_en'] ?? '').toString();
                            _selectedServiceNameAr =
                                (langMap?['ar'] ?? '').toString();
                            _selectedServiceNameKu =
                                (langMap?['ku'] ?? '').toString();
                          });
                        },
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
                                  .withValues(alpha: isSelected ? 1 : 0.3),
                            ),
                          ),
                          child: Text(
                            displayName,
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

                ElevatedButton.icon(
                  onPressed: canBook
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LabTimeSlotPage(
                                labId:
                                    widget.data['providerId']?.toString() ?? '',
                                centerId: centerId,
                                facilityName: facilityName,
                                imageUrl: imageUrl,
                                serviceGroup: serviceGroup,
                                specialtyId: _selectedServiceKey!,
                                serviceNameEn: _selectedServiceNameEn,
                                serviceNameAr: _selectedServiceNameAr,
                                serviceNameKu: _selectedServiceNameKu,
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

                if (!canBook && serviceChips.isEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'coming_soon'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],

                if (!canBook &&
                    serviceChips.isNotEmpty &&
                    _selectedServiceKey == null) ...[
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconWidget,
    required this.label,
    required this.color,
    this.onTap,
  });

  final Widget iconWidget;
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
            child: iconWidget,
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
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
