import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/announcement.dart';

/// Session-cached list of active home announcements (max 2 shown).
///
/// Non-autoDispose: result lives for the provider scope lifetime (app session).
/// Call ref.invalidate(announcementsProvider) after a user dismiss to refresh.
///
/// Query: active==true, endAt>=now, orderBy(endAt), limit(10).
/// Client filters: startAt<=now, not in dismissed set, priority sort, take(2).
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final now = DateTime.now();
  final nowTs = Timestamp.fromDate(now);

  final snap = await FirebaseFirestore.instance
      .collection('public_home_announcements')
      .where('active', isEqualTo: true)
      .where('endAt', isGreaterThanOrEqualTo: nowTs)
      .orderBy('endAt')
      .limit(10)
      .get();

  final prefs = await SharedPreferences.getInstance();
  final dismissed =
      (prefs.getStringList('dismissedAnnouncements') ?? []).toSet();

  final filtered = snap.docs
      .map((d) => Announcement.fromMap(d.id, d.data()))
      .where((a) => !a.startAt.isAfter(now))
      .where((a) => !dismissed.contains(a.dismissKey))
      // Future province targeting: uncomment and wire selectedProvinceKey
      // .where((a) => a.targetProvinceKeys == null ||
      //     a.targetProvinceKeys!.contains(selectedProvinceKey))
      .toList()
    ..sort((x, y) => x.priority.compareTo(y.priority));

  return filtered.take(2).toList();
});
