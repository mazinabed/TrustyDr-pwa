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
    } catch (_) {
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
      } catch (_) {}
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
    } catch (_) {}
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

  // ─── Lab specialty seeding ────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _newLabSpecialties = [
    {
      'name_en': 'Medical Imaging',
      'name_ar': 'التصوير الطبي',
      'name_ku': 'وێنەگرتنی پزیشکی',
      'icon': 'assets/icons/radiology.png',
      'iconUrl': '',
      'status': 'active',
      'serviceGroup': 'imaging',
      'lang': {'ar': 'التصوير الطبي', 'ku': 'وێنەگرتنی پزیشکی'},
    },
    {
      'name_en': 'X-Ray',
      'name_ar': 'الأشعة السينية',
      'name_ku': 'ئێکسڕەی',
      'icon': 'assets/icons/radiology.png',
      'iconUrl': '',
      'status': 'active',
      'serviceGroup': 'imaging',
      'lang': {'ar': 'الأشعة السينية', 'ku': 'ئێکسڕەی'},
    },
    {
      'name_en': 'Ultrasound',
      'name_ar': 'السونار',
      'name_ku': 'سۆنار',
      'icon': 'assets/icons/radiology.png',
      'iconUrl': '',
      'status': 'active',
      'serviceGroup': 'imaging',
      'lang': {'ar': 'السونار', 'ku': 'سۆنار'},
    },
    {
      'name_en': 'MRI',
      'name_ar': 'الرنين المغناطيسي',
      'name_ku': 'ئێم ئار ئای',
      'icon': 'assets/icons/radiology.png',
      'iconUrl': '',
      'status': 'active',
      'serviceGroup': 'imaging',
      'lang': {'ar': 'الرنين المغناطيسي', 'ku': 'ئێم ئار ئای'},
    },
    {
      'name_en': 'CT Scan',
      'name_ar': 'الأشعة المقطعية',
      'name_ku': 'سی تی سکان',
      'icon': 'assets/icons/radiology.png',
      'iconUrl': '',
      'status': 'active',
      'serviceGroup': 'imaging',
      'lang': {'ar': 'الأشعة المقطعية', 'ku': 'سی تی سکان'},
    },
    {
      'name_en': 'Echocardiography',
      'name_ar': 'إيكو القلب',
      'name_ku': 'ئیکۆی دڵ',
      'icon': 'assets/icons/radiology.png',
      'iconUrl': '',
      'status': 'active',
      'serviceGroup': 'imaging',
      'lang': {'ar': 'إيكو القلب', 'ku': 'ئیکۆی دڵ'},
    },
  ];

  // Adds serviceGroup to the 3 existing lab/imaging specialties.
  // Queries by name_en — safe even without knowing their auto-generated IDs.
  Future<void> _classifyExistingLabSpecialties() async {
    setState(() {
      _isUploading = true;
      _status = 'Classifying existing lab specialties...';
    });
    try {
      final toClassify = {
        'Radiology': 'imaging',
        'Laboratory Medicine': 'laboratory',
        'Vision & Eye Care': 'imaging',
      };

      int updated = 0;
      int notFound = 0;

      for (final entry in toClassify.entries) {
        final snap = await _firestore
            .collection('specialties')
            .where('name_en', isEqualTo: entry.key)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          notFound++;
          continue;
        }

        await snap.docs.first.reference.update({'serviceGroup': entry.value});
        updated++;
      }

      _showSnack(
        '✅ Classified $updated specialties.${notFound > 0 ? ' $notFound not found in Firestore.' : ''}',
        true,
      );
    } catch (e) {
      _showSnack('❌ Classification failed: $e', false);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Creates the 6 new lab/imaging specialties with auto-generated IDs.
  // Skips any that already exist (matched by name_en) to prevent duplicates.
  Future<void> _seedNewLabSpecialties() async {
    setState(() {
      _isUploading = true;
      _status = 'Seeding new lab specialties...';
    });
    try {
      int created = 0;
      int skipped = 0;

      for (final spec in _newLabSpecialties) {
        final nameEn = spec['name_en'] as String;

        final existing = await _firestore
            .collection('specialties')
            .where('name_en', isEqualTo: nameEn)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          skipped++;
          continue;
        }

        await _firestore.collection('specialties').doc().set(spec);
        created++;
      }

      _showSnack(
        '✅ Created $created lab specialties.${skipped > 0 ? ' Skipped $skipped (already exist).' : ''}',
        true,
      );
    } catch (e) {
      _showSnack('❌ Lab specialty seed failed: $e', false);
    } finally {
      setState(() => _isUploading = false);
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
              else ...[
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
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _classifyExistingLabSpecialties,
                  icon: const Icon(Icons.label_outline),
                  label: const Text('Classify Existing Lab Specialties'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _seedNewLabSpecialties,
                  icon: const Icon(Icons.biotech_outlined),
                  label: const Text('Seed New Lab Specialties'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                ),
              ],
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
