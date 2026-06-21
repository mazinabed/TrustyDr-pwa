import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/doctor_streams_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/core/utils/doctor_search_utils.dart';
import 'package:trustydr/pages/doctor/doctor_profile_v2.dart';
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

    final specialtiesAsync = ref.watch(specialtiesStreamProvider);
    final labDocs = specialtiesAsync.when(
      data: (snap) => snap.docs.where((d) {
        final sg = (d.data()['serviceGroup'] ?? '').toString();
        return sg == 'laboratory' || sg == 'imaging';
      }).toList(),
      loading: () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      error: (_, __) => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
    );
    final labIds = labDocs.map((d) => d.id).toSet();

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
                            child: _providerList(labIds),
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

  // --------------------------------------------------
  // Search Bar
  // --------------------------------------------------
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

  // --------------------------------------------------
  // Specialty Bar — lab/imaging specialties only
  // --------------------------------------------------
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

  // --------------------------------------------------
  // Provider List — filtered to lab/imaging only
  // --------------------------------------------------
  Widget _providerList(Set<String> labIds) {
    final doctorsAsync = ref.watch(doctorsStreamProvider);

    return doctorsAsync.when(
      data: (docs) {
        final filtered = docs.where((doc) {
          final d = doc.data();

          // 1. Must belong to a lab/imaging specialty
          final specKey =
              (d['specialty_key'] ?? d['specialtyKey'] ?? '').toString();
          final specLower = (d['specialty_lower'] ?? '').toString();

          final bool isLabProvider;
          if (labIds.isEmpty) {
            isLabProvider = false;
          } else if (specKey.isNotEmpty) {
            isLabProvider = labIds.contains(specKey);
          } else {
            // Fallback: specialty_lower matched against lab doc IDs
            isLabProvider = labIds.contains(specLower);
          }
          if (!isLabProvider) return false;

          // 2. If a specific lab specialty chip is selected, narrow to it
          if (_selectedLabKey.isNotEmpty) {
            if (specKey.isNotEmpty) {
              if (specKey != _selectedLabKey) return false;
            } else {
              if (specLower != _selectedLabKey) return false;
            }
          }

          // 3. Search filter
          if (_searchQuery.isNotEmpty) {
            final stripped = stripDoctorTitles(_searchQuery);
            if (stripped.length >= 3) {
              final q = stripped.toLowerCase();
              final nameMatch = (d['name_en'] ?? d['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (d['name_ar'] ?? '').toString().toLowerCase().contains(q) ||
                  (d['name_ku'] ?? '').toString().toLowerCase().contains(q);
              final clinicMatch = (d['clinicName_en'] ?? d['clinicName'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (d['clinicName_ar'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (d['clinicName_ku'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q);
              if (!nameMatch && !clinicMatch) return false;
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
            final lang = context.locale.languageCode;

            final nameEn = (d['name_en'] ?? '').toString();
            final nameAr = (d['name_ar'] ?? nameEn).toString();
            final nameKu = (d['name_ku'] ?? nameEn).toString();
            final name = lang == 'ar'
                ? nameAr
                : lang == 'ku'
                    ? nameKu
                    : nameEn;

            final specialtyEn =
                (d['specialty_en'] ?? d['specialtyName_en'] ?? '').toString();
            final specialtyAr =
                (d['specialty_ar'] ?? d['specialtyName_ar'] ?? specialtyEn)
                    .toString();
            final specialtyKu =
                (d['specialty_ku'] ?? d['specialtyName_ku'] ?? specialtyEn)
                    .toString();
            final specialty = lang == 'ar'
                ? specialtyAr
                : lang == 'ku'
                    ? specialtyKu
                    : specialtyEn;

            final rawExp = d['experienceYears'] ?? d['yearsOfExperience'];
            final exp = (rawExp is num && rawExp.toInt() > 0)
                ? rawExp.toInt().toString()
                : '';

            final rating = (d['ratingAverage'] is num)
                ? (d['ratingAverage'] as num).toDouble()
                : 0.0;
            final reviews = (d['ratingCount'] ?? 0).toInt();
            final clinic = d['clinicName'] ?? d['address'] ?? d['city'] ?? '';
            final isVerified = d['verified'] == true || d['isVerified'] == true;

            String imageUrl = 'assets/user/placeholder_user.png';
            try {
              final photos = d['photos'];
              if (photos is List && photos.isNotEmpty) {
                final first = photos.first?.toString().trim();
                if (first != null && first.startsWith('http')) {
                  imageUrl = first;
                }
              } else if (d['imageUrl'] != null &&
                  d['imageUrl'].toString().trim().startsWith('http')) {
                imageUrl = d['imageUrl'].toString().trim();
              }
            } catch (_) {}

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 400),
                    child: DoctorProfileV2(doctorId: id),
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
                                    'doctor_prefix_name'.tr(args: [name]),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? PatientAppColors.brandBlue
                                            .withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isVerified
                                        ? tr('verified')
                                        : tr('not_registered'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isVerified
                                          ? PatientAppColors.brandBlue
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: const TextStyle(
                                color: PatientAppColors.brandTeal,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (exp.isNotEmpty)
                              Text(
                                '$exp ${tr('years_experience')}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            if (clinic.toString().isNotEmpty)
                              Text(
                                clinic.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '($reviews ${tr('reviews')})',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
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
}
