// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/patient/write_review_page.dart'
//     show WriteReviewModal;
// import 'package:trustydr/pages/screens.dart' show LoginScreen;
// import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
// import 'package:trustydr/pages/patient/appointment_detail_page.dart';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:url_launcher/url_launcher.dart';

// class DoctorProfile extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfile({super.key, required this.doctorId});

//   @override
//   State<DoctorProfile> createState() => _DoctorProfileState();
// }

// class _DoctorProfileState extends State<DoctorProfile> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final user = FirebaseAuth.instance.currentUser;
//   Map<String, dynamic>? doctorData;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchDoctorData();
//   }

//   Future<void> _fetchDoctorData() async {
//     try {
//       final doc =
//           await _firestore.collection('doctors').doc(widget.doctorId).get();
//       if (doc.exists) {
//         setState(() {
//           doctorData = doc.data()!;
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("Error fetching doctor data: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _callClinic() async {
//     final phone = (doctorData?['phone'] ?? '').toString().trim();
//     if (phone.isEmpty) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Phone number not available')),
//         );
//       }
//       return;
//     }

//     final uri = Uri(scheme: 'tel', path: phone);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Cannot make the call')),
//         );
//       }
//     }
//   }

//   void _chatDoctor() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Chat feature coming soon...')),
//     );
//   }

//   Future<void> _openDirections() async {
//     final lat = doctorData?['latitude'];
//     final lng = doctorData?['longitude'];
//     if (lat != null && lng != null) {
//       final uri = Uri.parse(
//           'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Clinic location not available')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (doctorData == null) {
//       return const Scaffold(
//         body: Center(child: Text("Doctor not found.")),
//       );
//     }

//     final name = (doctorData!['name'] ?? 'Doctor').toString();
//     final specialty = (doctorData!['specialty'] ?? '').toString();
//     final clinic = (doctorData!['clinicName'] ?? '').toString();
//     final experience = (doctorData!['experienceYears'] ?? 'N/A').toString();
//     final rating = (doctorData!['ratingAverage'] ?? 0).toString();
//     final ratingCount = (doctorData!['ratingCount'] ?? 0).toString();
//     final photos = (doctorData!['photos'] as List?) ?? [];
//     final imageUrl = photos.isNotEmpty ? photos.first.toString() : '';
//     final address = (doctorData!['clinicAddress'] ??
//             doctorData!['address'] ??
//             'Address not available')
//         .toString();
//     final city =
//         (doctorData!['city_en'] ?? doctorData!['city'] ?? '').toString();
//     final fullAddress = city.isNotEmpty ? "$address, $city" : address;
//     final languages = List<String>.from(doctorData!['languages'] ?? []);
//     final phone = (doctorData!['phone'] ?? '').toString().trim();
//     final email = (doctorData!['email'] ?? doctorData!['contactEmail'] ?? '')
//         .toString()
//         .trim();

//     // Verified vs Not Registered
//     final bool isVerified =
//         doctorData!['verified'] == true || doctorData!['isVerified'] == true;

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       floatingActionButton: user == null || !isVerified
//           ? null
//           : FloatingActionButton.extended(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.fade,
//                     duration: const Duration(milliseconds: 400),
//                     child: DoctorTimeSlot(
//                       doctorId: widget.doctorId,
//                       doctorName: name,
//                       doctorImage: imageUrl,
//                       doctorType: specialty,
//                       experience: experience,
//                       clinicName: doctorData!['clinicName'] ?? 'Unknown Clinic',
//                       province: doctorData!['province'] ?? 'Unknown Province',
//                       city: doctorData!['city_en'] ??
//                           doctorData!['city'] ??
//                           'Unknown City',
//                     ),
//                   ),
//                 );
//               },
//               backgroundColor: primaryColor,
//               icon: const Icon(Icons.calendar_month),
//               label: const Text("Book Appointment"),
//             ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Column(
//             children: [
//               // Header card
//               Container(
//                 width: double.infinity,
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius:
//                       BorderRadius.vertical(bottom: Radius.circular(40)),
//                 ),
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 55,
//                       backgroundColor: Colors.white,
//                       backgroundImage:
//                           imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
//                       child: imageUrl.isEmpty
//                           ? const Icon(Icons.person,
//                               size: 60, color: Colors.grey)
//                           : null,
//                     ),
//                     const SizedBox(height: 12),
//                     Text('Dr. $name',
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 4),
//                     Text(specialty,
//                         style: const TextStyle(
//                             color: Colors.white70, fontSize: 14)),
//                     const SizedBox(height: 4),
//                     if (clinic.isNotEmpty)
//                       Text(clinic,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                               color: Colors.white70, fontSize: 13)),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.star,
//                             color: Colors.amberAccent, size: 18),
//                         const SizedBox(width: 4),
//                         Text("$rating ($ratingCount reviews)",
//                             style: const TextStyle(
//                                 color: Colors.white, fontSize: 14)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // Icon row: Call (if phone), Directions, Claim/Chat
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     if (phone.isNotEmpty)
//                       _iconButton(
//                           Icons.call, "Call", Colors.green, _callClinic),
//                     _iconButton(Icons.directions, "Directions", Colors.orange,
//                         _openDirections),
//                     _iconButton(
//                         Icons.verified_user_outlined,
//                         isVerified ? "Verified" : "Claim",
//                         isVerified ? Colors.blue : Colors.grey, () {
//                       if (!isVerified) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text(
//                                 'If this is your clinic, please contact support to claim it.'),
//                           ),
//                         );
//                       }
//                     }),
//                   ],
//                 ),
//               ),

//               // About + Contact + Reviews
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("About Doctor",
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 8),
//                     Text(
//                       "$name is a $specialty specialist with $experience years of experience at $clinic.",
//                       style:
//                           const TextStyle(fontSize: 14, color: Colors.black87),
//                     ),
//                     const SizedBox(height: 16),
//                     _infoTile("Clinic Address", fullAddress),
//                     if (languages.isNotEmpty)
//                       _infoTile("Languages", languages.join(", ")),
//                     _infoTile("Experience", "$experience years"),

//                     const SizedBox(height: 12),
//                     // 🔹 Contact section
//                     const Divider(),
//                     const SizedBox(height: 8),
//                     const Text("Contact",
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 6),
//                     _infoTile(
//                       "Phone",
//                       phone.isNotEmpty ? phone : "Not available",
//                     ),
//                     if (email.isNotEmpty) _infoTile("Email", email),

//                     const SizedBox(height: 20),
//                     const Divider(),
//                     const SizedBox(height: 12),
//                     const Text("Patient Reviews",
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 8),
//                     _reviewsList(),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               if (user == null && isVerified)
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: GestureDetector(
//                     onTap: () {
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                         content: Text('Please log in to book an appointment.'),
//                       ));
//                     },
//                     child: Container(
//                       width: double.infinity,
//                       height: 55,
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                           begin: Alignment.centerLeft,
//                           end: Alignment.centerRight,
//                         ),
//                         borderRadius: BorderRadius.circular(30),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       alignment: Alignment.center,
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.lock, color: Colors.white),
//                           SizedBox(width: 8),
//                           Text(
//                             "Login to Book Appointment",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _iconButton(
//       IconData icon, String label, Color color, VoidCallback onTap) {
//     return Column(
//       children: [
//         InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(40),
//           child: CircleAvatar(
//             backgroundColor: color.withOpacity(0.15),
//             radius: 28,
//             child: Icon(icon, color: color, size: 26),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(label,
//             style: const TextStyle(
//                 fontSize: 12,
//                 color: Colors.black54,
//                 fontWeight: FontWeight.w500)),
//       ],
//     );
//   }

//   Widget _infoTile(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black)),
//           const SizedBox(height: 4),
//           Text(value,
//               style: const TextStyle(fontSize: 14, color: Colors.black54)),
//         ],
//       ),
//     );
//   }

//   Widget _reviewsList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _firestore
//           .collection('doctors')
//           .doc(widget.doctorId)
//           .collection('reviews')
//           .orderBy('createdAt', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Text(
//             "No reviews yet.",
//             style: TextStyle(color: Colors.grey),
//           );
//         }

//         final reviews = snapshot.data!.docs;
//         return Column(
//           children: reviews.map((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final userName = data['userName'] ?? 'Anonymous';
//             final rating = (data['rating'] ?? 0).toInt();
//             final comment =
//                 data['comment'] ?? data['reviews'] ?? 'No comment provided';
//             final createdAt = (data['createdAt'] is Timestamp)
//                 ? (data['createdAt'] as Timestamp).toDate()
//                 : null;

//             return Card(
//               margin: const EdgeInsets.symmetric(vertical: 6),
//               elevation: 1.5,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: Colors.teal.shade100,
//                   child: Text(userName[0].toUpperCase(),
//                       style: const TextStyle(color: Colors.black)),
//                 ),
//                 title: Text(userName,
//                     style: const TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: List.generate(
//                         5,
//                         (index) => Icon(
//                           index < rating ? Icons.star : Icons.star_border,
//                           color: Colors.amberAccent,
//                           size: 18,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(comment,
//                         style: const TextStyle(color: Colors.black87)),
//                     if (createdAt != null)
//                       Text(
//                         "${createdAt.toLocal()}".split(' ')[0],
//                         style:
//                             const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:url_launcher/url_launcher.dart';

// class DoctorProfile extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfile({super.key, required this.doctorId});

//   @override
//   State<DoctorProfile> createState() => _DoctorProfileState();
// }

// class _DoctorProfileState extends State<DoctorProfile> {
//   @override
//   Widget build(BuildContext context) {
//     final docRef =
//         FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId);

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         stream: docRef.snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.teal),
//             );
//           }

//           final data = snapshot.data!.data();
//           if (data == null) {
//             return const Center(child: Text("Doctor not found"));
//           }

//           // --------------------------
//           // Extract fields
//           // --------------------------
//           final name = data['name'] ?? '';
//           final specialty = data['specialty'] ?? '';
//           final about = data['about'] ?? '';
//           final exp = data['experienceYears']?.toString() ?? 'N/A';
//           final clinicAddress = data['clinicAddress'] ?? data['address'] ?? '';
//           final languages = List<String>.from(data['languages'] ?? []);
//           final phone = data['phone'] ?? '';

//           final facebookPageId = data['sourceIds']?['facebookPageId'];
//           final googlePlaceId = data['sourceIds']?['googlePlaceId'];

//           final lat = data['latitude'];
//           final lng = data['longitude'];

//           final isVerified =
//               data['verified'] == true || data['isVerified'] == true;

//           final rating = (data['ratingAverage'] is num)
//               ? (data['ratingAverage']).toDouble()
//               : 0.0;
//           final reviewCount = (data['ratingCount'] ?? 0).toInt();

//           // --------------------------
//           // Image handling
//           // --------------------------
//           String imageUrl = "";
//           try {
//             if (data['photos'] is List && data['photos'].isNotEmpty) {
//               final first = data['photos'][0].toString();
//               if (first.startsWith('http')) imageUrl = first;
//             } else if (data['imageUrl'] != null &&
//                 data['imageUrl'].toString().startsWith('http')) {
//               imageUrl = data['imageUrl'];
//             }
//           } catch (_) {}

//           return CustomScrollView(
//             slivers: [
//               SliverAppBar(
//                 expandedHeight: 260,
//                 pinned: true,
//                 backgroundColor: Colors.white,
//                 leading: IconButton(
//                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         const SizedBox(height: 40),

//                         // ---- Avatar ----
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.white,
//                           child: ClipOval(
//                             child: imageUrl.isNotEmpty
//                                 ? Image.network(
//                                     imageUrl,
//                                     width: 100,
//                                     height: 100,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) =>
//                                         _fallbackAvatar(),
//                                   )
//                                 : _fallbackAvatar(),
//                           ),
//                         ),

//                         const SizedBox(height: 12),

//                         // ---- Name ----
//                         Text(
//                           'Dr. $name',
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),

//                         const SizedBox(height: 4),

//                         // ---- Specialty ----
//                         Text(
//                           specialty,
//                           style: const TextStyle(color: Colors.white70),
//                         ),

//                         const SizedBox(height: 8),

//                         // ---- Rating ----
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.star,
//                                 color: Colors.amber, size: 18),
//                             const SizedBox(width: 4),
//                             Text(
//                               rating.toStringAsFixed(1),
//                               style: const TextStyle(
//                                   color: Colors.white, fontSize: 14),
//                             ),
//                             Text(
//                               " ($reviewCount reviews)",
//                               style: const TextStyle(
//                                   color: Colors.white70, fontSize: 12),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               // --------------------------
//               // Contact Action Buttons
//               // --------------------------
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _actionButton(
//                         icon: Icons.call,
//                         color: Colors.green,
//                         label: tr('call'),
//                         onTap: () {
//                           if (phone.trim().isNotEmpty) {
//                             launchUrl(Uri.parse("tel:$phone"));
//                           } else {
//                             _showNoInfo(tr("no_phone_available"));
//                           }
//                         },
//                       ),
//                       _actionButton(
//                         icon: Icons.map,
//                         color: Colors.blue,
//                         label: tr('directions'),
//                         onTap: () {
//                           if (lat != null && lng != null) {
//                             launchUrl(
//                               Uri.parse(
//                                   "https://www.google.com/maps/search/?api=1&query=$lat,$lng"),
//                               mode: LaunchMode.externalApplication,
//                             );
//                           } else {
//                             _showNoInfo(tr("no_location_available"));
//                           }
//                         },
//                       ),
//                       _actionButton(
//                         icon: Icons.facebook,
//                         color: Colors.indigo,
//                         label: "Facebook",
//                         onTap: () {
//                           if (facebookPageId != null &&
//                               facebookPageId.toString().trim().isNotEmpty) {
//                             final url =
//                                 "https://www.facebook.com/$facebookPageId";
//                             launchUrl(Uri.parse(url),
//                                 mode: LaunchMode.externalApplication);
//                           } else {
//                             _showNoInfo(tr("no_facebook_available"));
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // --------------------------
//               // About Section
//               // --------------------------
//               SliverToBoxAdapter(
//                 child: _whiteCard(
//                   title: tr("about_doctor"),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         about.isNotEmpty
//                             ? about
//                             : tr("no_description_available"),
//                         style: greyNormalTextStyle,
//                       ),
//                       const SizedBox(height: 20),

//                       // ---- Clinic Address ----
//                       _sectionTitle(tr("clinic_address")),
//                       Text(
//                         clinicAddress.isNotEmpty
//                             ? clinicAddress
//                             : tr("no_address_available"),
//                         style: greyNormalTextStyle,
//                       ),
//                       const SizedBox(height: 20),

//                       // ---- Languages ----
//                       _sectionTitle(tr("languages")),
//                       Text(
//                         languages.isEmpty
//                             ? tr("no_languages_listed")
//                             : languages.join(", "),
//                         style: greyNormalTextStyle,
//                       ),
//                       const SizedBox(height: 20),

//                       // ---- Experience ----
//                       _sectionTitle(tr("experience")),
//                       Text(
//                         exp == "N/A"
//                             ? tr("experience_not_available")
//                             : "$exp ${tr('years')}",
//                         style: greyNormalTextStyle,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SliverToBoxAdapter(child: SizedBox(height: 40)),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // --------------------------
//   // Reusable Action Button
//   // --------------------------
//   Widget _actionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required Function() onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 26),
//           ),
//           const SizedBox(height: 6),
//           Text(label, style: const TextStyle(fontSize: 13)),
//         ],
//       ),
//     );
//   }

//   // --------------------------
//   // White Card Section
//   // --------------------------
//   Widget _whiteCard({required String title, required Widget child}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           )
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _sectionTitle(title),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _sectionTitle(String txt) {
//     return Text(
//       txt,
//       style: const TextStyle(
//         fontSize: 15,
//         fontWeight: FontWeight.bold,
//         color: Colors.black87,
//       ),
//     );
//   }

//   // --------------------------
//   // Fallback Avatar
//   // --------------------------
//   Widget _fallbackAvatar() {
//     return Image.asset(
//       "assets/icons/stethoscope.png",
//       width: 60,
//       height: 60,
//       fit: BoxFit.contain,
//     );
//   }

//   void _showNoInfo(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
// import 'package:trustydr/pages/screens.dart' show LoginScreen;
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:url_launcher/url_launcher.dart';

// class DoctorProfile extends StatefulWidget {
//   final String doctorId;

//   const DoctorProfile({super.key, required this.doctorId});

//   @override
//   State<DoctorProfile> createState() => _DoctorProfileState();
// }

// class _DoctorProfileState extends State<DoctorProfile> {
//   final _auth = FirebaseAuth.instance;

//   @override
//   Widget build(BuildContext context) {
//     final doctorRef =
//         FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId);

//     final scheduleQuery = FirebaseFirestore.instance
//         .collection('schedules')
//         .where('doctorId', isEqualTo: widget.doctorId)
//         .where('status', isEqualTo: 'published')
//         .where('isActive', isEqualTo: true)
//         .limit(1);

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         stream: doctorRef.snapshots(),
//         builder: (context, snap) {
//           if (!snap.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.teal),
//             );
//           }

//           final data = snap.data!.data();
//           if (data == null) {
//             return Center(child: Text(tr('doctor_not_found')));
//           }

//           final user = _auth.currentUser;

//           // -------- Doctor fields --------
//           final name = data['name'] ?? '';
//           final specialty = data['specialty'] ?? '';
//           final about = data['about'] ?? '';
//           final exp = data['experienceYears']?.toString() ?? 'N/A';
//           final clinic = data['clinicName'] ?? '';
//           final city = data['city_en'] ?? data['city'] ?? '';
//           final province = data['province'] ?? '';
//           final phone = data['phone'] ?? '';
//           final languages = List<String>.from(data['languages'] ?? []);
//           final lat = data['latitude'];
//           final lng = data['longitude'];

//           final isVerified =
//               data['verified'] == true || data['isVerified'] == true;
//           final canBook = data['canBook'] == true;

//           final rating = (data['ratingAverage'] is num)
//               ? (data['ratingAverage'] as num).toDouble()
//               : 0.0;
//           final reviews = (data['ratingCount'] ?? 0).toInt();

//           // -------- Image --------
//           String imageUrl = '';
//           try {
//             if (data['photos'] is List && data['photos'].isNotEmpty) {
//               final first = data['photos'][0].toString();
//               if (first.startsWith('http')) imageUrl = first;
//             } else if (data['imageUrl'] != null &&
//                 data['imageUrl'].toString().startsWith('http')) {
//               imageUrl = data['imageUrl'];
//             }
//           } catch (_) {}

//           return CustomScrollView(
//             slivers: [
//               // ================= HEADER =================
//               SliverAppBar(
//                 expandedHeight: 260,
//                 pinned: true,
//                 backgroundColor: Colors.white,
//                 leading: IconButton(
//                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         CircleAvatar(
//                           radius: 50,
//                           backgroundColor: Colors.white,
//                           child: ClipOval(
//                             child: imageUrl.isNotEmpty
//                                 ? Image.network(
//                                     imageUrl,
//                                     width: 100,
//                                     height: 100,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) =>
//                                         _fallbackAvatar(),
//                                   )
//                                 : _fallbackAvatar(),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'Dr. $name',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           specialty,
//                           style: const TextStyle(color: Colors.white70),
//                         ),
//                         const SizedBox(height: 6),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.star,
//                                 color: Colors.amber, size: 18),
//                             const SizedBox(width: 4),
//                             Text(
//                               rating.toStringAsFixed(1),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                             Text(
//                               " ($reviews ${tr('reviews')})",
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               // ================= ACTIONS =================
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 20),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _action(
//                         icon: Icons.call,
//                         label: tr('call'),
//                         color: Colors.green,
//                         onTap: phone.isNotEmpty
//                             ? () => launchUrl(Uri.parse('tel:$phone'))
//                             : null,
//                       ),
//                       _action(
//                         icon: Icons.map,
//                         label: tr('directions'),
//                         color: Colors.blue,
//                         onTap: (lat != null && lng != null)
//                             ? () => launchUrl(
//                                   Uri.parse(
//                                       'https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
//                                   mode: LaunchMode.externalApplication,
//                                 )
//                             : null,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               // ================= BOOKING CARD =================
//               SliverToBoxAdapter(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: scheduleQuery.snapshots(),
//                   builder: (context, s) {
//                     final hasSchedule = s.hasData && s.data!.docs.isNotEmpty;

//                     if (!canBook || !isVerified || !hasSchedule) {
//                       return const SizedBox.shrink();
//                     }

//                     return _whiteCard(
//                       title: tr('book_appointment'),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             tr('book_appointment_hint'),
//                             style: greyNormalTextStyle,
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: user == null
//                                 ? () {
//                                     Navigator.push(
//                                       context,
//                                       PageTransition(
//                                         type: PageTransitionType.rightToLeft,
//                                         child: const LoginScreen(),
//                                       ),
//                                     );
//                                   }
//                                 : () {
//                                     Navigator.push(
//                                       context,
//                                       PageTransition(
//                                         type: PageTransitionType.rightToLeft,
//                                         child: DoctorTimeSlot(
//                                           doctorId: widget.doctorId,
//                                           doctorName: name,
//                                           doctorImage: imageUrl,
//                                           doctorType: specialty,
//                                           experience: exp,
//                                           clinicName: clinic,
//                                           province: province,
//                                           city: city,
//                                         ),

//                                       ),
//                                     );
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               minimumSize: const Size.fromHeight(48),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                             ),
//                             child: Text(
//                               user == null
//                                   ? tr('login_to_book')
//                                   : tr('book_now'),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),

//               // ================= ABOUT =================
//               SliverToBoxAdapter(
//                 child: _whiteCard(
//                   title: tr('about_doctor'),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         about.isNotEmpty
//                             ? about
//                             : tr('no_description_available'),
//                         style: greyNormalTextStyle,
//                       ),
//                       const SizedBox(height: 16),
//                       _info(tr('clinic'), clinic),
//                       _info(tr('location'),
//                           '$city${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}$province'),
//                       _info(
//                         tr('languages'),
//                         languages.isEmpty
//                             ? tr('no_languages_listed')
//                             : languages.join(', '),
//                       ),
//                       _info(
//                         tr('experience'),
//                         exp == 'N/A'
//                             ? tr('experience_not_available')
//                             : '$exp ${tr('years')}',
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SliverToBoxAdapter(
//                 child: SizedBox(height: 40),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // ================= HELPERS =================

//   Widget _action({
//     required IconData icon,
//     required String label,
//     required Color color,
//     VoidCallback? onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color),
//           ),
//           const SizedBox(height: 6),
//           Text(label, style: const TextStyle(fontSize: 13)),
//         ],
//       ),
//     );
//   }

//   Widget _whiteCard({required String title, required Widget child}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           )
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style:
//                   const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _info(String title, String value) {
//     if (value.trim().isEmpty) return const SizedBox.shrink();
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//           Text(value, style: greyNormalTextStyle),
//         ],
//       ),
//     );
//   }

//   Widget _fallbackAvatar() {
//     return Image.asset(
//       'assets/icons/stethoscope.png',
//       width: 60,
//       height: 60,
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/doctor/doctor_time_slot.dart';
import 'package:trustydr/pages/screens.dart' show LoginScreen;
import 'package:trustydr/widgets/doctor_reviews_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorProfile extends StatefulWidget {
  final String doctorId;

  const DoctorProfile({super.key, required this.doctorId});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final doctorRef =
        FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId);
    final centersQuery = FirebaseFirestore.instance
        .collection('schedules')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('status', isEqualTo: 'published')
        .where('isActive', isEqualTo: true);

    final scheduleQuery = FirebaseFirestore.instance
        .collection('schedules')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('status', isEqualTo: 'published')
        .where('isActive', isEqualTo: true)
        .limit(1);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doctorRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final data = snap.data!.data();
          if (data == null) {
            return Center(child: Text('doctor_not_found'.tr()));
          }

          final user = _auth.currentUser;

          // -------- Doctor fields --------
          final name = (data['name'] ?? '').toString();

          // OLD/legacy string (can still exist)
          final specialtyLegacy = (data['specialty'] ?? '').toString();

          // ✅ Production: specialty fields (best)
          final specialtyKey =
              (data['specialtyKey'] ?? data['specialty_key'] ?? '')
                  .toString()
                  .trim();

          final specialtyEn = (data['specialtyName_en'] ??
                  data['specialty_en'] ??
                  specialtyLegacy)
              .toString()
              .trim();

          final specialtyAr =
              (data['specialtyName_ar'] ?? data['specialty_ar'] ?? specialtyEn)
                  .toString()
                  .trim();

          final specialtyKu =
              (data['specialtyName_ku'] ?? data['specialty_ku'] ?? specialtyEn)
                  .toString()
                  .trim();

          // ✅ Show correct localized specialty on the profile header
          final lang = context.locale.languageCode;
          final specialtyShown = lang == 'ar'
              ? specialtyAr
              : lang == 'ku'
                  ? specialtyKu
                  : specialtyEn;

          final about = (data['about'] ?? '').toString();
          final exp = (data['experienceYears']?.toString() ?? 'N/A').toString();
          final clinic = (data['clinicName'] ?? '').toString();
          final city = (data['city_en'] ?? data['city'] ?? '').toString();
          final province = (data['province'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final languages = List<String>.from(data['languages'] ?? []);
          final lat = data['latitude'];
          final lng = data['longitude'];
          final centerId = data['centerId'] ?? '';
          final provinceKey = data['provinceKey'] ?? '';
          final cityKey = data['cityKey'] ?? '';

          final isVerified =
              data['verified'] == true || data['isVerified'] == true;
          final canBook = data['canBook'] == true;

          final rating = (data['ratingAverage'] is num)
              ? (data['ratingAverage'] as num).toDouble()
              : 0.0;
          final reviews = (data['ratingCount'] ?? 0).toInt();

          // -------- Image --------
          String imageUrl = '';
          try {
            if (data['photos'] is List && (data['photos'] as List).isNotEmpty) {
              final first = (data['photos'] as List).first.toString();
              if (first.startsWith('http')) imageUrl = first;
            } else if (data['imageUrl'] != null &&
                data['imageUrl'].toString().startsWith('http')) {
              imageUrl = data['imageUrl'].toString();
            }
          } catch (_) {}

          return CustomScrollView(
            slivers: [
              // ================= HEADER =================
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _fallbackAvatar(),
                                  )
                                : _fallbackAvatar(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dr. $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          specialtyShown,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              " ($reviews ${'reviews'.tr()})",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ================= ACTIONS =================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _action(
                        icon: Icons.call,
                        label: 'call_now'.tr(),
                        color: Colors.green,
                        onTap: phone.isNotEmpty
                            ? () => launchUrl(Uri.parse('tel:$phone'))
                            : null,
                      ),
                      _action(
                        icon: Icons.map,
                        label: 'directions'.tr(),
                        color: Colors.blue,
                        onTap: (lat != null && lng != null)
                            ? () => launchUrl(
                                  Uri.parse(
                                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
                                  mode: LaunchMode.externalApplication,
                                )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

              // ================= BOOKING CARD =================
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: scheduleQuery.snapshots(),
                  builder: (context, s) {
                    final hasSchedule = s.hasData && s.data!.docs.isNotEmpty;

                    if (!canBook || !isVerified || !hasSchedule) {
                      return const SizedBox.shrink();
                    }

                    return _modernCard(
                      title: 'book_appointment'.tr(),
                      icon: Icons.calendar_month,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'book_appointment_hint'.tr(),
                            style: greyNormalTextStyle,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: user == null
                                ? () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.rightToLeft,
                                        child: const LoginScreen(),
                                      ),
                                    );
                                  }
                                : () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                          type: PageTransitionType.rightToLeft,
                                          child: DoctorTimeSlot(
                                            doctorId: widget.doctorId,
                                            doctorName: name,
                                            doctorImage: imageUrl,

                                            specialtyKey: specialtyKey,
                                            specialtyEn: specialtyEn,
                                            specialtyAr: specialtyAr,
                                            specialtyKu: specialtyKu,

                                            experience: exp,
                                            clinicName: clinic,
                                            province: province,
                                            city: city,

                                            // ⭐ ADD THESE
                                            centerId: centerId,
                                            provinceKey: provinceKey,
                                            cityKey: cityKey,
                                          )),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              user == null
                                  ? 'login_to_book'.tr()
                                  : 'book_now'.tr(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              //work at
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: centersQuery.snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final centers = snap.data!.docs;

                    return _modernCard(
                      title: 'available_at'.tr(),
                      icon: Icons.local_hospital,
                      child: Column(
                        children: centers.map((doc) {
                          final c = doc.data() as Map<String, dynamic>;

                          String clinicName;

                          if (lang == 'ar') {
                            clinicName =
                                (c['clinicName_ar'] ?? c['clinicName'] ?? '')
                                    .toString();
                          } else if (lang == 'ku') {
                            clinicName =
                                (c['clinicName_ku'] ?? c['clinicName'] ?? '')
                                    .toString();
                          } else {
                            clinicName =
                                (c['clinicName_en'] ?? c['clinicName'] ?? '')
                                    .toString();
                          }

                          String city;
                          String province;

                          if (lang == 'ar') {
                            city =
                                (c['city_ar'] ?? c['city_en'] ?? '').toString();
                            province =
                                (c['province_ar'] ?? c['province_en'] ?? '')
                                    .toString();
                          } else if (lang == 'ku') {
                            city =
                                (c['city_ku'] ?? c['city_en'] ?? '').toString();
                            province =
                                (c['province_ku'] ?? c['province_en'] ?? '')
                                    .toString();
                          } else {
                            city = (c['city_en'] ?? '').toString();
                            province = (c['province_en'] ?? '').toString();
                          }

                          String address;

                          if (lang == 'ar') {
                            address = (c['clinicAddress_ar'] ?? '').toString();
                          } else if (lang == 'ku') {
                            address = (c['clinicAddress_ku'] ?? '').toString();
                          } else {
                            address = (c['clinicAddress_en'] ?? '').toString();
                          }
                          final centerId = (c['centerId'] ?? '').toString();

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft,
                                  child: DoctorTimeSlot(
                                    doctorId: widget.doctorId,
                                    doctorName: name,
                                    doctorImage: imageUrl,
                                    specialtyKey: specialtyKey,
                                    specialtyEn: specialtyEn,
                                    specialtyAr: specialtyAr,
                                    specialtyKu: specialtyKu,
                                    experience: exp,
                                    clinicName: clinicName,
                                    province: province,
                                    city: city,
                                    centerId: centerId,
                                    provinceKey: c['provinceKey'],
                                    cityKey: c['cityKey'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_hospital,
                                        color: Colors.teal),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          clinicName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (address.isNotEmpty)
                                          Text(
                                            address,
                                            style: greyNormalTextStyle,
                                          ),
                                        Text(
                                          "$city${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}$province",
                                          style: greyNormalTextStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),

              // ================= ABOUT =================
              SliverToBoxAdapter(
                child: _modernCard(
                  title: 'about_doctor'.tr(),
                  icon: Icons.person,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        about.isNotEmpty
                            ? about
                            : 'no_description_available'.tr(),
                        style: greyNormalTextStyle,
                      ),
                      const SizedBox(height: 16),
                      _info('clinic'.tr(), clinic),
                      _info(
                        'location'.tr(),
                        "$city${city.isNotEmpty && province.isNotEmpty ? ', ' : ''}$province",
                      ),
                      _info(
                        'languages'.tr(),
                        languages.isEmpty
                            ? 'no_languages_listed'.tr()
                            : languages.join(', '),
                      ),
                      _info(
                        'experience'.tr(),
                        exp == 'N/A'
                            ? 'experience_not_available'.tr()
                            : '$exp ${'years'.tr()}',
                      ),
                    ],
                  ),
                ),
              ),

// ================= REVIEWS =================
              SliverToBoxAdapter(
                child: _modernCard(
                  title: 'reviews'.tr(),
                  icon: Icons
                      .star, // or 'Patient Reviews' if you don't have a key yet
                  child: DoctorReviewsSection(doctorId: widget.doctorId),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= HELPERS =================

  Widget _action({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _modernCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.teal, size: 18),
                ),
              if (icon != null) const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _info(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: greyNormalTextStyle),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Image.asset(
      'assets/icons/stethoscope.png',
      width: 60,
      height: 60,
    );
  }
}
