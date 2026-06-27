import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/patient_result.dart';

// ── Shared utilities used by both MyResultsPage and ResultDetailPage ──────────

bool isImagingCategory(String serviceCategory) {
  final lc = serviceCategory.toLowerCase();
  return lc.contains('imaging') ||
      lc.contains('radiology') ||
      lc.contains('xray') ||
      lc.contains('x-ray') ||
      lc.contains('scan') ||
      lc.contains('mri') ||
      lc.contains('ultrasound');
}

String formatResultDate(PatientResult result, String lang) {
  if (result.releasedAt != null) {
    return DateFormat.yMMMd(lang).format(result.releasedAt!);
  }
  if (result.dateKey.isNotEmpty) {
    try {
      return DateFormat.yMMMd(lang).format(DateTime.parse(result.dateKey));
    } catch (_) {
      return result.dateKey;
    }
  }
  return '';
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class ResultCategoryIcon extends StatelessWidget {
  final String serviceCategory;
  const ResultCategoryIcon({super.key, required this.serviceCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: PatientAppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isImagingCategory(serviceCategory)
            ? Icons.image_search_outlined
            : Icons.science_outlined,
        size: 22,
        color: Colors.white,
      ),
    );
  }
}

class ResultCategoryChip extends StatelessWidget {
  final String serviceCategory;
  const ResultCategoryChip({super.key, required this.serviceCategory});

  @override
  Widget build(BuildContext context) {
    final isImg = isImagingCategory(serviceCategory);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: PatientAppColors.brandBlueAlt.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isImg ? 'imaging'.tr() : 'lab'.tr(),
        style: const TextStyle(
          color: PatientAppColors.brandBlueAlt,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ResultTestChip extends StatelessWidget {
  final String label;
  final bool isOverflow;
  const ResultTestChip(
      {super.key, required this.label, this.isOverflow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverflow
            ? Colors.grey.shade100
            : PatientAppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverflow
              ? Colors.grey.shade300
              : PatientAppColors.brandTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isOverflow ? Colors.grey.shade600 : PatientAppColors.brandTeal,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
