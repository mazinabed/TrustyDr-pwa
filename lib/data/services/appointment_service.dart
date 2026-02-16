// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final appointmentServiceProvider =
//     Provider<AppointmentService>((ref) => AppointmentService());

// class AppointmentService {
//   final _db = FirebaseFirestore.instance;

//   Future<void> createAppointment(Map<String, dynamic> data) async {
//     await _db.collection('appointments').add(data);
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> userAppointments(String uid) {
//     return _db
//         .collection('appointments')
//         .where('userId', isEqualTo: uid)
//         .snapshots();
//   }
// }
