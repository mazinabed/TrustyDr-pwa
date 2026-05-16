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
//         backgroundColor: whiteColor,
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
//               color: whiteColor,
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
//                     Icon(Icons.history, color: greyColor, size: 22.0),
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
//               color: whiteColor,
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
        backgroundColor: whiteColor,
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
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index].data();
            final id = docs[index].id;

            final name = doc['name'] ?? 'Doctor';
            final title = doc['specialty'] ?? '';

            return ListTile(
              title: Text(name),
              subtitle: Text(title),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorProfileV2(doctorId: id),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(tr('search_error'))),
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
              color: whiteColor,
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
                    Icon(Icons.history, color: greyColor, size: 22.0),
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
              color: whiteColor,
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
                        color: isVerified ? Colors.blue : Colors.orange,
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
