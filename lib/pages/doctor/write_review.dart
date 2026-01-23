// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class WriteReview extends StatefulWidget {
//   final String doctorId;
//   const WriteReview({super.key, required this.doctorId});

//   @override
//   State<WriteReview> createState() => _WriteReviewState();
// }

// class _WriteReviewState extends State<WriteReview> {
//   final TextEditingController _reviewController = TextEditingController();
//   double _rating = 0;
//   bool _isSubmitting = false;

//   final _firestore = FirebaseFirestore.instance;
//   final _auth = FirebaseAuth.instance;

//   Future<void> _submitReview() async {
//     if (_rating == 0 || _reviewController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(tr('review_missing_fields'))),
//       );
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception(tr('error_user_not_logged_in'));

//       final reviewData = {
//         "userId": user.uid,
//         "userName": user.displayName ?? "Anonymous",
//         "userImage": user.photoURL ?? "https://via.placeholder.com/150",
//         "rating": _rating,
//         "review": _reviewController.text.trim(),
//         "timestamp": DateTime.now().toIso8601String(),
//       };

//       await _firestore
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('reviews')
//           .add(reviewData);

//       await _updateDoctorRating();

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(tr('review_submitted_success'))),
//       );

//       Navigator.pop(context);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }

//   Future<void> _updateDoctorRating() async {
//     final reviewsRef = _firestore
//         .collection('doctors')
//         .doc(widget.doctorId)
//         .collection('reviews');

//     final snapshot = await reviewsRef.get();
//     if (snapshot.docs.isEmpty) return;

//     final ratings =
//         snapshot.docs.map((doc) => (doc['rating'] as num).toDouble()).toList();

//     final avgRating = ratings.reduce((a, b) => a + b) /
//         (ratings.isEmpty ? 1 : ratings.length);

//     await _firestore.collection('doctors').doc(widget.doctorId).update({
//       "ratingAverage": double.parse(avgRating.toStringAsFixed(1)),
//       "ratingCount": ratings.length,
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(tr('write_review'))),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               tr('your_rating'),
//               style: const TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: List.generate(5, (index) {
//                 return IconButton(
//                   icon: Icon(
//                     index < _rating ? Icons.star : Icons.star_border,
//                     color: Colors.amber,
//                     size: 30,
//                   ),
//                   onPressed: () => setState(() => _rating = index + 1.0),
//                 );
//               }),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _reviewController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: tr('write_review_hint'),
//                 border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8.0)),
//               ),
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isSubmitting ? null : _submitReview,
//                 child: _isSubmitting
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(tr('submit_review')),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
