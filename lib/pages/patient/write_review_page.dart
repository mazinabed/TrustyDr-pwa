import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WriteReviewModal extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final String appointmentId;

  const WriteReviewModal({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.appointmentId,
  });

  @override
  State<WriteReviewModal> createState() => _WriteReviewModalState();
}

class _WriteReviewModalState extends State<WriteReviewModal> {
  double _rating = 0.0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _submitReview() async {
    final user = _auth.currentUser;
    if (user == null || _rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      // ✅ GET NAME FROM USERS COLLECTION
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final displayName =
          userDoc.data()?['name'] ?? user.displayName ?? 'Anonymous';

      // 1️⃣ Create review
      await _firestore
          .collection('doctors')
          .doc(widget.doctorId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userName': displayName, // ✅ correct name
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Mark appointment as reviewed
      await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'hasReviewed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Review error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(widget.doctorImage),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rate Dr. ${widget.doctorName}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  spacing: 8,
                  children: List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 34,
                      ),
                      onPressed: () => setState(() => _rating = i + 1.0),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF5CC6BA),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Review',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
