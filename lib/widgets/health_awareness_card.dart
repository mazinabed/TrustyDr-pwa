import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

class HealthAwarenessCard extends StatelessWidget {
  const HealthAwarenessCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final idx = (now.day - 1) % 7;
    final tipKey = 'health_awareness.tip_${idx + 1}';
    final lang = context.locale.languageCode;
    final intlLocale = lang == 'ku' ? 'ar' : lang;
    final weekday = DateFormat('EEEE', intlLocale).format(now);
    final dateStr = DateFormat('d MMM', intlLocale).format(now);
    final dateLabel = '$weekday  •  $dateStr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
          boxShadow: PatientAppColors.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0x1A5CC6BA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: PatientAppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'health_awareness.today_tip'.tr(),
                                  style: const TextStyle(
                                    color: PatientAppColors.darkNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1A5CC6BA),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'health_awareness.source'.tr(),
                                style: const TextStyle(
                                  color: PatientAppColors.brandTeal,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tipKey.tr(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.black38,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'health_awareness.disclaimer'.tr(),
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
