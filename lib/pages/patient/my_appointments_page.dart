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
//                       backgroundColor: primaryColor,
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
//               labelColor: primaryColor,
//               unselectedLabelColor: Colors.black54,
//               indicator: UnderlineTabIndicator(
//                 borderSide: BorderSide(color: primaryColor, width: 3),
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
//             primaryColor.withOpacity(0.12),
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
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/patient/write_review_page.dart'
    show WriteReviewModal;
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
import 'package:trustydr/pages/patient/appointment_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';

class MyAppointmentsPage extends StatefulWidget {
  final bool showBack;

  const MyAppointmentsPage({
    super.key,
    this.showBack = true, // default = bottom tab
  });

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;
  late final TabController _tab;

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

  String _localizedSpecialty(Map<String, dynamic> data, BuildContext context) {
    final lang = context.locale.languageCode;

    // ✅ New appointments (Option B)
    if (lang == 'ar' && data['specialtyName_ar'] != null) {
      return data['specialtyName_ar'].toString();
    }
    if (lang == 'ku' && data['specialtyName_ku'] != null) {
      return data['specialtyName_ku'].toString();
    }
    if (data['specialtyName_en'] != null) {
      return data['specialtyName_en'].toString();
    }

    // 🟡 Fallback for old appointments
    if (data['doctorType'] != null) {
      return data['doctorType'].toString();
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

   if (user == null) {
  return Scaffold(
    backgroundColor: const Color(0xFFF6F8FB),
    body: Column(
      children: [
        TrustyDrCurvedHeader(
          title: 'my_appointments'.tr(),
          showBack: widget.showBack, height: 100,
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('login_required'.tr(), style: blackHeadingTextStyle),
                  const SizedBox(height: 10),
                  Text(
                    'please_login'.tr(),
                    textAlign: TextAlign.center,
                    style: greySmallTextStyle,
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
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
    ),
  );
}


    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          // 🌈 Gradient Header with Title
      TrustyDrCurvedHeader(
  title: 'my_appointments'.tr(),
  showBack: widget.showBack, height: 100,
),

          // White curved divider below gradient
          Container(
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F8FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          // 📅 Tabs
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
              labelColor: primaryColor,
              unselectedLabelColor: Colors.black54,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: primaryColor, width: 3),
                insets: const EdgeInsets.symmetric(horizontal: 24),
              ),
              tabs: [
                Tab(text: 'upcoming'.tr()),
                Tab(text: 'past'.tr()),
                Tab(text: 'canceled'.tr()),
              ],
            ),
          ),

          // 🔄 Tab Views
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildList(user.uid, ['pending', 'confirmed']),
                _buildList(user.uid, ['completed']),
                _buildList(user.uid, ['canceled']),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ⚠️ Firestore whereIn limit = 10 values MAX
  Widget _buildList(String userId, List<String> statuses) {
    assert(statuses.length <= 10);
    final q = _fs
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: statuses)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'error_generic'.tr(),
              style: blackNormalTextStyle,
            ),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text('no_results'.tr(), style: greyNormalTextStyle),
          );
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;

            final doctorName = (data['doctorName'] ?? '').toString();

            final doctorImage = (data['doctorImage'] ?? '').toString();
            final clinicName = (data['clinicName'] ?? '').toString();
            final dateKey = (data['dateKey'] ?? '').toString();
            final time = (data['time'] ?? data['slotTime'] ?? '').toString();
            final status = (data['status'] ?? 'Pending').toString();
            final city = (data['city'] ?? '').toString();
            final province = (data['province'] ?? '').toString();
            final doctorId = (data['doctorId'] ?? '').toString();
            final experience = (data['experience'] ?? '').toString();

            final isPastTab =
                statuses.length == 1 && statuses.first == 'completed';
            final specialty = _localizedSpecialty(data, context);

            return _AppointmentCard(
              id: id,
              doctorId: doctorId,
              doctorName: doctorName,
              doctorType: specialty,
              doctorImage: doctorImage,
              clinicName: clinicName,
              city: city,
              province: province,
              experience: experience,
              dateKey: dateKey,
              time: time,
              status: status,
              hasReviewed: data['hasReviewed'] == true,
              onOpenDetails: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: AppointmentDetailPage(appointmentId: id),
                  ),
                );
              },
              onCancel: () => _confirmCancel(id),
              onReschedule: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: DoctorTimeSlot(
                      doctorId: doctorId,
                      doctorName: doctorName,
                      doctorImage: doctorImage,

                      // ✅ SOURCE OF TRUTH = appointment
                      specialtyKey: data['specialtyKey'] ?? '',
                      specialtyEn: data['specialtyName_en'] ?? '',
                      specialtyAr: data['specialtyName_ar'] ?? '',
                      specialtyKu: data['specialtyName_ku'] ?? '',
                      experience: experience.isEmpty ? 'N/A' : experience,
                      clinicName: clinicName,
                      province: province,
                      city: city,
                    ),
                  ),
                );
              },
              onWriteReview: isPastTab
                  ? () => _openWriteReview(
                        appointmentId: id,
                        doctorId: doctorId,
                        doctorName: doctorName,
                        doctorImage: doctorImage,
                      )
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmCancel(String appointmentId) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('cancel_appointment'.tr()),
        content: Text(
          'cancel_appointment_confirm'.tr(),
        ),
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
      await _fs.collection('appointments').doc(appointmentId).update({
        'status': 'canceled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    await showModalBottomSheet(
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
  }
}

// Reuse gradient header for consistent top curve
class _AppointmentCard extends StatelessWidget {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorType;
  final String doctorImage;
  final String clinicName;
  final String city;
  final String province;
  final String experience;
  final String dateKey;
  final String time;
  final String status;
  final VoidCallback onOpenDetails;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;
  final VoidCallback? onWriteReview;
  final bool hasReviewed;

  const _AppointmentCard({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorType,
    required this.doctorImage,
    required this.clinicName,
    required this.city,
    required this.province,
    required this.experience,
    required this.dateKey,
    required this.time,
    required this.status,
    required this.onOpenDetails,
    required this.onCancel,
    required this.onReschedule,
    this.onWriteReview,
    required this.hasReviewed,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLc = status.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.12),
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
                /// ---------------- HEADER ----------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: doctorImage.isNotEmpty
                          ? Image.network(
                              doctorImage,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 36),
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, size: 36),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'doctor_prefix'.tr()} $doctorName',
                            style: blackNormalBoldTextStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(doctorType, style: greySmallTextStyle),
                          const SizedBox(height: 4),
                          if (clinicName.isNotEmpty)
                            Text('🏥 $clinicName', style: greySmallTextStyle),
                          if (city.isNotEmpty || province.isNotEmpty)
                            Text(
                              '📍 $city${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}$province',
                              style: greySmallTextStyle,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                '$dateKey • $time',
                                style: blackSmallTextStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// STATUS CHIP
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// ---------------- ACTIONS ----------------
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: onOpenDetails,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text('view_details'.tr()),
                    ),

                    /// ⭐ REVIEW (ONLY ONCE, ONLY WHEN COMPLETED)
                    if (statusLc == 'completed' &&
                        !hasReviewed &&
                        onWriteReview != null)
                      TextButton.icon(
                        onPressed: onWriteReview,
                        icon: const Icon(Icons.rate_review,
                            color: Colors.amber, size: 18),
                        label: Text(
                          'write_review'.tr(),
                          style: const TextStyle(color: Colors.amber),
                        ),
                      ),

                    /// RESCHEDULE
                    if (statusLc != 'completed' && statusLc != 'canceled')
                      TextButton.icon(
                        onPressed: onReschedule,
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: Text('reschedule'.tr()),
                      ),

                    /// CANCEL
                    if (statusLc != 'canceled' && statusLc != 'completed')
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel,
                            color: Colors.red, size: 18),
                        label: Text(
                          'cancel'.tr(),
                          style: const TextStyle(color: Colors.red),
                        ),
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
}

class _CurvedGradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  const _CurvedGradientHeader(
      {required this.child, this.height = 180, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}
