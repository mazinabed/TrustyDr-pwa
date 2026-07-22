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
  final String clinicalRequestId;
  final bool isRead;
  final bool dismissed;
  final DateTime createdAt;

  // TrustyDr Workflow & Notification Platform, Phase 1+2 (see
  // NOTIFICATION_PLATFORM_PROGRESS.md) -- additive fields only present on
  // notifications written by the new Notification Engine. `category` is
  // empty for every pre-existing notification type (appointment reminders,
  // referrals, etc.), which have not migrated to the platform yet -- code
  // must not assume these are populated.
  final String category; // '' | 'timeline' | 'event'
  final String? workflowType;
  final String? entityType;
  final String? entityId;
  final String? currentStage;
  final bool isCompleted;
  final bool isCancelled;
  final String priority; // 'critical' | 'high' | 'normal' | 'low' | 'silent'
  final List<String> actions;
  final String? navigationRoute;
  final Map<String, dynamic>? navigationParams;
  // Legacy Marketplace field (predates the platform, kept for routing).
  final String marketplaceOrderId;

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
    this.clinicalRequestId = '',
    required this.isRead,
    this.dismissed = false,
    required this.createdAt,
    this.category = '',
    this.workflowType,
    this.entityType,
    this.entityId,
    this.currentStage,
    this.isCompleted = false,
    this.isCancelled = false,
    this.priority = 'normal',
    this.actions = const [],
    this.navigationRoute,
    this.navigationParams,
    this.marketplaceOrderId = '',
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
      clinicalRequestId: (d['clinicalRequestId'] ?? '').toString(),
      isRead: (d['isRead'] as bool?) ?? false,
      dismissed: (d['dismissed'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: (d['category'] ?? '').toString(),
      workflowType: (d['workflowType'] as String?),
      entityType: (d['entityType'] as String?),
      entityId: (d['entityId'] as String?),
      currentStage: (d['currentStage'] as String?),
      isCompleted: (d['isCompleted'] as bool?) ?? false,
      isCancelled: (d['isCancelled'] as bool?) ?? false,
      priority: (d['priority'] ?? 'normal').toString(),
      actions: (d['actions'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      navigationRoute: (d['navigationTarget'] is Map)
          ? (d['navigationTarget']['route'] as String?)
          : null,
      navigationParams: (d['navigationTarget'] is Map &&
              d['navigationTarget']['params'] is Map)
          ? Map<String, dynamic>.from(d['navigationTarget']['params'])
          : null,
      marketplaceOrderId: (d['marketplaceOrderId'] ?? '').toString(),
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
