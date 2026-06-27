import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeAddress {
  const HomeAddress({
    required this.province,
    required this.city,
    required this.full,
    this.note = '',
  });

  final String province;
  final String city;
  final String full;
  final String note;

  bool get isEmpty => province.isEmpty && city.isEmpty && full.isEmpty;

  factory HomeAddress.fromMap(Map<String, dynamic> m) {
    return HomeAddress(
      province: (m['province'] ?? '').toString(),
      city: (m['city'] ?? '').toString(),
      full: (m['full'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'province': province,
        'city': city,
        'full': full,
        'note': note,
      };
}

/// Streams the current user's home address from [users/{uid}.homeAddress].
///
/// Returns null when the user is unauthenticated, the field is absent, or
/// all address fields are empty. Never reads if not authenticated.
final homeAddressProvider = StreamProvider.autoDispose<HomeAddress?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final raw = snap.data()?['homeAddress'];
    if (raw == null || raw is! Map) return null;
    final addr = HomeAddress.fromMap(Map<String, dynamic>.from(raw));
    return addr.isEmpty ? null : addr;
  });
});
