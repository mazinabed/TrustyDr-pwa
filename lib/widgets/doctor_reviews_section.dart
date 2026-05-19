import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

class DoctorReviewsSection extends StatelessWidget {
  final String doctorId;

  const DoctorReviewsSection({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              color: PatientAppColors.brandIndigo,
            ),
          );
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'no_reviews_yet'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        final reviews = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'patient_reviews'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...reviews.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['userName'] ?? 'Anonymous';
              final rating = (data['rating'] ?? 0).toDouble();
              final comment = data['comment'] ?? '';
              final ts = data['createdAt'] as Timestamp?;
              final date =
                  ts != null ? DateFormat.yMMMd().format(ts.toDate()) : '';

              return _ReviewTile(
                name: name,
                rating: rating,
                comment: comment,
                date: date,
              );
            }),
          ],
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final double rating;
  final String comment;
  final String date;

  const _ReviewTile({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _Stars(rating: rating),
            ],
          ),
          if (comment.toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment),
          ],
          if (date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              date,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.amber,
        );
      }),
    );
  }
}
