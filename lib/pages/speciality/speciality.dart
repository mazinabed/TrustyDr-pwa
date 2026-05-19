// import 'package:trustydr/constant/constant.dart' hide blackColor;
// import 'package:trustydr/pages/screens.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';

// class SpecialityScreen extends StatefulWidget {
//   final String? provinceKey;
//   final String? cityEn;
//   final String? preselected;

//   const SpecialityScreen({
//     super.key,
//     required this.provinceKey,
//     required this.cityEn,
//     this.preselected,
//   });

//   @override
//   State<SpecialityScreen> createState() => _SpecialityScreenState();
// }

// class _SpecialityScreenState extends State<SpecialityScreen> {
//   String _searchQuery = '';

//   String _displayName(Map<String, dynamic> data) {
//     final lang = context.locale.languageCode;
//     if (lang == 'ar' && (data['lang']?['ar'] ?? '').toString().isNotEmpty) {
//       return data['lang']['ar'];
//     } else if (lang == 'ku' &&
//         (data['lang']?['ku'] ?? '').toString().isNotEmpty) {
//       return data['lang']['ku'];
//     }
//     return data['name_en'] ?? '';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding:
//                 const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
//             ),
//             child: Row(
//               children: [
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.arrow_back_ios,
//                       color: Colors.white, size: 20),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     tr('Specialties'),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//             child: TextField(
//               onChanged: (val) => setState(() => _searchQuery = val),
//               decoration: InputDecoration(
//                 hintText: tr('Search specialties'),
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 12),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Colors.grey, width: 0.3),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//               stream: FirebaseFirestore.instance
//                   .collection('specialties')
//                   .where('status', isEqualTo: 'active')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                       child: CircularProgressIndicator(color: PatientAppColors.brandTeal));
//                 }

//                 if (snapshot.hasError) {
//                   return Center(
//                       child: Text('Error: ${snapshot.error}',
//                           style: greyNormalTextStyle));
//                 }

//                 final docs = snapshot.data?.docs ?? [];
//                 if (docs.isEmpty) {
//                   return Center(
//                       child: Text(tr('No specialties found'),
//                           style: greyNormalTextStyle));
//                 }

//                 final filtered = docs.where((d) {
//                   final name = (d['name_en'] ?? '').toString().toLowerCase();
//                   return name.contains(_searchQuery.toLowerCase());
//                 }).toList();

//                 return GridView.builder(
//                   padding: const EdgeInsets.all(20),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 20,
//                     crossAxisSpacing: 20,
//                     childAspectRatio: 1,
//                   ),
//                   itemCount: filtered.length,
//                   itemBuilder: (_, i) {
//                     final data = filtered[i].data();
//                     final displayName = _displayName(data);
//                     final iconUrl = (data['iconUrl'] ?? '').toString().trim();

//                     return InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           PageTransition(
//                             type: PageTransitionType.fade,
//                             duration: const Duration(milliseconds: 400),
//                             child: DoctorList(
//                               doctorType: data['name_en'],
//                               provinceKey: widget.provinceKey,
//                               cityEn: widget.cityEn,
//                             ),
//                           ),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(20),
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 250),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [
//                               Color(0xFFECF8F6),
//                               Color(0xFFFFFFFF),
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.25),
//                               blurRadius: 6,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             if (iconUrl.isNotEmpty)
//                               Image.network(
//                                 iconUrl,
//                                 width: 70,
//                                 height: 70,
//                                 fit: BoxFit.contain,
//                                 errorBuilder: (_, __, ___) => const Icon(
//                                     Icons.medical_services,
//                                     color: PatientAppColors.brandTeal,
//                                     size: 50),
//                               )
//                             else
//                               const Icon(Icons.medical_services,
//                                   color: PatientAppColors.brandTeal, size: 50),
//                             const SizedBox(height: 12),
//                             Text(
//                               displayName,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart' hide blackColor;
// import 'package:trustydr/pages/screens.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';

// class SpecialityScreen extends StatefulWidget {
//   final String? provinceKey;
//   final String? cityEn;

//   const SpecialityScreen({
//     super.key,
//     required this.provinceKey,
//     required this.cityEn,
//   });

//   @override
//   State<SpecialityScreen> createState() => _SpecialityScreenState();
// }

// class _SpecialityScreenState extends State<SpecialityScreen> {
//   /// "all" = show all doctors
//   /// otherwise: specialty_lower value (e.g. "dentistry")
//   String _selectedSpecialty = "all";

//   // -------------------------------
//   // Helpers
//   // -------------------------------
//   String _displaySpecialtyName(Map<String, dynamic> data) {
//     final lang = context.locale.languageCode;
//     final langMap = (data['lang'] ?? {}) as Map<String, dynamic>?;

//     if (lang == 'ar' && (langMap?['ar'] ?? '').toString().trim().isNotEmpty) {
//       return langMap!['ar'];
//     } else if (lang == 'ku' &&
//         (langMap?['ku'] ?? '').toString().trim().isNotEmpty) {
//       return langMap!['ku'];
//     }
//     return (data['name_en'] ?? '').toString();
//   }

//   // -------------------------------
//   // Streams
//   // -------------------------------
//   Stream<QuerySnapshot<Map<String, dynamic>>> _specialtyStream() {
//     return FirebaseFirestore.instance
//         .collection('specialties')
//         .where('status', isEqualTo: 'active')
//         .snapshots();
//   }

//   /// We fetch ALL doctors and filter on client,
//   /// so it supports both:
//   /// - Registered doctors: province_key + city_en
//   /// - Google imported clinics: province + city
//   Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _doctorStream() {
//     final provinceFilter = (widget.provinceKey ?? '').toLowerCase().trim();
//     final cityFilter = (widget.cityEn ?? '').toLowerCase().trim();

//     return FirebaseFirestore.instance
//         .collection('doctors')
//         .snapshots()
//         .map((snap) {
//       List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.docs;

//       docs = docs.where((doc) {
//         final data = doc.data();

//         // ✅ Status filter: default to "active" if missing
//         final status = (data['status'] ?? 'active').toString().toLowerCase();
//         if (status != 'active') return false;

//         // ✅ Location filter (supports both registered & Google clinics)
//         if (provinceFilter.isNotEmpty || cityFilter.isNotEmpty) {
//           final cityRaw =
//               (data['city_en'] ?? data['city'] ?? '').toString().toLowerCase();
//           final provRaw = (data['province_key'] ?? data['province'] ?? '')
//               .toString()
//               .toLowerCase();

//           if (cityFilter.isNotEmpty) {
//             final matchCity =
//                 cityRaw.contains(cityFilter) || provRaw.contains(cityFilter);
//             if (!matchCity) return false;
//           }

//           if (provinceFilter.isNotEmpty) {
//             final matchProv = cityRaw.contains(provinceFilter) ||
//                 provRaw.contains(provinceFilter);
//             if (!matchProv) return false;
//           }
//         }

//         // ✅ Specialty filter
//         if (_selectedSpecialty != "all") {
//           final specLower = (data['specialty_lower'] ?? data['specialty'] ?? '')
//               .toString()
//               .toLowerCase();
//           if (specLower != _selectedSpecialty.toLowerCase()) {
//             return false;
//           }
//         }

//         return true;
//       }).toList();

//       // ✅ Sort: registered → rating → name
//       docs.sort((a, b) {
//         final A = a.data();
//         final B = b.data();

//         final bool aVerified = A['verified'] == true || A['isVerified'] == true;
//         final bool bVerified = B['verified'] == true || B['isVerified'] == true;

//         // Registered (verified) first
//         if (aVerified != bVerified) {
//           if (aVerified) return -1;
//           return 1;
//         }

//         // Higher rating first
//         final double ar = (A['ratingAverage'] is num)
//             ? (A['ratingAverage'] as num).toDouble()
//             : 0.0;
//         final double br = (B['ratingAverage'] is num)
//             ? (B['ratingAverage'] as num).toDouble()
//             : 0.0;
//         if (ar != br) return br.compareTo(ar);

//         // Name A → Z
//         final an = (A['name'] ?? '').toString().toLowerCase();
//         final bn = (B['name'] ?? '').toString().toLowerCase();
//         return an.compareTo(bn);
//       });

//       return docs;
//     });
//   }

//   // -------------------------------
//   // UI
//   // -------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Column(
//         children: [
//           _header(),
//           const SizedBox(height: 10),
//           _specialtyBar(),
//           const SizedBox(height: 8),
//           Expanded(child: _doctorList()),
//         ],
//       ),
//     );
//   }

//   Widget _header() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.only(top: 55, left: 20, right: 20, bottom: 25),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon:
//                 const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               tr('Specialties'),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // -------------------------------
//   // Specialty scroll bar
//   // -------------------------------
//   Widget _specialtyBar() {
//     return SizedBox(
//       height: 110,
//       child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: _specialtyStream(),
//         builder: (context, snapshot) {
//           final items = <Widget>[];

//           // 🔹 "All" item – no filter
//           items.add(_specialtyItem(
//             name: tr('all_doctors'),
//             iconUrl: "",
//             value: "all",
//           ));

//           if (snapshot.hasError) {
//             return ListView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               children: items,
//             );
//           }

//           if (snapshot.hasData) {
//             for (final doc in snapshot.data!.docs) {
//               final data = doc.data();
//               final icon = (data['iconUrl'] ?? '').toString().trim();
//               final specLower =
//                   (data['name_en'] ?? '').toString().toLowerCase();

//               items.add(_specialtyItem(
//                 name: _displaySpecialtyName(data),
//                 iconUrl: icon,
//                 value: specLower,
//               ));
//             }
//           }

//           return ListView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             children: items,
//           );
//         },
//       ),
//     );
//   }

//   Widget _specialtyItem({
//     required String name,
//     required String iconUrl,
//     required String value,
//   }) {
//     final bool active = _selectedSpecialty == value;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedSpecialty = value;
//         });
//       },
//       child: Container(
//         width: 90,
//         margin: const EdgeInsets.only(right: 16),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           gradient: active
//               ? const LinearGradient(
//                   colors: [Color(0xFF4A90E2), Color(0xFF5CC6BA)],
//                 )
//               : null,
//           color: active ? null : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(active ? 0.15 : 0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             )
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (iconUrl.isNotEmpty)
//               Image.network(
//                 iconUrl,
//                 width: 40,
//                 height: 40,
//                 fit: BoxFit.contain,
//                 errorBuilder: (_, __, ___) => const Icon(
//                   Icons.medical_services,
//                   color: PatientAppColors.brandTeal,
//                   size: 40,
//                 ),
//               )
//             else
//               const Icon(Icons.medical_services, color: PatientAppColors.brandTeal, size: 40),
//             const SizedBox(height: 8),
//             Text(
//               name,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: active ? Colors.white : Colors.black87,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // -------------------------------
//   // Doctors list (registered + google)
//   // -------------------------------
//   Widget _doctorList() {
//     return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
//       stream: _doctorStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(color: PatientAppColors.brandTeal),
//           );
//         }

//         if (snapshot.hasError) {
//           return Center(
//             child: Text(
//               '${tr('error')}: ${snapshot.error}',
//               style: const TextStyle(color: Colors.black87),
//             ),
//           );
//         }

//         final docs = snapshot.data ?? [];

//         if (docs.isEmpty) {
//           return Center(
//             child: Text(
//               tr('no_doctors_found'),
//               style: const TextStyle(color: Colors.grey),
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           itemCount: docs.length,
//           itemBuilder: (_, i) {
//             final doc = docs[i];
//             final data = doc.data();

//             final id = doc.id;
//             final name = data['name'] ?? 'Unknown';
//             final specialty = data['specialty'] ?? '';
//             final exp = (data['experienceYears'] ?? 0).toString();
//             final rating = (data['ratingAverage'] is num)
//                 ? (data['ratingAverage'] as num).toDouble()
//                 : 0.0;
//             final reviews = (data['ratingCount'] ?? 0).toInt();
//             final clinic = data['clinicName'] ?? data['address'] ?? '';

//             final bool isVerified =
//                 data['verified'] == true || data['isVerified'] == true;

//             String imageUrl = 'assets/user/placeholder_user.png';
//             try {
//               final photos = data['photos'];
//               if (photos is List && photos.isNotEmpty) {
//                 final first = photos.first?.toString().trim();
//                 if (first != null && first.startsWith('http')) {
//                   imageUrl = first;
//                 }
//               } else if (data['imageUrl'] != null &&
//                   data['imageUrl'].toString().trim().startsWith('http')) {
//                 imageUrl = data['imageUrl'].toString().trim();
//               }
//             } catch (_) {}

//             return GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.fade,
//                     duration: const Duration(milliseconds: 400),
//                     child: DoctorProfile(doctorId: id),
//                   ),
//                 );
//               },
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 8,
//                       offset: const Offset(0, 3),
//                     )
//                   ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(14),
//                   child: Row(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(50),
//                         child: imageUrl.startsWith('http')
//                             ? Image.network(
//                                 imageUrl,
//                                 width: 90,
//                                 height: 90,
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (_, __, ___) => Image.asset(
//                                   'assets/user/placeholder_user.png',
//                                   width: 90,
//                                   height: 90,
//                                   fit: BoxFit.cover,
//                                 ),
//                               )
//                             : Image.asset(
//                                 imageUrl,
//                                 width: 90,
//                                 height: 90,
//                                 fit: BoxFit.cover,
//                               ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     'Dr. $name',
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: isVerified
//                                         ? PatientAppColors.brandBlue.withOpacity(0.15)
//                                         : Colors.orange.withOpacity(0.15),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     isVerified
//                                         ? tr('verified')
//                                         : tr('not_registered'),
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.w600,
//                                       color: isVerified
//                                           ? Colors.blue
//                                           : Colors.orange,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               specialty,
//                               style: const TextStyle(
//                                 color: PatientAppColors.brandTeal,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '$exp ${tr('years_experience')}',
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             if (clinic.isNotEmpty)
//                               Text(
//                                 clinic,
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.black45,
//                                   fontStyle: FontStyle.italic,
//                                 ),
//                               ),
//                             const SizedBox(height: 6),
//                             Row(
//                               children: [
//                                 const Icon(Icons.star,
//                                     color: Colors.amber, size: 16),
//                                 const SizedBox(width: 3),
//                                 Text(
//                                   rating.toStringAsFixed(1),
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 5),
//                                 Text(
//                                   '($reviews reviews)',
//                                   style: const TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

//working but we are moving to provilders so not FirebaseFirestore.instance in the code.

// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/pages/screens.dart';
// import 'package:trustydr/pages/speciality/google_clinic_details_page.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';

// class SpecialityScreen extends StatefulWidget {
//   final String? provinceKey;
//   final String? cityEn;
//   final bool showBack;

//   const SpecialityScreen({
//     super.key,
//     this.provinceKey,
//     this.cityEn,
//     this.showBack = false, // 👈 DEFAULT = root tab
//   });

//   @override
//   State<SpecialityScreen> createState() => _SpecialityScreenState();
// }

// class _SpecialityScreenState extends State<SpecialityScreen> {
//   Timer? _searchDebounce;

//   String _selectedSpecialty = "all";
//   String _searchQuery = "";

//   Stream<QuerySnapshot<Map<String, dynamic>>>? _specialtyStreamCached;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.cityEn != null && widget.cityEn!.isNotEmpty) {
//       _specialtyStreamCached = FirebaseFirestore.instance
//           .collection('specialties')
//           .where('status', isEqualTo: 'active')
//           .snapshots();
//     }
//   }

//   @override
//   void dispose() {
//     _searchDebounce?.cancel();
//     super.dispose();
//   }

//   // -------------------------------
//   // Helpers
//   // -------------------------------
//   Stream<QuerySnapshot<Map<String, dynamic>>> _googleClinicsStream() {
//     // 🔒 HARD GUARD — no city = no reads
//     if (widget.cityEn == null || widget.cityEn!.isEmpty) {
//       return const Stream.empty();
//     }

//     return FirebaseFirestore.instance
//         .collection('google_doctors')
//         .where('provinceKey', isEqualTo: widget.provinceKey)
//         .where(
//           'city_lower',
//           isEqualTo: widget.cityEn!.toLowerCase().trim(),
//         )
//         .snapshots();
//   }

//   String _displaySpecialtyName(Map<String, dynamic> data) {
//     final lang = context.locale.languageCode;
//     final langMap = (data['lang'] ?? {}) as Map<String, dynamic>?;

//     if (lang == 'ar' && (langMap?['ar'] ?? '').toString().trim().isNotEmpty) {
//       return langMap!['ar'];
//     } else if (lang == 'ku' &&
//         (langMap?['ku'] ?? '').toString().trim().isNotEmpty) {
//       return langMap!['ku'];
//     }
//     return (data['name_en'] ?? '').toString();
//   }

//   // -------------------------------
//   // Streams
//   // -------------------------------

//   Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _doctorStream() {
//     Query<Map<String, dynamic>> q =
//         FirebaseFirestore.instance.collection('doctors');

//     q = q.where('status', isEqualTo: 'active');

//     if (widget.provinceKey != null && widget.provinceKey!.isNotEmpty) {
//       q = q.where('province_key', isEqualTo: widget.provinceKey);
//     }

//     if (_selectedSpecialty != "all") {
//       q = q.where('specialty_lower', isEqualTo: _selectedSpecialty);
//     }

//     return q.snapshots().map((snap) {
//       var docs = snap.docs;

//       // 🔍 APPLY SEARCH (debounced)
//       if (_searchQuery.trim().isNotEmpty) {
//         final q = _searchQuery.toLowerCase().trim();
//         docs = docs.where((doc) {
//           final d = doc.data();
//           return (d['name'] ?? '').toString().toLowerCase().contains(q) ||
//               (d['specialty'] ?? '').toString().toLowerCase().contains(q) ||
//               (d['clinicName'] ?? '').toString().toLowerCase().contains(q);
//         }).toList();
//       }

//       return docs;
//     });
//   }

//   // -------------------------------
//   // UI
//   // -------------------------------
//   @override
//   Widget build(BuildContext context) {
//     // 🔒 HARD GUARD — no city → no Firestore reads
//     if (_specialtyStreamCached == null) {
//       return Center(
//         child: Text(
//           tr('select_city_first'),
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.black54,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       );
//     }
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Column(
//         children: [
//           _header(),
//           const SizedBox(height: 12),
//           _searchBar(),
//           const SizedBox(height: 10),
//           _specialtyBar(),
//           const SizedBox(height: 8),
//           Expanded(
//             child: CustomScrollView(
//               key: const PageStorageKey('speciality_scroll'), // ✅ keeps scroll
//               slivers: [
//                 SliverToBoxAdapter(child: _doctorList()),
//                 if (_selectedSpecialty == "all")
//                   SliverToBoxAdapter(child: _googleClinicsSection()),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _googleClinicsSection() {
//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: _googleClinicsStream(), // ✅ cached stream
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Padding(
//             padding: EdgeInsets.all(24),
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const SizedBox.shrink();
//         }

//         final docs = snapshot.data!.docs;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Divider(thickness: 1.2),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//               child: Text(
//                 tr('google_clinics_title'),
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ...docs.map((doc) {
//               final d = doc.data();

//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                 color: Colors.orange.shade50,
//                 child: ListTile(
//                   leading: const Icon(
//                     Icons.local_hospital,
//                     color: Colors.orange,
//                   ),
//                   title: Text(
//                     d['name'] ?? '',
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Text(d['address'] ?? ''),
//                   trailing: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         tr('from_google'),
//                         style: const TextStyle(
//                           color: Colors.orange,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         tr('not_registered'),
//                         style: const TextStyle(
//                           color: Colors.orange,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => GoogleClinicDetailsPage(data: d),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             }),
//           ],
//         );
//       },
//     );
//   }

//   Widget _header() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.only(top: 55, left: 20, right: 20, bottom: 25),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
//       ),
//       child: Row(
//         children: [
//           if (widget.showBack)
//             IconButton(
//               onPressed: () => Navigator.of(context).maybePop(),
//               icon: const Icon(
//                 Icons.arrow_back_ios,
//                 color: Colors.white,
//                 size: 22,
//               ),
//             ),
//           if (widget.showBack) const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               tr('specialties.title'),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // -------------------------------
//   // Search Bar
//   // -------------------------------
//   Widget _searchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Container(
//         height: 46,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 5,
//               offset: const Offset(0, 3),
//             )
//           ],
//         ),
//         child: TextField(
//           onChanged: (val) {
//             _searchDebounce?.cancel();
//             _searchDebounce = Timer(
//               const Duration(milliseconds: 350),
//               () => setState(() => _searchQuery = val),
//             );
//           },
//           decoration: InputDecoration(
//             hintText: tr('search_doctor_or_clinic'),
//             hintStyle: const TextStyle(color: Colors.grey),
//             prefixIcon: const Icon(Icons.search, color: Colors.grey),
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//           ),
//         ),
//       ),
//     );
//   }

//   // -------------------------------
//   // Horizontal Specialties
//   // -------------------------------
//   Widget _specialtyBar() {
//     return SizedBox(
//       height: 110,
//       child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: _specialtyStreamCached,
//         builder: (context, snapshot) {
//           final items = <Widget>[];

//           items.add(_specialtyItem(
//             name: tr('all_doctors'),
//             iconUrl: "",
//             value: "all",
//           ));

//           if (snapshot.hasData) {
//             for (final doc in snapshot.data!.docs) {
//               final data = doc.data();
//               final icon = (data['iconUrl'] ?? '').toString().trim();
//               final specLower =
//                   (data['name_en'] ?? '').toString().toLowerCase();

//               items.add(_specialtyItem(
//                 name: _displaySpecialtyName(data),
//                 iconUrl: icon,
//                 value: specLower,
//               ));
//             }
//           }

//           return ListView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             children: items,
//           );
//         },
//       ),
//     );
//   }

//   Widget _specialtyItem({
//     required String name,
//     required String iconUrl,
//     required String value,
//   }) {
//     final active = _selectedSpecialty == value;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedSpecialty = value;
//         });
//       },
//       child: Container(
//         width: 90,
//         margin: const EdgeInsets.only(right: 16),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           gradient: active
//               ? const LinearGradient(
//                   colors: [Color(0xFF4A90E2), Color(0xFF5CC6BA)],
//                 )
//               : null,
//           color: active ? null : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(active ? 0.15 : 0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             )
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             (iconUrl.isNotEmpty)
//                 ? Image.network(
//                     iconUrl,
//                     width: 40,
//                     height: 40,
//                     errorBuilder: (_, __, ___) => const Icon(
//                       Icons.medical_services,
//                       color: PatientAppColors.brandTeal,
//                       size: 40,
//                     ),
//                   )
//                 : const Icon(
//                     Icons.medical_services,
//                     color: PatientAppColors.brandTeal,
//                     size: 40,
//                   ),
//             const SizedBox(height: 8),
//             Text(
//               name,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: active ? Colors.white : Colors.black87,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ----------------------------------------------------------
//   // Doctor image widget with rounded fallback avatar
//   // ----------------------------------------------------------
//   Widget doctorImage(String? imageUrl) {
//     const fallback = 'assets/icons/stethoscope.png';

//     if (imageUrl == null || imageUrl.trim().isEmpty) {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(50),
//         child: Image.asset(
//           fallback,
//           width: 90,
//           height: 90,
//           fit: BoxFit.cover,
//         ),
//       );
//     }

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(50),
//       child: Image.network(
//         imageUrl,
//         width: 90,
//         height: 90,
//         fit: BoxFit.cover,
//         cacheWidth: 180, // 👈 2x size for sharpness
//         filterQuality: FilterQuality.low,
//         errorBuilder: (_, __, ___) {
//           return Image.asset(
//             fallback,
//             width: 90,
//             height: 90,
//             fit: BoxFit.cover,
//           );
//         },
//       ),
//     );
//   }

//   // -------------------------------
//   // Doctor List
//   // -------------------------------
//   Widget _doctorList() {
//     return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
//       stream: _doctorStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Padding(
//             padding: EdgeInsets.only(top: 40),
//             child: Center(child: CircularProgressIndicator(color: PatientAppColors.brandTeal)),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Padding(
//               padding: const EdgeInsets.only(top: 40),
//               child: Text(
//                 tr('no_doctors_found'),
//                 style: const TextStyle(color: Colors.grey),
//               ),
//             ),
//           );
//         }

//         final docs = snapshot.data!;

//         return Column(
//           children: List.generate(docs.length, (i) {
//             final doc = docs[i];
//             final data = doc.data();

//             final id = doc.id;
//             final name = (data['name'] ?? 'Unknown')
//                 .toString()
//                 .replaceFirst(RegExp(r'^Dr\. ?', caseSensitive: false), '');

//             final specialty = data['specialty'] ?? '';
//             final exp = (data['experienceYears'] ?? 0).toString();
//             final rating = (data['ratingAverage'] is num)
//                 ? (data['ratingAverage'] as num).toDouble()
//                 : 0.0;
//             final reviews = (data['ratingCount'] ?? 0).toInt();
//             final clinic =
//                 data['clinicName'] ?? data['address'] ?? data['city'] ?? '';

//             final isVerified =
//                 data['verified'] == true || data['isVerified'] == true;

//             String imageUrl = 'assets/user/placeholder_user.png';
//             try {
//               final photos = data['photos'];
//               if (photos is List && photos.isNotEmpty) {
//                 final first = photos.first?.toString().trim();
//                 if (first != null && first.startsWith('http')) imageUrl = first;
//               } else if (data['imageUrl'] != null &&
//                   data['imageUrl'].toString().trim().startsWith('http')) {
//                 imageUrl = data['imageUrl'].toString().trim();
//               }
//             } catch (_) {}

//             return GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.fade,
//                     duration: const Duration(milliseconds: 400),
//                     child: DoctorProfile(doctorId: id),
//                   ),
//                 );
//               },
//               child: Container(
//                 margin: const EdgeInsets.only(bottom: 14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 8,
//                       offset: const Offset(0, 3),
//                     )
//                   ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(14),
//                   child: Row(
//                     children: [
//                       doctorImage(imageUrl),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     "Dr. $name",
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: isVerified
//                                         ? PatientAppColors.brandBlue.withOpacity(0.15)
//                                         : Colors.orange.withOpacity(0.15),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     isVerified
//                                         ? tr('verified')
//                                         : tr('not_registered'),
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.w600,
//                                       color: isVerified
//                                           ? Colors.blue
//                                           : Colors.orange,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               specialty,
//                               style: const TextStyle(
//                                 color: PatientAppColors.brandTeal,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               "$exp ${tr('years_experience')}",
//                               style: const TextStyle(
//                                 color: Colors.black54,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             if (clinic.isNotEmpty)
//                               Text(
//                                 clinic,
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.black45,
//                                 ),
//                               ),
//                             const SizedBox(height: 6),
//                             Row(
//                               children: [
//                                 const Icon(Icons.star,
//                                     color: Colors.amber, size: 16),
//                                 const SizedBox(width: 3),
//                                 Text(
//                                   rating.toStringAsFixed(1),
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 const SizedBox(width: 5),
//                                 Text(
//                                   "($reviews ${tr('reviews')})",
//                                   style: const TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }

import 'dart:async';

import 'package:trustydr/pages/doctor/doctor_profile_v2.dart';
import 'package:trustydr/widget/doctor_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:page_transition/page_transition.dart';

import 'package:trustydr/core/providers/app_location_provider.dart';
import 'package:trustydr/core/providers/doctor_streams_provider.dart';
import 'package:trustydr/pages/screens.dart';
import 'package:trustydr/pages/speciality/google_clinic_details_page.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';

class SpecialityScreen extends ConsumerStatefulWidget {
  final bool showBack;

  const SpecialityScreen({
    super.key,
    this.showBack = true,
  });

  @override
  ConsumerState<SpecialityScreen> createState() => _SpecialityScreenState();
}

class _SpecialityScreenState extends ConsumerState<SpecialityScreen> {
  Timer? _searchDebounce;

  String _selectedSpecialty = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final location = ref.watch(appLocationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget content = Column(
            children: [
              TrustyDrCurvedHeader(
                title: 'specialties.title'.tr(),
                showBack: widget.showBack,
                height: 160,
              ),
              const SizedBox(height: 12),
              _searchBar(),
              const SizedBox(height: 10),
              _specialtyBar(),
              const SizedBox(height: 8),
              Expanded(
                child: location == null ||
                        location.cityEn.isEmpty ||
                        location.provinceKey.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            tr('select_city_first'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        key: const PageStorageKey('speciality_scroll'),
                        slivers: [
                          SliverToBoxAdapter(child: _doctorList()),
                          if (_selectedSpecialty == 'all')
                            SliverToBoxAdapter(
                              child: _googleClinicsSection(),
                            ),
                        ],
                      ),
              ),
            ],
          );
          if (constraints.maxWidth >= 768)
            content = WebScaffoldContainer(child: content);
          return content;
        },
      ),
    );
  }

  // --------------------------------------------------
  // Header
  // --------------------------------------------------
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 55, left: 20, right: 20, bottom: 25),
      decoration: const BoxDecoration(
        gradient: PatientAppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Row(
        children: [
          if (widget.showBack)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 22,
              ),
            ),
          if (widget.showBack) const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('specialties.title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Search Bar (local filter only — NO FIRESTORE)
  // --------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextField(
          onChanged: (val) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(
              const Duration(milliseconds: 350),
              () => setState(() => _searchQuery = val),
            );
          },
          decoration: InputDecoration(
            hintText: tr('search_doctor_or_clinic'),
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Specialties Bar (provider-based)
  // --------------------------------------------------
  Widget _specialtyBar() {
    final specialtiesAsync = ref.watch(specialtiesStreamProvider);

    return SizedBox(
      height: 110,
      child: specialtiesAsync.when(
        data: (snap) {
          final items = <Widget>[
            _specialtyItem(
              name: tr('all_doctors'),
              value: 'all',
            ),
          ];

          for (final doc in snap.docs) {
            final data = doc.data();
            items.add(
              _specialtyItem(
                name: _displaySpecialtyName(data),
                value: (data['name_en'] ?? '').toString().toLowerCase(),
              ),
            );
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: items,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _specialtyItem({
    required String name,
    required String value,
  }) {
    final active = _selectedSpecialty == value;
    final location = ref.read(appLocationProvider);

    return GestureDetector(
      onTap: () {
        // 🔒 UX guard only (NOT for Firestore)
        if (location == null || location.cityEn == null) return;

        setState(() => _selectedSpecialty = value);
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: active ? PatientAppColors.reverseBrandGradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _displaySpecialtyName(Map<String, dynamic> data) {
    final lang = context.locale.languageCode;
    final langMap = (data['lang'] ?? {}) as Map<String, dynamic>?;

    if (lang == 'ar' && (langMap?['ar'] ?? '').toString().isNotEmpty) {
      return langMap!['ar'];
    }
    if (lang == 'ku' && (langMap?['ku'] ?? '').toString().isNotEmpty) {
      return langMap!['ku'];
    }
    return (data['name_en'] ?? '').toString();
  }

  // --------------------------------------------------
  // Doctors (PROVIDER ONLY)
  // --------------------------------------------------
  Widget _doctorList() {
    final doctorsAsync = ref.watch(doctorsStreamProvider);

    return doctorsAsync.when(
      data: (docs) {
        final filtered = docs.where((doc) {
          final d = doc.data();

          // 1️⃣ Specialty filter
          if (_selectedSpecialty != 'all') {
            final doctorSpecialty =
                (d['specialty'] ?? '').toString().toLowerCase();

            if (doctorSpecialty != _selectedSpecialty) {
              return false;
            }
          }

          // 2️⃣ Search filter
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();

            return (d['name'] ?? '').toString().toLowerCase().contains(q) ||
                (d['specialty'] ?? '').toString().toLowerCase().contains(q) ||
                (d['clinicName'] ?? '').toString().toLowerCase().contains(q);
          }

          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                tr('no_doctors_found'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: List.generate(filtered.length, (i) {
            final doc = filtered[i];
            final data = doc.data();

            final id = doc.id;

            final lang = context.locale.languageCode;

// ---------- NAME ----------
            final nameEn = (data['name_en'] ?? '').toString();
            final nameAr = (data['name_ar'] ?? nameEn).toString();
            final nameKu = (data['name_ku'] ?? nameEn).toString();

            final name = lang == 'ar'
                ? nameAr
                : lang == 'ku'
                    ? nameKu
                    : nameEn;

// ---------- SPECIALTY ----------
            final specialtyEn =
                (data['specialty_en'] ?? data['specialtyName_en'] ?? '')
                    .toString();

            final specialtyAr = (data['specialty_ar'] ??
                    data['specialtyName_ar'] ??
                    specialtyEn)
                .toString();

            final specialtyKu = (data['specialty_ku'] ??
                    data['specialtyName_ku'] ??
                    specialtyEn)
                .toString();

            final specialty = lang == 'ar'
                ? specialtyAr
                : lang == 'ku'
                    ? specialtyKu
                    : specialtyEn;

// ---------- EXPERIENCE ----------
            final exp =
                (data['yearsOfExperience'] ?? data['experienceYears'] ?? 0)
                    .toString();

            final rating = (data['ratingAverage'] is num)
                ? (data['ratingAverage'] as num).toDouble()
                : 0.0;
            final reviews = (data['ratingCount'] ?? 0).toInt();
            final clinic =
                data['clinicName'] ?? data['address'] ?? data['city'] ?? '';

            final isVerified =
                data['verified'] == true || data['isVerified'] == true;

            String imageUrl = 'assets/user/placeholder_user.png';
            try {
              final photos = data['photos'];
              if (photos is List && photos.isNotEmpty) {
                final first = photos.first?.toString().trim();
                if (first != null && first.startsWith('http')) {
                  imageUrl = first;
                }
              } else if (data['imageUrl'] != null &&
                  data['imageUrl'].toString().trim().startsWith('http')) {
                imageUrl = data['imageUrl'].toString().trim();
              }
            } catch (_) {}

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 400),
                    child: DoctorProfileV2(doctorId: id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      DoctorAvatar(imageUrl: imageUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'doctor_prefix_name'.tr(args: [name]),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? PatientAppColors.brandBlue
                                            .withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isVerified
                                        ? tr('verified')
                                        : tr('not_registered'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isVerified
                                          ? PatientAppColors.brandBlue
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: const TextStyle(
                                color: PatientAppColors.brandTeal,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$exp ${tr('years_experience')}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            if (clinic.isNotEmpty)
                              Text(
                                clinic,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "($reviews ${tr('reviews')})",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
            child:
                CircularProgressIndicator(color: PatientAppColors.brandTeal)),
      ),
      error: (e, st) {
        return Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'error_generic'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------
  // Google Clinics (PROVIDER ONLY)
  // --------------------------------------------------
  Widget _googleClinicsSection() {
    final clinicsAsync = ref.watch(googleClinicsStreamProvider);

    return clinicsAsync.when(
      data: (snap) {
        if (snap.docs.isEmpty) return const SizedBox.shrink();

        final docs = snap.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(thickness: 1.2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                tr('google_clinics_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...docs.map((doc) {
              final d = doc.data();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(
                    Icons.local_hospital,
                    color: Colors.orange,
                  ),
                  title: Text(
                    (d['name'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text((d['address'] ?? '').toString()),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr('from_google'),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        tr('not_registered'),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GoogleClinicDetailsPage(data: d),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
