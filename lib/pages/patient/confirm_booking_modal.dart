// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ConfirmBookingModal extends StatefulWidget {
//   final String doctorId;
//   final String doctorName;
//   final String doctorImage;
//   final String doctorType;
//   final String clinicName;
//   final String province;
//   final String city;

//   final DateTime date;
//   final String slotLabel;
//   final int capacityPerSlot;

//   const ConfirmBookingModal({
//     super.key,
//     required this.doctorId,
//     required this.doctorName,
//     required this.doctorImage,
//     required this.doctorType,
//     required this.clinicName,
//     required this.province,
//     required this.city,
//     required this.date,
//     required this.slotLabel,
//     required this.capacityPerSlot,
//   });

//   @override
//   State<ConfirmBookingModal> createState() => _ConfirmBookingModalState();
// }

// class _ConfirmBookingModalState extends State<ConfirmBookingModal> {
//   final _auth = FirebaseAuth.instance;
//   final _fs = FirebaseFirestore.instance;

//   bool _forSelf = true;
//   final _patientNameCtrl = TextEditingController();
//   final _relationshipCtrl = TextEditingController();
//   final _notesCtrl = TextEditingController();

//   bool _submitting = false;

//   String get _dateKey =>
//       "${widget.date.year.toString().padLeft(4, '0')}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}";

//   Future<void> _book() async {
//     final user = _auth.currentUser;
//     if (user == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please log in to book.')),
//       );
//       return;
//     }

//     if (!_forSelf) {
//       if (_patientNameCtrl.text.trim().isEmpty ||
//           _relationshipCtrl.text.trim().isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Please enter patient name and relationship.')),
//         );
//         return;
//       }
//     }

//     final sure = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Confirm Booking'),
//         content: Text(
//           "Book ${DateFormat('EEE, MMM d').format(widget.date)} • ${widget.slotLabel} with Dr. ${widget.doctorName}?",
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('No')),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
//             child: const Text('Yes', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//     if (sure != true) return;

//     setState(() => _submitting = true);

//     try {
//       final dup = await _fs
//           .collection('appointments')
//           .where('userId', isEqualTo: user.uid)
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('dateKey', isEqualTo: _dateKey)
//           .where('status', whereIn: ['Pending', 'Confirmed'])
//           .limit(1)
//           .get();
//       if (dup.docs.isNotEmpty) {
//         setState(() => _submitting = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//                 'You already have an active appointment for this doctor on this day.'),
//           ),
//         );
//         return;
//       }

//       final slotSnap = await _fs
//           .collection('appointments')
//           .where('doctorId', isEqualTo: widget.doctorId)
//           .where('dateKey', isEqualTo: _dateKey)
//           .where('slotTime', isEqualTo: widget.slotLabel)
//           .where('status',
//               whereIn: ['Pending', 'Confirmed', 'Completed']).get();

//       if (slotSnap.size >= widget.capacityPerSlot) {
//         setState(() => _submitting = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('This time is now FULL. Please pick another.')),
//         );
//         return;
//       }

//       final now = DateTime.now().toUtc();
//       final appt = {
//         'userId': user.uid,

//         'doctorId': widget.doctorId,
//         'doctorName': widget.doctorName,
//         'doctorImage': widget.doctorImage,
//         'doctorType': widget.doctorType,
//         'clinicName': widget.clinicName,
//         'province': widget.province,
//         'city': widget.city,

//         'dateKey': _dateKey,
//         'date': DateTime(
//           widget.date.year,
//           widget.date.month,
//           widget.date.day,
//         ).toUtc().toIso8601String(),

//         'time': widget.slotLabel,
//         'slotTime': widget.slotLabel,

//         // ✅ FIXED LOGIC
//         'forSelf': _forSelf,
//         'patientName': _forSelf
//             ? (user.displayName?.trim().isNotEmpty == true
//                 ? user.displayName!.trim()
//                 : 'Patient')
//             : _patientNameCtrl.text.trim(),

//         'bookedByName': user.displayName?.trim().isNotEmpty == true
//             ? user.displayName!.trim()
//             : 'Unknown',

//         'relationship': _forSelf ? 'Self' : _relationshipCtrl.text.trim(),

//         'notes': _notesCtrl.text.trim(),

//         'paymentStatus': 'Unpaid',
//         'status': 'Pending',

//         'createdAt': FieldValue.serverTimestamp(),
//         'updatedAt': FieldValue.serverTimestamp(),
//         'createdAtIso': now.toIso8601String(),
//       };

//       await _fs.collection('appointments').add(appt);

//       if (!mounted) return;
//       Navigator.pop(context, true);
//     } catch (e) {
//       debugPrint('❌ booking error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error booking. Please try again.')),
//       );
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.78,
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
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(3),
//                 ),
//                 margin: const EdgeInsets.only(bottom: 12),
//               ),
//             ),
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 26,
//                   backgroundImage: widget.doctorImage.startsWith('http')
//                       ? NetworkImage(widget.doctorImage)
//                       : const AssetImage('assets/user/placeholder_user.png')
//                           as ImageProvider,
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     'Dr. ${widget.doctorName} • ${widget.doctorType}',
//                     style: blackNormalBoldTextStyle,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 6),
//             Text('${widget.clinicName} • ${widget.city}, ${widget.province}',
//                 style: greySmallTextStyle),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: scaffoldBgColor,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.event, size: 18, color: Colors.teal),
//                   const SizedBox(width: 8),
//                   Text(
//                     '${DateFormat('EEE, MMM d, yyyy').format(widget.date)}  •  ${widget.slotLabel}',
//                     style: blackNormalTextStyle,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text('For whom?', style: blackNormalBoldTextStyle),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 ChoiceChip(
//                   label: const Text('Self'),
//                   selected: _forSelf,
//                   onSelected: (v) => setState(() => _forSelf = true),
//                 ),
//                 const SizedBox(width: 10),
//                 ChoiceChip(
//                   label: const Text('Someone else'),
//                   selected: !_forSelf,
//                   onSelected: (v) => setState(() => _forSelf = false),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             if (!_forSelf) ...[
//               TextField(
//                 controller: _patientNameCtrl,
//                 decoration: const InputDecoration(
//                   labelText: 'Patient full name',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _relationshipCtrl,
//                 decoration: const InputDecoration(
//                   labelText: 'Relationship (e.g., Daughter, Father)',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//             TextField(
//               controller: _notesCtrl,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 labelText: 'Notes (optional)',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _submitting ? null : _book,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10)),
//                 ),
//                 child: _submitting
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                             strokeWidth: 2, color: Colors.white),
//                       )
//                     : const Text('Confirm Booking',
//                         style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//new with force name and add reason for visit.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class ConfirmBookingModal extends StatefulWidget {
  final String specialtyKey;
  final String specialtyEn;
  final String specialtyAr;
  final String specialtyKu;

  final String doctorId;
  final String doctorName;
  final String doctorImage;

  final String clinicName;
  final String province;
  final String city;

  final DateTime date;
  final String slotLabel;
  final int capacityPerSlot;

  const ConfirmBookingModal({
    super.key,
    required this.specialtyKey,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.specialtyKu,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.clinicName,
    required this.province,
    required this.city,
    required this.date,
    required this.slotLabel,
    required this.capacityPerSlot,
  });

  @override
  State<ConfirmBookingModal> createState() => _ConfirmBookingModalState();
}

class _ConfirmBookingModalState extends State<ConfirmBookingModal> {
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  bool _forSelf = true;
  final _patientNameCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _submitting = false;

  // ✅ Visit reason
  final List<String> _visitReasons = [
    'visit_reason.checkup'.tr(),
    'visit_reason.followup'.tr(),
    'visit_reason.pain'.tr(),
    'visit_reason.refill'.tr(),
    'visit_reason.consultation'.tr(),
    'visit_reason.other'.tr(),
  ];

  DateTime _buildAppointmentDateTime() {
    final label = widget.slotLabel; // e.g. "12:30 PM"
    final parts = label.split(' ');
    final time = parts[0];
    final ampm = parts[1];

    final hm = time.split(':');
    int hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);

    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      hour,
      minute,
    );
  }

  String? _visitReason;

  String get _dateKey =>
      "${widget.date.year.toString().padLeft(4, '0')}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}";

  // ===========================================================
  // ONE-TIME NAME PROMPT
  // ===========================================================
  Future<String?> _askForNameOnce(BuildContext context) async {
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('full_name'.tr()),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'enter_full_name'.tr(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(context, ctrl.text.trim());
              }
            },
            child: Text('continue'.tr()),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // BOOK
  // ===========================================================
  Future<void> _book() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // ---------------------------------------
    // Resolve patient + bookedBy names
    // ---------------------------------------
    final userSnap = await _fs.collection('users').doc(user.uid).get();

    String? profileName = userSnap.data()?['name'] ??
        userSnap.data()?['username'] ??
        user.displayName;

    if (_forSelf && (profileName == null || profileName.trim().isEmpty)) {
      final enteredName = await _askForNameOnce(context);
      if (enteredName == null) return;

      profileName = enteredName;

      // Save to user profile
      await _fs.collection('users').doc(user.uid).set({
        'name': enteredName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (!_forSelf &&
        (_patientNameCtrl.text.trim().isEmpty ||
            _relationshipCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('patient_info_required'.tr()),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final appointmentAt = _buildAppointmentDateTime();

      final appt = {
        'userId': user.uid,

        'doctorId': widget.doctorId,
        'doctorName': widget.doctorName,
        'doctorImage': widget.doctorImage,

        'specialtyKey': widget.specialtyKey,
        'specialtyName_en': widget.specialtyEn,
        'specialtyName_ar': widget.specialtyAr,
        'specialtyName_ku': widget.specialtyKu,

        'clinicName': widget.clinicName,
        'province': widget.province,
        'city': widget.city,

        // ✅ CANONICAL TIME (THIS FIXES EVERYTHING)
        'appointmentAt': Timestamp.fromDate(appointmentAt),

        // Keep for grouping / UI
        'dateKey': _dateKey,
        'slotTime': widget.slotLabel,

        'forSelf': _forSelf,
        'patientName': _forSelf ? profileName : _patientNameCtrl.text.trim(),
        'bookedByName': profileName,
        'relationship': _forSelf ? 'Self' : _relationshipCtrl.text.trim(),

        'visitReason': _visitReason,
        'notes': _notesCtrl.text.trim(),

        'paymentStatus': 'unpaid',

        // ✅ NORMALIZED STATUS
        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _fs.collection('appointments').add(appt);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('❌ booking error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ===========================================================
  // UI
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListView(
          controller: controller,
          children: [
            Text(
              '${DateFormat('EEE, MMM d, yyyy').format(widget.date)} • ${widget.slotLabel}',
              style: blackNormalBoldTextStyle,
            ),
            const SizedBox(height: 16),

            // -------------------------
            // FOR WHOM
            // -------------------------
            Row(
              children: [
                ChoiceChip(
                  label: Text('self'.tr()),
                  selected: _forSelf,
                  onSelected: (_) => setState(() => _forSelf = true),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text('someone_else'.tr()),
                  selected: !_forSelf,
                  onSelected: (_) => setState(() => _forSelf = false),
                ),
              ],
            ),

            if (!_forSelf) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _patientNameCtrl,
                decoration:
                    InputDecoration(labelText: 'patient_full_name'.tr()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _relationshipCtrl,
                decoration: InputDecoration(labelText: 'relationship'.tr()),
              ),
            ],

            // -------------------------
            // VISIT REASON
            // -------------------------
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _visitReason,
              decoration: InputDecoration(
                labelText: 'reason_for_visit_optional'.tr(),
              ),
              items: _visitReasons
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _visitReason = v),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'notes_optional'.tr()),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _book,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('confirm_booking'.tr(),
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
