import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type;
  final String subtype;
  final String appointmentId;
  final String doctorName;
  final String doctorNameEn;
  final String doctorNameAr;
  final String doctorNameKu;
  final DateTime? appointmentAt;
  final String dateKey;
  final String titleEn;
  final String titleAr;
  final String titleKu;
  final String bodyEn;
  final String bodyAr;
  final String bodyKu;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.subtype,
    required this.appointmentId,
    required this.doctorName,
    required this.doctorNameEn,
    required this.doctorNameAr,
    required this.doctorNameKu,
    this.appointmentAt,
    required this.dateKey,
    required this.titleEn,
    required this.titleAr,
    required this.titleKu,
    required this.bodyEn,
    required this.bodyAr,
    required this.bodyKu,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> d) {
    return AppNotification(
      id: id,
      type: (d['type'] ?? 'appointment_reminder').toString(),
      subtype: (d['subtype'] ?? '').toString(),
      appointmentId: (d['appointmentId'] ?? '').toString(),
      doctorName: (d['doctorName'] ?? '').toString(),
      doctorNameEn: (d['doctorName_en'] ?? d['doctorName'] ?? '').toString(),
      doctorNameAr: (d['doctorName_ar'] ?? d['doctorName'] ?? '').toString(),
      doctorNameKu: (d['doctorName_ku'] ?? d['doctorName'] ?? '').toString(),
      appointmentAt: (d['appointmentAt'] as Timestamp?)?.toDate(),
      dateKey: (d['dateKey'] ?? '').toString(),
      titleEn: (d['titleEn'] ?? '').toString(),
      titleAr: (d['titleAr'] ?? '').toString(),
      titleKu: (d['titleKu'] ?? '').toString(),
      bodyEn: (d['bodyEn'] ?? '').toString(),
      bodyAr: (d['bodyAr'] ?? '').toString(),
      bodyKu: (d['bodyKu'] ?? '').toString(),
      isRead: (d['isRead'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Localized title — ku → ar → en fallback
  String localizedTitle(String lang) {
    if (lang == 'ar') return titleAr.isNotEmpty ? titleAr : titleEn;
    if (lang == 'ku') {
      if (titleKu.isNotEmpty) return titleKu;
      if (titleAr.isNotEmpty) return titleAr;
      return titleEn;
    }
    return titleEn;
  }

  // Localized body — ku → ar → en fallback
  String localizedBody(String lang) {
    if (lang == 'ar') return bodyAr.isNotEmpty ? bodyAr : bodyEn;
    if (lang == 'ku') {
      if (bodyKu.isNotEmpty) return bodyKu;
      if (bodyAr.isNotEmpty) return bodyAr;
      return bodyEn;
    }
    return bodyEn;
  }
}
