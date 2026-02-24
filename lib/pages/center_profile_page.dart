import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/pages/doctor/doctor_profile_v2.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';

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
      .collection('doctors')
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

                  if (imageUrl != null)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  if (address != null &&
                      address.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16,
                              color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
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
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: doctorsStream,
                builder: (context, docSnap) {
                  if (!docSnap.hasData) {
                    return const Center(
                        child:
                            CircularProgressIndicator());
                  }

                  final docs = docSnap.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        tr('centers.no_doctors'),
                        style: const TextStyle(
                            color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final doctor =
                          docs[i].data();
                      final doctorId =
                          docs[i].id;

                      final doctorName =
                          lang == 'ar'
                              ? (doctor[
                                          'name_ar'] ??
                                      doctor[
                                          'name'])
                              : lang == 'ku'
                                  ? (doctor[
                                              'name_ku'] ??
                                          doctor[
                                              'name'])
                                  : (doctor[
                                              'name_en'] ??
                                          doctor[
                                              'name']);

                      final specialty =
                          lang == 'ar'
                              ? (doctor[
                                          'specialty_ar'] ??
                                      '')
                              : lang == 'ku'
                                  ? (doctor[
                                              'specialty_ku'] ??
                                          '')
                                  : (doctor[
                                              'specialty_en'] ??
                                          '');

                      final image =
                          doctor['imageUrl'];

                      return Card(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(16),
                        ),
                        margin:
                            const EdgeInsets
                                .only(
                                    bottom:
                                        12),
                        child: ListTile(
                          leading:
                              CircleAvatar(
                            backgroundImage:
                                image !=
                                        null
                                    ? NetworkImage(
                                        image)
                                    : null,
                            child: image ==
                                    null
                                ? Text(
                                    doctorName
                                            ?.toString()
                                            .isNotEmpty ==
                                        true
                                        ? doctorName![
                                            0]
                                        : '?',
                                  )
                                : null,
                          ),
                          title:
                              Text(doctorName ??
                                  ''),
                          subtitle:
                              specialty
                                          ?.toString()
                                          .isNotEmpty ==
                                      true
                                  ? Text(
                                      specialty)
                                  : null,
                          trailing:
                              const Icon(
                            Icons
                                .arrow_forward_ios,
                            size: 14,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DoctorProfileV2(
                                        doctorId:
                                            doctorId),
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