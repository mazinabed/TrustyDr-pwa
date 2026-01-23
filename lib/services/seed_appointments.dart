import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:math';

class SeedAppointmentsService {
  static Future<void> createSampleAppointments() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    final firestore = FirebaseFirestore.instance;

    final doctors = [
      {
        'id': 'doc_zaid_alamiri',
        'name': 'Dr. Zaid Alamiri',
        'type': 'Cardiologist',
        'image': 'https://example.com/images/doc_zaid_alamiri.jpg',
        'clinic': 'Al-Basra Heart Center',
        'city': 'Basra',
        'province': 'Basra',
      },
      {
        'id': 'doc_ahmed_salem',
        'name': 'Dr. Ahmed Salem',
        'type': 'Dermatologist',
        'image': 'https://example.com/images/doc_ahmed_salem.jpg',
        'clinic': 'Baghdad Skin Clinic',
        'city': 'Baghdad',
        'province': 'Baghdad',
      },
    ];

    final users = [
      {'id': 'user_001', 'name': 'Ali Kareem'},
      {'id': 'user_002', 'name': 'Sara Hadi'},
    ];

    for (int i = 0; i < 8; i++) {
      final doctor = doctors[Random().nextInt(doctors.length)];
      final user = users[Random().nextInt(users.length)];
      final date = DateTime.now().add(Duration(days: Random().nextInt(14)));
      final time =
          "${9 + Random().nextInt(8)}:${Random().nextInt(2) * 30 == 0 ? '00' : '30'}";

      final appointmentData = {
        'doctorId': doctor['id'],
        'doctorName': doctor['name'],
        'doctorType': doctor['type'],
        'doctorImage': doctor['image'],
        'clinicName': doctor['clinic'],
        'province': doctor['province'],
        'city': doctor['city'],
        'userId': user['id'],
        'patientName': user['name'],
        'date': date.toIso8601String(),
        'time': time,
        'status': ['Pending', 'Confirmed', 'Completed'][Random().nextInt(3)],
        'paymentStatus': ['Unpaid', 'Paid'][Random().nextInt(2)],
        'notes': 'Initial consultation for follow-up.',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firestore.collection('appointments').add(appointmentData);
    }

    print("✅ Sample appointments uploaded successfully!");
  }
}
