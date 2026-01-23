import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UploadFirestoreData extends StatefulWidget {
  const UploadFirestoreData({super.key});

  @override
  State<UploadFirestoreData> createState() => _UploadFirestoreDataState();
}

class _UploadFirestoreDataState extends State<UploadFirestoreData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  String _status = '';

  Future<List<dynamic>?> _loadJsonList(String fileName) async {
    try {
      final raw = await rootBundle.loadString('assets/data/$fileName');
      return json.decode(raw) as List<dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to load $fileName: $e');
      return null;
    }
  }

  Future<void> _uploadCollection(String name, String fileName) async {
    final dataList = await _loadJsonList(fileName);
    if (dataList == null || dataList.isEmpty) {
      _showSnack('⚠️ $fileName empty or invalid.', false);
      return;
    }

    setState(() {
      _status = 'Uploading $name...';
    });

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final item in dataList) {
      final docRef = _firestore.collection(name).doc();
      batch.set(docRef, item);
      count++;

      if (count % 400 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    await batch.commit();
    _showSnack('✅ Uploaded $count $name successfully.', true);
  }

  Future<void> _uploadReviews() async {
    final dataList = await _loadJsonList('reviews.json');
    if (dataList == null || dataList.isEmpty) {
      _showSnack('⚠️ No reviews found.', false);
      return;
    }

    setState(() {
      _status = 'Uploading reviews...';
    });

    int count = 0;

    for (final r in dataList) {
      try {
        final review = Map<String, dynamic>.from(r);
        final doctorId = review['doctorId'];
        if (doctorId == null || doctorId.toString().isEmpty) continue;

        final docRef = _firestore
            .collection('doctors')
            .doc(doctorId)
            .collection('reviews')
            .doc();

        await docRef.set(review);
        count++;
      } catch (e) {
        debugPrint('⚠️ Failed to upload review: $e');
      }
    }

    _showSnack('✅ Uploaded $count reviews successfully.', true);
    await _updateAllDoctorRatings();
  }

  Future<void> _updateAllDoctorRatings() async {
    final doctors = await _firestore.collection('doctors').get();
    for (final doc in doctors.docs) {
      await _updateDoctorRating(doc.id);
    }
  }

  Future<void> _updateDoctorRating(String doctorId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      int count = reviewsSnapshot.docs.length;

      for (final doc in reviewsSnapshot.docs) {
        final data = doc.data();
        if (data['rating'] != null) {
          totalRating += (data['rating'] as num).toDouble();
        }
      }

      double avg = totalRating / count;

      await _firestore.collection('doctors').doc(doctorId).update({
        'ratingAverage': double.parse(avg.toStringAsFixed(1)),
        'ratingCount': count,
      });
    } catch (e) {
      debugPrint('⚠️ Rating update failed for $doctorId: $e');
    }
  }

  Future<void> uploadAll() async {
    setState(() => _isUploading = true);
    try {
      await _uploadCollection('specialties', 'specialties.json');
      await _uploadCollection('doctors', 'doctors.json');
      await _uploadCollection('users', 'users.json');
      await _uploadReviews();
      _showSnack('✅ All data uploaded successfully!', true);
    } catch (e) {
      _showSnack('❌ Upload failed: $e', false);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnack(String message, bool success) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Data Uploader')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: uploadAll,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload All Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                _status.isEmpty
                    ? 'This tool uploads specialties, doctors, users, and reviews\ninto their Firestore collections.'
                    : _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
