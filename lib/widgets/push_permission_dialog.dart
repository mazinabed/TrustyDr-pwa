import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

/// Custom TrustyDr push-permission dialog shown before the browser prompt.
/// Returns true if user tapped Enable, false/null if Not Now.
class PushPermissionDialog extends StatelessWidget {
  const PushPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.notifications_active, color: PatientAppColors.brandIndigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'push.dialog_title'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('push.dialog_body'.tr()),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.phone_iphone, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'push.ios_note'.tr(),
                    style:
                        const TextStyle(fontSize: 11.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('push.not_now'.tr()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: PatientAppColors.brandIndigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('push.enable'.tr()),
        ),
      ],
    );
  }
}

/// Convenience function — shows [PushPermissionDialog] as a modal.
/// Returns true if Enable was tapped, false if Not Now, null if dismissed.
Future<bool?> showPushPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PushPermissionDialog(),
  );
}
