import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/pharmacy_providers_stream_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/pharmacy/pharmacy_provider_profile_page.dart';
import 'package:trustydr/widget/doctor_avatar.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class PharmaciesScreen extends ConsumerStatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  ConsumerState<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends ConsumerState<PharmaciesScreen> {
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(appLocationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'pharmacies'.tr(),
                showBack: true,
                height: 160,
              ),
              const SizedBox(height: 12),
              _searchBar(),
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
                        key: const PageStorageKey('pharmacies_scroll'),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _providerList(),
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

  Widget _providerList() {
    final providersAsync = ref.watch(pharmacyProvidersStreamProvider);

    return providersAsync.when(
      data: (docs) {
        final lang = context.locale.languageCode;

        final filtered = docs.where((doc) {
          final d = doc.data();
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
                'no_pharmacies_found'.tr(),
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

            final address = (d['facilityAddress'] ?? '').toString();

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
                    child: PharmacyProviderProfilePage(providerId: id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14, left: 16, right: 16),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PatientAppColors.brandTeal
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'pharmacy'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: PatientAppColors.brandTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.black26,
                        size: 20,
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
