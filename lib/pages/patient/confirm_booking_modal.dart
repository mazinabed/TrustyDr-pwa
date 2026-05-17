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
import 'package:trustydr/data/services/appointment_builder.dart';
import 'package:trustydr/services/database_service.dart';

class ConfirmBookingModal extends StatefulWidget {
  final String specialtyKey;
  final String specialtyEn;
  final String specialtyAr;
  final String specialtyKu;
  final String scheduleId;
  final DateTime slotStartAt;
  final int slotDurationMinutes;

  final String doctorId;
  final String doctorName;
  final String doctorImage;

  final String clinicName;

  final String centerId;
  final String provinceKey;
  final String cityKey;

  final DateTime date;
  final String slotLabel;
  final int capacityPerSlot;

  const ConfirmBookingModal({
    super.key,
    required this.scheduleId,
    required this.slotStartAt,
    required this.slotDurationMinutes,
    required this.specialtyKey,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.specialtyKu,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.clinicName,
    required this.date,
    required this.slotLabel,
    required this.capacityPerSlot,
    // ⭐ ADD THESE
    required this.centerId,
    required this.provinceKey,
    required this.cityKey,
  });

  @override
  State<ConfirmBookingModal> createState() => _ConfirmBookingModalState();
}

class _ConfirmBookingModalState extends State<ConfirmBookingModal> {
  final _auth = FirebaseAuth.instance;

  bool _forSelf = true;
  final _patientNameCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _submitting = false;

  // ✅ Visit reason
  final List<String> _visitReasons = [
    'visit_reason.checkup',
    'visit_reason.followup',
    'visit_reason.pain',
    'visit_reason.refill',
    'visit_reason.consultation',
    'visit_reason.other',
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

    //---------------------------------------
    // Resolve patient + bookedBy names
    //---------------------------------------
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String? profileName = userSnap.data()?['name'] ??
        userSnap.data()?['username'] ??
        user.displayName;

    if (!mounted) return;

    if (_forSelf && (profileName == null || profileName.trim().isEmpty)) {
      final enteredName = await _askForNameOnce(context);
      if (enteredName == null) return;

      profileName = enteredName;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': enteredName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    //---------------------------------------
    // Validate dependent
    //---------------------------------------
    if (!_forSelf &&
        (_patientNameCtrl.text.trim().isEmpty ||
            _relationshipCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('patient_info_required'.tr())),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      //---------------------------------------
      // 🔥 BUILD APPOINTMENT (ONLY WAY)
      //---------------------------------------
// 🔥 HARD GUARD — profileName can NEVER be null past this point
      profileName ??= user.displayName ?? 'Patient';

      final slotId = await AppointmentBuilder.create(
        scheduleId: widget.scheduleId,

        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        doctorImage: widget.doctorImage,

        patientId: user.uid,
        patientName: _forSelf ? profileName! : _patientNameCtrl.text.trim(),

        phone: null, // add later when patient model finalized
        relationship: _forSelf ? null : _relationshipCtrl.text.trim(),

        slotStartAt: widget.slotStartAt,

        source: "patient_app",
        bookedByUserId: user.uid,
        bookedByRole: "patient",
        bookedByName: profileName,

        visitReason: _visitReason,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
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
    final locale = context.locale.languageCode;

    final specialty = locale == 'ar'
        ? widget.specialtyAr
        : locale == 'ku'
            ? widget.specialtyKu
            : widget.specialtyEn;

    final formattedDate =
        DateFormat.yMMMEd(locale).add_jm().format(widget.slotStartAt);

    return Directionality(
      textDirection: Directionality.of(context),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.75,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: ListView(
            controller: controller,
            children: [
              // ===========================
              // DOCTOR + CENTER HEADER
              // ===========================

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryColor.withOpacity(.1),
                      backgroundImage: widget.doctorImage.isNotEmpty
                          ? NetworkImage(widget.doctorImage)
                          : null,
                      child: widget.doctorImage.isEmpty
                          ? Icon(Icons.person, color: primaryColor)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'doctor_prefix_name'.tr(args: [widget.doctorName]),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.local_hospital,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.clinicName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ===========================
              // DATE CARD
              // ===========================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: primaryColor.withOpacity(.07),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'minutes_short'
                          .tr(args: [widget.slotDurationMinutes.toString()]),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===========================
              // WHO IS THIS FOR
              // ===========================

              Text(
                'who_is_this_for'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  ChoiceChip(
                    label: Text('self'.tr()),
                    selected: _forSelf,
                    onSelected: (_) => setState(() => _forSelf = true),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: Text('someone_else'.tr()),
                    selected: !_forSelf,
                    onSelected: (_) => setState(() => _forSelf = false),
                  ),
                ],
              ),

              if (!_forSelf) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _patientNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'patient_full_name'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _relationshipCtrl,
                  decoration: InputDecoration(
                    labelText: 'relationship'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ===========================
              // VISIT REASON
              // ===========================

              DropdownButtonFormField<String>(
                value: _visitReason,
                decoration: InputDecoration(
                  labelText: 'reason_for_visit_optional'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: _visitReasons.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Text(key.tr()),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => _visitReason = v);
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'additional_notes_optional'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ===========================
              // CONFIRM BUTTON
              // ===========================

              ElevatedButton(
                onPressed: _submitting ? null : _book,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        'book_appointment'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'secure_booking'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
