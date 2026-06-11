import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_notification.dart';

/// Streams the authenticated user's notifications, newest first.
/// Returns an empty stream when the user is not signed in.
/// Limited to 50 most-recent docs to keep reads low-cost.
final notificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .where((n) => !n.dismissed)
            .toList(),
      );
});

/// Count of notifications where isRead == false.
/// Emits 0 while loading or on error — never null.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).when(
        data: (list) => list.where((n) => !n.isRead).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});
