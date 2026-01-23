// import 'package:cloud_firestore/cloud_firestore.dart';

// class Doctor {
//   final String id;
//   final String name;
//   final String specialty;
//   final int experience;
//   final String imageUrl;

//   Doctor({
//     required this.id,
//     required this.name,
//     required this.specialty,
//     required this.experience,
//     required this.imageUrl,
//   });

//   factory Doctor.fromFirestore(
//     DocumentSnapshot<Map<String, dynamic>> snapshot,
//     SnapshotOptions? options,
//   ) {
//     final data = snapshot.data()!;
//     return Doctor(
//       id: snapshot.id,
//       name: data['name'] as String? ?? 'Dr. Unknown',
//       specialty: data['specialty'] as String? ?? 'General Practice',
//       experience: data['experience'] as int? ?? 0,
//       imageUrl: data['imageUrl'] as String? ?? '',
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'name': name,
//       'specialty': specialty,
//       'experience': experience,
//       'imageUrl': imageUrl,
//       'lastUpdated': FieldValue.serverTimestamp(),
//     };
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final int experience;
  final String imageUrl;

  // NEW FIELDS (Step 1)
  final bool isVerified; // true = registered doctor in your app
  final String
      verificationStatus; // "verified" | "unverified" | "pending" | "rejected"
  final String
      sourceType; // "app" | "google_places" | "facebook_page" | "manual"
  final bool canBook; // false for unverified doctors
  final bool canCall; // true if phone number exists for unverified
  final Map<String, dynamic>? sourceIds; // external IDs

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.imageUrl,

    // NEW DEFAULT VALUES (safe defaults)
    this.isVerified = true,
    this.verificationStatus = 'verified',
    this.sourceType = 'app',
    this.canBook = true,
    this.canCall = true,
    this.sourceIds,
  });

  factory Doctor.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return Doctor(
      id: snapshot.id,
      name: data['name'] as String? ?? 'Dr. Unknown',
      specialty: data['specialty'] as String? ?? 'General Practice',
      experience: data['experience'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',

      // 🔹 NEW FIELDS WITH SAFE DEFAULTS
      isVerified: data['isVerified'] as bool? ?? true,
      verificationStatus: data['verificationStatus'] as String? ?? 'verified',
      sourceType: data['sourceType'] as String? ?? 'app',
      canBook: data['canBook'] as bool? ?? true,
      canCall: data['canCall'] as bool? ?? true,
      sourceIds: data['sourceIds'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'specialty': specialty,
      'experience': experience,
      'imageUrl': imageUrl,
      'lastUpdated': FieldValue.serverTimestamp(),

      // 🔹 NEW FIELDS
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'sourceType': sourceType,
      'canBook': canBook,
      'canCall': canCall,
      'sourceIds': sourceIds,
    };
  }
}
