import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService());

class DoctorService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> specialtiesStream() {
    return _db
        .collection('specialties')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> listDoctorsBySpecialty(
      String specialty,
      {String? cityEn,
      String? provinceKey}) {
    var query =
        _db.collection('doctors').where('specialty', isEqualTo: specialty);
    if (cityEn != null && cityEn.isNotEmpty) {
      query = query.where('city_en', isEqualTo: cityEn);
    }
    if (provinceKey != null && provinceKey.isNotEmpty) {
      query = query.where('province', isEqualTo: provinceKey);
    }
    return query.get();
  }
}
