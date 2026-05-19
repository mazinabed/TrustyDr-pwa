import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeNotificationsWidget extends StatelessWidget {
  /// For now this is UI-only.
  /// Later you can replace this with real data.
  final List<String> notifications;

  const HomeNotificationsWidget({
    super.key,
    this.notifications = const [],
  });

  bool get hasNotifications => notifications.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: fixPadding * 2,
        vertical: fixPadding,
      ),
      child: Container(
        padding: EdgeInsets.all(fixPadding * 1.6),
        decoration: BoxDecoration(
          color: PatientAppColors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: PatientAppColors.shadowCard,
        ),
        child: hasNotifications
            ? _buildNotificationContent(context)
            : _buildEmptyState(context),
      ),
    );
  }

  /// 🔔 When notifications exist
  Widget _buildNotificationContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(Icons.notifications_active_outlined),
        SizedBox(width: fixPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('home.notifications_title'),
                style: blackNormalTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: fixPadding * 0.5),
              Text(
                notifications.first,
                style: blackNormalTextStyle.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🌱 When there are NO notifications
  Widget _buildEmptyState(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBadge(Icons.favorite_outline),
        SizedBox(width: fixPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('home.no_notifications_title'),
                style: blackNormalTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: fixPadding * 0.5),
              Text(
                tr('home.no_notifications_message'),
                style: blackNormalTextStyle.copyWith(
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PatientAppColors.brandBlueAlt.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: PatientAppColors.brandBlueAlt,
        size: 22,
      ),
    );
  }
}
