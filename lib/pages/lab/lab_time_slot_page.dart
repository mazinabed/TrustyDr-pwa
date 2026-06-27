import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/pages/lab/confirm_lab_request_sheet.dart';

/// Date / slot picker for diagnostic provider (lab or imaging) bookings.
///
/// Mirrors [DoctorTimeSlot] but:
///   - queries schedules by doctorId = labId (the doctorId = labId convention)
///   - no visitType filter (labs don't use visitType)
///   - navigates to [ConfirmLabRequestSheet] on slot pick
class LabTimeSlotPage extends StatefulWidget {
  const LabTimeSlotPage({
    super.key,
    required this.labId,
    required this.centerId,
    required this.facilityName,
    required this.imageUrl,
    // serviceGroup: the provider's serviceGroup key ('laboratory' / 'imaging').
    required this.serviceGroup,
    // specialtyId: the specialties collection doc ID selected by the patient.
    required this.specialtyId,
    required this.serviceNameEn,
    required this.serviceNameAr,
    required this.serviceNameKu,
    this.providerNameEn = '',
    this.providerNameAr = '',
    this.providerNameKu = '',
    this.providerAddress = '',
    this.providerImage = '',
    this.providerPhone = '',
    // Catalog fields — present for catalog-backed bookings; empty for legacy.
    this.serviceId = '',
    this.subcategory = '',
    this.estimatedDurationMinutes,
    this.price,
  });

  final String labId;
  final String centerId;
  final String facilityName;
  final String imageUrl;
  final String serviceGroup;
  final String specialtyId;
  final String serviceNameEn;
  final String serviceNameAr;
  final String serviceNameKu;
  final String providerNameEn;
  final String providerNameAr;
  final String providerNameKu;
  final String providerAddress;
  final String providerImage;
  final String providerPhone;
  final String serviceId;
  final String subcategory;
  final int? estimatedDurationMinutes;
  final int? price;

  @override
  State<LabTimeSlotPage> createState() => _LabTimeSlotPageState();
}

class _LabSlotEntry {
  final String label;
  final String slotId;
  final DateTime slotStart;
  const _LabSlotEntry(this.label, this.slotId, this.slotStart);
}

class _LabTimeSlotPageState extends State<LabTimeSlotPage> {
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

  // ── Baghdad / UTC+3 helpers ──────────────────────────────────────────────

  DateTime _toBaghdadUtc(DateTime local) => DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
      ).subtract(const Duration(hours: 3));

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
    final baghdad = utcDt.toUtc().add(const Duration(hours: 3));
    final h = baghdad.hour % 12 == 0 ? 12 : baghdad.hour % 12;
    final m = baghdad.minute.toString().padLeft(2, '0');
    final ampm = baghdad.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String _localizeLabel(String label) {
    final lang = context.locale.languageCode;
    if (lang != 'ar' && lang != 'ku') return label;
    return label.replaceAll('AM', 'ص').replaceAll('PM', 'م');
  }

  @override
  void initState() {
    super.initState();
    _loadScheduleForSelectedDay();
  }

  // ── Schedule loading ─────────────────────────────────────────────────────

  Future<void> _loadScheduleForSelectedDay() async {
    setState(() {
      _loadingSchedule = true;
      _loadingUsage = true;
      _scheduleForDay = null;
    });

    try {
      final weekday = _selectedDay.weekday;
      // doctorId = labId: lab schedules use the lab's own ID in the doctorId field.
      // NO visitType filter — labs don't set visitType on schedules.
      final qs = await _fs
          .collection('schedules')
          .where('centerId', isEqualTo: widget.centerId)
          .where('doctorId', isEqualTo: widget.labId)
          .where('dayOfWeek', isEqualTo: weekday)
          .where('status', isEqualTo: 'published')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) {
        setState(() {
          _scheduleForDay = null;
          _loadingSchedule = false;
          _loadingUsage = false;
          _calendarInitialized = true;
        });
        return;
      }

      final doc = qs.docs.first;
      final data = doc.data();
      _scheduleForDay = {...data, 'scheduleId': doc.id};

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
        _loadingSchedule = false;
        _loadingUsage = false;
        _calendarInitialized = true;
      });
    }
  }

  Future<void> _loadUsageForSelectedDate() async {
    setState(() {
      _loadingUsage = true;
      _takenSlotIds = {};
    });
    try {
      final entries = _buildSlotEntries();
      if (entries.isEmpty) {
        if (mounted) setState(() => _loadingUsage = false);
        return;
      }
      final futures = entries.map((e) async {
        try {
          final snap = await _fs.collection('slot_locks').doc(e.slotId).get();
          return snap.exists ? e.slotId : null;
        } catch (_) {
          return e.slotId;
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
    } catch (_) {
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  // ── Slot generation ──────────────────────────────────────────────────────

  List<_LabSlotEntry> _buildSlotEntries() {
    if (_scheduleForDay == null) return [];
    final validToTs = _scheduleForDay!['validTo'];
    if (validToTs is Timestamp) {
      final vtDate = validToTs.toDate();
      final sel =
          DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      final vt = DateTime(vtDate.year, vtDate.month, vtDate.day);
      if (sel.isAfter(vt)) return [];
    }

    final scheduleId = (_scheduleForDay!['scheduleId'] ?? '').toString();
    final start = _parseHm(_scheduleForDay!['startTime'], _selectedDay);
    final end = _parseHm(_scheduleForDay!['endTime'], _selectedDay);
    final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;

    // Break windows (list of {start, end} maps)
    final rawBreaks = (_scheduleForDay!['breaks'] as List? ?? []);

    final entries = <_LabSlotEntry>[];
    DateTime cur = start;
    while (cur.isBefore(end)) {
      final slotStart = cur;
      cur = cur.add(Duration(minutes: dur));

      // Skip slots that fall entirely within a break window
      bool inBreak = false;
      for (final b in rawBreaks) {
        if (b is Map) {
          final bs = b['start'] as String?;
          final be = b['end'] as String?;
          if (bs != null && be != null) {
            final breakStart = _parseHm(bs, _selectedDay);
            final breakEnd = _parseHm(be, _selectedDay);
            if (!slotStart.isBefore(breakStart) &&
                slotStart.isBefore(breakEnd)) {
              inBreak = true;
              break;
            }
          }
        }
      }
      if (inBreak) continue;

      final slotId = '${scheduleId}_${slotStart.millisecondsSinceEpoch}';
      entries.add(_LabSlotEntry(_formatHm(slotStart), slotId, slotStart));
    }
    return entries;
  }

  // ── Calendar helpers ─────────────────────────────────────────────────────

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

  // ── Slot tap ─────────────────────────────────────────────────────────────

  Future<void> _onPickSlot(_LabSlotEntry entry) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('login_to_book'.tr())),
      );
      return;
    }
    if (_takenSlotIds.contains(entry.slotId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('slot_full'.tr())),
      );
      return;
    }

    final dur = (_scheduleForDay!['slotDurationMinutes'] ?? 20) as int;
    final scheduleId = (_scheduleForDay!['scheduleId'] ?? '').toString();

    final wasBooked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmLabRequestSheet(
        labId: widget.labId,
        centerId: widget.centerId,
        facilityName: widget.facilityName,
        imageUrl: widget.imageUrl,
        scheduleId: scheduleId,
        slotId: entry.slotId,
        slotStartAt: entry.slotStart,
        slotDurationMinutes: dur,
        date: _selectedDay,
        slotLabel: entry.label,
        serviceGroup: widget.serviceGroup,
        specialtyId: widget.specialtyId,
        serviceNameEn: widget.serviceNameEn,
        serviceNameAr: widget.serviceNameAr,
        serviceNameKu: widget.serviceNameKu,
        providerNameEn: widget.providerNameEn,
        providerNameAr: widget.providerNameAr,
        providerNameKu: widget.providerNameKu,
        providerAddress: widget.providerAddress,
        providerImage: widget.providerImage,
        providerPhone: widget.providerPhone,
        serviceId: widget.serviceId,
        subcategory: widget.subcategory,
        estimatedDurationMinutes: widget.estimatedDurationMinutes,
        price: widget.price,
      ),
    );

    if (wasBooked == true && mounted) {
      await _loadUsageForSelectedDate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PatientAppColors.brandTeal,
          content: Text(
            'lab_booking.request_scheduled'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  String get _localizedServiceName {
    final lang = context.locale.languageCode;
    if (lang == 'ar' && widget.serviceNameAr.isNotEmpty) {
      return widget.serviceNameAr;
    }
    if (lang == 'ku' && widget.serviceNameKu.isNotEmpty) {
      return widget.serviceNameKu;
    }
    return widget.serviceNameEn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'select_time'.tr(),
          style: const TextStyle(
            color: PatientAppColors.brandTeal,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PatientAppColors.brandTeal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Provider header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        PatientAppColors.brandTeal.withValues(alpha: 0.1),
                    backgroundImage: widget.imageUrl.isNotEmpty
                        ? NetworkImage(widget.imageUrl)
                        : null,
                    child: widget.imageUrl.isEmpty
                        ? Icon(Icons.biotech_rounded,
                            color: PatientAppColors.brandTeal, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.facilityName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _localizedServiceName,
                          style: TextStyle(
                            fontSize: 13,
                            color: PatientAppColors.brandTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Calendar ─────────────────────────────────────────────────
            if (!_calendarInitialized)
              const SizedBox(
                height: 340,
                child: Center(
                  child: CircularProgressIndicator(
                      color: PatientAppColors.brandTeal),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
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
                      color: PatientAppColors.brandTeal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: PatientAppColors.brandTeal,
                      shape: BoxShape.circle,
                    ),
                    disabledTextStyle:
                        const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  onDaySelected: (sel, foc) async {
                    if (!_isDateEnabled(sel)) return;
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

            // ── Slot grid ────────────────────────────────────────────────
            if (_loadingSchedule)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                      color: PatientAppColors.brandTeal),
                ),
              )
            else if (_scheduleForDay == null)
              SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    'lab_booking.no_schedule'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              _buildSlotGrid(),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    if (_loadingUsage) {
      return const Center(
        child: CircularProgressIndicator(color: PatientAppColors.brandTeal),
      );
    }

    final entries = _buildSlotEntries();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'no_available_slots'.tr(),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: entries.map((entry) {
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
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(height: 4),
                    Text(
                      'slot_booked'.tr(),
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 11),
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
              onTap: () => _onPickSlot(entry),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: PatientAppColors.brandTeal, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _localizeLabel(entry.label),
                  style: const TextStyle(
                    color: PatientAppColors.brandTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
