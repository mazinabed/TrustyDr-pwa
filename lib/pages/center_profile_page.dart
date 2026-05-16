import 'dart:ui' as ui show TextDirection;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/pages/doctor/doctor_profile_v2.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:url_launcher/url_launcher.dart';

class CenterProfilePage extends ConsumerWidget {
  final String centerId;

  const CenterProfilePage({
    super.key,
    required this.centerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centerStream = FirebaseFirestore.instance
        .collection('medical_centers')
        .doc(centerId)
        .snapshots();

    final doctorsStream = FirebaseFirestore.instance
        .collection('public_doctors')
        .where('centerId', isEqualTo: centerId)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: centerStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(child: Text("Center not found"));
          }
          final phone = data['phone'] ?? '';

          final lang = context.locale.languageCode;

          final name = lang == 'ar'
              ? (data['clinicName_ar'] ?? data['clinicName'])
              : lang == 'ku'
                  ? (data['clinicName_ku'] ?? data['clinicName'])
                  : (data['clinicName_en'] ?? data['clinicName']);

          final address = lang == 'ar'
              ? (data['clinicAddress_ar'] ?? '')
              : lang == 'ku'
                  ? (data['clinicAddress_ku'] ?? '')
                  : (data['clinicAddress_en'] ?? '');

          final imageUrl = data['imageUrl'];

          String formatIraqiPhone(String phone) {
            if (phone.isEmpty) return '';

            String p = phone.replaceAll(' ', '');

            // Convert +964XXXXXXXXX → 0XXXXXXXXX
            if (p.startsWith('+964')) {
              p = '0${p.substring(4)}';
            }

            // Convert 964XXXXXXXXX → 0XXXXXXXXX
            if (p.startsWith('964')) {
              p = '0${p.substring(3)}';
            }

            // Format spacing
            if (p.length == 11) {
              return "${p.substring(0, 4)} ${p.substring(4, 7)} ${p.substring(7)}";
            }

            return p;
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    TrustyDrCurvedHeader(
                      title: name ?? '',
                      showBack: true,
                      height: 140,
                    ),

                    const SizedBox(height: 12),

                    /// CENTER CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// IMAGE (FULL WIDTH)
                            if (imageUrl != null &&
                                imageUrl.toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18)),
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),

                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// CENTER NAME
                                  Text(
                                    name ?? '',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  /// ADDRESS + PHONE + DOCTORS
                                  Column(
                                    children: [
                                      /// ADDRESS
                                      if (address.toString().isNotEmpty)
                                        Row(
                                          children: [
                                            const SizedBox(width: 2),
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.teal,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                address.toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 6),

                                      /// PHONE
                                      Row(
                                        children: [
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 8),
                                          Directionality(
                                            textDirection: ui.TextDirection.ltr,
                                            child: Text(
                                              formatIraqiPhone(
                                                  phone.toString()),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.teal,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      /// DOCTOR COUNT
                                      Row(
                                        children: [
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.people_outline,
                                            size: 16,
                                            color: Colors.black45,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "${data['doctorCount'] ?? 0} ${tr('centers.doctors')}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    tr('centers.doctors'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: 8),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: doctorsStream,
                  builder: (context, docSnap) {
                    if (!docSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = docSnap.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          tr('centers.no_doctors'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doctor = docs[i].data();
                        final doctorId = docs[i].id;

                        final doctorName = lang == 'ar'
                            ? (doctor['name_ar'] ?? doctor['name'])
                            : lang == 'ku'
                                ? (doctor['name_ku'] ?? doctor['name'])
                                : (doctor['name_en'] ?? doctor['name']);

                        final specialty = lang == 'ar'
                            ? (doctor['specialty_ar'] ?? '')
                            : lang == 'ku'
                                ? (doctor['specialty_ku'] ?? '')
                                : (doctor['specialty_en'] ?? '');

                        final image = doctor['imageUrl'];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  image != null ? NetworkImage(image) : null,
                              child: image == null
                                  ? Text(
                                      doctorName?.toString().isNotEmpty == true
                                          ? doctorName![0]
                                          : '?',
                                    )
                                  : null,
                            ),
                            title: Text(doctorName ?? ''),
                            subtitle: specialty?.toString().isNotEmpty == true
                                ? Text(specialty)
                                : null,
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DoctorProfileV2(doctorId: doctorId),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
