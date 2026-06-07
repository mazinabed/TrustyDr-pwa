import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/patient_app_colors.dart';

class CrossPortalDoctorCard extends StatelessWidget {
  const CrossPortalDoctorCard({super.key});

  static const _doctorPortalUrl = 'https://doctor.trustydr.com';

  Future<void> _launch() async {
    final uri = Uri.parse(_doctorPortalUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'ku';
    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF9),
          borderRadius: BorderRadius.circular(PatientAppColors.radiusMd),
          border: Border.all(color: const Color(0xFF99E6D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: PatientAppColors.brandTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cross_portal_doctor_title'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'cross_portal_doctor_body'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GestureDetector(
                onTap: _launch,
                child: Text(
                  'cross_portal_doctor_cta'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PatientAppColors.brandTeal,
                    decoration: TextDecoration.underline,
                    decorationColor: PatientAppColors.brandTeal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
