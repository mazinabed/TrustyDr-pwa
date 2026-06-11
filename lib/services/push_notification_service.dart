import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/config/push_config.dart';

/// Manages FCM push notification tokens for the patient app.
///
/// Responsibilities:
///   - Request browser push permission
///   - Store/refresh/delete FCM tokens in users/{uid}/fcmTokens/{docId}
///   - Persist local state (declined flag, Firestore doc ID) in SharedPreferences
///
/// Web-only: all methods are no-ops on native platforms.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _prefDeclined = 'push_permission_dismissed';
  static const _prefTokenDocId = 'fcm_token_doc_id';

  final _fs = FirebaseFirestore.instance;

  // ─── Permission state ──────────────────────────────────────────────────────

  /// Current browser-level authorization status.
  Future<AuthorizationStatus> currentPermissionStatus() async {
    if (!kIsWeb) return AuthorizationStatus.notDetermined;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// True if user previously tapped "Not Now" on our custom dialog.
  Future<bool> hasDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefDeclined) ?? false;
  }

  /// Store the "Not Now" dismissal so we don't prompt repeatedly.
  Future<void> markDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDeclined, true);
  }

  // ─── Token lifecycle ───────────────────────────────────────────────────────

  /// Request browser push permission, then get and store the FCM token.
  /// Returns true if permission was granted and token was stored.
  Future<bool> requestPermissionAndStoreToken({
    required String uid,
    required String language,
  }) async {
    if (!kIsWeb) return false;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }

    await _storeToken(uid: uid, language: language);
    return true;
  }

  /// Called from main.dart's onTokenRefresh listener.
  /// Updates the token field in the existing Firestore doc without changing language.
  Future<void> onTokenRefreshed(String newToken, {required String uid}) async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final existingDocId = prefs.getString(_prefTokenDocId);
    if (existingDocId == null || existingDocId.isEmpty) return;

    try {
      await _fs
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(existingDocId)
          .update({
        'token': newToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Doc was deleted (e.g. stale cleanup). Ignore — next login creates a fresh one.
    }
  }

  /// Delete this device's FCM token from Firestore. Call before sign-out.
  Future<void> deleteToken(String uid) async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final docId = prefs.getString(_prefTokenDocId);
      if (docId != null && docId.isNotEmpty) {
        await _fs
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(docId)
            .delete();
        await prefs.remove(_prefTokenDocId);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Best-effort cleanup — swallow errors so logout always completes.
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<void> _storeToken({
    required String uid,
    required String language,
    String? token,
  }) async {
    final resolvedToken = token ??
        await FirebaseMessaging.instance
            .getToken(vapidKey: PushConfig.vapidKey);
    if (resolvedToken == null) return;

    final prefs = await SharedPreferences.getInstance();
    final existingDocId = prefs.getString(_prefTokenDocId);

    final tokenColl = _fs.collection('users').doc(uid).collection('fcmTokens');

    if (existingDocId != null && existingDocId.isNotEmpty) {
      // Update existing device doc — preserve createdAt, update token + updatedAt.
      await tokenColl.doc(existingDocId).set(
        {
          'token': resolvedToken,
          'platform': 'web',
          'language': language,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      // First time on this device — create a new doc.
      final ref = await tokenColl.add({
        'token': resolvedToken,
        'platform': 'web',
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await prefs.setString(_prefTokenDocId, ref.id);
    }
  }
}
