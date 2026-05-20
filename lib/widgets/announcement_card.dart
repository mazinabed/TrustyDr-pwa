import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final String lang;
  final VoidCallback? onDismiss;
  final VoidCallback? onCtaTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.lang,
    this.onDismiss,
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _AnnouncementStyle.forType(announcement.type);
    final title = announcement.localizedTitle(lang);
    final body = announcement.localizedBody(lang);
    final ctaText = announcement.localizedCtaText(lang);
    final showBody = body.isNotEmpty;
    final showCta = onCtaTap != null &&
        announcement.ctaLink != null &&
        (ctaText?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
          boxShadow: PatientAppColors.shadowCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
          child: ColoredBox(
            color: style.bg,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left severity stripe
                  SizedBox(
                    width: 4,
                    child: ColoredBox(color: style.stripe),
                  ),
                  // Card content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Identity label — separates announcements from health-tip cards
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: style.stripe,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'announcement.label'.tr(),
                                style: TextStyle(
                                  color: style.stripe,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Title row: icon + title + optional dismiss ×
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(
                                  style.icon,
                                  size: 14,
                                  color: style.iconColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: PatientAppColors.darkNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              if (announcement.dismissible &&
                                  onDismiss != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: onDismiss,
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(left: 4, top: 1),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Body text (optional, max 3 lines)
                          if (showBody) ...[
                            const SizedBox(height: 5),
                            Text(
                              body,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                height: 1.45,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          // CTA button (optional)
                          if (showCta) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: GestureDetector(
                                onTap: onCtaTap,
                                behavior: HitTestBehavior.opaque,
                                child: Text(
                                  ctaText!,
                                  style: TextStyle(
                                    color: style.stripe,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementStyle {
  final Color bg;
  final Color stripe;
  final Color iconColor;
  final IconData icon;

  const _AnnouncementStyle({
    required this.bg,
    required this.stripe,
    required this.iconColor,
    required this.icon,
  });

  static _AnnouncementStyle forType(String type) => switch (type) {
        'warning' => const _AnnouncementStyle(
            bg: Color(0xFFFFF8E1),
            stripe: Color(0xFFF59E0B),
            iconColor: Color(0xFFF59E0B),
            icon: Icons.warning_amber_rounded,
          ),
        'critical' => const _AnnouncementStyle(
            bg: Color(0xFFFFEBEE),
            stripe: PatientAppColors.statusCancelled,
            iconColor: PatientAppColors.statusCancelled,
            icon: Icons.error_outline,
          ),
        'campaign' => const _AnnouncementStyle(
            bg: Color(0xFFEBF4FF),
            stripe: PatientAppColors.brandBlue,
            iconColor: PatientAppColors.brandBlue,
            icon: Icons.campaign_outlined,
          ),
        'update' => const _AnnouncementStyle(
            bg: Color(0xFFF3F0FF),
            stripe: PatientAppColors.brandIndigo,
            iconColor: PatientAppColors.brandIndigo,
            icon: Icons.new_releases_outlined,
          ),
        'seasonal' => const _AnnouncementStyle(
            bg: Color(0xFFFFF3E0),
            stripe: Color(0xFFE67E22),
            iconColor: Color(0xFFE67E22),
            icon: Icons.wb_sunny_outlined,
          ),
        _ => const _AnnouncementStyle(
            // 'info' and any unknown type
            bg: Color(0xFFE8F8F6),
            stripe: PatientAppColors.brandTeal,
            iconColor: PatientAppColors.brandTeal,
            icon: Icons.info_outline,
          ),
      };
}
