import 'package:cloud_firestore/cloud_firestore.dart';

class PatientReferralRequest {
  final String id;
  final String patientId;

  // Sender snapshot
  final String doctorId;
  final String doctorNameEn;
  final String doctorNameAr;
  final String doctorNameKu;
  final String doctorImage;
  final String doctorSpecialtyEn;
  final String doctorSpecialtyAr;
  final String doctorSpecialtyKu;
  final String centerId;
  final String centerNameEn;
  final String centerNameAr;
  final String centerNameKu;

  // Partner snapshot
  final String partnerProviderId;
  final String partnerNameEn;
  final String partnerNameAr;
  final String partnerNameKu;
  final String partnerImage;
  final String partnerPhone;
  final String partnerAddress;
  final String partnerCity;
  final String partnerProvince;
  final String partnerServiceGroup;

  // Requested service snapshot
  final String serviceNameEn;
  final String serviceNameAr;
  final String serviceNameKu;
  final String serviceGroup;

  // Clinical details
  final String instructions;
  final String urgency;

  // Live status (mirrored by onClinicalReferralStatusUpdated)
  final String partnerStatus;
  final String status;
  final String patientReleaseStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientReferralRequest({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorNameEn,
    required this.doctorNameAr,
    required this.doctorNameKu,
    required this.doctorImage,
    required this.doctorSpecialtyEn,
    required this.doctorSpecialtyAr,
    required this.doctorSpecialtyKu,
    required this.centerId,
    required this.centerNameEn,
    required this.centerNameAr,
    required this.centerNameKu,
    required this.partnerProviderId,
    required this.partnerNameEn,
    required this.partnerNameAr,
    required this.partnerNameKu,
    required this.partnerImage,
    required this.partnerPhone,
    required this.partnerAddress,
    required this.partnerCity,
    required this.partnerProvince,
    required this.partnerServiceGroup,
    required this.serviceNameEn,
    required this.serviceNameAr,
    required this.serviceNameKu,
    required this.serviceGroup,
    required this.instructions,
    required this.urgency,
    required this.partnerStatus,
    required this.status,
    required this.patientReleaseStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientReferralRequest.fromMap(String id, Map<String, dynamic> d) {
    String s(String key) => (d[key] ?? '').toString();
    return PatientReferralRequest(
      id: id,
      patientId: s('patientId'),
      doctorId: s('doctorId'),
      doctorNameEn: s('doctorName_en'),
      doctorNameAr: s('doctorName_ar'),
      doctorNameKu: s('doctorName_ku'),
      doctorImage: s('doctorImage'),
      doctorSpecialtyEn: s('doctorSpecialty_en'),
      doctorSpecialtyAr: s('doctorSpecialty_ar'),
      doctorSpecialtyKu: s('doctorSpecialty_ku'),
      centerId: s('centerId'),
      centerNameEn: s('centerName_en'),
      centerNameAr: s('centerName_ar'),
      centerNameKu: s('centerName_ku'),
      partnerProviderId: s('partnerProviderId'),
      partnerNameEn: s('partnerName_en'),
      partnerNameAr: s('partnerName_ar'),
      partnerNameKu: s('partnerName_ku'),
      partnerImage: s('partnerImage'),
      partnerPhone: s('partnerPhone'),
      partnerAddress: s('partnerAddress'),
      partnerCity: s('partnerCity'),
      partnerProvince: s('partnerProvince'),
      partnerServiceGroup: s('partnerServiceGroup'),
      serviceNameEn: s('serviceNameEn'),
      serviceNameAr: s('serviceNameAr'),
      serviceNameKu: s('serviceNameKu'),
      serviceGroup: s('serviceGroup'),
      instructions: s('instructions'),
      urgency: s('urgency'),
      partnerStatus: s('partnerStatus'),
      status: s('status'),
      patientReleaseStatus: s('patientReleaseStatus'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isReleased => patientReleaseStatus == 'released';

  String doctorName(String lang) {
    if (lang == 'ar') {
      return doctorNameAr.isNotEmpty ? doctorNameAr : doctorNameEn;
    }
    if (lang == 'ku') {
      if (doctorNameKu.isNotEmpty) return doctorNameKu;
      if (doctorNameAr.isNotEmpty) return doctorNameAr;
      return doctorNameEn;
    }
    return doctorNameEn;
  }

  String partnerName(String lang) {
    if (lang == 'ar') {
      return partnerNameAr.isNotEmpty ? partnerNameAr : partnerNameEn;
    }
    if (lang == 'ku') {
      if (partnerNameKu.isNotEmpty) return partnerNameKu;
      if (partnerNameAr.isNotEmpty) return partnerNameAr;
      return partnerNameEn;
    }
    return partnerNameEn;
  }

  String centerName(String lang) {
    if (lang == 'ar') {
      return centerNameAr.isNotEmpty ? centerNameAr : centerNameEn;
    }
    if (lang == 'ku') {
      if (centerNameKu.isNotEmpty) return centerNameKu;
      if (centerNameAr.isNotEmpty) return centerNameAr;
      return centerNameEn;
    }
    return centerNameEn;
  }

  String serviceName(String lang) {
    if (lang == 'ar') {
      return serviceNameAr.isNotEmpty ? serviceNameAr : serviceNameEn;
    }
    if (lang == 'ku') {
      if (serviceNameKu.isNotEmpty) return serviceNameKu;
      if (serviceNameAr.isNotEmpty) return serviceNameAr;
      return serviceNameEn;
    }
    return serviceNameEn;
  }

  String doctorSpecialty(String lang) {
    if (lang == 'ar') {
      return doctorSpecialtyAr.isNotEmpty
          ? doctorSpecialtyAr
          : doctorSpecialtyEn;
    }
    if (lang == 'ku') {
      if (doctorSpecialtyKu.isNotEmpty) return doctorSpecialtyKu;
      if (doctorSpecialtyAr.isNotEmpty) return doctorSpecialtyAr;
      return doctorSpecialtyEn;
    }
    return doctorSpecialtyEn;
  }
}
