import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/patient/confirm_booking_modal.dart';
import 'package:trustydr/pages/patient/my_appointments_page.dart'
    show MyAppointmentsPage;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DoctorTimeSlot extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String specialtyKey;
  final String specialtyEn;
  final String specialtyAr;
  final String specialtyKu;
  final String experience;
final String centerId;
final String provinceKey;
final String cityKey;
final String? province;
final String? city;
final String clinicName;
final String? clinicAddress;
// ✅ ADD THIS

 
 

  const DoctorTimeSlot({
    super.key,
      required this.centerId,
  required this.provinceKey,
  required this.cityKey,
this.province,
this.city,


    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    // ✅ REQUIRED
    required this.specialtyKey,
    required this.specialtyEn,
    required this.specialtyAr,
    required this.specialtyKu,
    required this.experience,
    required this.clinicName,
 this.clinicAddress,

  });

  @override
  State<DoctorTimeSlot> createState() => _DoctorTimeSlotState();
}





class _DoctorTimeSlotState extends State<DoctorTimeSlot> {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, dynamic>? _scheduleForDay;
  bool _loadingSchedule = true;

  final Map<String, int> _slotUsage = {};
  bool _loadingUsage = true;

  int _capacityPerSlot = 1;

  String _dateKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  DateTime _parseHm(String hm, DateTime base) {
    final parts = hm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return DateTime(base.year, base.month, base.day, h, m);
  }

  String _formatHm(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  void initState() {
    super.initState();
    _loadScheduleForSelectedDay();
  }

  Future<void> _loadScheduleForSelectedDay() async {
    setState(() {
      _loadingSchedule = true;
      _loadingUsage = true;
      _scheduleForDay = null;
      _slotUsage.clear();
    });

    try {
      final weekday = _selectedDay.weekday;
      final qs = await _fs
          .collection('schedules')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('dayOfWeek', isEqualTo: weekday)
          .where('status', isEqualTo: 'published') // ✅ FIX
          .where('isActive', isEqualTo: true)
          .where('visitType', isEqualTo: 'inPerson')
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        setState(() {
          _scheduleForDay = null;
          _capacityPerSlot = 1;
          _loadingSchedule = false;
          _loadingUsage = false;
        });
        return;
      }

final doc = qs.docs.first;
final data = doc.data(); // ⭐ DEFINE DATA AGAIN

_scheduleForDay = {
  ...data,
  'scheduleId': doc.id,
};

_capacityPerSlot = (data['capacityPerSlot'] ?? 1) is int
    ? data['capacityPerSlot'] as int
    : int.tryParse("${data['capacityPerSlot']}") ?? 1;

      setState(() => _loadingSchedule = false);

      await _loadUsageForSelectedDate();
    } catch (_) {
      setState(() {
        _scheduleForDay = null;
        _capacityPerSlot = 1;
        _loadingSchedule = false;
        _loadingUsage = false;
      });
    }
  }

  String get _localizedSpecialty {
    final lang = context.locale.languageCode;

    if (lang == 'ar') return widget.specialtyAr;
    if (lang == 'ku') return widget.specialtyKu;
    return widget.specialtyEn;
  }

  Future<void> _loadUsageForSelectedDate() async {
    setState(() {
      _loadingUsage = true;
      _slotUsage.clear();
    });
    try {
      final dateKey = _dateKey(_selectedDay);
      final qs = await _fs
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('dateKey', isEqualTo: dateKey)
          .where('status', whereIn: ['pending', 'confirmed', 'completed'])
          .limit(500)
          .get();

      for (final d in qs.docs) {
        final data = d.data();
        final t = (data['slotTime'] ?? data['time'] ?? '').toString();
        if (t.isEmpty) continue;
        _slotUsage[t] = (_slotUsage[t] ?? 0) + 1;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  List<String> _buildSlots() {
    if (_scheduleForDay == null) return [];

    final start = _parseHm(_scheduleForDay!['startTime'], _selectedDay);
    final end = _parseHm(_scheduleForDay!['endTime'], _selectedDay);
    final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;

    final slots = <String>[];
    DateTime cur = start;
    while (cur.isBefore(end)) {
      slots.add(_formatHm(cur));
      cur = cur.add(Duration(minutes: dur));
    }
    return slots;
  }

  bool _isFull(String slotLabel) {
    final used = _slotUsage[slotLabel] ?? 0;
    return used >= _capacityPerSlot;
  }

  Future<bool> _hasActiveSameDayBooking({
    required String userId,
    required String doctorId,
    required String dateKey,
  }) async {
    try {
      final qs = await _fs
          .collection('appointments')
.where('patientId', isEqualTo: userId)
          .where('doctorId', isEqualTo: doctorId)
          .where('dateKey', isEqualTo: dateKey)
          .where('status', whereIn: ['pending', 'confirmed'])
          .limit(1)
          .get();
      return qs.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: whiteColor,
        title: Text('select_time'.tr(), style: appBarTitleTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                fixPadding * 2, fixPadding, fixPadding * 2, fixPadding),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: widget.doctorImage.startsWith('http')
                      ? NetworkImage(widget.doctorImage)
                      : const AssetImage('assets/user/placeholder_user.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${widget.doctorName}',
                          style: blackNormalBoldTextStyle),
                      const SizedBox(height: 2),
                      Text(
                        _localizedSpecialty,
                        style: greySmallTextStyle,
                      ),
                      const SizedBox(height: 2),
                      Text('${widget.experience} yrs • ${widget.clinicName}',
                          style: primaryColorsmallBoldTextStyle),
                      Text('${widget.city}, ${widget.province}',
                          style: greySmallTextStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: fixPadding * 1.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: _focusedDay,
              currentDay: DateTime.now(),
              selectedDayPredicate: (d) =>
                  d.year == _selectedDay.year &&
                  d.month == _selectedDay.month &&
                  d.day == _selectedDay.day,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              onDaySelected: (sel, foc) async {
                setState(() {
                  _selectedDay = sel;
                  _focusedDay = foc;
                });
                await _loadScheduleForSelectedDay();
              },
              onPageChanged: (foc) => _focusedDay = foc,
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingSchedule)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_scheduleForDay == null)
            SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'no_clinic_hours_day'.tr(),
                  style: greyNormalTextStyle,
                ),
              ),
            )
          else
            _buildSlotGrid(),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 24,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    final slots = _buildSlots();

    if (_loadingUsage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (slots.isEmpty) {
      return Center(
        child: Text('no_available_slots'.tr(), style: greyNormalTextStyle),
      );
    }

    return Padding(
      padding: EdgeInsets.all(fixPadding * 2),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: slots.map((label) {
          final isFull = _isFull(label);

          return GestureDetector(
            onTap: isFull ? null : () => _onPickSlot(label),
            child: Container(
              width: 96,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isFull ? Colors.grey.shade200 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFull ? Colors.grey.shade300 : primaryColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: isFull
                          ? greySmallTextStyle
                          : primaryColorNormalTextStyle),
                  const SizedBox(height: 4),
                  if (isFull)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'FULL',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    )
                  else
                    Text(
                      '${_slotUsage[label] ?? 0}/$_capacityPerSlot',
                      style: greySmallTextStyle,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

String _to24Hour(String label) {
  final parsed = DateFormat('h:mm a').parse(label);
  return DateFormat('HH:mm').format(parsed);
}



  Future<void> _onPickSlot(String slotLabel) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('login_to_book'.tr()),
        ),
      );
      return;
    }

    final dateKey = _dateKey(_selectedDay);
    final hasDup = await _hasActiveSameDayBooking(
      userId: user.uid,
      doctorId: widget.doctorId,
      dateKey: dateKey,
    );
    if (hasDup) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'appointment_conflict_doctor_day'.tr(),
            ),
          ),
        );
      }
      return;
    }

    if (_isFull(slotLabel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('slot_full'.tr())),
      );
      return;
    }
final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;

final slotStart = _parseHm(
  _to24Hour(slotLabel), // helper below
  _selectedDay,
);

    final prettyDate = DateFormat('EEE, MMM d, yyyy').format(_selectedDay);
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('confirm_booking'.tr()),
        content: Text(
          'confirm_booking_message'.tr(namedArgs: {
            'date': prettyDate,
            'slot': slotLabel,
            'doctor': widget.doctorName,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text(
              'confirm'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );


final schedule = _scheduleForDay!;

final centerId = (schedule['centerId'] ?? '').toString();
final lang = context.locale.languageCode;

String clinicName;

if (lang == 'ar') {
  clinicName =
      (schedule['clinicName_ar'] ?? schedule['clinicName_en'] ?? '').toString();
} else if (lang == 'ku') {
  clinicName =
      (schedule['clinicName_ku'] ?? schedule['clinicName_en'] ?? '').toString();
} else {
  clinicName =
      (schedule['clinicName_en'] ?? schedule['clinicName'] ?? '').toString();
}
final provinceKey = (schedule['provinceKey'] ?? '').toString();
final cityKey = (schedule['cityKey'] ?? '').toString();

// 🔥 HARD GUARD (VERY IMPORTANT)
// if (centerId.isEmpty || clinicName.isEmpty || provinceKey.isEmpty || cityKey.isEmpty) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(content: Text('Center location is missing. Please contact the clinic.')),
//   );
//   return;
// }

    if (sure != true) return;
    final wasBooked = await showModalBottomSheet<bool>(
      
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      
    builder: (_) => ConfirmBookingModal(
  scheduleId: (_scheduleForDay!['scheduleId'] ?? '').toString(),

  slotStartAt: slotStart,
  slotDurationMinutes: dur,

  doctorId: widget.doctorId,
  doctorName: widget.doctorName,
  doctorImage: widget.doctorImage,

  specialtyKey: widget.specialtyKey,
  specialtyEn: widget.specialtyEn,
  specialtyAr: widget.specialtyAr,
  specialtyKu: widget.specialtyKu,

  clinicName: clinicName,   // ✅ FROM SCHEDULE

  date: _selectedDay,
  slotLabel: slotLabel,
  capacityPerSlot: _capacityPerSlot,

  centerId: centerId,        // ✅ FROM SCHEDULE
  provinceKey: provinceKey,  // ✅ FROM SCHEDULE
  cityKey: cityKey,          // ✅ FROM SCHEDULE
),

    );

    if (wasBooked == true && mounted) {
      await _loadUsageForSelectedDate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryColor,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'appointment_booked_message'.tr(namedArgs: {
                    'date': DateFormat('yyyy-MM-dd').format(_selectedDay),
                    'slot': slotLabel,
                  }),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyAppointmentsPage()),
                  );
                },
                child: Text(
                  'my_appointments'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
