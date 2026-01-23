// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class TestFirestorePage extends StatelessWidget {
//   const TestFirestorePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final doctorsRef = FirebaseFirestore.instance
//         .collection('users')
//         .where('role', isEqualTo: 'doctor');

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('قائمة الأطباء'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: doctorsRef.snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('لا يوجد أطباء حالياً'));
//           }

//           final doctors = snapshot.data!.docs;

//           return ListView.builder(
//             itemCount: doctors.length,
//             itemBuilder: (context, index) {
//               final doc = doctors[index];
//               final data = doc.data() as Map<String, dynamic>;

//               final name = data['name'] ?? 'طبيب';
//               final specialty = data['specialty'] ?? '';
//               final city = data['city'] ?? '';

//               String? profileImage;
//               if (data.containsKey('profileImage') &&
//                   data['profileImage'] != null &&
//                   data['profileImage'] != '') {
//                 profileImage = data['profileImage'];
//               }

//               return ListTile(
//                 leading: CircleAvatar(
//                   radius: 25,
//                   backgroundColor: Colors.grey.shade300,
//                   backgroundImage: profileImage != null
//                       ? NetworkImage(profileImage)
//                       : const NetworkImage(
//                           'https:
//                   child: profileImage == null
//                       ? Text(
//                           name[0],
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         )
//                       : null,
//                 ),
//                 title: Text(
//                   name,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('$specialty • $city'),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
