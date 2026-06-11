import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/providers/notifications_provider.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/models/app_notification.dart';
import 'package:trustydr/pages/patient/appointment_detail_page.dart';
import 'package:trustydr/services/push_notification_service.dart';
import 'package:trustydr/widgets/push_permission_dialog.dart';

class Notifications extends ConsumerStatefulWidget {
  const Notifications({super.key});

  @override
  ConsumerState<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<Notifications> {
  // Tracks the last-known unread count so we can detect new arrivals
  // and play a sound only when a previously unseen notification appears.
  int _lastUnreadCount = 0;

  // Whether to show the push-enable banner. null = still loading.
  bool _showPushBanner = false;

  @override
  void initState() {
    super.initState();
    _checkPushBanner();
  }

  Future<void> _checkPushBanner() async {
    if (!kIsWeb) return;
    final status =
        await PushNotificationService.instance.currentPermissionStatus();
    // Show the banner whenever permission is unresolved (default).
    // Do NOT gate on hasDeclined() here — that flag only suppresses the
    // post-booking auto-popup. The notifications page banner is the user's
    // manual opt-in path and must always be available.
    if (status == AuthorizationStatus.authorized) return;
    if (status == AuthorizationStatus.denied) return;
    if (mounted) setState(() => _showPushBanner = true);
  }

  Future<void> _onBannerTap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final result = await showPushPermissionDialog(context);
    if (!mounted) return;
    if (result == true) {
      final lang = context.locale.languageCode;
      final granted =
          await PushNotificationService.instance.requestPermissionAndStoreToken(
        uid: user.uid,
        language: lang,
      );
      if (granted && mounted) setState(() => _showPushBanner = false);
    } else {
      await PushNotificationService.instance.markDeclined();
      if (mounted) setState(() => _showPushBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    // Play sound + haptic when unread count rises while the page is open.
    ref.listen<AsyncValue<List<AppNotification>>>(
      notificationsProvider,
      (_, next) {
        final count =
            next.whenData((l) => l.where((n) => !n.isRead).length).value ?? 0;
        if (count > _lastUnreadCount) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.lightImpact();
        }
        _lastUnreadCount = count;
      },
    );

    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'home.notifications_title'.tr(),
          style: appBarTitleTextStyle.copyWith(
            color: PatientAppColors.brandIndigo,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PatientAppColors.brandIndigo),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Column(
              children: [
                if (_showPushBanner) _PushBanner(onTap: _onBannerTap),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.bellSlash,
                          color: Colors.grey,
                          size: 60,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'home.no_notifications_title'.tr(),
                          style: greyNormalTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length + (_showPushBanner ? 1 : 0),
            itemBuilder: (context, index) {
              if (_showPushBanner && index == 0) {
                return _PushBanner(onTap: _onBannerTap);
              }
              final notif = notifications[index - (_showPushBanner ? 1 : 0)];
              return _NotificationCard(
                notif: notif,
                lang: lang,
                onTap: () => _onNotifTap(context, notif),
                onDismiss: () => _dismiss(notif),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markRead(AppNotification notif) async {
    if (notif.isRead) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notif.id)
        .update({'isRead': true});
  }

  Future<void> _dismiss(AppNotification notif) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notif.id)
        .update({
      'dismissed': true,
      'dismissedAt': FieldValue.serverTimestamp(),
    });
  }

  void _onNotifTap(BuildContext context, AppNotification notif) {
    _markRead(notif);
    if (notif.type == 'appointment_reminder' &&
        notif.appointmentId.isNotEmpty) {
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: AppointmentDetailPage(appointmentId: notif.appointmentId),
        ),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notif,
    required this.lang,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notif;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          fixPadding * 2,
          fixPadding * 2,
          fixPadding * 2,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: notif.isRead ? Colors.white : PatientAppColors.appBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 1,
              spreadRadius: 1,
              color: Colors.grey[300]!,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                    PatientAppColors.brandBlueAlt.withValues(alpha: 0.12),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: PatientAppColors.brandBlueAlt,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.localizedTitle(lang),
                            style: blackNormalBoldTextStyle,
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: PatientAppColors.brandBlueAlt,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.localizedBody(lang),
                      style: greySmallTextStyle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notif.createdAt, lang),
                      style: greySmallTextStyle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            // Dismiss button — visible but unobtrusive
            Tooltip(
              message: 'dismiss'.tr(),
              child: InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt, String lang) {
    return DateFormat.yMMMd(lang).format(dt);
  }
}

class _PushBanner extends StatelessWidget {
  const _PushBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: PatientAppColors.brandIndigo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PatientAppColors.brandIndigo.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: PatientAppColors.brandIndigo,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'push.banner_title'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: PatientAppColors.brandIndigo,
                    ),
                  ),
                  Text(
                    'push.banner_body'.tr(),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: PatientAppColors.brandIndigo,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
