// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class AppointmentDetailPage extends StatelessWidget {
//   final String appointmentId;
//   const AppointmentDetailPage({super.key, required this.appointmentId});

//   @override
//   Widget build(BuildContext context) {
//     final fs = FirebaseFirestore.instance;

//     return StreamBuilder<DocumentSnapshot>(
//       stream: fs.collection('appointments').doc(appointmentId).snapshots(),
//       builder: (context, snap) {
//         if (snap.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//               body: Center(child: CircularProgressIndicator()));
//         }
//         if (!snap.hasData || !snap.data!.exists) {
//           return Scaffold(
//             body: Center(child: Text('appointment_not_found'.tr())),
//           );
//         }

//         final data = snap.data!.data() as Map<String, dynamic>;
//         final status = (data['status'] ?? 'Pending').toString();
//         final doctorName = (data['doctorName'] ?? '').toString();
//         final doctorImg = (data['doctorImage'] ?? '').toString();
//         final doctorType = (data['doctorType'] ?? '').toString();

//         final clinicName = (data['clinicName'] ?? '').toString();
//         final city = (data['city'] ?? '').toString();
//         final province = (data['province'] ?? '').toString();

//         final dateKey = (data['dateKey'] ?? '').toString();
//         final time = (data['time'] ?? data['slotTime'] ?? '').toString();

//         final forSelf = (data['forSelf'] ?? true) as bool;
//         final patientName = (data['patientName'] ?? '').toString();
//         final relationship = (data['relationship'] ?? '').toString();
//         final notes = (data['notes'] ?? '').toString();
//         final paymentStatus = (data['paymentStatus'] ?? 'Unpaid').toString();

//         Color badge() {
//           switch (status.toLowerCase()) {
//             case 'confirmed':
//               return Colors.green;
//             case 'pending':
//               return Colors.orange;
//             case 'completed':
//               return Colors.blue;
//             case 'cancelled':
//               return Colors.red;
//             default:
//               return Colors.grey;
//           }
//         }

//         return Scaffold(
//           backgroundColor: PatientAppColors.surface,
//           appBar: AppBar(
//             elevation: 0,
//             backgroundColor: PatientAppColors.surface,
//             title: Text(tr('DetailTitle'), style: appBarTitleTextStyle),
//             iconTheme: const IconThemeData(color: Colors.black),
//           ),
//           body: ListView(
//             padding: EdgeInsets.fromLTRB(
//                 fixPadding * 1.6, fixPadding, fixPadding * 1.6, 100),
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: whiteColor,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.05), blurRadius: 12)
//                   ],
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CircleAvatar(
//                       radius: 32,
//                       backgroundImage: doctorImg.startsWith('http')
//                           ? NetworkImage(doctorImg)
//                           : const AssetImage('assets/user/placeholder_user.png')
//                               as ImageProvider,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '$clinicName • $city, $province',
//                             style: primaryColorsmallBoldTextStyle,
//                           ),
//                           Text(doctorType, style: greySmallTextStyle),
//                           const SizedBox(height: 4),
//                           Text('$clinicName • $city, $province',
//                               style: primaryColorsmallBoldTextStyle),
//                           const SizedBox(height: 10),
//                           Row(
//                             children: [
//                               Icon(Icons.event,
//                                   size: 18, color: Colors.teal[400]),
//                               const SizedBox(width: 6),
//                               Text('$dateKey  •  $time',
//                                   style: blackNormalTextStyle),
//                               const Spacer(),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 10, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: badge().withOpacity(0.12),
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                                 child: Text(
//                                   status,
//                                   style: TextStyle(
//                                       color: badge(),
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 14),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: whiteColor,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.05), blurRadius: 12)
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(tr('patient'), style: blackHeadingTextStyle),
//                     const SizedBox(height: 8),
//                     _row(tr('for'), forSelf ? tr('self') : tr('someoneElse')),
//                     if (!forSelf) _row(tr('name'), patientName),
//                     if (!forSelf) _row('Relationship', relationship),
//                     if (!forSelf) _row(tr('relationship'), relationship),
//                     _row('Payment', paymentStatus),
//                     if ((notes).isNotEmpty) ...[
//                       const SizedBox(height: 10),
//                       Text(tr('notes'), style: blackNormalBoldTextStyle),
//                       const SizedBox(height: 4),
//                       Text(notes, style: blackNormalTextStyle),
//                     ],
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 14),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: whiteColor,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.05), blurRadius: 12)
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('address'.tr(), style: blackHeadingTextStyle),
//                     const SizedBox(height: 8),
//                     Text(clinicName, style: blackNormalBoldTextStyle),
//                     const SizedBox(height: 4),
//                     Text('$city, $province', style: greyNormalTextStyle),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           bottomSheet: _BottomActions(
//             appointmentId: appointmentId,
//             doctorId: (data['doctorId'] ?? '').toString(),
//             currentDateKey: dateKey,
//             currentSlot: time,
//           ),
//         );
//       },
//     );
//   }

//   Widget _row(String k, String v) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6.0),
//       child: Row(
//         children: [
//           SizedBox(width: 110, child: Text(k, style: greySmallBoldTextStyle)),
//           Expanded(
//               child: Text(v,
//                   style: blackNormalTextStyle,
//                   overflow: TextOverflow.ellipsis)),
//         ],
//       ),
//     );
//   }
// }

// class _BottomActions extends StatefulWidget {
//   final String appointmentId;
//   final String doctorId;
//   final String currentDateKey;
//   final String currentSlot;

//   const _BottomActions({
//     required this.appointmentId,
//     required this.doctorId,
//     required this.currentDateKey,
//     required this.currentSlot,
//   });

//   @override
//   State<_BottomActions> createState() => _BottomActionsState();
// }

// class _BottomActionsState extends State<_BottomActions> {
//   final _fs = FirebaseFirestore.instance;
//   final _auth = FirebaseAuth.instance;

//   bool _working = false;

//   String _dateKey(DateTime d) =>
//       "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

//   Future<void> _cancel() async {
//     final sure = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('cancel_appointment'.tr()),
//         content: Text('cancel_appointment_confirm'.tr()),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text('cancel'.tr()),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: Text(
//               'confirm'.tr(),
//               style: const TextStyle(color: Colors.white),
//             ),
//           )
//         ],
//       ),
//     );
//     if (sure != true) return;

//     setState(() => _working = true);
//     try {
//       await _fs.collection('appointments').doc(widget.appointmentId).update({
//         'status': 'Cancelled',
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('appointment_cancelled'.tr())),
//       );
//     } catch (e) {
//       debugPrint('cancel error: $e');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('error_generic'.tr())),
//       );
//     } finally {
//       if (mounted) setState(() => _working = false);
//     }
//   }

//   Future<void> _reschedule() async {
//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _RescheduleSheet(
//         appointmentId: widget.appointmentId,
//         doctorId: widget.doctorId,
//         currentDateKey: widget.currentDateKey,
//         currentSlot: widget.currentSlot,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: whiteColor,
//       padding: EdgeInsets.fromLTRB(fixPadding * 1.6, 10, fixPadding * 1.6, 16),
//       child: SafeArea(
//         top: false,
//         child: Row(
//           children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _working ? null : _reschedule,
//                 icon: const Icon(Icons.edit_calendar),
//                 label: Text('reschedule'.tr()),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _working ? null : _cancel,
//                 icon: const Icon(Icons.cancel),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                 label: Text(
//                   'cancel'.tr(),
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RescheduleSheet extends StatefulWidget {
//   final String appointmentId;
//   final String doctorId;
//   final String currentDateKey;
//   final String currentSlot;

//   const _RescheduleSheet({
//     required this.appointmentId,
//     required this.doctorId,
//     required this.currentDateKey,
//     required this.currentSlot,
//   });

//   @override
//   State<_RescheduleSheet> createState() => _RescheduleSheetState();
// }

// class _RescheduleSheetState extends State<_RescheduleSheet> {
//   final _fs = FirebaseFirestore.instance;
//   final _auth = FirebaseAuth.instance;

//   DateTime _pickedDate = DateTime.now();
//   Map<String, dynamic>? _scheduleForDay;
//   bool _loadingSchedule = true;

//   final Map<String, int> _slotUsage = {};
//   bool _loadingUsage = true;
//   int _capacityPerSlot = 1;

//   String _dateKey(DateTime d) =>
//       "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

//   DateTime _parseHm(String hm, DateTime base) {
//     final p = hm.split(':');
//     return DateTime(
//         base.year, base.month, base.day, int.parse(p[0]), int.parse(p[1]));
//   }

//   String _formatHm(DateTime dt) {
//     final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
//     final m = dt.minute.toString().padLeft(2, '0');
//     final ap = dt.hour >= 12 ? 'PM' : 'AM';
//     return '$h:$m $ap';
//   }

//   List<String> _buildSlots() {
//     if (_scheduleForDay == null) return [];
//     final start = _parseHm(_scheduleForDay!['startTime'], _pickedDate);
//     final end = _parseHm(_scheduleForDay!['endTime'], _pickedDate);
//     final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;

//     final slots = <String>[];
//     var cur = start;
//     while (cur.isBefore(end)) {
//       final label = _formatHm(cur);
//       slots.add(label);
//       cur = cur.add(Duration(minutes: dur));
//     }
//     return slots;
//   }

//   bool _isFull(String slotLabel) {
//     final used = _slotUsage[slotLabel] ?? 0;
//     return used >= _capacityPerSlot;
//   }

//   @override
//   void initState() {
//     super.initState();

//     final now = DateTime.now();
//     if (DateTime(_pickedDate.year, _pickedDate.month, _pickedDate.day)
//         .isBefore(DateTime(now.year, now.month, now.day))) {
//       _pickedDate = DateTime(now.year, now.month, now.day);
//     }
//     _loadSchedule();
//   }

//   Future<void> _loadSchedule() async {
//     setState(() {
//       _loadingSchedule = true;
//       _loadingUsage = true;
//       _scheduleForDay = null;
//       _slotUsage.clear();
//     });

//     try {
//       final weekday = _pickedDate.weekday;
//       final qs = await _fs
//           .collection('schedules')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('dayOfWeek', isEqualTo: weekday)
//           .where('status', isEqualTo: 'clinic')
//           .limit(1)
//           .get();

//       if (qs.docs.isEmpty) {
//         setState(() {
//           _scheduleForDay = null;
//           _capacityPerSlot = 1;
//           _loadingSchedule = false;
//           _loadingUsage = false;
//         });
//         return;
//       }
//       final data = qs.docs.first.data();
//       _scheduleForDay = data;
//       _capacityPerSlot = (data['capacityPerSlot'] ?? 1) is int
//           ? data['capacityPerSlot'] as int
//           : int.tryParse("${data['capacityPerSlot']}") ?? 1;

//       setState(() => _loadingSchedule = false);
//       await _loadUsage();
//     } catch (e) {
//       debugPrint('reschedule: schedule load err $e');
//       setState(() {
//         _scheduleForDay = null;
//         _capacityPerSlot = 1;
//         _loadingSchedule = false;
//         _loadingUsage = false;
//       });
//     }
//   }

//   Future<void> _loadUsage() async {
//     setState(() {
//       _loadingUsage = true;
//       _slotUsage.clear();
//     });

//     try {
//       final dateKey = _dateKey(_pickedDate);
//       final qs = await _fs
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('dateKey', isEqualTo: dateKey)
//           .where('status',
//               whereIn: ['Pending', 'Confirmed', 'Completed']).get();
//       for (final d in qs.docs) {
//         final data = d.data();
//         final t = (data['slotTime'] ?? data['time'] ?? '').toString();
//         if (t.isEmpty) continue;
//         _slotUsage[t] = (_slotUsage[t] ?? 0) + 1;
//       }
//     } catch (e) {
//       debugPrint('reschedule: usage load err $e');
//     } finally {
//       if (mounted) setState(() => _loadingUsage = false);
//     }
//   }

//   Future<void> _pickDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _pickedDate.isBefore(now) ? now : _pickedDate,
//       firstDate: now,
//       lastDate: now.add(const Duration(days: 60)),
//     );
//     if (picked != null) {
//       setState(() => _pickedDate = picked);
//       await _loadSchedule();
//     }
//   }

//   Future<void> _applyReschedule(String newSlot) async {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final sure = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('confirm_reschedule'.tr()),
//         content: Text(
//           'reschedule_confirm_message'.tr(namedArgs: {
//             'date': DateFormat('EEE, MMM d').format(_pickedDate),
//             'slot': newSlot,
//           }),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text('cancel'.tr()),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
//             child: Text(
//               'confirm'.tr(),
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//     if (sure != true) return;

//     try {
//       final dateKey = _dateKey(_pickedDate);
//       final dup = await _fs
//           .collection('appointments')
//           .where('userId', isEqualTo: user.uid)
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('dateKey', isEqualTo: dateKey)
//           .where('status', whereIn: ['Pending', 'Confirmed'])
//           .limit(1)
//           .get();
//       if (dup.docs.isNotEmpty && dup.docs.first.id != widget.appointmentId) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('appointment_conflict_day'.tr())),
//           );
//         }
//         return;
//       }

//       final slotSnap = await _fs
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('dateKey', isEqualTo: dateKey)
//           .where('slotTime', isEqualTo: newSlot)
//           .where('status',
//               whereIn: ['Pending', 'Confirmed', 'Completed']).get();
//       if (slotSnap.size >= _capacityPerSlot) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('slot_full_pick_another'.tr())),
//           );
//         }

//         await _loadUsage();
//         return;
//       }

//       await _fs.collection('appointments').doc(widget.appointmentId).update({
//         'dateKey': dateKey,
//         'date': DateTime(_pickedDate.year, _pickedDate.month, _pickedDate.day)
//             .toUtc()
//             .toIso8601String(),
//         'time': newSlot,
//         'slotTime': newSlot,
//         'status': 'Pending',
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       if (!mounted) return;
//       Navigator.pop(context);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('appointment_rescheduled'.tr())),
//         );
//       }
//     } catch (e) {
//       debugPrint('reschedule error: $e');
//       if (!mounted) return;
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('error_generic'.tr())),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.85,
//       minChildSize: 0.6,
//       maxChildSize: 0.95,
//       builder: (_, controller) => Container(
//         decoration: BoxDecoration(
//           color: whiteColor,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14)
//           ],
//         ),
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
//         child: ListView(
//           controller: controller,
//           children: [
//             Center(
//               child: Container(
//                 width: 44,
//                 height: 5,
//                 decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(3)),
//                 margin: const EdgeInsets.only(bottom: 14),
//               ),
//             ),
//             Row(
//               children: [
//                 const Icon(Icons.edit_calendar, color: Colors.teal),
//                 const SizedBox(width: 8),
//                 Text('reschedule'.tr(), style: blackHeadingTextStyle),
//                 const Spacer(),
//                 TextButton.icon(
//                   onPressed: _pickDate,
//                   icon: const Icon(Icons.date_range),
//                   label: Text(DateFormat('EEE, MMM d').format(_pickedDate)),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             if (_loadingSchedule)
//               const Center(
//                   child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 30),
//                 child: CircularProgressIndicator(),
//               ))
//             else if (_scheduleForDay == null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 30),
//                 child: Center(
//                     child: Text('no_clinic_hours_day'.tr(),
//                         style: greyNormalTextStyle)),
//               )
//             else ...[
//               if (_loadingUsage)
//                 const Center(
//                     child: Padding(
//                   padding: EdgeInsets.symmetric(vertical: 20),
//                   child: CircularProgressIndicator(),
//                 )),
//               if (!_loadingUsage)
//                 Wrap(
//                   spacing: 10,
//                   runSpacing: 10,
//                   children: _buildSlots().map((slot) {
//                     final isFull = _isFull(slot);
//                     return GestureDetector(
//                       onTap: isFull ? null : () => _applyReschedule(slot),
//                       child: Container(
//                         width: 96,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: isFull ? Colors.grey.shade200 : Colors.white,
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: isFull ? Colors.grey.shade300 : primaryColor,
//                             width: 1,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.04),
//                               blurRadius: 6,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(slot,
//                                 style: isFull
//                                     ? greySmallTextStyle
//                                     : primaryColorNormalTextStyle),
//                             const SizedBox(height: 4),
//                             if (isFull)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text('slot_full'.tr(),
//                                     style: TextStyle(
//                                         color: Colors.red,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 11)),
//                               )
//                             else
//                               Text(
//                                 '${_slotUsage[slot] ?? 0}/$_capacityPerSlot',
//                                 style: greySmallTextStyle,
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

class AppointmentDetailPage extends StatelessWidget {
  final String appointmentId;
  const AppointmentDetailPage({super.key, required this.appointmentId});
  String localizedField(
    Map<String, dynamic> data,
    String base,
    BuildContext context,
  ) {
    final lang = context.locale.languageCode;

    final localized = data['${base}_$lang'];
    if (localized != null && localized.toString().isNotEmpty) {
      return localized.toString();
    }

    final en = data['${base}_en'];
    if (en != null && en.toString().isNotEmpty) {
      return en.toString();
    }

    return (data[base] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return StreamBuilder<DocumentSnapshot>(
      stream: fs.collection('appointments').doc(appointmentId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: PatientAppColors.brandIndigo,
              ),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            body: Center(child: Text('DetailNotFound'.tr())),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;

        final status = (data['status'] ?? '').toString();

        final clinicName = localizedField(data, 'clinicName', context);
        final clinicAddress = localizedField(data, 'clinicAddress', context);

// 🔥 NEW TIME (correct)
        String formattedTime = '';
        if (data['slotStartAt'] != null) {
          final dt = (data['slotStartAt'] as Timestamp).toDate();
          formattedTime = DateFormat.yMMMEd(context.locale.languageCode)
              .add_jm()
              .format(dt);
        }

        final dateKey = (data['dateKey'] ?? '').toString();
        final province = localizedField(data, 'province', context);
        final city = localizedField(data, 'city', context);

        final forSelf = data['forSelf'] ?? true;
        final patientName = (data['patientName'] ?? '').toString();
        final relationship = (data['relationship'] ?? '').toString();
        final rawStatus = (data['paymentStatus'] ?? '').toString();

        String paymentStatusKey;

        switch (rawStatus.toLowerCase()) {
          case 'paid':
            paymentStatusKey = 'Paid';
            break;

          case 'unpaid':
            paymentStatusKey = 'Unpaid';
            break;

          default:
            paymentStatusKey = rawStatus;
        }

        Color statusColor() {
          switch (status.toLowerCase()) {
            case 'confirmed':
              return PatientAppColors.statusConfirmed;
            case 'completed':
              return PatientAppColors.statusCompleted;
            case 'cancelled':
              return PatientAppColors.statusCancelled;
            default:
              return PatientAppColors.statusWarning;
          }
        }

        return Scaffold(
          backgroundColor: PatientAppColors.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: PatientAppColors.brandIndigo),
            title: Text(
              'DetailTitle'.tr(),
              style: appBarTitleTextStyle.copyWith(
                color: PatientAppColors.brandIndigo,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              fixPadding * 1.6,
              fixPadding,
              fixPadding * 1.6,
              120,
            ),
            children: [
              /// 📅 APPOINTMENT CARD
              _card(
                child: Row(
                  children: [
                    /// Doctor Avatar
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.shade200,
                      ),
                      child: data['doctorImage'] != null &&
                              data['doctorImage'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                data['doctorImage'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.person, size: 32),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Doctor Name
                          Text(
                            data['doctorName'] ?? '',
                            style: blackHeadingTextStyle.copyWith(fontSize: 18),
                          ),

                          const SizedBox(height: 4),

                          /// Specialty
                          Text(
                            localizedField(data, 'specialtyName', context),
                            style: TextStyle(
                              color: PatientAppColors.brandIndigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// STATUS CHIP
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor().withOpacity(.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'status.$status'.tr(),
                              style: TextStyle(
                                color: statusColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// 👤 PATIENT
              _card(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: PatientAppColors.brandIndigo, size: 26),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'appointment_time'.tr(),
                          style: greySmallBoldTextStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedTime,
                          style: blackHeadingTextStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// 📍 ADDRESS
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_hospital,
                            color: PatientAppColors.brandIndigo),
                        const SizedBox(width: 6),
                        Text('clinic'.tr(), style: blackHeadingTextStyle),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      clinicName,
                      style: blackNormalBoldTextStyle,
                    ),
                    if (clinicAddress.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(clinicAddress, style: greyNormalTextStyle),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      "$city, $province",
                      style: greyNormalTextStyle,
                    ),
                  ],
                ),
              ),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('patient'.tr(), style: blackHeadingTextStyle),
                    const SizedBox(height: 8),
                    _row('name'.tr(), patientName),
                    if (!forSelf) _row('relationship'.tr(), relationship),
                    _row('payment'.tr(), (tr(paymentStatusKey))),
                  ],
                ),
              ),
              if (data['visitReason'] != null || data['notes'] != null)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('visit_details'.tr(), style: blackHeadingTextStyle),
                      const SizedBox(height: 8),
                      if (data['visitReason'] != null)
                        _row(
                          'reason'.tr(),
                          (data['visitReason'] as String).tr(),
                        ),
                      if (data['notes'] != null &&
                          data['notes'].toString().isNotEmpty)
                        _row('notes'.tr(), data['notes']),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

// Future<Map<String, String>> getLocationNames(
//   BuildContext context,
//   String provinceKey,
//   String cityKey,
// ) async {
//   if (provinceKey.isEmpty || cityKey.isEmpty) {
//     return {'province': '', 'city': ''};
//   }

//   final lang = context.locale.languageCode;

//   final doc = await FirebaseFirestore.instance
//       .collection('cities')
//       .doc(provinceKey)
//       .get();

//   if (!doc.exists) {
//     return {'province': '', 'city': ''};
//   }

//   final data = doc.data()!;

//   //-----------------------------
//   // ✅ PROVINCE
//   //-----------------------------
//   final province =
//     data[lang] ?? data['name_en'] ?? '';

//   //-----------------------------
//   // ✅ CITY
//   //-----------------------------
//   final subCities = List<Map<String, dynamic>>.from(
//     data['subCities'] ?? [],
//   );

// final cityKeyPart = cityKey.split('_').last.toLowerCase();

// Map<String, dynamic>? cityMatch;

// for (final c in subCities) {
//   final en = (c['en'] ?? '').toString().toLowerCase();

//   if (en.contains(cityKeyPart) || cityKeyPart.contains(en)) {
//     cityMatch = c;
//     break;
//   }
// }

// final city =
//     cityMatch?[lang] ??
//     cityMatch?['en'] ??
//     '';

//   return {
//     'province': province,
//     'city': city,
//   };
// }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: greySmallBoldTextStyle),
          ),
          Expanded(
            child: Text(
              value,
              style: blackNormalTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
