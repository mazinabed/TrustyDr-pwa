import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/widgets/doctor_reviews_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorProfileV2 extends StatelessWidget {
  final String doctorId;

  const DoctorProfileV2({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final doctorRef =
        FirebaseFirestore.instance.collection('public_doctors').doc(doctorId);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doctorRef.snapshots(),
        builder: (context, doctorSnap) {
          if (!doctorSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final doctorData = doctorSnap.data!.data();
          if (doctorData == null) {
            return Center(child: Text('doctor_not_found'.tr()));
          }

          return _DoctorProfileBody(
            doctorId: doctorId,
            doctorData: doctorData,
          );
        },
      ),
    );
  }
}

class _DoctorProfileBody extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const _DoctorProfileBody({
    required this.doctorId,
    required this.doctorData,
  });

  @override
  Widget build(BuildContext context) {
    final schedulesQuery = FirebaseFirestore.instance
        .collection('schedules')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'published')
        .where('isActive', isEqualTo: true);

    return StreamBuilder<QuerySnapshot>(
      stream: schedulesQuery.snapshots(),
      builder: (context, scheduleSnap) {
        final schedules = scheduleSnap.data?.docs ?? [];

        final hasSchedule = schedules.isNotEmpty;

        final centerIds = schedules
            .map((doc) => (doc['centerId'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final limitedCenterIds = centerIds.take(10).toList();
        return FutureBuilder<QuerySnapshot?>(
          future: centerIds.isEmpty
              ? null
              : FirebaseFirestore.instance
                  .collection('medical_centers')
                  .where(FieldPath.documentId, whereIn: limitedCenterIds)
                  .get(),
          builder: (context, centerSnap) {
            final centers = centerSnap.data?.docs ?? [];

            return _DoctorProfileView(
              doctorId: doctorId,
              doctorData: doctorData,
              schedules: schedules,
              centers: centers,
              hasSchedule: hasSchedule,
            );
          },
        );
      },
    );
  }
}

class _DoctorProfileView extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;
  final List<QueryDocumentSnapshot> schedules;
  final List<QueryDocumentSnapshot> centers;
  final bool hasSchedule;

  const _DoctorProfileView({
    required this.doctorId,
    required this.doctorData,
    required this.schedules,
    required this.centers,
    required this.hasSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    final lang = context.locale.languageCode;
    final specialtyKey =
        (doctorData['specialtyKey'] ?? doctorData['specialty_key'] ?? '')
            .toString()
            .trim();
    // ================= DOCTOR DATA =================

    final nameEn = (doctorData['name_en'] ?? '').toString();

    final nameAr = (doctorData['name_ar'] ?? nameEn).toString();

    final nameKu = (doctorData['name_ku'] ?? nameEn).toString();

    final name = lang == 'ar'
        ? nameAr
        : lang == 'ku'
            ? nameKu
            : nameEn;

    String about;

    if (lang == 'ar') {
      about = (doctorData['bio_ar'] ??
              doctorData['about_ar'] ??
              doctorData['bio_en'] ??
              doctorData['about_en'] ??
              doctorData['about'] ??
              '')
          .toString();
    } else if (lang == 'ku') {
      about = (doctorData['bio_ku'] ??
              doctorData['about_ku'] ??
              doctorData['bio_en'] ??
              doctorData['about_en'] ??
              doctorData['about'] ??
              '')
          .toString();
    } else {
      about = (doctorData['bio_en'] ??
              doctorData['about_en'] ??
              doctorData['about'] ??
              '')
          .toString();
    }

    final exp =
        (doctorData['yearsOfExperience'] ?? doctorData['experienceYears'])
                ?.toString() ??
            'N/A';

    final specialtyLegacy = (doctorData['specialty'] ?? '').toString();

    final specialtyEn =
        (doctorData['specialty_en'] ?? specialtyLegacy).toString();
    final specialtyAr = (doctorData['specialty_ar'] ?? specialtyEn).toString();
    final specialtyKu = (doctorData['specialty_ku'] ?? specialtyEn).toString();

    final specialtyShown = lang == 'ar'
        ? specialtyAr
        : lang == 'ku'
            ? specialtyKu
            : specialtyEn;

    final phone = (doctorData['phone'] ?? '').toString();
    final languages = List<String>.from(doctorData['languages'] ?? []);

    final isVerified =
        doctorData['verified'] == true || doctorData['isVerified'] == true;
    final canBook = doctorData['canBook'] == true;

    final rating = (doctorData['ratingAverage'] is num)
        ? (doctorData['ratingAverage'] as num).toDouble()
        : 0.0;
    final reviews = (doctorData['ratingCount'] ?? 0).toInt();

    String imageUrl = '';
    if (doctorData['photos'] is List &&
        (doctorData['photos'] as List).isNotEmpty) {
      imageUrl = (doctorData['photos'] as List).first.toString();
    } else if (doctorData['imageUrl'] != null) {
      imageUrl = doctorData['imageUrl'].toString();
    }

    SliverAppBar _buildHeader(
      BuildContext context,
      String name,
      String specialty,
      double rating,
      int reviews,
      String imageUrl,
    ) {
      return SliverAppBar(
        expandedHeight: 260,
        pinned: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/icons/stethoscope.png',
                            width: 60,
                            height: 60,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'doctor_prefix_name'.tr(args: [name]),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  specialty,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      " ($reviews ${'reviews'.tr()})",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    Widget _action({
      required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    SliverToBoxAdapter _buildActions(BuildContext context, String phone) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(
                icon: Icons.call,
                label: 'call_now'.tr(),
                color: Colors.green,
                onTap: phone.isNotEmpty
                    ? () => launchUrl(Uri.parse('tel:$phone'))
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    Widget _modernCard({
      required String title,
      required Widget child,
      IconData? icon,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
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
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.teal, size: 18),
                  ),
                if (icon != null) const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

    Widget _info(String title, String value) {
      if (value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value, style: greyNormalTextStyle),
          ],
        ),
      );
    }

    SliverToBoxAdapter _buildBookingCard(
      BuildContext context,
      User? user,
      String doctorName,
      String imageUrl,
      String exp,
      String specialtyKey,
      String specialtyEn,
      String specialtyAr,
      String specialtyKu,
      List<QueryDocumentSnapshot> schedules,
      List<QueryDocumentSnapshot> centers,
    ) {
      return SliverToBoxAdapter(
        child: _modernCard(
          title: 'book_appointment'.tr(),
          icon: Icons.calendar_month,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'book_appointment_hint'.tr(),
                style: greyNormalTextStyle,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: user == null
                    ? () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const LoginScreen(),
                          ),
                        );
                      }
                    : () {
                        if (schedules.isEmpty) return;

                        if (centers.length == 1) {
                          final centerDoc = centers.first;
                          final center =
                              centerDoc.data() as Map<String, dynamic>;

                          // SAFE schedule match
                          final matchingSchedules = schedules
                              .where((s) => s['centerId'] == centerDoc.id)
                              .toList();

                          if (matchingSchedules.isEmpty) {
                            return; // no schedule for this center
                          }

                          final schedule = matchingSchedules.first;

                          final lang = context.locale.languageCode;

                          String clinicName;
                          if (lang == 'ar') {
                            clinicName = (center['clinicName_ar'] ??
                                    center['clinicName_en'] ??
                                    '')
                                .toString();
                          } else if (lang == 'ku') {
                            clinicName = (center['clinicName_ku'] ??
                                    center['clinicName_en'] ??
                                    '')
                                .toString();
                          } else {
                            clinicName =
                                (center['clinicName_en'] ?? '').toString();
                          }

                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: DoctorTimeSlot(
                                doctorId: doctorId,
                                doctorName: doctorName,
                                doctorImage: imageUrl,
                                specialtyKey: specialtyKey,
                                specialtyEn: specialtyEn,
                                specialtyAr: specialtyAr,
                                specialtyKu: specialtyKu,
                                experience: exp,
                                centerId: centerDoc.id,
                                provinceKey: schedule['provinceKey'] ?? '',
                                cityKey: schedule['cityKey'] ?? '',
                                clinicName: clinicName,
                              ),
                            ),
                          );
                        } else {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (sheetCtx) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 20, 20, 8),
                                      child: Text(
                                        'select_center_to_book'.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ...centers.map((centerDoc) {
                                      final c = centerDoc.data()
                                          as Map<String, dynamic>;
                                      final matching = schedules
                                          .where((s) =>
                                              s['centerId'] == centerDoc.id)
                                          .toList();
                                      if (matching.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      final schedule = matching.first;
                                      final String cn = lang == 'ar'
                                          ? (c['clinicName_ar'] ??
                                                  c['clinicName_en'] ??
                                                  '')
                                              .toString()
                                          : lang == 'ku'
                                              ? (c['clinicName_ku'] ??
                                                      c['clinicName_en'] ??
                                                      '')
                                                  .toString()
                                              : (c['clinicName_en'] ?? '')
                                                  .toString();
                                      return ListTile(
                                        leading: const Icon(
                                            Icons.local_hospital,
                                            color: Colors.teal),
                                        title: Text(cn),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14),
                                        onTap: () {
                                          Navigator.pop(sheetCtx);
                                          Navigator.push(
                                            context,
                                            PageTransition(
                                              type: PageTransitionType
                                                  .rightToLeft,
                                              child: DoctorTimeSlot(
                                                doctorId: doctorId,
                                                doctorName: doctorName,
                                                doctorImage: imageUrl,
                                                specialtyKey: specialtyKey,
                                                specialtyEn: specialtyEn,
                                                specialtyAr: specialtyAr,
                                                specialtyKu: specialtyKu,
                                                experience: exp,
                                                centerId: centerDoc.id,
                                                clinicName: cn,
                                                provinceKey:
                                                    schedule['provinceKey'] ??
                                                        '',
                                                cityKey:
                                                    schedule['cityKey'] ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  user == null ? 'login_to_book'.tr() : 'book_now'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    SliverToBoxAdapter _buildCentersSection(
      BuildContext context,
      List<QueryDocumentSnapshot> centers,
      List<QueryDocumentSnapshot> schedules,
      String doctorName,
      String imageUrl,
      String exp,
    ) {
      return SliverToBoxAdapter(
        child: _modernCard(
          title: 'available_at'.tr(),
          icon: Icons.local_hospital,
          child: Column(
            children: centers
                .map((doc) {
                  final c = doc.data() as Map<String, dynamic>;

                  // 🔹 SAFE schedule matching
                  final matchingSchedules =
                      schedules.where((s) => s['centerId'] == doc.id).toList();

                  if (matchingSchedules.isEmpty) {
                    return null; // important: return null, not SizedBox
                  }

                  final schedule = matchingSchedules.first;

                  final lang = context.locale.languageCode;

                  String clinicName;
                  String city;
                  String province;
                  String address;

                  if (lang == 'ar') {
                    clinicName =
                        (c['clinicName_ar'] ?? c['clinicName_en'] ?? '')
                            .toString();
                    city = (c['city_ar'] ?? '').toString();
                    province = (c['province_ar'] ?? '').toString();
                    address = (c['clinicAddress_ar'] ?? '').toString();
                  } else if (lang == 'ku') {
                    clinicName =
                        (c['clinicName_ku'] ?? c['clinicName_en'] ?? '')
                            .toString();
                    city = (c['city_ku'] ?? '').toString();
                    province = (c['province_ku'] ?? '').toString();
                    address = (c['clinicAddress_ku'] ?? '').toString();
                  } else {
                    clinicName = (c['clinicName_en'] ?? '').toString();
                    city = (c['city_en'] ?? '').toString();
                    province = (c['province_en'] ?? '').toString();
                    address = (c['clinicAddress_en'] ?? '').toString();
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: DoctorTimeSlot(
                            doctorId: doctorId,
                            doctorName: doctorName,
                            doctorImage: imageUrl,
                            specialtyKey: specialtyKey,
                            specialtyEn: specialtyEn,
                            specialtyAr: specialtyAr,
                            specialtyKu: specialtyKu,
                            experience: exp,
                            clinicName: clinicName,
                            province: province,
                            city: city,
                            centerId: doc.id,
                            provinceKey: schedule['provinceKey'],
                            cityKey: schedule['cityKey'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_hospital,
                                color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(clinicName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                if (address.isNotEmpty)
                                  Text(address, style: greyNormalTextStyle),
                                Text(
                                  "$city${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}$province",
                                  style: greyNormalTextStyle,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                })
                .whereType<Widget>() // 🔹 filters out null safely
                .toList(),
          ),
        ),
      );
    }

    SliverToBoxAdapter _buildAboutSection(
      BuildContext context,
      String about,
      List<String> languages,
      String exp,
    ) {
      return SliverToBoxAdapter(
        child: _modernCard(
          title: 'about_doctor'.tr(),
          icon: Icons.person,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                about.isNotEmpty ? about : 'no_description_available'.tr(),
                style: greyNormalTextStyle,
              ),
              const SizedBox(height: 16),
              _info(
                'languages'.tr(),
                languages.isEmpty
                    ? 'no_languages_listed'.tr()
                    : languages.join(', '),
              ),
              _info(
                'experience'.tr(),
                exp == 'N/A'
                    ? 'experience_not_available'.tr()
                    : '$exp ${'years'.tr()}',
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        _buildHeader(context, name, specialtyShown, rating, reviews, imageUrl),
        _buildActions(context, phone),
        if (canBook && isVerified && hasSchedule)
          _buildBookingCard(
            context,
            user,
            name,
            imageUrl,
            exp,
            specialtyKey,
            specialtyEn,
            specialtyAr,
            specialtyKu,
            schedules,
            centers,
          ),
        if (centers.isNotEmpty)
          _buildCentersSection(
              context, centers, schedules, name, imageUrl, exp),
        _buildAboutSection(context, about, languages, exp),
        SliverToBoxAdapter(
          child: _modernCard(
            title: 'reviews'.tr(),
            icon: Icons.star,
            child: DoctorReviewsSection(doctorId: doctorId),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}
