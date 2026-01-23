import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileServiceProvider =
    Provider<ProfileService>((ref) => ProfileService());

class ProfileService {
  final _db = FirebaseFirestore.instance;

  Future<void> upsertUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}
