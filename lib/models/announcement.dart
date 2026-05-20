import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String titleEn;
  final String titleAr;
  final String titleKu;
  final String bodyEn;
  final String bodyAr;
  final String bodyKu;
  final String type;
  final String severity;
  final int priority;
  final bool active;
  final bool dismissible;
  final DateTime startAt;
  final DateTime endAt;
  final int version;
  final String? ctaTextEn;
  final String? ctaTextAr;
  final String? ctaTextKu;
  final String? ctaLink;
  final String? imageUrl;
  // Future province targeting — null means show to all provinces
  final List<String>? targetProvinceKeys;

  const Announcement({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.titleKu,
    required this.bodyEn,
    required this.bodyAr,
    required this.bodyKu,
    required this.type,
    required this.severity,
    required this.priority,
    required this.active,
    required this.dismissible,
    required this.startAt,
    required this.endAt,
    required this.version,
    this.ctaTextEn,
    this.ctaTextAr,
    this.ctaTextKu,
    this.ctaLink,
    this.imageUrl,
    this.targetProvinceKeys,
  });

  factory Announcement.fromMap(String docId, Map<String, dynamic> d) {
    final targeting = d['targeting'] as Map<String, dynamic>?;
    return Announcement(
      id: docId,
      titleEn: (d['title_en'] ?? '').toString(),
      titleAr: (d['title_ar'] ?? '').toString(),
      titleKu: (d['title_ku'] ?? '').toString(),
      bodyEn: (d['body_en'] ?? '').toString(),
      bodyAr: (d['body_ar'] ?? '').toString(),
      bodyKu: (d['body_ku'] ?? '').toString(),
      type: (d['type'] ?? 'info').toString(),
      severity: (d['severity'] ?? 'low').toString(),
      priority: (d['priority'] as num?)?.toInt() ?? 50,
      active: (d['active'] as bool?) ?? false,
      dismissible: (d['dismissible'] as bool?) ?? true,
      startAt: (d['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (d['endAt'] as Timestamp?)?.toDate() ?? DateTime(2099),
      version: (d['version'] as num?)?.toInt() ?? 1,
      ctaTextEn: d['ctaText_en']?.toString(),
      ctaTextAr: d['ctaText_ar']?.toString(),
      ctaTextKu: d['ctaText_ku']?.toString(),
      ctaLink: d['ctaLink']?.toString(),
      imageUrl: d['imageUrl']?.toString(),
      targetProvinceKeys: (targeting?['provinceKeys'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  // Localized title: ku → ar → en fallback chain
  String localizedTitle(String lang) {
    if (lang == 'ar') return titleAr.isNotEmpty ? titleAr : titleEn;
    if (lang == 'ku') {
      if (titleKu.isNotEmpty) return titleKu;
      if (titleAr.isNotEmpty) return titleAr;
      return titleEn;
    }
    return titleEn;
  }

  // Localized body: ku → ar → en fallback chain
  String localizedBody(String lang) {
    if (lang == 'ar') return bodyAr.isNotEmpty ? bodyAr : bodyEn;
    if (lang == 'ku') {
      if (bodyKu.isNotEmpty) return bodyKu;
      if (bodyAr.isNotEmpty) return bodyAr;
      return bodyEn;
    }
    return bodyEn;
  }

  // Localized CTA label: ku → ar → en fallback chain
  String? localizedCtaText(String lang) {
    if (lang == 'ar') {
      return (ctaTextAr?.isNotEmpty ?? false) ? ctaTextAr : ctaTextEn;
    }
    if (lang == 'ku') {
      if (ctaTextKu?.isNotEmpty ?? false) return ctaTextKu;
      if (ctaTextAr?.isNotEmpty ?? false) return ctaTextAr;
      return ctaTextEn;
    }
    return ctaTextEn;
  }

  // SharedPreferences key that encodes both id and version.
  // Bumping version in Firestore re-surfaces a previously dismissed card.
  String get dismissKey => '${id}_v$version';
}
