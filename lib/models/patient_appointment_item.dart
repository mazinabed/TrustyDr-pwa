import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PatientAppointmentType { doctor, laboratory, imaging }

enum PatientAppointmentStatus {
  pendingConfirmation,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  missed,
}

/// Unified presentation model for both doctor appointments and patient-self-booked
/// lab/imaging clinical_requests.
///
/// All localized fields are stored as en/ar/ku variants; call [providerName],
/// [serviceLabel], [locationLabel] with the current language code to pick the
/// right one. The UI never needs to know which Firestore collection produced this.
class PatientAppointmentItem {
  const PatientAppointmentItem({
    required this.sourceId,
    required this.type,
    required this.providerNameEn,
    required this.providerNameAr,
    required this.providerNameKu,
    this.providerImage,
    required this.serviceLabelEn,
    required this.serviceLabelAr,
    required this.serviceLabelKu,
    required this.appointmentDateTime,
    required this.status,
    this.locationLabelEn,
    this.locationLabelAr,
    this.locationLabelKu,
    this.addressLabelEn,
    this.addressLabelAr,
    this.addressLabelKu,
    // Action routing fields
    this.timeLabel,
    this.slotId,
    this.doctorId,
    this.specialtyKey,
    this.specialtyNameEn,
    this.specialtyNameAr,
    this.specialtyNameKu,
    this.centerId,
    this.provinceKey,
    this.cityKey,
    // Lab action routing fields
    this.labId,
    this.specialtyId,
  });

  final String sourceId;
  final PatientAppointmentType type;

  // Provider identity
  final String providerNameEn;
  final String providerNameAr;
  final String providerNameKu;
  final String? providerImage;

  // Service / specialty
  final String serviceLabelEn;
  final String serviceLabelAr;
  final String serviceLabelKu;

  final DateTime appointmentDateTime;

  // Doctor appointments: raw time string from Firestore (e.g. "10:30 AM").
  // Lab appointments: null — format from appointmentDateTime at render time.
  final String? timeLabel;

  final PatientAppointmentStatus status;

  // Facility name (doctor: clinic name; lab: provider name for location row)
  final String? locationLabelEn;
  final String? locationLabelAr;
  final String? locationLabelKu;

  // Street address (doctor: clinic address; lab: providerAddress)
  final String? addressLabelEn;
  final String? addressLabelAr;
  final String? addressLabelKu;

  // Action routing — doctor appointments
  final String? slotId;
  final String? doctorId;
  final String? specialtyKey;
  final String? specialtyNameEn;
  final String? specialtyNameAr;
  final String? specialtyNameKu;
  final String? centerId;
  final String? provinceKey;
  final String? cityKey;

  // Action routing — lab/imaging appointments
  final String? labId;
  final String? specialtyId;

  // ── Localized getters ────────────────────────────────────────────────────────

  String providerName(String lang) {
    if (lang == 'ar' && providerNameAr.isNotEmpty) return providerNameAr;
    if (lang == 'ku' && providerNameKu.isNotEmpty) return providerNameKu;
    return providerNameEn;
  }

  String serviceLabel(String lang) {
    if (lang == 'ar' && serviceLabelAr.isNotEmpty) return serviceLabelAr;
    if (lang == 'ku' && serviceLabelKu.isNotEmpty) return serviceLabelKu;
    return serviceLabelEn;
  }

  String? locationLabel(String lang) {
    final s = lang == 'ar'
        ? (locationLabelAr ?? locationLabelEn)
        : lang == 'ku'
            ? (locationLabelKu ?? locationLabelEn)
            : locationLabelEn;
    return (s != null && s.isNotEmpty) ? s : null;
  }

  String? addressLabel(String lang) {
    final s = lang == 'ar'
        ? (addressLabelAr ?? addressLabelEn)
        : lang == 'ku'
            ? (addressLabelKu ?? addressLabelEn)
            : addressLabelEn;
    return (s != null && s.isNotEmpty) ? s : null;
  }

  // ── Status helpers ───────────────────────────────────────────────────────────

  String statusKey() {
    switch (status) {
      case PatientAppointmentStatus.pendingConfirmation:
        return 'pendingConfirmation';
      case PatientAppointmentStatus.confirmed:
        return 'confirmed';
      case PatientAppointmentStatus.checkedIn:
        return 'checkedIn';
      case PatientAppointmentStatus.completed:
        return 'completed';
      case PatientAppointmentStatus.cancelled:
        return 'cancelled';
      case PatientAppointmentStatus.missed:
        return 'missed';
    }
  }

  Color statusColor() {
    switch (status) {
      case PatientAppointmentStatus.confirmed:
        return const Color(0xFF4CAF50);
      case PatientAppointmentStatus.checkedIn:
        return const Color(0xFF5CC6BA);
      case PatientAppointmentStatus.completed:
        return const Color(0xFF2196F3);
      case PatientAppointmentStatus.cancelled:
      case PatientAppointmentStatus.missed:
        return const Color(0xFFF44336);
      case PatientAppointmentStatus.pendingConfirmation:
        return const Color(0xFFFF9800);
    }
  }

  bool get isUpcoming =>
      status == PatientAppointmentStatus.pendingConfirmation ||
      status == PatientAppointmentStatus.confirmed ||
      status == PatientAppointmentStatus.checkedIn;

  bool get isPast => status == PatientAppointmentStatus.completed;

  bool get isCancelled =>
      status == PatientAppointmentStatus.cancelled ||
      status == PatientAppointmentStatus.missed;

  // ── Mappers ──────────────────────────────────────────────────────────────────

  /// Maps an [appointments] Firestore document.
  static PatientAppointmentItem fromAppointment(
      Map<String, dynamic> data, String id) {
    return PatientAppointmentItem(
      sourceId: id,
      type: PatientAppointmentType.doctor,
      providerNameEn:
          _str(data, 'doctorName_en') ?? _str(data, 'doctorName') ?? '',
      providerNameAr:
          _str(data, 'doctorName_ar') ?? _str(data, 'doctorName') ?? '',
      providerNameKu:
          _str(data, 'doctorName_ku') ?? _str(data, 'doctorName') ?? '',
      providerImage: data['doctorImage'] as String?,
      serviceLabelEn:
          _str(data, 'specialtyName_en') ?? _str(data, 'doctorType') ?? '',
      serviceLabelAr:
          _str(data, 'specialtyName_ar') ?? _str(data, 'doctorType') ?? '',
      serviceLabelKu:
          _str(data, 'specialtyName_ku') ?? _str(data, 'doctorType') ?? '',
      appointmentDateTime: _parseAppointmentDate(data),
      timeLabel: _str(data, 'time') ?? _str(data, 'slotTime'),
      status: _mapDoctorStatus(data['status'] as String? ?? ''),
      locationLabelEn: _str(data, 'clinicName_en') ?? _str(data, 'clinicName'),
      locationLabelAr: _str(data, 'clinicName_ar') ?? _str(data, 'clinicName'),
      locationLabelKu: _str(data, 'clinicName_ku') ?? _str(data, 'clinicName'),
      addressLabelEn:
          _str(data, 'clinicAddress_en') ?? _str(data, 'clinicAddress'),
      addressLabelAr:
          _str(data, 'clinicAddress_ar') ?? _str(data, 'clinicAddress'),
      addressLabelKu:
          _str(data, 'clinicAddress_ku') ?? _str(data, 'clinicAddress'),
      slotId: data['slotId'] as String?,
      doctorId: data['doctorId'] as String?,
      specialtyKey: data['specialtyKey'] as String?,
      specialtyNameEn: data['specialtyName_en'] as String?,
      specialtyNameAr: data['specialtyName_ar'] as String?,
      specialtyNameKu: data['specialtyName_ku'] as String?,
      centerId: data['centerId'] as String?,
      provinceKey: data['provinceKey'] as String?,
      cityKey: data['cityKey'] as String?,
    );
  }

  /// Maps a [clinical_requests] document (patient-self-booked, source='scheduled').
  static PatientAppointmentItem fromLabRequest(
      Map<String, dynamic> data, String id) {
    final serviceGroup =
        (data['serviceCategory'] as String? ?? 'laboratory').toLowerCase();
    final type = serviceGroup == 'imaging'
        ? PatientAppointmentType.imaging
        : PatientAppointmentType.laboratory;

    // Localized service name from snapshotted subTypeItems[0]
    String svcEn = '', svcAr = '', svcKu = '';
    final items = data['subTypeItems'];
    if (items is List && items.isNotEmpty) {
      final first = items.first as Map<String, dynamic>;
      svcEn = (first['nameEn'] ?? '').toString();
      svcAr = (first['nameAr'] ?? '').toString();
      svcKu = (first['nameKu'] ?? '').toString();
    }

    DateTime dt;
    final slot = data['slotStartAt'];
    if (slot is Timestamp) {
      dt = slot.toDate();
    } else {
      dt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final address = (data['providerAddress'] ?? '').toString();

    return PatientAppointmentItem(
      sourceId: id,
      type: type,
      providerNameEn: _str(data, 'providerName_en') ?? '',
      providerNameAr: _str(data, 'providerName_ar') ?? '',
      providerNameKu: _str(data, 'providerName_ku') ?? '',
      providerImage: data['providerImage'] as String?,
      serviceLabelEn: svcEn,
      serviceLabelAr: svcAr,
      serviceLabelKu: svcKu,
      appointmentDateTime: dt,
      timeLabel: null,
      status: _mapLabStatus(data['partnerStatus'] as String? ?? ''),
      locationLabelEn: address.isNotEmpty ? address : null,
      slotId: data['slotId'] as String?,
      centerId: data['centerId'] as String?,
      labId: data['partnerProviderId'] as String?,
      specialtyId: (items is List && items.isNotEmpty)
          ? ((items.first as Map<String, dynamic>)['id']?.toString())
          : null,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static String? _str(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isNotEmpty ? s : null;
  }

  static DateTime _parseAppointmentDate(Map<String, dynamic> data) {
    // appointmentAt is the canonical slot-start Timestamp written by the booking
    // flow. Check it first so the card and detail page always agree.
    final at = data['appointmentAt'];
    if (at is Timestamp) return at.toDate();
    // slotStartAt is used on newer records; fall back for older ones.
    final slot = data['slotStartAt'];
    if (slot is Timestamp) return slot.toDate();
    // date may be a Timestamp or a legacy display string — last-resort fallbacks.
    final d = data['date'];
    if (d is Timestamp) return d.toDate();
    if (d is String && d.isNotEmpty) {
      final dt = DateTime.tryParse(d);
      if (dt != null) return dt;
    }
    final dk = (data['dateKey'] as String? ?? '').trim();
    if (dk.isNotEmpty) {
      final dt = DateTime.tryParse(dk);
      if (dt != null) return dt;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static PatientAppointmentStatus _mapDoctorStatus(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return PatientAppointmentStatus.confirmed;
      case 'completed':
        return PatientAppointmentStatus.completed;
      case 'cancelled':
      case 'canceled':
        return PatientAppointmentStatus.cancelled;
      default:
        return PatientAppointmentStatus.pendingConfirmation;
    }
  }

  static PatientAppointmentStatus _mapLabStatus(String s) {
    switch (s.toLowerCase()) {
      case 'scheduled':
        return PatientAppointmentStatus.confirmed;
      case 'checkedin':
        return PatientAppointmentStatus.checkedIn;
      case 'processing':
      case 'completed':
        return PatientAppointmentStatus.completed;
      case 'cancelled':
      case 'canceled':
        return PatientAppointmentStatus.cancelled;
      case 'noshow':
        return PatientAppointmentStatus.missed;
      default:
        return PatientAppointmentStatus.pendingConfirmation;
    }
  }
}
