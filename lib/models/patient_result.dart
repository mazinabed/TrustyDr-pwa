import 'package:cloud_firestore/cloud_firestore.dart';

class PatientSubTypeItem {
  final String id;
  final bool isCustom;
  final String? nameEn;
  final String? nameAr;
  final String? nameKu;

  const PatientSubTypeItem({
    required this.id,
    required this.isCustom,
    this.nameEn,
    this.nameAr,
    this.nameKu,
  });

  String displayName(String lang) {
    if (!isCustom) return resolveTestKeyLabel(id, lang);
    if (lang == 'ar' && (nameAr?.isNotEmpty ?? false)) return nameAr!;
    if (lang == 'ku' && (nameKu?.isNotEmpty ?? false)) return nameKu!;
    return nameEn ?? id;
  }

  factory PatientSubTypeItem.fromMap(dynamic raw) {
    if (raw is String) return PatientSubTypeItem(id: raw, isCustom: false);
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return PatientSubTypeItem(
        id: (m['id'] as String?) ?? '',
        isCustom: (m['isCustom'] as bool?) ?? false,
        nameEn: m['nameEn'] as String?,
        nameAr: m['nameAr'] as String?,
        nameKu: m['nameKu'] as String?,
      );
    }
    return const PatientSubTypeItem(id: '', isCustom: false);
  }
}

class PatientResultItem {
  final String id;
  final bool isCustom;
  final String? nameEn;
  final String? nameAr;
  final String? nameKu;
  final String valueDisplay;
  final String? unit;
  final String? note;

  const PatientResultItem({
    required this.id,
    required this.isCustom,
    this.nameEn,
    this.nameAr,
    this.nameKu,
    required this.valueDisplay,
    this.unit,
    this.note,
  });

  String displayName(String lang) {
    if (!isCustom) return resolveTestKeyLabel(id, lang);
    if (lang == 'ar' && (nameAr?.isNotEmpty ?? false)) return nameAr!;
    if (lang == 'ku' && (nameKu?.isNotEmpty ?? false)) return nameKu!;
    return nameEn ?? id;
  }

  factory PatientResultItem.fromMap(dynamic raw) {
    if (raw is! Map) {
      return const PatientResultItem(id: '', isCustom: false, valueDisplay: '');
    }
    final m = Map<String, dynamic>.from(raw);
    final valueType = (m['valueType'] as String?) ?? 'text';
    final String valueDisplay;
    switch (valueType) {
      case 'number':
        final v = (m['value'] as num?)?.toDouble();
        valueDisplay = v != null ? _formatNum(v) : '';
      case 'numberPair':
        final vp = (m['valuePrimary'] as num?)?.toDouble();
        final vs = (m['valueSecondary'] as num?)?.toDouble();
        if (vp != null && vs != null) {
          valueDisplay = '${_formatNum(vp)} / ${_formatNum(vs)}';
        } else if (vp != null) {
          valueDisplay = _formatNum(vp);
        } else {
          valueDisplay = '';
        }
      default:
        valueDisplay = (m['valueText'] as String?) ?? '';
    }
    return PatientResultItem(
      id: (m['id'] as String?) ?? '',
      isCustom: (m['isCustom'] as bool?) ?? false,
      nameEn: m['nameEn'] as String?,
      nameAr: m['nameAr'] as String?,
      nameKu: m['nameKu'] as String?,
      valueDisplay: valueDisplay,
      unit: m['unit'] as String?,
      note: m['note'] as String?,
    );
  }

  static String _formatNum(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

class PatientAttachment {
  final String id;
  final String fileName;
  final String mimeType;
  final String storagePath;
  final DateTime? uploadedAt;

  const PatientAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.storagePath,
    this.uploadedAt,
  });

  factory PatientAttachment.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final ts = d['uploadedAt'];
    return PatientAttachment(
      id: doc.id,
      fileName: (d['fileName'] as String?) ?? '',
      mimeType: (d['mimeType'] as String?) ?? '',
      storagePath: (d['storagePath'] as String?) ?? '',
      uploadedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class PatientResult {
  final String id;
  final String serviceCategory;
  final List<PatientSubTypeItem> subTypeItems;
  final List<PatientResultItem> resultItems;
  final String doctorName;
  final String dateKey;
  final DateTime? releasedAt;
  final String? doctorNote;
  final String? resultNote;
  final bool releaseResultNote;
  final int attachmentCount;
  // Provider/lab name — read from existing Firestore fields (no schema change)
  final String providerNameEn;
  final String providerNameAr;
  final String providerNameKu;

  const PatientResult({
    required this.id,
    required this.serviceCategory,
    required this.subTypeItems,
    required this.resultItems,
    required this.doctorName,
    required this.dateKey,
    this.releasedAt,
    this.doctorNote,
    this.resultNote,
    required this.releaseResultNote,
    required this.attachmentCount,
    this.providerNameEn = '',
    this.providerNameAr = '',
    this.providerNameKu = '',
  });

  factory PatientResult.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final releaseResultNote = (d['releaseResultNote'] as bool?) ?? false;
    return PatientResult(
      id: doc.id,
      serviceCategory: (d['serviceCategory'] as String?) ?? '',
      subTypeItems: d['subTypeItems'] is List
          ? (d['subTypeItems'] as List)
              .map(PatientSubTypeItem.fromMap)
              .where((e) => e.id.isNotEmpty)
              .toList()
          : (d['subType'] is String && (d['subType'] as String).isNotEmpty)
              ? [
                  PatientSubTypeItem(
                      id: d['subType'] as String, isCustom: false)
                ]
              : const [],
      resultItems: d['resultItems'] is List
          ? (d['resultItems'] as List)
              .map(PatientResultItem.fromMap)
              .where((e) => e.id.isNotEmpty)
              .toList()
          : const [],
      doctorName: (d['doctorName'] as String?) ?? '',
      dateKey: (d['dateKey'] as String?) ?? '',
      releasedAt: (d['releasedAt'] as Timestamp?)?.toDate(),
      doctorNote: d['doctorNote'] as String?,
      resultNote: releaseResultNote ? d['resultNote'] as String? : null,
      releaseResultNote: releaseResultNote,
      attachmentCount: (d['attachmentCount'] as int?) ?? 0,
      // Prefer providerName_* (patient self-booked), fall back to partnerName_* (doctor-referred)
      providerNameEn:
          (d['providerName_en'] ?? d['partnerName_en'] ?? '').toString(),
      providerNameAr:
          (d['providerName_ar'] ?? d['partnerName_ar'] ?? '').toString(),
      providerNameKu:
          (d['providerName_ku'] ?? d['partnerName_ku'] ?? '').toString(),
    );
  }

  String providerName(String lang) {
    if (lang == 'ar' && providerNameAr.isNotEmpty) return providerNameAr;
    if (lang == 'ku') {
      if (providerNameKu.isNotEmpty) return providerNameKu;
      if (providerNameAr.isNotEmpty) return providerNameAr;
    }
    return providerNameEn;
  }
}

// ── Test-key label resolver ───────────────────────────────────────────────────
// Maps well-known non-custom test IDs to localized readable labels.
// Unknown keys fall back to title-cased underscore-replaced English.

const _testKeyLabels = <String, Map<String, String>>{
  'weight': {
    'en': 'Weight',
    'ar': 'الوزن',
    'ku': 'کێشی',
  },
  'height': {
    'en': 'Height',
    'ar': 'الطول',
    'ku': 'بەرزی',
  },
  'bmi': {
    'en': 'BMI',
    'ar': 'مؤشر كتلة الجسم',
    'ku': 'پێوانەی کتلەی جەسەد',
  },
  'vision_test': {
    'en': 'Vision Test',
    'ar': 'فحص النظر',
    'ku': 'تاقیکردنەوەی بینین',
  },
  'eye_pressure': {
    'en': 'Eye Pressure',
    'ar': 'ضغط العين',
    'ku': 'پشافتنی چاو',
  },
  'hearing_test': {
    'en': 'Hearing Test',
    'ar': 'فحص السمع',
    'ku': 'تاقیکردنەوەی بیستن',
  },
  'range_of_motion': {
    'en': 'Range of Motion',
    'ar': 'نطاق الحركة',
    'ku': 'ئەندازەی جووڵەوە',
  },
  'other_measurement': {
    'en': 'Other Measurement',
    'ar': 'قياس آخر',
    'ku': 'پێوانەیەکی تر',
  },
};

String resolveTestKeyLabel(String id, String lang) {
  final entry = _testKeyLabels[id];
  if (entry != null) {
    if (lang == 'ar') return entry['ar']!;
    if (lang == 'ku') return entry['ku'] ?? entry['ar'] ?? entry['en']!;
    return entry['en']!;
  }
  // Unknown key: replace underscores with spaces and title-case each word.
  return id
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
