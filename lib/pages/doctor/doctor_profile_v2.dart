import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/widgets/doctor_reviews_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Returns true when the center has at least one valid date window open.
/// Mirrors centerAccessProvider date-only logic from the doctor portal.
/// Does NOT read subscriptionStatus — dates are the sole source of truth.
bool _isCenterOperational(Map<String, dynamic> data) {
  final now = DateTime.now();
  final te = data['trialEnds'];
  final se = data['subscriptionEnd'];
  final gpe = data['gracePeriodEnds'];
  final trialEnds = te is Timestamp ? te.toDate() : null;
  final subscriptionEnd = se is Timestamp ? se.toDate() : null;
  final gracePeriodEnds = gpe is Timestamp ? gpe.toDate() : null;
  return (trialEnds != null && now.isBefore(trialEnds)) ||
      (subscriptionEnd != null && now.isBefore(subscriptionEnd)) ||
      (gracePeriodEnds != null && now.isBefore(gracePeriodEnds));
}

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
              child:
                  CircularProgressIndicator(color: PatientAppColors.brandTeal),
            );
          }

          final doctorData = doctorSnap.data!.data();
          if (doctorData == null) {
            return const _DoctorNotFoundView();
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
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

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

    final rawExp =
        doctorData['experienceYears'] ?? doctorData['yearsOfExperience'];
    final exp = (rawExp is num && rawExp.toInt() > 0)
        ? rawExp.toInt().toString()
        : 'N/A';

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
    final email = (doctorData['email'] ?? '').toString();
    final languages = List<String>.from(doctorData['languages'] ?? []);

    final isVerified =
        doctorData['verified'] == true || doctorData['isVerified'] == true;
    final canBook = doctorData['canBook'] == true;
    final canCall = doctorData['canCall'] == true;

    final showSocialLinks = doctorData['showSocialLinks'] == true;
    final rawSocial = doctorData['socialLinks'];
    final Map<String, String> socialLinks =
        (showSocialLinks && rawSocial is Map)
            ? Map<String, String>.fromEntries(
                ['instagram', 'facebook', 'tiktok', 'youtube', 'website']
                    .where((k) =>
                        rawSocial[k] is String &&
                        (rawSocial[k] as String).trim().isNotEmpty)
                    .map((k) => MapEntry(k, (rawSocial[k] as String).trim())),
              )
            : {};

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

    final clinicName = lang == 'ar'
        ? (doctorData['clinicName_ar'] ?? doctorData['clinicName_en'] ?? '')
            .toString()
        : lang == 'ku'
            ? (doctorData['clinicName_ku'] ?? doctorData['clinicName_en'] ?? '')
                .toString()
            : (doctorData['clinicName_en'] ?? doctorData['clinicName'] ?? '')
                .toString();

    final cityLoc = lang == 'ar'
        ? (doctorData['city_ar'] ?? '').toString()
        : lang == 'ku'
            ? (doctorData['city_ku'] ?? '').toString()
            : (doctorData['city_en'] ?? '').toString();

    final provinceLoc = lang == 'ar'
        ? (doctorData['province_ar'] ?? '').toString()
        : lang == 'ku'
            ? (doctorData['province_ku'] ?? '').toString()
            : (doctorData['province_en'] ?? '').toString();

    final locationLine =
        [cityLoc, provinceLoc].where((s) => s.isNotEmpty).join(', ');

    SliverAppBar buildHeader(
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
              gradient: PatientAppColors.brandGradient,
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

    Widget actionButton({
      required Widget iconWidget,
      required String label,
      required Color color,
      VoidCallback? onTap,
    }) {
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

    SliverToBoxAdapter buildAllActions(BuildContext context, String phone,
        String email, bool canCall, Map<String, String> socialLinks) {
      final items = <Widget>[];

      if (canCall && phone.isNotEmpty) {
        items.add(actionButton(
          iconWidget: Icon(Icons.call, color: PatientAppColors.statusConfirmed),
          label: 'call_now'.tr(),
          color: PatientAppColors.statusConfirmed,
          onTap: () => launchUrl(Uri.parse('tel:$phone')),
        ));
      }
      if (email.isNotEmpty) {
        items.add(actionButton(
          iconWidget:
              Icon(Icons.email_outlined, color: PatientAppColors.brandTeal),
          label: 'email_address'.tr(),
          color: PatientAppColors.brandTeal,
          onTap: () => launchUrl(Uri.parse('mailto:$email')),
        ));
      }

      void addSocial(
          String key, IconData faIcon, String labelKey, Color color) {
        final url = socialLinks[key];
        if (url == null) return;
        final uri = Uri.tryParse(url);
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          return;
        }
        items.add(actionButton(
          iconWidget: FaIcon(faIcon, color: color, size: 24),
          label: labelKey.tr(),
          color: color,
          onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
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

      if (items.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: items,
          ),
        ),
      );
    }

    Widget modernCard({
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
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PatientAppColors.brandTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(icon, color: PatientAppColors.brandTeal, size: 18),
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

    Widget info(String title, String value) {
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

    SliverToBoxAdapter buildBookingCard(
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
      // ── Operational filtering ──────────────────────────────────────
      // Only show centers/schedules whose date window is still open.
      // Expired centers are silently excluded; if ALL centers are expired
      // a neutral "not accepting bookings" message is shown instead of
      // the booking button. No billing or payment language is exposed.
      final operationalCenters = centers.where((cd) {
        final data = cd.data() as Map<String, dynamic>? ?? {};
        return _isCenterOperational(data);
      }).toList();
      final operationalCenterIds =
          operationalCenters.map((cd) => cd.id).toSet();
      final operationalSchedules = schedules
          .where((s) =>
              operationalCenterIds.contains(s['centerId']?.toString() ?? ''))
          .toList();
      final allCentersExpired =
          centers.isNotEmpty && operationalCenters.isEmpty;

      return SliverToBoxAdapter(
        child: modernCard(
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
              if (allCentersExpired)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'doctor_not_accepting_bookings'.tr(),
                    style: greyNormalTextStyle,
                    textAlign: TextAlign.center,
                  ),
                )
              else
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
                          if (operationalSchedules.isEmpty) return;

                          if (operationalCenters.length == 1) {
                            final centerDoc = operationalCenters.first;
                            final center =
                                centerDoc.data() as Map<String, dynamic>;

                            // SAFE schedule match
                            final matchingSchedules = operationalSchedules
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      ...operationalCenters.map((centerDoc) {
                                        final c = centerDoc.data()
                                            as Map<String, dynamic>;
                                        final matching = operationalSchedules
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
                                              color:
                                                  PatientAppColors.brandTeal),
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
                    backgroundColor: PatientAppColors.brandIndigo,
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

    SliverToBoxAdapter buildCentersSection(
      BuildContext context,
      List<QueryDocumentSnapshot> centers,
      List<QueryDocumentSnapshot> schedules,
      String doctorName,
      String imageUrl,
      String exp,
    ) {
      return SliverToBoxAdapter(
        child: modernCard(
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
                              color: PatientAppColors.brandTeal
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_hospital,
                                color: PatientAppColors.brandTeal),
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

    SliverToBoxAdapter buildAboutSection(
      BuildContext context,
      String about,
      List<String> languages,
      String exp,
      String clinicName,
      String locationLine,
    ) {
      return SliverToBoxAdapter(
        child: modernCard(
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
              info(
                'languages'.tr(),
                languages.isEmpty
                    ? 'no_languages_listed'.tr()
                    : languages.map((l) {
                        final key = 'lang.$l';
                        final result = key.tr();
                        return result == key ? l : result;
                      }).join(', '),
              ),
              if (exp != 'N/A')
                info(
                  'experience'.tr(),
                  '$exp ${'years'.tr()}',
                ),
              info('clinic'.tr(), clinicName),
              info('location'.tr(), locationLine),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        buildHeader(context, name, specialtyShown, rating, reviews, imageUrl),
        buildAllActions(context, phone, email, canCall, socialLinks),
        if (canBook && isVerified && hasSchedule)
          buildBookingCard(
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
          buildCentersSection(context, centers, schedules, name, imageUrl, exp),
        buildAboutSection(
            context, about, languages, exp, clinicName, locationLine),
        SliverToBoxAdapter(
          child: modernCard(
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

class _DoctorNotFoundView extends StatelessWidget {
  const _DoctorNotFoundView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: BackButton(color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off, size: 72, color: Colors.grey[350]),
                    const SizedBox(height: 24),
                    Text(
                      'doctor_not_found'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PatientAppColors.brandTeal,
                        side:
                            const BorderSide(color: PatientAppColors.brandTeal),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('go_back'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
