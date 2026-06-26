import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/diagnostic_provider_streams_provider.dart';
import 'package:trustydr/core/providers/doctor_streams_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/lab/diagnostic_provider_profile_page.dart';
import 'package:trustydr/widget/doctor_avatar.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class LaboratoriesScreen extends ConsumerStatefulWidget {
  const LaboratoriesScreen({super.key});

  @override
  ConsumerState<LaboratoriesScreen> createState() => _LaboratoriesScreenState();
}

class _LaboratoriesScreenState extends ConsumerState<LaboratoriesScreen> {
  Timer? _searchDebounce;

  // Value is a specialty doc ID. The chip's serviceGroup is used to derive
  // the providerKind filter; '' = show all.
  String _selectedLabKey = '';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(appLocationProvider);

    // Specialty chips — same source as before, filtered to lab/imaging groups.
    final specialtiesAsync = ref.watch(specialtiesStreamProvider);
    final labDocs = specialtiesAsync.when(
      data: (snap) => snap.docs.where((d) {
        final sg = (d.data()['serviceGroup'] ?? '').toString();
        return sg == 'laboratory' || sg == 'imaging';
      }).toList(),
      loading: () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      error: (_, __) => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'labs'.tr(),
                showBack: true,
                height: 160,
              ),
              const SizedBox(height: 12),
              _searchBar(),
              const SizedBox(height: 10),
              _specialtyBar(labDocs),
              const SizedBox(height: 8),
              Expanded(
                child: location == null ||
                        location.cityEn.isEmpty ||
                        location.provinceKey.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'select_city_first'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        key: const PageStorageKey('labs_scroll'),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _providerList(labDocs),
                          ),
                        ],
                      ),
              ),
            ],
          );
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }

  // ── Search bar ───────────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (val) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(
              const Duration(milliseconds: 350),
              () => setState(() => _searchQuery = val),
            );
          },
          decoration: InputDecoration(
            hintText: 'search_doctor_or_clinic'.tr(),
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ── Specialty chip bar ───────────────────────────────────────────────────────

  Widget _specialtyBar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> labDocs,
  ) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _specialtyChip(name: 'all_labs'.tr(), value: ''),
          ...labDocs.map(
            (doc) => _specialtyChip(
              name: _displaySpecialtyName(doc.data()),
              value: doc.id,
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialtyChip({required String name, required String value}) {
    final active = _selectedLabKey == value;
    final location = ref.read(appLocationProvider);

    return GestureDetector(
      onTap: () {
        if (location == null) return;
        setState(() => _selectedLabKey = value);
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: active ? PatientAppColors.reverseBrandGradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _displaySpecialtyName(Map<String, dynamic> data) {
    final lang = context.locale.languageCode;
    final langMap = (data['lang'] ?? {}) as Map<String, dynamic>?;

    if (lang == 'ar' && (langMap?['ar'] ?? '').toString().isNotEmpty) {
      return langMap!['ar'];
    }
    if (lang == 'ku' && (langMap?['ku'] ?? '').toString().isNotEmpty) {
      return langMap!['ku'];
    }
    return (data['name_en'] ?? '').toString();
  }

  // ── Provider list ────────────────────────────────────────────────────────────
  // Reads from public_diagnostic_providers via diagnosticProvidersStreamProvider.
  // The specialty chip filter maps the selected chip's serviceGroup to providerKind.

  Widget _providerList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> labDocs,
  ) {
    // Map: specialty doc ID → serviceGroup ('laboratory' | 'imaging')
    final specGroupMap = {
      for (final doc in labDocs)
        doc.id: (doc.data()['serviceGroup'] ?? '').toString(),
    };

    final providersAsync = ref.watch(diagnosticProvidersStreamProvider);

    return providersAsync.when(
      data: (docs) {
        final lang = context.locale.languageCode;

        final filtered = docs.where((doc) {
          final d = doc.data();

          // 1. If a category chip is selected, filter by providerKind.
          if (_selectedLabKey.isNotEmpty) {
            final selectedGroup = specGroupMap[_selectedLabKey] ?? '';
            if (selectedGroup.isNotEmpty) {
              final kind =
                  (d['providerKind'] ?? d['serviceGroup'] ?? '').toString();
              if (kind != selectedGroup) return false;
            }
          }

          // 2. Text search against facility name fields.
          if (_searchQuery.isNotEmpty && _searchQuery.length >= 3) {
            final q = _searchQuery.toLowerCase();
            final nameEn =
                (d['facilityName_en'] ?? '').toString().toLowerCase();
            final nameAr =
                (d['facilityName_ar'] ?? '').toString().toLowerCase();
            final nameKu =
                (d['facilityName_ku'] ?? '').toString().toLowerCase();
            final addr = (d['facilityAddress'] ?? '').toString().toLowerCase();
            if (!nameEn.contains(q) &&
                !nameAr.contains(q) &&
                !nameKu.contains(q) &&
                !addr.contains(q)) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'no_labs_found'.tr(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: List.generate(filtered.length, (i) {
            final doc = filtered[i];
            final d = doc.data();
            final id = doc.id;

            final facilityName = lang == 'ar'
                ? (d['facilityName_ar']?.toString().isNotEmpty == true
                    ? d['facilityName_ar']
                    : d['facilityName_en'] ?? '')
                : lang == 'ku'
                    ? (d['facilityName_ku']?.toString().isNotEmpty == true
                        ? d['facilityName_ku']
                        : d['facilityName_en'] ?? '')
                    : (d['facilityName_en'] ?? '');

            final specialtyEn = (d['specialty_en'] ?? '').toString();
            final specialtyAr = (d['specialty_ar'] ?? specialtyEn).toString();
            final specialtyKu = (d['specialty_ku'] ?? specialtyEn).toString();
            final specialty = lang == 'ar'
                ? specialtyAr
                : lang == 'ku'
                    ? specialtyKu
                    : specialtyEn;

            final address = (d['facilityAddress'] ?? '').toString();
            final serviceCount = (d['serviceCount'] ?? 0) as int;
            final providerKind = (d['providerKind'] ?? 'laboratory').toString();

            String imageUrl = 'assets/user/placeholder_user.png';
            final raw = d['imageUrl']?.toString().trim() ?? '';
            if (raw.startsWith('http')) imageUrl = raw;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 400),
                    child: DiagnosticProviderProfilePage(providerId: id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      DoctorAvatar(imageUrl: imageUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    facilityName.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Provider kind badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: providerKind == 'imaging'
                                        ? const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.12)
                                        : PatientAppColors.brandTeal
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _kindLabel(providerKind, lang),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: providerKind == 'imaging'
                                          ? const Color(0xFF7C3AED)
                                          : PatientAppColors.brandTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (specialty.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                specialty,
                                style: const TextStyle(
                                  color: PatientAppColors.brandTeal,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (serviceCount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '$serviceCount ${'services_available'.tr()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(color: PatientAppColors.brandTeal),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'error_generic'.tr(),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  String _kindLabel(String kind, String lang) {
    if (kind == 'imaging') {
      if (lang == 'ar') return 'تصوير طبي';
      if (lang == 'ku') return 'وێنەکێشانی پزیشکی';
      return 'Imaging';
    }
    if (lang == 'ar') return 'مختبر';
    if (lang == 'ku') return 'تاقیگە';
    return 'Lab';
  }
}
