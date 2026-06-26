// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/patient/write_review_page.dart'
//     show WriteReviewModal;
// import 'package:trustydr/pages/screens.dart' show LoginScreen;
// import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
// import 'package:trustydr/pages/patient/appointment_detail_page.dart';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';

// class MyAppointmentsPage extends StatefulWidget {
//   const MyAppointmentsPage({super.key});

//   @override
//   State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
// }

// class _MyAppointmentsPageState extends State<MyAppointmentsPage>
//     with SingleTickerProviderStateMixin {
//   final _auth = FirebaseAuth.instance;
//   final _fs = FirebaseFirestore.instance;
//   late final TabController _tab;

//   @override
//   void initState() {
//     super.initState();
//     _tab = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tab.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = _auth.currentUser;
//     if (user == null) {
//       return Scaffold(
//         backgroundColor: whiteColor,
//         body: SafeArea(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
//                   const SizedBox(height: 12),
//                   Text('Login Required', style: blackHeadingTextStyle),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Please sign in to view and manage your appointments.',
//                     textAlign: TextAlign.center,
//                     style: greySmallTextStyle,
//                   ),
//                   const SizedBox(height: 18),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         PageTransition(
//                           type: PageTransitionType.rightToLeft,
//                           child: const LoginScreen(),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: PatientAppColors.brandIndigo,
//                       minimumSize: const Size.fromHeight(44),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child:
//                         Text('Go to Login', style: whiteColorButtonTextStyle),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: scaffoldBgColor,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: whiteColor,
//         titleSpacing: 0,
//         title: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Text('My Appointments', style: appBarTitleTextStyle),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(60),
//           child: Container(
//             margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 )
//               ],
//             ),
//             child: TabBar(
//               controller: _tab,
//               labelColor: PatientAppColors.brandIndigo,
//               unselectedLabelColor: Colors.black54,
//               indicator: UnderlineTabIndicator(
//                 borderSide: BorderSide(color: PatientAppColors.brandIndigo, width: 3),
//                 insets: const EdgeInsets.symmetric(horizontal: 24),
//               ),
//               tabs: const [
//                 Tab(text: 'Upcoming'),
//                 Tab(text: 'Past'),
//                 Tab(text: 'Cancelled'),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tab,
//         children: [
//           _buildList(user.uid, ['pending', 'confirmed']),
//           _buildList(user.uid, ['completed']),
//           _buildList(user.uid, ['cancelled']),
//         ],
//       ),
//     );
//   }

//   Widget _buildList(String userId, List<String> statuses) {
//     final q = _fs
//         .collection('appointments')
//         .where('userId', isEqualTo: userId)
//         .orderBy('createdAt', descending: true);

//     return StreamBuilder<QuerySnapshot>(
//       stream: q.snapshots(),
//       builder: (context, snap) {
//         if (snap.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snap.hasError) {
//           return Center(
//             child: Text('Error: ${snap.error}', style: blackNormalTextStyle),
//           );
//         }
//         if (!snap.hasData || snap.data!.docs.isEmpty) {
//           return Center(
//             child: Text('No appointments found.', style: greyNormalTextStyle),
//           );
//         }

//         final docs = snap.data!.docs;
//         return ListView.builder(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
//           itemCount: docs.length,
//           itemBuilder: (_, i) {
//             final data = docs[i].data() as Map<String, dynamic>;
//             final id = docs[i].id;

//             final doctorName = (data['doctorName'] ?? '').toString();
//             final doctorType = (data['doctorType'] ?? '').toString();
//             final doctorImage = (data['doctorImage'] ?? '').toString();
//             final clinicName = (data['clinicName'] ?? '').toString();
//             final dateKey = (data['dateKey'] ?? '').toString();
//             final time = (data['time'] ?? data['slotTime'] ?? '').toString();
//             final status = (data['status'] ?? 'Pending').toString();
//             final city = (data['city'] ?? '').toString();
//             final province = (data['province'] ?? '').toString();
//             final doctorId = (data['doctorId'] ?? '').toString();
//             final experience = (data['experience'] ?? '').toString();

//             final isPastTab =
//                 statuses.length == 1 && statuses.first == 'Completed';

//             return _AppointmentCard(
//               id: id,
//               doctorId: doctorId,
//               doctorName: doctorName,
//               doctorType: doctorType,
//               doctorImage: doctorImage,
//               clinicName: clinicName,
//               city: city,
//               province: province,
//               experience: experience,
//               dateKey: dateKey,
//               time: time,
//               status: status,
//               onOpenDetails: () {
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.rightToLeft,
//                     child: AppointmentDetailPage(appointmentId: id),
//                   ),
//                 );
//               },
//               onCancel: () => _confirmCancel(id),
//               onReschedule: () {
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.rightToLeft,
//                     child: DoctorTimeSlot(
//                       doctorId: doctorId,
//                       doctorName: doctorName,
//                       doctorImage: doctorImage,
//                       doctorType: doctorType,
//                       experience: experience.isEmpty ? 'N/A' : experience,
//                       clinicName: clinicName,
//                       province: province,
//                       city: city,
//                     ),
//                   ),
//                 );
//               },
//               onWriteReview: isPastTab
//                   ? () => _openWriteReview(
//                         doctorId: doctorId,
//                         doctorName: doctorName,
//                         doctorImage: doctorImage,
//                       )
//                   : null,
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _confirmCancel(String appointmentId) async {
//     final yes = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Cancel Appointment'),
//         content: const Text(
//           'Are you sure you want to cancel this appointment?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('No'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Yes, Cancel'),
//           ),
//         ],
//       ),
//     );

//     if (yes != true) return;

//     try {
//       await _fs.collection('appointments').doc(appointmentId).update({
//         'status': 'Cancelled',
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('❌ Appointment cancelled.')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }

//   Future<void> _openWriteReview({
//     required String doctorId,
//     required String doctorName,
//     required String doctorImage,
//   }) async {
//     await showModalBottomSheet(
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       builder: (_) => FractionallySizedBox(
//         heightFactor: 0.85,
//         child: WriteReviewModal(
//           doctorId: doctorId,
//           doctorName: doctorName,
//           doctorImage: doctorImage,
//         ),
//       ),
//     );
//   }
// }

// class _AppointmentCard extends StatelessWidget {
//   final String id;
//   final String doctorId;
//   final String doctorName;
//   final String doctorType;
//   final String doctorImage;
//   final String clinicName;
//   final String city;
//   final String province;
//   final String experience;
//   final String dateKey;
//   final String time;
//   final String status;
//   final VoidCallback onOpenDetails;
//   final VoidCallback onCancel;
//   final VoidCallback onReschedule;
//   final VoidCallback? onWriteReview;

//   const _AppointmentCard({
//     required this.id,
//     required this.doctorId,
//     required this.doctorName,
//     required this.doctorType,
//     required this.doctorImage,
//     required this.clinicName,
//     required this.city,
//     required this.province,
//     required this.experience,
//     required this.dateKey,
//     required this.time,
//     required this.status,
//     required this.onOpenDetails,
//     required this.onCancel,
//     required this.onReschedule,
//     this.onWriteReview,
//   });

//   Color get _statusColor {
//     switch (status.toLowerCase()) {
//       case 'confirmed':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'completed':
//         return Colors.blue;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         gradient: LinearGradient(
//           colors: [
//             PatientAppColors.brandIndigo.withOpacity(0.12),
//             Colors.white,
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           )
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(16),
//           onTap: onOpenDetails,
//           child: Padding(
//             padding: const EdgeInsets.all(14),
//             child: Column(
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: doctorImage.isNotEmpty
//                           ? Image.network(
//                               doctorImage,
//                               width: 70,
//                               height: 70,
//                               fit: BoxFit.cover,
//                               errorBuilder: (_, __, ___) => Container(
//                                 width: 70,
//                                 height: 70,
//                                 color: Colors.grey[200],
//                                 child: const Icon(Icons.person, size: 36),
//                               ),
//                             )
//                           : Container(
//                               width: 70,
//                               height: 70,
//                               color: Colors.grey[200],
//                               child: const Icon(Icons.person, size: 36),
//                             ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Dr. $doctorName',
//                               style: blackNormalBoldTextStyle),
//                           const SizedBox(height: 4),
//                           Text(doctorType, style: greySmallTextStyle),
//                           const SizedBox(height: 4),
//                           if (clinicName.isNotEmpty)
//                             Text('🏥 $clinicName', style: greySmallTextStyle),
//                           if (city.isNotEmpty || province.isNotEmpty)
//                             Text(
//                                 '📍 $city${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}$province',
//                                 style: greySmallTextStyle),
//                           const SizedBox(height: 6),
//                           Row(
//                             children: [
//                               const Icon(Icons.calendar_month,
//                                   size: 16, color: Colors.black54),
//                               const SizedBox(width: 6),
//                               Text('$dateKey • $time',
//                                   style: blackSmallTextStyle),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: _statusColor.withOpacity(0.15),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         status,
//                         style: TextStyle(
//                           color: _statusColor,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     TextButton.icon(
//                       onPressed: onOpenDetails,
//                       icon: const Icon(Icons.info_outline, size: 18),
//                       label: const Text('Details'),
//                     ),
//                     if (status.toLowerCase() == 'completed' &&
//                         onWriteReview != null)
//                       TextButton.icon(
//                         onPressed: onWriteReview,
//                         icon: const Icon(Icons.rate_review,
//                             color: Colors.amber, size: 18),
//                         label: const Text('Write Review',
//                             style: TextStyle(color: Colors.amber)),
//                       ),
//                     if (status.toLowerCase() != 'completed' &&
//                         status.toLowerCase() != 'cancelled')
//                       TextButton.icon(
//                         onPressed: onReschedule,
//                         icon: const Icon(Icons.edit_calendar, size: 18),
//                         label: const Text('Reschedule'),
//                       ),
//                     if (status.toLowerCase() != 'cancelled' &&
//                         status.toLowerCase() != 'completed')
//                       TextButton.icon(
//                         onPressed: onCancel,
//                         icon: const Icon(Icons.cancel,
//                             color: Colors.red, size: 18),
//                         label: const Text('Cancel',
//                             style: TextStyle(color: Colors.red)),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//This is with modern and match app style but missing back arrow.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/patient_appointments_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_appointment_item.dart';
import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
import 'package:trustydr/pages/lab/lab_time_slot_page.dart';
import 'package:trustydr/pages/patient/appointment_detail_page.dart';
import 'package:trustydr/pages/patient/lab_appointment_detail_page.dart';
import 'package:trustydr/pages/patient/write_review_page.dart'
    show WriteReviewModal;
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class MyAppointmentsPage extends ConsumerStatefulWidget {
  final bool showBack;

  const MyAppointmentsPage({
    Key? key,
    this.showBack = true,
  }) : super(key: key);

  @override
  ConsumerState<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends ConsumerState<MyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  late final TabController _tab;
  final Set<String> _sessionReviewedIds = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return _buildLoginPrompt(context);
    }

    final lang = context.locale.languageCode;
    final allAsync = ref.watch(patientAllAppointmentsProvider);

    Widget content = Column(
      children: [
        TrustyDrCurvedHeader(
          title: 'my_appointments'.tr(),
          showBack: widget.showBack,
          height: 100,
        ),
        Container(
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tab,
            labelColor: PatientAppColors.brandIndigo,
            unselectedLabelColor: Colors.black54,
            indicator: UnderlineTabIndicator(
              borderSide:
                  BorderSide(color: PatientAppColors.brandIndigo, width: 3),
              insets: const EdgeInsets.symmetric(horizontal: 24),
            ),
            tabs: [
              Tab(text: 'upcoming'.tr()),
              Tab(text: 'past'.tr()),
              Tab(text: 'canceled'.tr()),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildTab(allAsync, (i) => i.isUpcoming, lang: lang),
              _buildTab(allAsync, (i) => i.isPast,
                  lang: lang, descending: true),
              _buildTab(allAsync, (i) => i.isCancelled,
                  lang: lang, descending: true),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: PatientAppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 768) {
            content = WebScaffoldContainer(child: content);
          }
          return content;
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientAppColors.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'my_appointments'.tr(),
                showBack: widget.showBack,
                height: 100,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('login_required'.tr(),
                            style: blackHeadingTextStyle),
                        const SizedBox(height: 10),
                        Text(
                          'please_login'.tr(),
                          textAlign: TextAlign.center,
                          style: greySmallTextStyle,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: const LoginScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PatientAppColors.brandIndigo,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'login_button'.tr(),
                            style: whiteColorButtonTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildTab(
    AsyncValue<List<PatientAppointmentItem>> allAsync,
    bool Function(PatientAppointmentItem) filter, {
    required String lang,
    bool descending = false,
  }) {
    return allAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: PatientAppColors.brandIndigo),
      ),
      error: (e, _) => Center(
        child: Text('error_generic'.tr(), style: blackNormalTextStyle),
      ),
      data: (all) {
        var items = all.where(filter).toList();
        if (descending) items = items.reversed.toList();
        if (items.isEmpty) {
          return Center(
            child: Text('no_results'.tr(), style: greyNormalTextStyle),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            if (item.type == PatientAppointmentType.doctor) {
              return _DoctorCard(
                item: item,
                lang: lang,
                hasReviewed: _sessionReviewedIds.contains(item.sourceId),
                onOpenDetails: () => Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: AppointmentDetailPage(appointmentId: item.sourceId),
                  ),
                ),
                onReschedule: () => _openReschedule(item, lang),
                onCancel: () =>
                    _confirmCancel(item.sourceId, slotId: item.slotId),
                onWriteReview: item.isPast
                    ? () => _openWriteReview(
                          appointmentId: item.sourceId,
                          doctorId: item.doctorId ?? '',
                          doctorName: item.providerName(lang),
                          doctorImage: item.providerImage ?? '',
                        )
                    : null,
              );
            }
            return _LabCard(
              item: item,
              lang: lang,
              onViewDetails: () => _openLabDetails(item, lang),
              onReschedule:
                  item.isUpcoming ? () => _openLabReschedule(item, lang) : null,
              onCancel: item.isUpcoming
                  ? () => _confirmLabCancel(item.sourceId, slotId: item.slotId)
                  : null,
            );
          },
        );
      },
    );
  }

  void _openReschedule(PatientAppointmentItem item, String lang) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: DoctorTimeSlot(
          doctorId: item.doctorId ?? '',
          doctorName: item.providerName(lang),
          doctorImage: item.providerImage ?? '',
          centerId: item.centerId ?? '',
          provinceKey: item.provinceKey ?? '',
          cityKey: item.cityKey ?? '',
          specialtyKey: item.specialtyKey ?? '',
          specialtyEn: item.specialtyNameEn ?? '',
          specialtyAr: item.specialtyNameAr ?? '',
          specialtyKu: item.specialtyNameKu ?? '',
          experience: 'N/A',
          clinicName: item.locationLabel(lang) ?? '',
          clinicAddress: item.addressLabel(lang) ?? '',
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    String appointmentId, {
    String? slotId,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('cancel_appointment'.tr()),
        content: Text('cancel_appointment_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      final effectiveSlotId = slotId ?? appointmentId;
      final batch = _fs.batch();
      batch.update(
        _fs.collection('appointments').doc(appointmentId),
        {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      batch.delete(_fs.collection('slot_locks').doc(effectiveSlotId));
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('appointment_canceled'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_generic'.tr())),
        );
      }
    }
  }

  Future<void> _openWriteReview({
    required String appointmentId,
    required String doctorId,
    required String doctorName,
    required String doctorImage,
  }) async {
    final reviewed = await showModalBottomSheet<bool>(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: WriteReviewModal(
          appointmentId: appointmentId,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorImage: doctorImage,
        ),
      ),
    );
    if (reviewed == true && mounted) {
      setState(() => _sessionReviewedIds.add(appointmentId));
    }
  }

  void _openLabDetails(PatientAppointmentItem item, String lang) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: LabAppointmentDetailPage(item: item),
      ),
    );
  }

  void _openLabReschedule(PatientAppointmentItem item, String lang) {
    final labId = item.labId;
    final centerId = item.centerId;
    final specialtyId = item.specialtyId;
    if (labId == null || centerId == null || specialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr())),
      );
      return;
    }
    final serviceGroup =
        item.type == PatientAppointmentType.imaging ? 'imaging' : 'laboratory';
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: LabTimeSlotPage(
          labId: labId,
          centerId: centerId,
          facilityName: item.providerName(lang),
          imageUrl: item.providerImage ?? '',
          serviceGroup: serviceGroup,
          specialtyId: specialtyId,
          serviceNameEn: item.serviceLabelEn,
          serviceNameAr: item.serviceLabelAr,
          serviceNameKu: item.serviceLabelKu,
          providerNameEn: item.providerNameEn,
          providerNameAr: item.providerNameAr,
          providerNameKu: item.providerNameKu,
          providerAddress: item.locationLabel('en') ?? '',
          providerImage: item.providerImage ?? '',
        ),
      ),
    );
  }

  Future<void> _confirmLabCancel(
    String requestId, {
    String? slotId,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('cancel_appointment'.tr()),
        content: Text('cancel_appointment_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      final batch = _fs.batch();
      batch.update(
        _fs.collection('clinical_requests').doc(requestId),
        {
          'partnerStatus': 'cancelled',
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      if (slotId != null) {
        batch.delete(_fs.collection('slot_locks').doc(slotId));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('appointment_canceled'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_generic'.tr())),
        );
      }
    }
  }
}

// ── Doctor appointment card ──────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final PatientAppointmentItem item;
  final String lang;
  final bool hasReviewed;
  final VoidCallback onOpenDetails;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback? onWriteReview;

  const _DoctorCard({
    required this.item,
    required this.lang,
    required this.hasReviewed,
    required this.onOpenDetails,
    required this.onReschedule,
    required this.onCancel,
    this.onWriteReview,
  });

  static String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusKey = item.statusKey();
    final statusColor = item.statusColor();
    final providerImage = item.providerImage ?? '';
    final clinicName = item.locationLabel(lang) ?? '';
    final clinicAddress = item.addressLabel(lang) ?? '';
    final dateStr = _fmtDate(item.appointmentDateTime);
    final timeStr = item.timeLabel ?? '';
    final dateTime = timeStr.isNotEmpty ? '$dateStr • $timeStr' : dateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            PatientAppColors.brandIndigo.withOpacity(0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpenDetails,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: providerImage.isNotEmpty
                          ? Image.network(
                              providerImage,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'doctor_prefix'.tr()} ${item.providerName(lang)}',
                            style: blackNormalBoldTextStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(item.serviceLabel(lang),
                              style: greySmallTextStyle),
                          const SizedBox(height: 4),
                          if (clinicName.isNotEmpty)
                            Text('🏥 $clinicName', style: greySmallTextStyle),
                          if (clinicAddress.isNotEmpty)
                            Text('📍 $clinicAddress',
                                style: greySmallTextStyle),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Flexible(
                                child:
                                    Text(dateTime, style: blackSmallTextStyle),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(
                        label: 'status.$statusKey'.tr(), color: statusColor),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: onOpenDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text('view_details'.tr()),
                    ),
                    if (item.isPast && !hasReviewed && onWriteReview != null)
                      TextButton.icon(
                        onPressed: onWriteReview,
                        icon: const Icon(Icons.rate_review,
                            color: Colors.amber, size: 18),
                        label: Text('write_review'.tr(),
                            style: const TextStyle(color: Colors.amber)),
                      ),
                    if (item.isUpcoming)
                      TextButton.icon(
                        onPressed: onReschedule,
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: Text('reschedule'.tr()),
                      ),
                    if (item.isUpcoming)
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel,
                            color: Colors.red, size: 18),
                        label: Text('cancel'.tr(),
                            style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.person, size: 36, color: Colors.grey),
      );
}

// ── Lab / imaging appointment card ───────────────────────────────────────────

class _LabCard extends StatelessWidget {
  final PatientAppointmentItem item;
  final String lang;
  final VoidCallback onViewDetails;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  const _LabCard({
    required this.item,
    required this.lang,
    required this.onViewDetails,
    this.onReschedule,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusKey = item.statusKey();
    final statusColor = item.statusColor();
    final providerImage = item.providerImage ?? '';
    final address = item.locationLabel(lang) ?? '';
    final dateStr = _fmtApptDate(item.appointmentDateTime);
    final timeStr = _fmtApptTime(item.appointmentDateTime);
    final isImaging = item.type == PatientAppointmentType.imaging;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5CC6BA).withOpacity(0.10),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // ── header row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: providerImage.isNotEmpty
                      ? Image.network(
                          providerImage,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(isImaging),
                        )
                      : _placeholder(isImaging),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.providerName(lang),
                              style: blackNormalBoldTextStyle,
                            ),
                          ),
                          _TypeBadge(isImaging: isImaging),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.serviceLabel(lang), style: greySmallTextStyle),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📍 $address', style: greySmallTextStyle),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('$dateStr • $timeStr',
                                style: blackSmallTextStyle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                    label: 'status.$statusKey'.tr(), color: statusColor),
              ],
            ),
            // ── action row ──
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text('view_details'.tr()),
                ),
                if (onReschedule != null)
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: Text('reschedule'.tr()),
                  ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                    label: Text('cancel'.tr(),
                        style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isImaging) => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isImaging ? Icons.image_search : Icons.science,
          size: 32,
          color: Colors.grey,
        ),
      );
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isImaging;
  const _TypeBadge({required this.isImaging});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF5CC6BA).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isImaging ? 'imaging'.tr() : 'lab'.tr(),
        style: const TextStyle(
          color: Color(0xFF5CC6BA),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── File-level date/time helpers (shared by _LabCard and state methods) ──────

String _fmtApptDate(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String _fmtApptTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
}
