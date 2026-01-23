import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String userId;
  String name;
  String avatarUrl;
  int age;

  final bool isSelf;

  Patient({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.age,
    required this.isSelf,
  });

  factory Patient.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Patient(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown Patient',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      age: data['age'] as int? ?? 0,
      isSelf: data['isSelf'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'age': age,
      'isSelf': isSelf,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
