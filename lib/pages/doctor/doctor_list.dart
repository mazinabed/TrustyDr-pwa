// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:trustydr/constant/constant.dart';
// // // import 'package:trustydr/pages/screens.dart';
// // // import 'package:trustydr/services/database_service.dart';
// // // import 'package:easy_localization/easy_localization.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:page_transition/page_transition.dart';
// // // import 'package:url_launcher/url_launcher.dart' show launchUrl;

// // // class DoctorList extends StatefulWidget {
// // //   final String? doctorType;
// // //   final String? provinceKey;
// // //   final String? cityEn;

// // //   const DoctorList({
// // //     super.key,
// // //     this.doctorType,
// // //     this.provinceKey,
// // //     this.cityEn,
// // //   });

// // //   @override
// // //   State<DoctorList> createState() => _DoctorListState();
// // // }

// // // class _DoctorListState extends State<DoctorList> {
// // //   final _firestore = FirebaseFirestore.instance;
// // //   final _dbService = DatabaseService();
// // //   String _searchQuery = '';

// // //   Stream<QuerySnapshot<Map<String, dynamic>>> _doctorStream() {
// // //     Query<Map<String, dynamic>> q = _firestore.collection('doctors');

// // //     // 🔹 Always filter active doctors ONCE
// // //     q = q.where('status', isEqualTo: 'active');

// // //     // 🔹 Province filter
// // //     if (widget.provinceKey?.isNotEmpty ?? false) {
// // //       q = q.where('province_key', isEqualTo: widget.provinceKey);
// // //     }

// // //     // 🔹 City filter
// // //     if (widget.cityEn?.isNotEmpty ?? false) {
// // //       q = q.where('city_en', isEqualTo: widget.cityEn);
// // //     }

// // //     // 🔹 Doctor specialty filter
// // //     if (widget.doctorType?.isNotEmpty ?? false) {
// // //       q = q.where(
// // //         'specialty_lower',
// // //         isEqualTo: widget.doctorType!.toLowerCase(),
// // //       );
// // //     }

// // //     // ❌ Do NOT add ".where('status')" here again — that caused the crash
// // //     // ❌ Do NOT filter "isVerified" here — we want both verified & unverified

// // //     return q.snapshots();
// // //   }

// // //   void _showLoginPrompt() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
// // //       ),
// // //       builder: (_) => Padding(
// // //         padding: const EdgeInsets.all(24),
// // //         child: Column(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
// // //             const SizedBox(height: 12),
// // //             Text(tr('login_required'),
// // //                 style:
// // //                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //             const SizedBox(height: 8),
// // //             Text(tr('login_to_book'),
// // //                 textAlign: TextAlign.center,
// // //                 style: const TextStyle(color: Colors.black54)),
// // //             const SizedBox(height: 16),
// // //             ElevatedButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context);
// // //                 Navigator.push(
// // //                   context,
// // //                   PageTransition(
// // //                     type: PageTransitionType.rightToLeft,
// // //                     child: const LoginScreen(),
// // //                   ),
// // //                 );
// // //               },
// // //               style: ElevatedButton.styleFrom(
// // //                 backgroundColor: primaryColor,
// // //                 minimumSize: const Size.fromHeight(44),
// // //                 shape: RoundedRectangleBorder(
// // //                     borderRadius: BorderRadius.circular(8)),
// // //               ),
// // //               child: Text(tr('go_to_login'),
// // //                   style: const TextStyle(color: Colors.white, fontSize: 16)),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final title = widget.doctorType != null
// // //         ? "${widget.doctorType} Doctors"
// // //         : tr('doctors');

// // //     return Scaffold(
// // //       backgroundColor: Colors.grey[100],
// // //       appBar: AppBar(
// // //         elevation: 0,
// // //         centerTitle: true,
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
// // //           onPressed: () => Navigator.pop(context),
// // //         ),
// // //         title: Text(
// // //           title,
// // //           style: const TextStyle(
// // //             color: Colors.white,
// // //             fontWeight: FontWeight.bold,
// // //             fontSize: 20,
// // //           ),
// // //         ),
// // //         flexibleSpace: Container(
// // //           decoration: const BoxDecoration(
// // //             gradient: LinearGradient(
// // //               colors: [Color(0xFF4A90E2), Color(0xFF5CC6BA)],
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //             ),
// // //           ),
// // //         ),
// // //         bottom: PreferredSize(
// // //           preferredSize: const Size.fromHeight(60),
// // //           child: Padding(
// // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //             child: _buildSearchBar(),
// // //           ),
// // //         ),
// // //       ),
// // //       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
// // //         stream: _doctorStream(),
// // //         builder: (context, snapshot) {
// // //           if (snapshot.connectionState == ConnectionState.waiting) {
// // //             return const Center(
// // //               child: CircularProgressIndicator(color: Colors.teal),
// // //             );
// // //           }

// // //           if (snapshot.hasError) {
// // //             return Center(
// // //               child: Text(
// // //                 "${tr('error')}: ${snapshot.error}",
// // //                 style: const TextStyle(color: Colors.black87),
// // //               ),
// // //             );
// // //           }

// // //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// // //             return Center(
// // //               child: Text(
// // //                 tr('no_doctors_found'),
// // //                 style: const TextStyle(color: Colors.grey),
// // //               ),
// // //             );
// // //           }

// // //           final filteredDocs = snapshot.data!.docs.where((doc) {
// // //             final name = (doc['name'] ?? '').toString().toLowerCase();
// // //             return name.contains(_searchQuery.toLowerCase());
// // //           }).toList();

// // //           if (filteredDocs.isEmpty) {
// // //             return Center(
// // //               child: Text(
// // //                 tr('no_matches_found'),
// // //                 style: const TextStyle(color: Colors.grey),
// // //               ),
// // //             );
// // //           }

// // //           return ListView.builder(
// // //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
// // //             itemCount: filteredDocs.length,
// // //             itemBuilder: (context, index) {
// // //               final doc = filteredDocs[index];
// // //               final data = doc.data();

// // //               final id = doc.id;
// // //               final name = data['name'] ?? 'Unknown';
// // //               final specialty = data['specialty'] ?? '';
// // //               final exp = (data['experienceYears'] ?? 0).toString();
// // //               final rating = (data['ratingAverage'] ?? 0).toDouble();
// // //               final reviews = (data['ratingCount'] ?? 0).toInt();
// // //               final clinic = data['clinicName'] ?? '';

// // //               // 🔹 NEW: check verification state from new model
// // //               final bool isVerified =
// // //                   data['isVerified'] ?? data['verified'] ?? true;
// // //               final String verificationStatus = data['verificationStatus'] ??
// // //                   (isVerified ? "verified" : "unverified");

// // //               String imageUrl = 'assets/user/placeholder_user.png';
// // //               try {
// // //                 final photos = data['photos'];
// // //                 if (photos != null) {
// // //                   if (photos is List && photos.isNotEmpty) {
// // //                     final firstUrl = photos.first?.toString().trim();
// // //                     if (firstUrl != null && firstUrl.startsWith('http')) {
// // //                       imageUrl = firstUrl;
// // //                     }
// // //                   } else if (photos is String &&
// // //                       photos.trim().startsWith('http')) {
// // //                     imageUrl = photos.trim();
// // //                   }
// // //                 } else if (data['photoUrl'] != null &&
// // //                     data['photoUrl'].toString().trim().startsWith('http')) {
// // //                   imageUrl = data['photoUrl'].toString().trim();
// // //                 }
// // //               } catch (e) {
// // //                 debugPrint('⚠️ Image load error for $name: $e');
// // //               }

// // //               return GestureDetector(
// // //                 onTap: () {
// // //                   Navigator.push(
// // //                     context,
// // //                     PageTransition(
// // //                       type: PageTransitionType.fade,
// // //                       duration: const Duration(milliseconds: 400),
// // //                       child: DoctorProfile(doctorId: id),
// // //                     ),
// // //                   );
// // //                 },
// // //                 child: Container(
// // //                   margin: const EdgeInsets.only(bottom: 14),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.white,
// // //                     borderRadius: BorderRadius.circular(16),
// // //                     boxShadow: [
// // //                       BoxShadow(
// // //                         color: Colors.black.withOpacity(0.05),
// // //                         blurRadius: 8,
// // //                         offset: const Offset(0, 3),
// // //                       )
// // //                     ],
// // //                   ),
// // //                   child: Padding(
// // //                     padding: const EdgeInsets.all(14),
// // //                     child: Row(
// // //                       children: [
// // //                         ClipRRect(
// // //                           borderRadius: BorderRadius.circular(50),
// // //                           child: imageUrl.startsWith('http')
// // //                               ? Image.network(
// // //                                   imageUrl,
// // //                                   width: 90,
// // //                                   height: 90,
// // //                                   fit: BoxFit.cover,
// // //                                   errorBuilder: (_, __, ___) => Image.asset(
// // //                                     'assets/user/placeholder_user.png',
// // //                                     width: 90,
// // //                                     height: 90,
// // //                                     fit: BoxFit.cover,
// // //                                   ),
// // //                                 )
// // //                               : Image.asset(
// // //                                   imageUrl,
// // //                                   width: 90,
// // //                                   height: 90,
// // //                                   fit: BoxFit.cover,
// // //                                 ),
// // //                         ),
// // //                         const SizedBox(width: 16),
// // //                         Expanded(
// // //                           child: Column(
// // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // //                             children: [
// // //                               Row(
// // //                                 children: [
// // //                                   Expanded(
// // //                                     child: Text(
// // //                                       'Dr. $name',
// // //                                       style: const TextStyle(
// // //                                         fontSize: 16,
// // //                                         fontWeight: FontWeight.bold,
// // //                                         color: Colors.black87,
// // //                                       ),
// // //                                     ),
// // //                                   ),

// // //                                   // 🔹 NEW BADGE FOR VERIFIED/UNVERIFIED
// // //                                   Container(
// // //                                     padding: const EdgeInsets.symmetric(
// // //                                         horizontal: 8, vertical: 4),
// // //                                     decoration: BoxDecoration(
// // //                                       color: isVerified
// // //                                           ? Colors.blue.withOpacity(0.15)
// // //                                           : Colors.orange.withOpacity(0.15),
// // //                                       borderRadius: BorderRadius.circular(8),
// // //                                     ),
// // //                                     child: Text(
// // //                                       isVerified
// // //                                           ? tr('verified')
// // //                                           : tr('not_registered'),
// // //                                       style: TextStyle(
// // //                                         fontSize: 11,
// // //                                         fontWeight: FontWeight.w600,
// // //                                         color: isVerified
// // //                                             ? Colors.blue
// // //                                             : Colors.orange,
// // //                                       ),
// // //                                     ),
// // //                                   ),
// // //                                 ],
// // //                               ),
// // //                               const SizedBox(height: 4),
// // //                               Text(
// // //                                 specialty,
// // //                                 style: const TextStyle(
// // //                                     color: Colors.teal, fontSize: 13),
// // //                               ),
// // //                               const SizedBox(height: 4),
// // //                               Text(
// // //                                 '$exp ${tr('years_experience')}',
// // //                                 style: const TextStyle(
// // //                                   color: Colors.black54,
// // //                                   fontSize: 12,
// // //                                 ),
// // //                               ),
// // //                               if (clinic.isNotEmpty)
// // //                                 Text(
// // //                                   clinic,
// // //                                   style: const TextStyle(
// // //                                     fontSize: 12,
// // //                                     color: Colors.black45,
// // //                                     fontStyle: FontStyle.italic,
// // //                                   ),
// // //                                 ),
// // //                               const SizedBox(height: 6),
// // //                               Row(
// // //                                 children: [
// // //                                   const Icon(Icons.star,
// // //                                       color: Colors.amber, size: 16),
// // //                                   const SizedBox(width: 3),
// // //                                   Text(
// // //                                     rating.toStringAsFixed(1),
// // //                                     style: const TextStyle(
// // //                                         fontWeight: FontWeight.bold),
// // //                                   ),
// // //                                   const SizedBox(width: 5),
// // //                                   Text(
// // //                                     '($reviews reviews)',
// // //                                     style: const TextStyle(
// // //                                       color: Colors.grey,
// // //                                       fontSize: 12,
// // //                                     ),
// // //                                   ),
// // //                                 ],
// // //                               ),
// // //                               const SizedBox(height: 8),

// // // // -------------------------
// // // // Contact Section
// // // // -------------------------
// // //                               if ((data['phone'] ?? '')
// // //                                   .toString()
// // //                                   .trim()
// // //                                   .isNotEmpty)
// // //                                 ElevatedButton.icon(
// // //                                   style: ElevatedButton.styleFrom(
// // //                                     backgroundColor: Colors.teal,
// // //                                     foregroundColor: Colors.white,
// // //                                     minimumSize: const Size(120, 36),
// // //                                     padding: const EdgeInsets.symmetric(
// // //                                         horizontal: 12, vertical: 6),
// // //                                     shape: RoundedRectangleBorder(
// // //                                       borderRadius: BorderRadius.circular(10),
// // //                                     ),
// // //                                   ),
// // //                                   icon: const Icon(Icons.call, size: 16),
// // //                                   label: Text(tr('call_now')),
// // //                                   onPressed: () {
// // //                                     final phone = data['phone'].toString();
// // //                                     launchUrl(Uri.parse("tel:$phone"));
// // //                                   },
// // //                                 )
// // //                               else
// // //                                 Text(
// // //                                   tr('no_contact_info'),
// // //                                   style: const TextStyle(
// // //                                     color: Colors.grey,
// // //                                     fontStyle: FontStyle.italic,
// // //                                     fontSize: 12,
// // //                                   ),
// // //                                 ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildSearchBar() {
// // //     return Container(
// // //       height: 46,
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(30),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withOpacity(0.08),
// // //             blurRadius: 5,
// // //             offset: const Offset(0, 3),
// // //           )
// // //         ],
// // //       ),
// // //       child: TextField(
// // //         onChanged: (val) => setState(() => _searchQuery = val),
// // //         decoration: InputDecoration(
// // //           hintText: tr('search_doctor'),
// // //           hintStyle: const TextStyle(color: Colors.grey),
// // //           prefixIcon: const Icon(Icons.search, color: Colors.grey),
// // //           border: InputBorder.none,
// // //           contentPadding: const EdgeInsets.symmetric(horizontal: 16),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/screens.dart';
// import 'package:trustydr/services/database_service.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:url_launcher/url_launcher.dart' show launchUrl;

// class DoctorList extends StatefulWidget {
//   final String? doctorType;
//   final String? provinceKey;
//   final String? cityEn;

//   const DoctorList({
//     super.key,
//     this.doctorType,
//     this.provinceKey,
//     this.cityEn,
//   });

//   @override
//   State<DoctorList> createState() => _DoctorListState();
// }

// class _DoctorListState extends State<DoctorList> {
//   final _firestore = FirebaseFirestore.instance;
//   final _dbService = DatabaseService();
//   String _searchQuery = '';

//   // ✅ CHANGE THIS to your seeded/google collection name
//   static const String seedCollection = 'google_doctors';

//   // ---------------------------
//   // Real doctors stream (bookable)
//   // ---------------------------
//   Stream<QuerySnapshot<Map<String, dynamic>>> _doctorStream() {
//     Query<Map<String, dynamic>> q = _firestore.collection('doctors');

//     // ✅ Only ACTIVE real doctors
//     q = q.where('status', isEqualTo: 'active');

//     if (widget.provinceKey?.isNotEmpty ?? false) {
//       q = q.where('province_key', isEqualTo: widget.provinceKey);
//     }

//     if (widget.cityEn?.isNotEmpty ?? false) {
//       q = q.where('city_en', isEqualTo: widget.cityEn);
//     }

//     if (widget.doctorType?.isNotEmpty ?? false) {
//       q = q.where(
//         'specialty_lower',
//         isEqualTo: widget.doctorType!.toLowerCase(),
//       );
//     }

//     return q.snapshots();
//   }

//   // ---------------------------
//   // Seed clinics stream (google/facebook)
//   // Bottom section ONLY. Not filtered by specialty.
//   // ---------------------------
//   Stream<QuerySnapshot<Map<String, dynamic>>> _seedClinicsStream() {
//     Query<Map<String, dynamic>> q = _firestore.collection(seedCollection);

//     // Seed clinics should be active only
//     q = q.where('isActive', isEqualTo: true);

//     // Filter by province/city (based on your doc fields: province_key, city_en)
//     if (widget.provinceKey?.isNotEmpty ?? false) {
//       q = q.where('province_key', isEqualTo: widget.provinceKey);
//     }

//     if (widget.cityEn?.isNotEmpty ?? false) {
//       q = q.where('city_en', isEqualTo: widget.cityEn);
//     }

//     return q.snapshots();
//   }

//   void _showLoginPrompt() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (_) => Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
//             const SizedBox(height: 12),
//             Text(tr('login_required'),
//                 style:
//                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text(tr('login_to_book'),
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(color: Colors.black54)),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.rightToLeft,
//                     child: const LoginScreen(),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 minimumSize: const Size.fromHeight(44),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8)),
//               ),
//               child: Text(tr('go_to_login'),
//                   style: const TextStyle(color: Colors.white, fontSize: 16)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final title = widget.doctorType != null
//         ? "${widget.doctorType} Doctors"
//         : tr('doctors');

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF4A90E2), Color(0xFF5CC6BA)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(60),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: _buildSearchBar(),
//           ),
//         ),
//       ),

//       // ✅ Outer stream = real doctors
//       body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: _doctorStream(),
//         builder: (context, doctorSnap) {
//           if (doctorSnap.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.teal),
//             );
//           }

//           if (doctorSnap.hasError) {
//             return Center(
//               child: Text(
//                 "${tr('error')}: ${doctorSnap.error}",
//                 style: const TextStyle(color: Colors.black87),
//               ),
//             );
//           }

//           final doctorDocs = (doctorSnap.data?.docs ?? []).where((doc) {
//             final name = (doc['name'] ?? '').toString().toLowerCase();
//             return name.contains(_searchQuery.toLowerCase());
//           }).toList();

//           // ✅ Inner stream = seed clinics (bottom section)
//           return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//             stream: _seedClinicsStream(),
//             builder: (context, seedSnap) {
//               final seedDocs = (seedSnap.data?.docs ?? []).where((doc) {
//                 final name = (doc['name'] ?? '').toString().toLowerCase();
//                 // Seed clinics should also respect the search bar
//                 return name.contains(_searchQuery.toLowerCase());
//               }).toList();

//               final hasDoctors = doctorDocs.isNotEmpty;
//               final hasSeed = seedDocs.isNotEmpty;

//               if (!hasDoctors && !hasSeed) {
//                 return Center(
//                   child: Text(
//                     tr('no_doctors_found'),
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 );
//               }

//               return ListView(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 children: [
//                   if (hasDoctors) ...[
//                     _sectionHeader(
//                       title: tr('doctors'), // real doctors
//                       icon: Icons.verified,
//                       iconColor: Colors.blue,
//                     ),
//                     const SizedBox(height: 10),
//                     ...doctorDocs.map((doc) => _realDoctorCard(doc)).toList(),
//                     const SizedBox(height: 16),
//                   ],

//                   // ✅ Seed clinics at bottom (NOT inside categories)
//                   if (hasSeed) ...[
//                     _sectionHeader(
//                       title: tr(
//                           'clinics_in_your_city'), // add key later if missing
//                       icon: Icons.location_city_outlined,
//                       iconColor: Colors.orange,
//                       subtitle: tr(
//                           'not_available_for_online_booking'), // add key later if missing
//                     ),
//                     const SizedBox(height: 10),
//                     ...seedDocs.map((doc) => _seedClinicCard(doc)).toList(),
//                     const SizedBox(height: 24),
//                   ],
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   // ---------------------------
//   // UI helpers
//   // ---------------------------
//   Widget _sectionHeader({
//     required String title,
//     required IconData icon,
//     required Color iconColor,
//     String? subtitle,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           )
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: iconColor.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: iconColor, size: 20),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title,
//                     style: const TextStyle(
//                         fontSize: 14.5, fontWeight: FontWeight.w800)),
//                 if (subtitle != null && subtitle.trim().isNotEmpty) ...[
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: const TextStyle(fontSize: 12, color: Colors.black54),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Real doctor card (existing behavior)
//   Widget _realDoctorCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data();

//     final id = doc.id;
//     final name = data['name'] ?? 'Unknown';
//     final specialty = data['specialty'] ?? '';
//     final exp = (data['experienceYears'] ?? 0).toString();
//     final rating = (data['ratingAverage'] ?? 0).toDouble();
//     final reviews = (data['ratingCount'] ?? 0).toInt();
//     final clinic = data['clinicName'] ?? '';

//     final bool isVerified = data['isVerified'] ?? data['verified'] ?? true;

//     String imageUrl = 'assets/user/placeholder_user.png';
//     try {
//       final photos = data['photos'];
//       if (photos != null) {
//         if (photos is List && photos.isNotEmpty) {
//           final firstUrl = photos.first?.toString().trim();
//           if (firstUrl != null && firstUrl.startsWith('http')) {
//             imageUrl = firstUrl;
//           }
//         } else if (photos is String && photos.trim().startsWith('http')) {
//           imageUrl = photos.trim();
//         }
//       } else if (data['photoUrl'] != null &&
//           data['photoUrl'].toString().trim().startsWith('http')) {
//         imageUrl = data['photoUrl'].toString().trim();
//       }
//     } catch (_) {}

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           PageTransition(
//             type: PageTransitionType.fade,
//             duration: const Duration(milliseconds: 400),
//             child: DoctorProfile(doctorId: id),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             )
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(50),
//                 child: imageUrl.startsWith('http')
//                     ? Image.network(
//                         imageUrl,
//                         width: 90,
//                         height: 90,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) => Image.asset(
//                           'assets/user/placeholder_user.png',
//                           width: 90,
//                           height: 90,
//                           fit: BoxFit.cover,
//                         ),
//                       )
//                     : Image.asset(
//                         imageUrl,
//                         width: 90,
//                         height: 90,
//                         fit: BoxFit.cover,
//                       ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             'Dr. $name',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: isVerified
//                                 ? Colors.blue.withOpacity(0.15)
//                                 : Colors.orange.withOpacity(0.15),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             isVerified ? tr('verified') : tr('not_registered'),
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w600,
//                               color: isVerified ? Colors.blue : Colors.orange,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       specialty,
//                       style: const TextStyle(color: Colors.teal, fontSize: 13),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       '$exp ${tr('years_experience')}',
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontSize: 12,
//                       ),
//                     ),
//                     if (clinic.isNotEmpty)
//                       Text(
//                         clinic,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.black45,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     const SizedBox(height: 6),
//                     Row(
//                       children: [
//                         const Icon(Icons.star, color: Colors.amber, size: 16),
//                         const SizedBox(width: 3),
//                         Text(
//                           rating.toStringAsFixed(1),
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(width: 5),
//                         Text(
//                           '($reviews reviews)',
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),

//                     // Contact
//                     if ((data['phone'] ?? '').toString().trim().isNotEmpty)
//                       ElevatedButton.icon(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.teal,
//                           foregroundColor: Colors.white,
//                           minimumSize: const Size(120, 36),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 6),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         icon: const Icon(Icons.call, size: 16),
//                         label: Text(tr('call_now')),
//                         onPressed: () {
//                           final phone = data['phone'].toString();
//                           launchUrl(Uri.parse("tel:$phone"));
//                         },
//                       )
//                     else
//                       Text(
//                         tr('no_contact_info'),
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontStyle: FontStyle.italic,
//                           fontSize: 12,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Seed clinic card (bottom section only)
//   Widget _seedClinicCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
//     final data = doc.data();

//     final name = (data['name'] ?? '').toString();
//     final specialty = (data['specialty'] ?? '').toString();
//     final address = (data['address'] ?? '').toString();
//     final bool canCall = (data['canCall'] ?? false) == true;
//     final phone = (data['phone'] ?? '').toString().trim();

//     String imageUrl = 'assets/user/placeholder_user.png';
//     try {
//       final photos = data['photos'];
//       if (photos is List && photos.isNotEmpty) {
//         final firstUrl = photos.first?.toString().trim();
//         if (firstUrl != null && firstUrl.startsWith('http')) {
//           imageUrl = firstUrl;
//         }
//       } else if (data['imageUrl'] != null &&
//           data['imageUrl'].toString().trim().startsWith('http')) {
//         imageUrl = data['imageUrl'].toString().trim();
//       }
//     } catch (_) {}

//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           )
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Row(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(50),
//               child: imageUrl.startsWith('http')
//                   ? Image.network(
//                       imageUrl,
//                       width: 90,
//                       height: 90,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => Image.asset(
//                         'assets/user/placeholder_user.png',
//                         width: 90,
//                         height: 90,
//                         fit: BoxFit.cover,
//                       ),
//                     )
//                   : Image.asset(
//                       imageUrl,
//                       width: 90,
//                       height: 90,
//                       fit: BoxFit.cover,
//                     ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           name.isEmpty ? tr('clinic') : name,
//                           style: const TextStyle(
//                             fontSize: 15.5,
//                             fontWeight: FontWeight.w800,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.orange.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           tr('not_registered'),
//                           style: const TextStyle(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.orange,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   if (specialty.isNotEmpty)
//                     Text(
//                       specialty,
//                       style: const TextStyle(color: Colors.teal, fontSize: 13),
//                     ),
//                   if (address.isNotEmpty) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       address,
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontSize: 12,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                   const SizedBox(height: 8),

//                   // Call only if you allow it
//                   if (canCall && phone.isNotEmpty)
//                     ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(120, 36),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 12, vertical: 6),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       icon: const Icon(Icons.call, size: 16),
//                       label: Text(tr('call_now')),
//                       onPressed: () => launchUrl(Uri.parse("tel:$phone")),
//                     )
//                   else
//                     Text(
//                       tr('not_available_for_online_booking'),
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontStyle: FontStyle.italic,
//                         fontSize: 12,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       height: 46,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 5,
//             offset: const Offset(0, 3),
//           )
//         ],
//       ),
//       child: TextField(
//         onChanged: (val) => setState(() => _searchQuery = val),
//         decoration: InputDecoration(
//           hintText: tr('search_doctor'),
//           hintStyle: const TextStyle(color: Colors.grey),
//           prefixIcon: const Icon(Icons.search, color: Colors.grey),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//         ),
//       ),
//     );
//   }
// }
