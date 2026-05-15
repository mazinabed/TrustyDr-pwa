import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/centers_provider.dart';
import 'package:trustydr/pages/center_profile_page.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';

class CentersScreen extends ConsumerStatefulWidget {
  final bool showBack;

  const CentersScreen({
    super.key,
    this.showBack = true,
  });

  @override
  ConsumerState<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends ConsumerState<CentersScreen> {
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
    final centersAsync = ref.watch(centersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          TrustyDrCurvedHeader(
            title: 'medical_centers'.tr(),
            showBack: widget.showBack,
            height: 160,
          ),
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 8),
          Expanded(
            child: location == null || location.cityEn == null
                ? _buildSelectCityFirst()
                : centersAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.teal)),
                    error: (e, _) => Center(child: Text(e.toString())),
                    data: (snapshot) {
                      final filtered = snapshot.docs.where((doc) {
                        if (_searchQuery.isEmpty) return true;

                        final data = doc.data();
                        final name = _localizedCenterName(context, data);

                        return name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'centers.empty'.tr(),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _buildCenterCard(context, filtered[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Select City First
  // --------------------------------------------------
  Widget _buildSelectCityFirst() {
    return Center(
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
    );
  }

  // --------------------------------------------------
  // Search Bar
  // --------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
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
            hintText: 'search_center'.tr(),
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Center Card
  // --------------------------------------------------
  Widget _buildCenterCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = _localizedCenterName(context, data);
    final doctorCount = data['doctorCount'] ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CenterProfilePage(
                centerId: doc.id,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_hospital, size: 36, color: Colors.teal),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$doctorCount ${'centers.doctors'.tr()}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Localized Name
  // --------------------------------------------------
  String _localizedCenterName(BuildContext context, Map<String, dynamic> data) {
    final lang = context.locale.languageCode;

    if (lang == 'ar') {
      return (data['clinicName_ar'] ?? data['clinicName'] ?? '').toString();
    }

    if (lang == 'ku') {
      return (data['clinicName_ku'] ?? data['clinicName'] ?? '').toString();
    }

    return (data['clinicName_en'] ?? data['clinicName'] ?? '').toString();
  }
}
