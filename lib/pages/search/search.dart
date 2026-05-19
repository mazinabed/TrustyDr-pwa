// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/pages/doctor/doctor_profile.dart';
// import 'package:flutter/material.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/widget/column_builder.dart';
// import 'package:trustydr/pages/screens.dart';

// class Search extends StatefulWidget {
//   final String city;
//   const Search({super.key, required this.city});

//   @override
//   _SearchState createState() => _SearchState();
// }

// class _SearchState extends State<Search> {
//   String get city => widget.city;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   List<Map<String, dynamic>> recentList = [];
//   List<Map<String, dynamic>> trendingList = [];
//   List<Map<String, dynamic>> liveSearchResults = [];

//   final TextEditingController _searchController = TextEditingController();
//   String searchQuery = '';

//   static const int _minSearchLength = 3;

//   @override
//   void initState() {
//     super.initState();
//     _loadTrendingDoctors();
//     _loadRecentSearches();

//     _searchController.addListener(() {
//       final newQuery = _searchController.text.trim();
//       if (newQuery != searchQuery) {
//         setState(() {
//           searchQuery = newQuery;
//         });
//         _executeLiveSearch(newQuery);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadTrendingDoctors() async {
//     try {
//       QuerySnapshot snapshot = await _firestore
//           .collection('doctors')
//           .where('city', isEqualTo: city)
//           .limit(10)
//           .get();

//       if (mounted) {
//         setState(() {
//           trendingList = snapshot.docs
//               .map((doc) => {
//                     'title': doc['specialty'],
//                     'name': doc['name'] ?? '',
//                     'id': doc.id,
//                   })
//               .toList();
//         });
//       }
//     } catch (e) {
//       print("⚠️ Error loading trending doctors: $e");
//     }
//   }

//   Future<void> _executeLiveSearch(String query) async {
//     if (query.length < _minSearchLength) {
//       setState(() => liveSearchResults = []);
//       return;
//     }

//     final lowerQuery = query.toLowerCase();
//     final endQuery = '$lowerQuery\uf8ff';

//     try {
//       final specialtyQuery = _firestore
//           .collection('doctors')
//           .where('city', isEqualTo: city)
//           .where('specialty_lower', isGreaterThanOrEqualTo: lowerQuery)
//           .where('specialty_lower', isLessThan: endQuery)
//           .limit(10)
//           .get();

//       final nameQuery = _firestore
//           .collection('doctors')
//           .where('city', isEqualTo: city)
//           .where('name_lower', isGreaterThanOrEqualTo: lowerQuery)
//           .where('name_lower', isLessThan: endQuery)
//           .limit(10)
//           .get();

//       final results = await Future.wait([specialtyQuery, nameQuery]);

//       final Set<String> seenIds = {};
//       final List<Map<String, dynamic>> combined = [];

//       for (var snapshot in results) {
//         for (var doc in snapshot.docs) {
//           if (seenIds.add(doc.id)) {
//             combined.add({
//               'title': doc['specialty'],
//               'name': doc['name'] ?? 'Doctor',
//               'id': doc.id,
//             });
//           }
//         }
//       }

//       if (mounted) {
//         setState(() => liveSearchResults = combined);
//       }
//     } catch (e) {
//       print("❌ Live search error: $e");
//       setState(() => liveSearchResults = []);
//     }
//   }

//   void _loadRecentSearches() {
//     setState(() {
//       recentList = [
//         {'title': 'Cardiologist'},
//         {'title': 'Nutritionist'},
//       ];
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isSearching = searchQuery.length >= _minSearchLength;

//     return Scaffold(
//       appBar: AppBar(
//         elevation: 1.0,
//         automaticallyImplyLeading: true,
//         backgroundColor: Colors.white,
//         title: Container(
//           height: 40.0,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(25.0),
//           ),
//           child: TextField(
//             controller: _searchController,
//             autofocus: true,
//             textInputAction: TextInputAction.search,
//             decoration: InputDecoration(
//               hintText: 'Search for doctors & labs in $city',
//               hintStyle: const TextStyle(fontSize: 15.0, color: Colors.grey),
//               prefixIcon: const Icon(Icons.search),
//               border: InputBorder.none,
//               suffixIcon: searchQuery.isNotEmpty
//                   ? IconButton(
//                       icon: const Icon(Icons.clear, color: Colors.grey),
//                       onPressed: () {
//                         _searchController.clear();
//                         FocusScope.of(context).unfocus();
//                       },
//                     )
//                   : null,
//             ),
//           ),
//         ),
//       ),
//       body: isSearching ? _buildSearchResults() : _buildDefaultView(),
//     );
//   }

//   Widget _buildSearchResults() {
//     if (liveSearchResults.isEmpty) {
//       return Center(
//         child: Text(
//           'No results found for "$searchQuery" in $city.',
//           style: greySmallTextStyle,
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: liveSearchResults.length,
//       itemBuilder: (context, index) {
//         final item = liveSearchResults[index];
//         return ListTile(
//           leading: const Icon(Icons.person, color: Colors.blue),
//           title: Text(item['name'] ?? '', style: blackNormalTextStyle),
//           subtitle: Text(item['title'] ?? '', style: greySmallTextStyle),
//           onTap: () {
//             final doctorId = item['id'];
//             if (doctorId == null || doctorId.toString().isEmpty) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text("⚠️ Doctor profile not found."),
//                 ),
//               );
//               return;
//             }

//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => DoctorProfile(doctorId: doctorId),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildDefaultView() {
//     return ListView(
//       children: [
//         if (recentList.isNotEmpty)
//           Container(
//             padding: EdgeInsets.symmetric(
//                 horizontal: fixPadding * 2.0, vertical: fixPadding),
//             color: Colors.grey[100],
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Your recent searches', style: blackNormalBoldTextStyle),
//                 InkWell(
//                   onTap: () {},
//                   child: Text('Show more', style: primaryColorsmallTextStyle),
//                 ),
//               ],
//             ),
//           ),
//         ColumnBuilder(
//           itemCount: recentList.length,
//           itemBuilder: (context, index) {
//             final item = recentList[index];
//             return Container(
//               color: Colors.white,
//               padding: EdgeInsets.symmetric(
//                   horizontal: fixPadding * 2.0, vertical: fixPadding),
//               child: InkWell(
//                 onTap: () {
//                   _searchController.text = item['title'] ?? '';
//                   _searchController.selection = TextSelection.fromPosition(
//                     TextPosition(offset: _searchController.text.length),
//                   );
//                 },
//                 child: Row(
//                   children: [
//                     Icon(Icons.history, color: Colors.grey, size: 22.0),
//                     SizedBox(width: fixPadding),
//                     Text(item['title'] ?? '', style: blackSmallTextStyle),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//         if (trendingList.isNotEmpty)
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(
//                 horizontal: fixPadding * 2.0, vertical: fixPadding),
//             color: Colors.grey[100],
//             child: Text('Trending around you', style: blackNormalBoldTextStyle),
//           ),
//         ColumnBuilder(
//           itemCount: trendingList.length,
//           itemBuilder: (context, index) {
//             final item = trendingList[index];
//             return Container(
//               color: Colors.white,
//               padding: EdgeInsets.symmetric(
//                   horizontal: fixPadding * 2.0, vertical: fixPadding),
//               child: InkWell(
//                 onTap: () {
//                   final doctorId = item['id'];
//                   if (doctorId == null) return;

//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => DoctorProfileV2(doctorId: doctorId),
//                     ),
//                   );
//                 },
//                 child: Row(
//                   children: [
//                     const Icon(Icons.trending_up,
//                         color: Colors.blue, size: 22.0),
//                     SizedBox(width: fixPadding),
//                     Text(item['name'] ?? '', style: blackSmallTextStyle),
//                     const SizedBox(width: 5),
//                     Text('• ${item['title'] ?? ''}', style: greySmallTextStyle),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

//this is working but we are Optemizing the search to save cost

import 'dart:async';
import 'package:trustydr/core/providers/doctorSearchProvider.dart';
import 'package:trustydr/pages/doctor/doctor_profile_v2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:trustydr/widget/column_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Search extends ConsumerStatefulWidget {
  final String city;
  const Search({super.key, required this.city});

  @override
  ConsumerState<Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  String get city => widget.city;

  List<Map<String, dynamic>> recentList = [];
  List<Map<String, dynamic>> trendingList = [];

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  static const int _minSearchLength = 3;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _loadRecentSearches(); // local-only, safe

    _searchController.addListener(() {
      final value = _searchController.text.trim();

      _debounce?.cancel();

      _debounce = Timer(const Duration(milliseconds: 400), () {
        if (!mounted) return;

        if (value != searchQuery) {
          setState(() {
            searchQuery = value;
          });
          // 🔒 NO Firestore calls here
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ------------------ RECENT SEARCHES -------------------

  void _loadRecentSearches() {
    setState(() {
      recentList = [];
    });
  }

  // ------------------ UI -------------------

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery.length >= _minSearchLength;

    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: Container(
          height: 40.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: tr('search_hint', args: [city]),
              hintStyle: const TextStyle(fontSize: 15.0, color: Colors.grey),
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: isSearching ? _buildSearchResults() : _buildDefaultView(),
    );
  }

  // ------------------ SEARCH RESULTS LIST -------------------

  Widget _buildSearchResults() {
    final resultsAsync = ref.watch(doctorSearchProvider(searchQuery));

    return resultsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Text(
              tr('no_results_for', args: [searchQuery]),
              style: greySmallTextStyle,
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: fixPadding * 1.5,
            vertical: fixPadding,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildDoctorCard(
            context,
            docs[index].id,
            docs[index].data(),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: PatientAppColors.brandIndigo),
      ),
      error: (_, __) => Center(child: Text(tr('search_error'))),
    );
  }

  Widget _buildDoctorCard(
    BuildContext context,
    String id,
    Map<String, dynamic> doc,
  ) {
    final lang = context.locale.languageCode;

    final name = lang == 'ar'
        ? (doc['name_ar'] ?? doc['name_en'] ?? doc['name'] ?? '').toString()
        : lang == 'ku'
            ? (doc['name_ku'] ?? doc['name_en'] ?? doc['name'] ?? '').toString()
            : (doc['name_en'] ?? doc['name'] ?? '').toString();

    final specialty = lang == 'ar'
        ? (doc['specialtyName_ar'] ??
                doc['specialty_ar'] ??
                doc['specialtyName_en'] ??
                doc['specialty'] ??
                '')
            .toString()
        : lang == 'ku'
            ? (doc['specialtyName_ku'] ??
                    doc['specialty_ku'] ??
                    doc['specialtyName_en'] ??
                    doc['specialty'] ??
                    '')
                .toString()
            : (doc['specialtyName_en'] ??
                    doc['specialty_en'] ??
                    doc['specialty'] ??
                    '')
                .toString();

    final clinic = lang == 'ar'
        ? (doc['clinicName_ar'] ??
                doc['clinicName_en'] ??
                doc['clinicName'] ??
                '')
            .toString()
        : lang == 'ku'
            ? (doc['clinicName_ku'] ??
                    doc['clinicName_en'] ??
                    doc['clinicName'] ??
                    '')
                .toString()
            : (doc['clinicName_en'] ?? doc['clinicName'] ?? '').toString();

    final city = lang == 'ar'
        ? (doc['city_ar'] ?? doc['city_en'] ?? '').toString()
        : lang == 'ku'
            ? (doc['city_ku'] ?? doc['city_en'] ?? '').toString()
            : (doc['city_en'] ?? '').toString();

    final imageUrl = (doc['imageUrl'] ?? '').toString();
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final ratingAverage = doc['ratingAverage'] is num
        ? (doc['ratingAverage'] as num).toDouble()
        : 0.0;
    final ratingCount =
        doc['ratingCount'] is int ? doc['ratingCount'] as int : 0;

    final locationText = [clinic, city].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      margin: EdgeInsets.only(bottom: fixPadding * 1.2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorProfileV2(doctorId: id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // ── Avatar / image ──────────────────────────
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  backgroundColor:
                      PatientAppColors.brandIndigo.withValues(alpha: 0.12),
                  child: imageUrl.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: PatientAppColors.brandIndigo,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // ── Info ────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? tr('doctor') : name,
                        style: blackNormalBoldTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (specialty.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: primaryColorsmallTextStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (locationText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                locationText,
                                style: greySmallTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ratingAverage > 0) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              ratingAverage.toStringAsFixed(1),
                              style: greySmallTextStyle,
                            ),
                            if (ratingCount > 0)
                              Text(
                                ' ($ratingCount)',
                                style: greySmallTextStyle,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── Arrow ───────────────────────────────────
                const Icon(Icons.chevron_right,
                    color: Colors.black26, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ DEFAULT VIEW -------------------

  Widget _buildDefaultView() {
    return ListView(
      children: [
        if (recentList.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: fixPadding * 2.0, vertical: fixPadding),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('recent_searches'), style: blackNormalBoldTextStyle),
                InkWell(
                  onTap: () {},
                  child:
                      Text(tr('show_more'), style: primaryColorsmallTextStyle),
                ),
              ],
            ),
          ),
        ColumnBuilder(
          itemCount: recentList.length,
          itemBuilder: (context, index) {
            final item = recentList[index];
            return Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: fixPadding * 2.0, vertical: fixPadding),
              child: InkWell(
                onTap: () {
                  _searchController.text = item['title'] ?? '';
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _searchController.text.length),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey, size: 22.0),
                    SizedBox(width: fixPadding),
                    Text(item['title'] ?? '', style: blackSmallTextStyle),
                  ],
                ),
              ),
            );
          },
        ),
        if (trendingList.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: fixPadding * 2.0, vertical: fixPadding),
            color: Colors.grey[100],
            child: Text(tr('trending_around_you'),
                style: blackNormalBoldTextStyle),
          ),
        ColumnBuilder(
          itemCount: trendingList.length,
          itemBuilder: (context, index) {
            final item = trendingList[index];
            final bool isVerified = item['isVerified'] ?? true;

            return Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: fixPadding * 2.0, vertical: fixPadding),
              child: InkWell(
                onTap: () {
                  final doctorId = item['id'];
                  if (doctorId == null) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorProfileV2(doctorId: doctorId),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: isVerified
                            ? PatientAppColors.brandBlue
                            : Colors.orange,
                        size: 22.0),
                    SizedBox(width: fixPadding),
                    Text(item['name'] ?? '', style: blackSmallTextStyle),
                    const SizedBox(width: 5),
                    Text('• ${item['title'] ?? ''}', style: greySmallTextStyle),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
