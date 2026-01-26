// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/doctor/doctor_profile.dart';
// import 'package:trustydr/services/database_service.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';

// class MyDoctorsPage extends StatefulWidget {
//   const MyDoctorsPage({super.key});

//   @override
//   State<MyDoctorsPage> createState() => _MyDoctorsPageState();
// }

// class _MyDoctorsPageState extends State<MyDoctorsPage> {
//   String _searchQuery = '';

//   @override
//   Widget build(BuildContext context) {
//     final user = DatabaseService().currentUser;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F8FB),
//       body: Stack(
//         children: [
//           /// 🔷 HEADER (FIXED HEIGHT)
//           _CurvedGradientHeader(
//             height: 210, // ✅ FIX overflow
//             child: SafeArea(
//               bottom: false,
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     /// Back + title
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.arrow_back_ios_new,
//                               color: Colors.white, size: 20),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                         Expanded(
//                           child: Text(
//                             'my_doctors'.tr(),
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 48),
//                       ],
//                     ),

//                     const SizedBox(height: 12),

//                     /// Search
//                     Container(
//                       height: 46,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       padding: const EdgeInsets.symmetric(horizontal: 14),
//                       child: TextField(
//                         onChanged: (v) =>
//                             setState(() => _searchQuery = v.toLowerCase()),
//                         decoration: InputDecoration(
//                           icon: const Icon(Icons.search, color: Colors.black54),
//                           hintText: 'search_doctor'.tr(),
//                           border: InputBorder.none,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// 🔷 CONTENT
//           Padding(
//             padding: const EdgeInsets.only(top: 220),
//             child: user == null
//                 ? _emptyState('please_login'.tr())
//                 : StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('appointments')
//                         .where('userId', isEqualTo: user.uid)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                         return _emptyState('no_doctors_yet'.tr());
//                       }

//                       final seen = <String>{};
//                       final doctors = snapshot.data!.docs
//                           .map((d) => d.data() as Map<String, dynamic>)
//                           .where((d) => seen.add(d['doctorId'] ?? ''))
//                           .where((d) {
//                         if (_searchQuery.isEmpty) return true;
//                         return (d['doctorName'] ?? '')
//                             .toString()
//                             .toLowerCase()
//                             .contains(_searchQuery);
//                       }).toList();

//                       return ListView.builder(
//                         padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
//                         itemCount: doctors.length,
//                         itemBuilder: (_, i) {
//                           final d = doctors[i];

//                           final name = d['doctorName'] ?? tr('doctor');
//                           final specialty = d['doctorType'] ??
//                               d['specialty'] ??
//                               tr('specialty');
//                           final clinic = d['clinicName'] ?? tr('clinic');

//                           return _doctorCard(
//                             name: name,
//                             specialty: specialty,
//                             clinic: clinic,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 PageTransition(
//                                   type: PageTransitionType.rightToLeft,
//                                   child: DoctorProfile(
//                                     doctorId: d['doctorId'] ?? '',
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🔹 DOCTOR CARD (CLEAN & REAL)
//   Widget _doctorCard({
//     required String name,
//     required String specialty,
//     required String clinic,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             /// Avatar (initials)
//             CircleAvatar(
//               radius: 28,
//               backgroundColor: primaryColor.withOpacity(0.15),
//               child: Text(
//                 name.isNotEmpty ? name[0].toUpperCase() : '?',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700,
//                   color: primaryColor,
//                 ),
//               ),
//             ),

//             const SizedBox(width: 14),

//             /// Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     specialty,
//                     style: TextStyle(
//                       color: primaryColor,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     clinic,
//                     style: const TextStyle(
//                       color: Colors.black54,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const Icon(Icons.chevron_right, color: Colors.black38),
//           ],
//         ),
//       ),
//     );
//   }

//   /// 🔹 EMPTY STATE
//   Widget _emptyState(String text) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
//             const SizedBox(height: 16),
//             Text(
//               text,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: Colors.black54, fontSize: 15),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// 🔷 HEADER WIDGET
// class _CurvedGradientHeader extends StatelessWidget {
//   final Widget child;
//   final double height;

//   const _CurvedGradientHeader({
//     required this.child,
//     required this.height,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
//       child: Container(
//         height: height,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: child,
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/doctor/doctor_profile.dart';
import 'package:trustydr/services/database_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:trustydr/widgets/trustydr_curved_header.dart';

class MyDoctorsPage extends StatefulWidget {
  const MyDoctorsPage({super.key});

  @override
  State<MyDoctorsPage> createState() => _MyDoctorsPageState();
}

class _MyDoctorsPageState extends State<MyDoctorsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(_fade);

    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// ✅ Localized specialty helper
  String _localizedSpecialty(Map<String, dynamic> data) {
    final lang = context.locale.languageCode;

    if (lang == 'ar' && data['specialtyName_ar'] != null) {
      return data['specialtyName_ar'].toString();
    }
    if (lang == 'ku' && data['specialtyName_ku'] != null) {
      return data['specialtyName_ku'].toString();
    }
    if (data['specialtyName_en'] != null) {
      return data['specialtyName_en'].toString();
    }

    // fallback (old data)
    if (data['doctorType'] != null) {
      return data['doctorType'].toString();
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final user = DatabaseService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          /// Gradient header
            TrustyDrCurvedHeader(
  title: tr('doctors'),
          // no title
  showBack: true,  // no arrow
  height: 160,      // tall hero banner
),
        
          /// Content
          Padding(
            padding: const EdgeInsets.only(top: 220),
            child: user == null
                ? _emptyState(tr('please_login'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _emptyState(tr('no_doctors_yet'));
                      }

                      final seen = <String>{};
                      final doctors = snapshot.data!.docs
                          .map((d) => d.data() as Map<String, dynamic>)
                          .where((d) => seen.add(d['doctorId'] ?? ''))
                          .where((d) {
                        if (_searchQuery.isEmpty) return true;
                        final name =
                            (d['doctorName'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      if (doctors.isEmpty) {
                        return _emptyState(tr('no_results_search'));
                      }

                      return FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: doctors.length,
                            itemBuilder: (_, i) {
                              final data = doctors[i];

                              final name = data['doctorName'] ?? tr('doctor');
                              final specialty = _localizedSpecialty(data);

                              return _doctorCard(
                                name: name,
                                specialty: specialty,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType.rightToLeft,
                                      child: DoctorProfile(
                                        doctorId: data['doctorId'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Empty state
  Widget _emptyState(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ],
          ),
        ),
      );

  /// ✅ Clean doctor card
  Widget _doctorCard({
    required String name,
    required String specialty,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

/// Gradient header
class _CurvedGradientHeader extends StatelessWidget {
  final Widget child;
  final double height;

  const _CurvedGradientHeader({
    required this.child,
    this.height = 180,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}
