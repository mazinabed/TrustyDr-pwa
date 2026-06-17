import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/patient/confirm_booking_modal.dart';
import 'package:trustydr/pages/patient/my_appointments_page.dart'
    show MyAppointmentsPage;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
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

class _SlotEntry {
  final String label;
  final String slotId;
  const _SlotEntry(this.label, this.slotId);
}

class _DoctorTimeSlotState extends State<DoctorTimeSlot> {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  DateTime _calendarLastDay = DateTime.now().add(const Duration(days: 60));
  bool _calendarInitialized = false;

  Map<String, dynamic>? _scheduleForDay;
  bool _loadingSchedule = true;

  Set<String> _takenSlotIds = {};
  bool _loadingUsage = true;

  int _capacityPerSlot = 1;

  DateTime _toBaghdadUtc(DateTime local) {
    return DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    ).subtract(const Duration(hours: 3));
  }

  DateTime _parseHm(String hm, DateTime base) {
    final parts = hm.split(':');
    return _toBaghdadUtc(DateTime(
      base.year,
      base.month,
      base.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    ));
  }

  String _formatHm(DateTime utcDt) {
    final baghdadLocal = utcDt.toUtc().add(const Duration(hours: 3));
    final h = baghdadLocal.hour % 12 == 0 ? 12 : baghdadLocal.hour % 12;
    final m = baghdadLocal.minute.toString().padLeft(2, '0');
    final ampm = baghdadLocal.hour >= 12 ? 'PM' : 'AM';
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
    });

    try {
      final weekday = _selectedDay.weekday;
      final qs = await _fs
          .collection('schedules')
          .where('centerId', isEqualTo: widget.centerId)
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('dayOfWeek', isEqualTo: weekday)
          .where('status', isEqualTo: 'published')
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
          _calendarInitialized = true;
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

      final maxDays = (data['maxFutureDays'] as int?) ?? 60;
      final now = DateTime.now();
      final todayNorm = DateTime(now.year, now.month, now.day);
      DateTime calEnd = todayNorm.add(Duration(days: maxDays));
      final validToTs = data['validTo'];
      if (validToTs is Timestamp) {
        final vtDate = validToTs.toDate();
        final vtNorm = DateTime(vtDate.year, vtDate.month, vtDate.day);
        if (vtNorm.isBefore(calEnd)) calEnd = vtNorm;
      }
      // calEnd must never be before today (expired validTo edge case)
      if (calEnd.isBefore(todayNorm)) calEnd = todayNorm;

      final calEndNorm = DateTime(calEnd.year, calEnd.month, calEnd.day);
      final selNorm =
          DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

      setState(() {
        _calendarLastDay = calEnd;
        if (selNorm.isAfter(calEndNorm)) {
          _selectedDay = todayNorm;
          _focusedDay = todayNorm;
          _scheduleForDay = null;
        }
        _calendarInitialized = true;
        _loadingSchedule = false;
      });

      await _loadUsageForSelectedDate();
    } catch (_) {
      setState(() {
        _scheduleForDay = null;
        _capacityPerSlot = 1;
        _loadingSchedule = false;
        _loadingUsage = false;
        _calendarInitialized = true;
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
      _takenSlotIds = {};
    });
    try {
      // Build slot IDs from the schedule — no list query needed.
      // Per-slot get() checks slot_locks/{slotId} directly.
      //   • no lock doc  → slot is available
      //   • lock exists  → slot is taken (regardless of who locked it)
      final entries = _buildSlotEntries();
      if (entries.isEmpty) {
        if (mounted) setState(() => _loadingUsage = false);
        return;
      }

      final futures = entries.map((entry) async {
        try {
          final snap =
              await _fs.collection('slot_locks').doc(entry.slotId).get();
          return snap.exists ? entry.slotId : null;
        } catch (_) {
          return entry.slotId;
        }
      });

      final results = await Future.wait(futures);
      final ids = results.whereType<String>().toSet();
      if (mounted) {
        setState(() {
          _takenSlotIds = ids;
          _loadingUsage = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  bool _isDateEnabled(DateTime day) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final dayNorm = DateTime(day.year, day.month, day.day);
    final lastNorm = DateTime(
        _calendarLastDay.year, _calendarLastDay.month, _calendarLastDay.day);
    return !dayNorm.isBefore(todayNorm) && !dayNorm.isAfter(lastNorm);
  }

  String _calendarLocale() {
    final lang = context.locale.languageCode;
    return (lang == 'ar' || lang == 'ku') ? 'ar' : 'en';
  }

  String _localizeSlotLabel(String label) {
    final lang = context.locale.languageCode;
    if (lang != 'ar' && lang != 'ku') return label;
    return label.replaceAll('AM', 'ص').replaceAll('PM', 'م');
  }

  String _arabicMonthOrdinal(int month) {
    const ordinals = [
      '',
      'الشهر الأول',
      'الشهر الثاني',
      'الشهر الثالث',
      'الشهر الرابع',
      'الشهر الخامس',
      'الشهر السادس',
      'الشهر السابع',
      'الشهر الثامن',
      'الشهر التاسع',
      'الشهر العاشر',
      'الشهر الحادي عشر',
      'الشهر الثاني عشر',
    ];
    return (month >= 1 && month <= 12) ? ordinals[month] : '';
  }

  List<_SlotEntry> _buildSlotEntries() {
    if (_scheduleForDay == null) return [];
    final validToTs = _scheduleForDay!['validTo'];
    if (validToTs is Timestamp) {
      final vtDate = validToTs.toDate();
      final sel =
          DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      final vt = DateTime(vtDate.year, vtDate.month, vtDate.day);
      if (sel.isAfter(vt)) return [];
    }
    final start = _parseHm(_scheduleForDay!['startTime'], _selectedDay);
    final end = _parseHm(_scheduleForDay!['endTime'], _selectedDay);
    final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;
    final scheduleId = (_scheduleForDay!['scheduleId'] ?? '').toString();
    final entries = <_SlotEntry>[];
    DateTime cur = start;
    while (cur.isBefore(end)) {
      final slotId = '${scheduleId}_${cur.millisecondsSinceEpoch}';
      entries.add(_SlotEntry(_formatHm(cur), slotId));
      cur = cur.add(Duration(minutes: dur));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'select_time'.tr(),
          style: appBarTitleTextStyle.copyWith(
            color: PatientAppColors.brandIndigo,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: PatientAppColors.brandIndigo),
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
            if (!_calendarInitialized)
              const SizedBox(
                height: 340,
                child: Center(
                  child: CircularProgressIndicator(
                    color: PatientAppColors.brandIndigo,
                  ),
                ),
              )
            else
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
                  lastDay: _calendarLastDay,
                  locale: _calendarLocale(),
                  daysOfWeekHeight: 24,
                  focusedDay: _focusedDay,
                  currentDay: DateTime.now(),
                  enabledDayPredicate: _isDateEnabled,
                  selectedDayPredicate: (d) =>
                      d.year == _selectedDay.year &&
                      d.month == _selectedDay.month &&
                      d.day == _selectedDay.day,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: PatientAppColors.brandIndigo.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: PatientAppColors.brandIndigo,
                      shape: BoxShape.circle,
                    ),
                    disabledTextStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      if (_calendarLocale() != 'ar') return null;
                      final name = DateFormat('EEEE', 'ar').format(day);
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                    headerTitleBuilder: (context, day) {
                      if (_calendarLocale() != 'ar') return null;
                      final monthYear =
                          DateFormat('MMMM yyyy', 'ar').format(day);
                      final ordinal = _arabicMonthOrdinal(day.month);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            monthYear,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            ordinal,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                  onDaySelected: (sel, foc) async {
                    if (!_isDateEnabled(sel)) {
                      setState(() {
                        _scheduleForDay = null;
                        _loadingSchedule = false;
                        _loadingUsage = false;
                        _takenSlotIds = {};
                      });
                      return;
                    }
                    setState(() {
                      _selectedDay = sel;
                      _focusedDay = foc;
                    });
                    await _loadScheduleForSelectedDay();
                  },
                  onPageChanged: (foc) {
                    final lastNorm = DateTime(_calendarLastDay.year,
                        _calendarLastDay.month, _calendarLastDay.day);
                    setState(() {
                      _focusedDay = foc.isAfter(lastNorm) ? lastNorm : foc;
                    });
                  },
                ),
              ),
            const SizedBox(height: 10),
            if (_loadingSchedule)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: PatientAppColors.brandIndigo,
                  ),
                ),
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
    if (_loadingUsage) {
      return const Center(
        child: CircularProgressIndicator(
          color: PatientAppColors.brandIndigo,
        ),
      );
    }

    final entries = _buildSlotEntries();

    if (entries.isEmpty) {
      return Center(
        child: Text('no_available_slots'.tr(), style: greyNormalTextStyle),
      );
    }

    return Padding(
      padding: EdgeInsets.all(fixPadding * 2),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: entries.map((entry) {
          final label = entry.label;
          final isFull = _takenSlotIds.contains(entry.slotId);

          if (isFull) {
            return Opacity(
              opacity: 0.55,
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'slot_booked'.tr(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _onPickSlot(label),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: PatientAppColors.brandIndigo, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(_localizeSlotLabel(label),
                    style: primaryColorNormalTextStyle),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _to24Hour(String label) {
    final parsed = DateFormat('h:mm a', 'en').parse(label);
    return DateFormat('HH:mm', 'en')
        .format(parsed); // 'en' prevents Arabic-Indic digits
  }

  Future<void> _onPickSlot(String slotLabel) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login_to_book'.tr())),
        );
        return;
      }

      if (!mounted) return;

      final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;
      final slotStart = _parseHm(_to24Hour(slotLabel), _selectedDay);
      final slotId =
          '${(_scheduleForDay!['scheduleId'] ?? '')}_${slotStart.millisecondsSinceEpoch}';

      if (_takenSlotIds.contains(slotId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('slot_full'.tr())),
        );
        return;
      }

      final locale0 = context.locale.languageCode;
      final prettyDate = (locale0 == 'ar' || locale0 == 'ku')
          ? DateFormat('d / M / yyyy').format(_selectedDay)
          : DateFormat('EEE, MMM d, yyyy').format(_selectedDay);
      final displaySlot = _localizeSlotLabel(slotLabel);
      final sure = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('confirm_booking'.tr()),
          content: Text(
            'confirm_booking_message'.tr(namedArgs: {
              'date': prettyDate,
              'slot': displaySlot,
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: PatientAppColors.brandIndigo),
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
            (schedule['clinicName_ar'] ?? schedule['clinicName_en'] ?? '')
                .toString();
      } else if (lang == 'ku') {
        clinicName =
            (schedule['clinicName_ku'] ?? schedule['clinicName_en'] ?? '')
                .toString();
      } else {
        clinicName = (schedule['clinicName_en'] ?? schedule['clinicName'] ?? '')
            .toString();
      }
      final provinceKey = (schedule['provinceKey'] ?? '').toString();
      final cityKey = (schedule['cityKey'] ?? '').toString();

      if (sure != true) return;
      if (!mounted) return;

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
          clinicName: clinicName,
          date: _selectedDay,
          slotLabel: slotLabel,
          capacityPerSlot: _capacityPerSlot,
          centerId: centerId,
          provinceKey: provinceKey,
          cityKey: cityKey,
        ),
      );

      if (wasBooked == true && mounted) {
        await _loadUsageForSelectedDate();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PatientAppColors.brandIndigo,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'appointment_booked_message'.tr(namedArgs: {
                      'date': DateFormat('yyyy-MM-dd').format(_selectedDay),
                      'slot': displaySlot,
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
                    style: const TextStyle(
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_generic'.tr())),
        );
      }
    }
  }
}
