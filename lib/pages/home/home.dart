// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/screens.dart' hide blackColor;
// import 'package:trustydr/services/database_service.dart';
// import 'package:flutter/material.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';

// class Home extends StatefulWidget {
//   const Home({super.key});
//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   final _db = FirebaseFirestore.instance;

//   bool _loadingCities = true;
//   List<QueryDocumentSnapshot<Map<String, dynamic>>> _provinceDocs = [];

//   String? _selectedProvinceKey;
//   String? _selectedCityEn;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     await DatabaseService().initialize();
//     await _loadSavedLocation();
//     await _loadCities();
//     await _tryDetectLocation();
//   }

//   Future<void> _loadCities() async {
//     try {
//       final snap = await _db.collection('cities').get();
//       _provinceDocs = snap.docs;
//     } finally {
//       if (mounted) setState(() => _loadingCities = false);
//     }
//   }

//   Future<void> _loadSavedLocation() async {
//     final prefs = await SharedPreferences.getInstance();
//     _selectedProvinceKey = prefs.getString('selectedProvinceKey');
//     _selectedCityEn = prefs.getString('selectedCityEn');
//   }

//   Future<void> _saveLocation(String? provinceKey, String? cityEn) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('selectedProvinceKey', provinceKey ?? '');
//     await prefs.setString('selectedCityEn', cityEn ?? '');
//   }

//   Future<void> _tryDetectLocation() async {
//     try {
//       if (_selectedCityEn != null) return;
//       if (!await Geolocator.isLocationServiceEnabled()) return;

//       var perm = await Geolocator.checkPermission();
//       if (perm == LocationPermission.denied) {
//         perm = await Geolocator.requestPermission();
//       }
//       if (perm == LocationPermission.denied ||
//           perm == LocationPermission.deniedForever) return;

//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
//       if (marks.isEmpty) return;

//       final cityName = (marks.first.locality ?? '').toLowerCase();
//       for (final doc in _provinceDocs) {
//         final data = doc.data();
//         final subs = (data['subCities'] as List?) ?? [];
//         for (final raw in subs) {
//           final c = Map<String, dynamic>.from(raw as Map);
//           final names = [
//             (c['en'] ?? '').toString().toLowerCase(),
//             (c['ar'] ?? '').toString().toLowerCase(),
//             (c['ku'] ?? '').toString().toLowerCase(),
//           ];
//           if (names.any((n) => n.isNotEmpty && cityName.contains(n))) {
//             setState(() {
//               _selectedProvinceKey = data['province_key'];
//               _selectedCityEn = c['en'];
//             });
//             _saveLocation(_selectedProvinceKey, _selectedCityEn);
//             return;
//           }
//         }
//       }
//     } catch (_) {}
//   }

//   String _displayProvince(Map<String, dynamic> p) {
//     final lang = Localizations.localeOf(context).languageCode;
//     if (lang == 'ar') return (p['lang']?['ar'] ?? p['name_en'])!;
//     if (lang == 'ku') return (p['lang']?['ku'] ?? p['name_en'])!;
//     return p['name_en']!;
//   }

//   String _displayCity(Map<String, dynamic> c) {
//     final lang = Localizations.localeOf(context).languageCode;
//     if (lang == 'ar') return (c['ar'] ?? c['en'])!;
//     if (lang == 'ku') return (c['ku'] ?? c['en'])!;
//     return c['en']!;
//   }

//   void _openLocationSelector() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (ctx) {
//         String? tempProvince = _selectedProvinceKey;
//         String? tempCity = _selectedCityEn;

//         List<Map<String, dynamic>> cities() {
//           final prov = _provinceDocs
//               .where((d) => d.data()['province_key'] == tempProvince)
//               .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()
//               .firstOrNull;
//           if (prov == null) return [];
//           final subs = (prov.data()['subCities'] as List?) ?? [];
//           final seen = <String>{};
//           return subs
//               .map((e) => Map<String, dynamic>.from(e as Map))
//               .where((c) => seen.add((c['en'] ?? '').toString()))
//               .toList();
//         }

//         final provinces = _provinceDocs
//             .map((d) => d.data())
//             .map((p) => DropdownMenuItem<String>(
//                   value: p['province_key'],
//                   child: Text(_displayProvince(p)),
//                 ))
//             .toList();

//         return Padding(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//             top: 20,
//           ),
//           child: StatefulBuilder(builder: (_, setModal) {
//             final cityList = cities()
//                 .map((c) => DropdownMenuItem<String>(
//                       value: c['en'],
//                       child: Text(_displayCity(c)),
//                     ))
//                 .toList();

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text('Select location',
//                     style:
//                         TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 20),
//                 DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: const InputDecoration(
//                     labelText: 'Province',
//                     border: OutlineInputBorder(),
//                   ),
//                   value: tempProvince,
//                   items: provinces,
//                   onChanged: (v) {
//                     setModal(() {
//                       tempProvince = v;
//                       tempCity = null;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: const InputDecoration(
//                     labelText: 'City',
//                     border: OutlineInputBorder(),
//                   ),
//                   value: tempCity,
//                   items: cityList,
//                   onChanged: (v) => setModal(() => tempCity = v),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _selectedProvinceKey = tempProvince;
//                       _selectedCityEn = tempCity;
//                     });
//                     _saveLocation(tempProvince, tempCity);
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: PatientAppColors.brandIndigo,
//                     minimumSize: const Size.fromHeight(44),
//                   ),
//                   child: const Text('Confirm'),
//                 ),
//               ],
//             );
//           }),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isGuest = !DatabaseService().isAuthenticated;

//     if (_loadingCities) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator(color: Colors.teal)),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F9FB),
//       body: Stack(
//         children: [
//           Container(
//             height: 340,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
//             ),
//           ),
//           SafeArea(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 _topBar(),
//                 const SizedBox(height: 10),
//                 _welcomeSection(isGuest: isGuest),
//                 const SizedBox(height: 16),
//                 _quickActionsGrid(),
//                 const SizedBox(height: 20),
//                 Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius:
//                         BorderRadius.vertical(top: Radius.circular(36)),
//                   ),
//                   padding: const EdgeInsets.only(top: 24),
//                   child: Column(
//                     children: [
//                       _nextAppointmentCard(),
//                       const SizedBox(height: 100),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: _bookFab(),
//     );
//   }

//   // --- TOP BAR & GREETING ---

//   Widget _topBar() => Padding(
//         padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text("My Health",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700)),
//             const _LanguageSelector(),
//           ],
//         ),
//       );

//   Widget _welcomeSection({required bool isGuest}) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(isGuest ? "Welcome" : "Welcome back",
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700)),
//             const SizedBox(height: 6),
//             Row(
//               children: [
//                 const Icon(Icons.place, size: 16, color: Colors.white),
//                 const SizedBox(width: 6),
//                 GestureDetector(
//                   onTap: _openLocationSelector,
//                   child: Text(
//                     _selectedCityEn ?? "Select city",
//                     style: const TextStyle(color: Colors.white, fontSize: 14),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );

//   // --- ACTION GRID ---

//   Widget _quickActionsGrid() {
//     final tiles = <_QuickTile>[
//       _QuickTile(
//           icon: Icons.category_outlined,
//           label: 'Specialties',
//           onTap: () => Navigator.push(
//               context,
//               PageTransition(
//                   type: PageTransitionType.fade,
//                   child: SpecialityScreen(
//                       provinceKey: _selectedProvinceKey,
//                       cityEn: _selectedCityEn)))),
//       _QuickTile(
//           icon: Icons.local_pharmacy_outlined,
//           label: 'Pharmacy',
//           onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Pharmacy coming soon')))),
//       _QuickTile(
//           icon: Icons.biotech_outlined,
//           label: 'Lab',
//           onTap: () => ScaffoldMessenger.of(context)
//               .showSnackBar(const SnackBar(content: Text('Lab coming soon')))),
//       _QuickTile(
//           icon: Icons.mail_outline,
//           label: 'Messages',
//           onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Messages coming soon')))),
//       _QuickTile(
//           icon: Icons.event_available_outlined,
//           label: 'My Appointments',
//           onTap: () => Navigator.push(
//               context,
//               PageTransition(
//                   type: PageTransitionType.rightToLeft,
//                   child: const MyAppointmentsPage()))),
//       _QuickTile(
//           icon: Icons.people_outline,
//           label: 'My Doctors',
//           onTap: () => Navigator.push(
//               context,
//               PageTransition(
//                   type: PageTransitionType.rightToLeft,
//                   child: const MyDoctorsPage()))),
//     ];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: GridView.count(
//         crossAxisCount: 3,
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         childAspectRatio: 1.05,
//         mainAxisSpacing: 12,
//         crossAxisSpacing: 12,
//         children: tiles.map((t) => t.build()).toList(),
//       ),
//     );
//   }

//   // --- UPCOMING VISIT (LIVE DATA) ---
//   Widget _nextAppointmentCard() {
//     final user = DatabaseService().currentUser;
//     if (user == null) return _noUpcomingCard();

//     // ✅ Matches your index order (status → userId → createdAt)
//     final query = FirebaseFirestore.instance
//         .collection('appointments')
//         .where('status',
//             isEqualTo: 'Pending') // or 'confirmed', based on your data
//         .where('userId', isEqualTo: user.uid)
//         .orderBy('createdAt', descending: true)
//         .limit(1);

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(color: Colors.teal),
//           );
//         }

//         if (snapshot.hasError) {
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               "Error loading appointments: ${snapshot.error}",
//               style: const TextStyle(color: Colors.red),
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return _noUpcomingCard();
//         }

//         final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

//         // Handle string-based date safely
//         DateTime? appointmentDate;
//         try {
//           if (data['date'] is String) {
//             appointmentDate = DateTime.tryParse(data['date']);
//           } else if (data['date'] is Timestamp) {
//             appointmentDate = (data['date'] as Timestamp).toDate();
//           }
//         } catch (_) {}

//         final doctorName = data['doctorName'] ?? 'Unknown Doctor';
//         final doctorType = data['doctorType'] ?? 'Specialty';
//         final clinic = data['clinicName'] ?? 'Clinic';
//         final slotTime = data['slotTime'] ?? '';

//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 8,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 _dateBadgeCustom(appointmentDate ?? DateTime.now()),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Upcoming Visit',
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.w700),
//                       ),
//                       const SizedBox(height: 4),
//                       Text('$doctorName · $doctorType',
//                           style: const TextStyle(color: Colors.black87)),
//                       const SizedBox(height: 4),
//                       Text('$clinic • $slotTime',
//                           style: const TextStyle(color: Colors.black54)),
//                       const SizedBox(height: 10),
//                       SizedBox(
//                         height: 36,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.rightToLeft,
//                                 child: const MyAppointmentsPage(),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF4A90E2),
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20)),
//                             elevation: 0,
//                           ),
//                           child: const Text(
//                             'View Details',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _noUpcomingCard() => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(14),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               _dateBadgeCustom(DateTime.now()),
//               const SizedBox(width: 14),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('No upcoming visits',
//                         style: TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.w700)),
//                     SizedBox(height: 6),
//                     Text('Book a visit to see a doctor.',
//                         style: TextStyle(color: Colors.black54)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );

//   // --- Localized date badge ---

//   Widget _dateBadgeCustom(DateTime date) {
//     final locale = Localizations.localeOf(context).toString();
//     final month = DateFormat.MMM(locale).format(date).toUpperCase();
//     final day = DateFormat.d(locale).format(date);
//     final dow = DateFormat.E(locale).format(date);

//     return Container(
//       width: 64,
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFF5CC6BA).withOpacity(.15),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(month,
//               style: const TextStyle(
//                   color: Color(0xFF4A90E2), fontWeight: FontWeight.w700)),
//           const SizedBox(height: 4),
//           Text(day,
//               style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w800,
//                   color: Colors.black)),
//           const SizedBox(height: 2),
//           Text(dow,
//               style: const TextStyle(color: Colors.black54, fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   // --- Floating Action Button ---

//   Widget _bookFab() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//         ),
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 10,
//               offset: const Offset(0, 4))
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(28),
//           onTap: () {
//             Navigator.push(
//               context,
//               PageTransition(
//                 type: PageTransitionType.fade,
//                 child: SpecialityScreen(
//                   provinceKey: _selectedProvinceKey,
//                   cityEn: _selectedCityEn,
//                 ),
//               ),
//             );
//           },
//           child: const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.add, color: Colors.white),
//                 SizedBox(width: 6),
//                 Text('Book Appointment',
//                     style: TextStyle(
//                         color: Colors.white, fontWeight: FontWeight.w700)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // --- Reusable quick tile widget ---

// class _QuickTile {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//   _QuickTile({required this.icon, required this.label, required this.onTap});

//   Widget build() => InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.95),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.08),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               )
//             ],
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 26, color: const Color(0xFF4A90E2)),
//               const SizedBox(height: 8),
//               Text(label,
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                       fontSize: 12.5, fontWeight: FontWeight.w600)),
//             ],
//           ),
//         ),
//       );
// }

// // --- Language Selector ---

// class _LanguageSelector extends StatelessWidget {
//   const _LanguageSelector();

//   @override
//   Widget build(BuildContext context) {
//     final current = Localizations.localeOf(context).languageCode;
//     return PopupMenuButton<Locale>(
//       icon: const Icon(Icons.language, color: Colors.white),
//       onSelected: (l) => Navigator.of(context).pushReplacement(PageTransition(
//           type: PageTransitionType.fade, child: const SplashScreen())),
//       itemBuilder: (_) => [
//         CheckedPopupMenuItem(
//             checked: current == 'en',
//             value: const Locale('en'),
//             child: const Text('English')),
//         CheckedPopupMenuItem(
//             checked: current == 'ar',
//             value: const Locale('ar'),
//             child: const Text('العربية')),
//         CheckedPopupMenuItem(
//             checked: current == 'ku',
//             value: const Locale('ku'),
//             child: const Text('کوردی')),
//       ],
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/services/database_service.dart';
// import 'package:trustydr/pages/screens.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   final _db = FirebaseFirestore.instance;
//   bool _loadingCities = true;
//   List<QueryDocumentSnapshot<Map<String, dynamic>>> _provinceDocs = [];
//   String? _selectedProvinceKey;
//   String? _selectedCityEn;
//   String? _displayName;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     await DatabaseService().initialize();
//     await _loadSavedLocation();
//     await _loadCities();
//     await _tryDetectLocation();
//     await _loadUserName();
//   }

//   Future<void> _loadUserName() async {
//     try {
//       final u = FirebaseAuth.instance.currentUser;
//       if (u == null) return;
//       String? name = u.displayName;

//       if (name == null || name.trim().isEmpty) {
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(u.uid)
//             .get();
//         final m = doc.data() ?? {};
//         name = (m['name'] ?? m['username'] ?? m['fullName'] ?? '').toString();
//       }

//       if (mounted) {
//         setState(() => _displayName =
//             (name?.trim().isEmpty ?? true) ? null : name!.trim());
//       }
//     } catch (_) {}
//   }

//   String _greetingText() {
//     final hour = DateTime.now().hour;
//     final base = hour < 12
//         ? 'Good morning'
//         : hour < 17
//             ? 'Good afternoon'
//             : 'Good evening';
//     final who = _displayName ?? 'there';
//     return '$base, $who 👋';
//   }

//   Future<void> _loadCities() async {
//     try {
//       final snap = await _db.collection('cities').get();
//       _provinceDocs = snap.docs;
//     } catch (e) {
//       debugPrint('Cities load failed: $e');
//     } finally {
//       if (mounted) setState(() => _loadingCities = false);
//     }
//   }

//   Future<void> _loadSavedLocation() async {
//     final prefs = await SharedPreferences.getInstance();
//     _selectedProvinceKey = prefs.getString('selectedProvinceKey');
//     _selectedCityEn = prefs.getString('selectedCityEn');
//   }

//   Future<void> _tryDetectLocation() async {
//     try {
//       if (_selectedCityEn != null) return;
//       if (!await Geolocator.isLocationServiceEnabled()) return;
//       var perm = await Geolocator.checkPermission();
//       if (perm == LocationPermission.denied) {
//         perm = await Geolocator.requestPermission();
//       }
//       if (perm == LocationPermission.denied ||
//           perm == LocationPermission.deniedForever) {
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition();
//       final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
//       if (marks.isEmpty) return;
//       final cityName = (marks.first.locality ?? '').toLowerCase();
//       for (final doc in _provinceDocs) {
//         final data = doc.data();
//         final subs = (data['subCities'] as List?) ?? [];
//         for (final raw in subs) {
//           final c = Map<String, dynamic>.from(raw as Map);
//           final names = [
//             (c['en'] ?? '').toString().toLowerCase(),
//             (c['ar'] ?? '').toString().toLowerCase(),
//             (c['ku'] ?? '').toString().toLowerCase(),
//           ];
//           if (names.any((n) => n.isNotEmpty && cityName.contains(n))) {
//             setState(() {
//               _selectedProvinceKey = data['province_key'];
//               _selectedCityEn = c['en'];
//             });
//             return;
//           }
//         }
//       }
//     } catch (_) {}
//   }

//   String _displayProvince(Map<String, dynamic> p) {
//     final lang = context.locale.languageCode;
//     if (lang == 'ar') return (p['lang']?['ar'] ?? p['name_en'])!;
//     if (lang == 'ku') return (p['lang']?['ku'] ?? p['name_en'])!;
//     return p['name_en']!;
//   }

//   // --------------------------- UI ---------------------------
//   @override
//   Widget build(BuildContext context) {
//     final isGuest = !DatabaseService().isAuthenticated;

//     if (_loadingCities) {
//       return const Scaffold(
//           body: Center(child: CircularProgressIndicator(color: Colors.teal)));
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F8FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: Row(
//           children: [
//             const Icon(Icons.location_on, color: Colors.black, size: 18),
//             const SizedBox(width: 6),
//             Text(
//               (_selectedProvinceKey != null && _selectedCityEn != null)
//                   ? '$_selectedCityEn, $_selectedProvinceKey'
//                   : tr('select_city'),
//               style: appBarLocationTextStyle,
//             ),
//           ],
//         ),
//         actions: const [_LanguageSelector()],
//       ),
//       body: Stack(
//         children: [
//           const _CurvedGradientHeader(height: 170, child: SizedBox.expand()),
//           ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(_greetingText(),
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w700)),
//                     const SizedBox(height: 12),
//                     _searchBar(),
//                   ],
//                 ),
//               ),
//               if (isGuest) _guestBanner(context),
//               const SizedBox(height: 8),
//               _quickActionsGrid(),
//               const SizedBox(height: 12),
//               _nextAppointmentCard(),
//               const SizedBox(height: 16),
//               _featuredSpecialties(),
//               const SizedBox(height: 8),
//               _pharmacySection(),
//               const SizedBox(height: 8),
//               _labsSection(),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // -------------------- UI Helpers --------------------

//   Widget _guestBanner(BuildContext context) => Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFF6D6),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFFFE8A3)),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.info_outline, color: Colors.black54),
//             const SizedBox(width: 8),
//             const Expanded(
//                 child: Text("You are currently browsing as a guest.",
//                     style: TextStyle(color: Colors.black87))),
//             TextButton(
//               onPressed: () => Navigator.push(
//                 context,
//                 PageTransition(
//                     type: PageTransitionType.rightToLeft,
//                     child: const LoginScreen()),
//               ),
//               child: const Text("Login"),
//             ),
//           ],
//         ),
//       );

//   Widget _searchBar() => Container(
//         height: 46,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(28),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: Row(
//           children: const [
//             Icon(Icons.search, color: Colors.black54),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text("Search for doctors or clinics…",
//                   style: TextStyle(color: Colors.black54, fontSize: 14)),
//             ),
//           ],
//         ),
//       );

//   Widget _quickActionsGrid() {
//     final items = [
//       _QuickTile(
//           icon: Icons.category_outlined,
//           label: 'Specialties',
//           onTap: () => Navigator.push(
//               context,
//               PageTransition(
//                   type: PageTransitionType.fade,
//                   child: SpecialityScreen(
//                       provinceKey: _selectedProvinceKey,
//                       cityEn: _selectedCityEn)))),
//       _QuickTile(
//           icon: Icons.local_pharmacy_outlined,
//           label: 'Pharmacy',
//           onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Pharmacy list coming soon')))),
//       _QuickTile(
//           icon: Icons.biotech_outlined,
//           label: 'Lab',
//           onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Labs list coming soon')))),
//       _QuickTile(
//           icon: Icons.mail_outline,
//           label: 'Messages',
//           onTap: () => ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Messages coming soon')))),
//       _QuickTile(
//           icon: Icons.calendar_month_outlined,
//           label: 'My Appointments',
//           onTap: () => Navigator.push(
//               context,
//               PageTransition(
//                   type: PageTransitionType.rightToLeft,
//                   child: const MyAppointmentsPage()))),
//       _QuickTile(
//           icon: Icons.people_outline,
//           label: 'My Doctors',
//           onTap: () => Navigator.push(
//               context,
//               PageTransition(
//                   type: PageTransitionType.rightToLeft,
//                   child: const MyDoctorsPage()))),
//     ];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3,
//             mainAxisSpacing: 12,
//             crossAxisSpacing: 12,
//             childAspectRatio: 1.05),
//         itemCount: items.length,
//         itemBuilder: (_, i) => items[i].build(),
//       ),
//     );
//   }

//   Widget _nextAppointmentCard() {
//     final user = DatabaseService().currentUser;
//     if (user == null) return _noUpcomingCard();

//     final query = FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: user.uid)
//         .orderBy('createdAt', descending: true)
//         .limit(1);

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return _noUpcomingCard();
//         }

//         final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
//         DateTime? appointmentDate;
//         try {
//           appointmentDate = data['date'] is String
//               ? DateTime.tryParse(data['date'])
//               : (data['date'] as Timestamp).toDate();
//         } catch (_) {}

//         final doctorName = data['doctorName'] ?? 'Unknown Doctor';
//         final doctorType = data['doctorType'] ?? 'Specialty';
//         final clinic = data['clinicName'] ?? 'Clinic';
//         final slotTime = data['slotTime'] ?? '';

//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 350),
//             transitionBuilder: (child, anim) => SlideTransition(
//               position:
//                   Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
//                       .animate(anim),
//               child: FadeTransition(opacity: anim, child: child),
//             ),
//             child: Container(
//               key: ValueKey(appointmentDate.toString()),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   _dateBadgeCustom(appointmentDate ?? DateTime.now()),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text('Upcoming Visit',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.w700)),
//                           const SizedBox(height: 4),
//                           Text('$doctorName · $doctorType',
//                               style: const TextStyle(color: Colors.black87)),
//                           const SizedBox(height: 4),
//                           Text('$clinic • $slotTime',
//                               style: const TextStyle(color: Colors.black54)),
//                           const SizedBox(height: 10),
//                           SizedBox(
//                             height: 36,
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 Navigator.push(
//                                   context,
//                                   PageTransition(
//                                       type: PageTransitionType.rightToLeft,
//                                       child: const MyAppointmentsPage()),
//                                 );
//                               },
//                               style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF4A90E2),
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20))),
//                               child: const Text('View Details',
//                                   style: TextStyle(color: Colors.white)),
//                             ),
//                           )
//                         ]),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _noUpcomingCard() => const SizedBox.shrink();

//   Widget _dateBadgeCustom(DateTime date) {
//     final month = [
//       'JAN',
//       'FEB',
//       'MAR',
//       'APR',
//       'MAY',
//       'JUN',
//       'JUL',
//       'AUG',
//       'SEP',
//       'OCT',
//       'NOV',
//       'DEC'
//     ][date.month - 1];
//     final day = date.day.toString().padLeft(2, '0');
//     final dow =
//         ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
//     return Container(
//       width: 60,
//       height: 70,
//       decoration: BoxDecoration(
//         color: const Color(0xFF4A90E2),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       alignment: Alignment.center,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(month,
//               style: const TextStyle(color: Colors.white70, fontSize: 12)),
//           Text(day,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold)),
//           Text(dow,
//               style: const TextStyle(color: Colors.white70, fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   Widget _featuredSpecialties() => const SizedBox.shrink();
//   Widget _pharmacySection() => const SizedBox.shrink();
//   Widget _labsSection() => const SizedBox.shrink();
// }

// // ---------- Helper Widgets ----------
// class _CurvedGradientHeader extends StatelessWidget {
//   final Widget child;
//   final double height;
//   const _CurvedGradientHeader(
//       {required this.child, this.height = 180, Key? key})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
//       child: Container(
//         height: height,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//               colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight),
//         ),
//         child: child,
//       ),
//     );
//   }
// }

// class _QuickTile {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;
//   _QuickTile({required this.icon, required this.label, required this.onTap});

//   Widget build() {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFFEAF9FF), Color(0xFFDFF3FA)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3))
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: const Color(0xFF4A90E2), size: 40),
//             const SizedBox(height: 8),
//             Text(label,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontWeight: FontWeight.bold, color: Colors.black87)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _LanguageSelector extends StatelessWidget {
//   const _LanguageSelector();

//   @override
//   Widget build(BuildContext context) {
//     final current = context.locale.languageCode;
//     return PopupMenuButton<Locale>(
//       icon: const Icon(Icons.language, color: Colors.black),
//       onSelected: (l) => context.setLocale(l),
//       itemBuilder: (_) => [
//         CheckedPopupMenuItem(
//             checked: current == 'en',
//             value: const Locale('en'),
//             child: const Text('English')),
//         CheckedPopupMenuItem(
//             checked: current == 'ar',
//             value: const Locale('ar'),
//             child: const Text('العربية')),
//         CheckedPopupMenuItem(
//             checked: current == 'ku',
//             value: const Locale('ku'),
//             child: const Text('کوردی')),
//       ],
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/screens.dart' hide blackColor;
// import 'package:trustydr/services/database_service.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:page_transition/page_transition.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
//   final _db = FirebaseFirestore.instance;

//   // Cities/provinces
//   bool _loadingCities = true;
//   List<QueryDocumentSnapshot<Map<String, dynamic>>> _provinceDocs = [];
//   String? _selectedProvinceKey;
//   String? _selectedCityEn;

//   // Greeting
//   String? _displayName;

//   // Tiles animation (300ms fade + slight slide-up)
//   late final AnimationController _tilesCtrl;
//   late final Animation<double> _tilesFade;
//   late final Animation<Offset> _tilesSlide;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//     _tilesCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _tilesFade = CurvedAnimation(parent: _tilesCtrl, curve: Curves.easeOut);
//     _tilesSlide =
//         Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(
//       CurvedAnimation(parent: _tilesCtrl, curve: Curves.easeOut),
//     );
//     // Start tiles animation after first frame so UI is mounted
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) _tilesCtrl.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _tilesCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _init() async {
//     await DatabaseService().initialize();
//     await _loadSavedLocation();
//     await _loadCities();
//     await _tryDetectLocation();
//     await _loadUserName();
//   }

//   Future<void> _loadUserName() async {
//     try {
//       final u = FirebaseAuth.instance.currentUser;
//       if (u == null) return;

//       String? name = u.displayName;
//       if (name == null || name.trim().isEmpty) {
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(u.uid)
//             .get();
//         final m = doc.data() ?? {};
//         name = (m['name'] ??
//                 m['username'] ??
//                 m['fullName'] ??
//                 m['displayName'] ??
//                 '')
//             .toString();
//       }
//       if (mounted) {
//         setState(() {
//           _displayName = (name?.trim().isEmpty ?? true) ? null : name!.trim();
//         });
//       }
//     } catch (_) {}
//   }

//   String _greetingText() {
//     final h = DateTime.now().hour;
//     final base = h < 12
//         ? 'Good morning'
//         : h < 17
//             ? 'Good afternoon'
//             : 'Good evening';
//     final who = _displayName ?? 'there';
//     return '$base, $who 👋';
//   }

//   Future<void> _loadCities() async {
//     try {
//       final snap = await _db.collection('cities').get();
//       _provinceDocs = snap.docs;
//     } catch (e) {
//       debugPrint('Cities load failed: $e');
//     } finally {
//       if (mounted) setState(() => _loadingCities = false);
//     }
//   }

//   Future<void> _loadSavedLocation() async {
//     final prefs = await SharedPreferences.getInstance();
//     _selectedProvinceKey = prefs.getString('selectedProvinceKey');
//     _selectedCityEn = prefs.getString('selectedCityEn');
//   }

//   Future<void> _saveLocation(String? provinceKey, String? cityEn) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('selectedProvinceKey', provinceKey ?? '');
//     await prefs.setString('selectedCityEn', cityEn ?? '');
//   }

//   Future<void> _tryDetectLocation() async {
//     try {
//       if (_selectedCityEn != null) return;
//       if (!await Geolocator.isLocationServiceEnabled()) return;

//       var perm = await Geolocator.checkPermission();
//       if (perm == LocationPermission.denied) {
//         perm = await Geolocator.requestPermission();
//       }
//       if (perm == LocationPermission.denied ||
//           perm == LocationPermission.deniedForever) return;

//       final pos = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);
//       final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
//       if (marks.isEmpty) return;

//       final cityName = (marks.first.locality ?? '').toLowerCase();
//       for (final doc in _provinceDocs) {
//         final data = doc.data();
//         final subs = (data['subCities'] as List?) ?? [];
//         for (final raw in subs) {
//           final c = Map<String, dynamic>.from(raw as Map);
//           final names = [
//             (c['en'] ?? '').toString().toLowerCase(),
//             (c['ar'] ?? '').toString().toLowerCase(),
//             (c['ku'] ?? '').toString().toLowerCase(),
//           ];
//           if (names.any((n) => n.isNotEmpty && cityName.contains(n))) {
//             if (!mounted) return;
//             setState(() {
//               _selectedProvinceKey = data['province_key'];
//               _selectedCityEn = c['en'];
//             });
//             _saveLocation(_selectedProvinceKey, _selectedCityEn);
//             return;
//           }
//         }
//       }
//     } catch (_) {}
//   }

//   String _displayProvince(Map<String, dynamic> p) {
//     final lang = context.locale.languageCode;
//     if (lang == 'ar') return (p['lang']?['ar'] ?? p['name_en'])!;
//     if (lang == 'ku') return (p['lang']?['ku'] ?? p['name_en'])!;
//     return p['name_en']!;
//   }

//   String _displayCity(Map<String, dynamic> c) {
//     final lang = context.locale.languageCode;
//     if (lang == 'ar') return (c['ar'] ?? c['en'])!;
//     if (lang == 'ku') return (c['ku'] ?? c['en'])!;
//     return c['en']!;
//   }

//   void _openLocationSelector() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (ctx) {
//         String? tempProvince = _selectedProvinceKey;
//         String? tempCity = _selectedCityEn;

//         List<Map<String, dynamic>> cities() {
//           final prov = _provinceDocs
//               .where((d) => d.data()['province_key'] == tempProvince)
//               .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()
//               .firstOrNull;
//           if (prov == null) return [];

//           final subs = (prov.data()['subCities'] as List?) ?? [];
//           final seen = <String>{};
//           return subs
//               .map((e) => Map<String, dynamic>.from(e as Map))
//               .where((c) => seen.add((c['en'] ?? '').toString()))
//               .toList();
//         }

//         return Padding(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//             top: 20,
//           ),
//           child: StatefulBuilder(builder: (_, setModal) {
//             final provinces = _provinceDocs
//                 .map((d) => d.data())
//                 .map((p) => DropdownMenuItem<String>(
//                       value: p['province_key'],
//                       child: Text(_displayProvince(p)),
//                     ))
//                 .toList();

//             final cityList = cities()
//                 .map((c) => DropdownMenuItem<String>(
//                       value: c['en'],
//                       child: Text(_displayCity(c)),
//                     ))
//                 .toList();

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(tr('select_location'), style: blackHeadingTextStyle),
//                 const SizedBox(height: 20),
//                 DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: InputDecoration(
//                     labelText: tr('province'),
//                     border: const OutlineInputBorder(),
//                   ),
//                   value: tempProvince,
//                   items: provinces,
//                   onChanged: (v) {
//                     setModal(() {
//                       tempProvince = v;
//                       tempCity = null;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: InputDecoration(
//                     labelText: tr('city'),
//                     border: const OutlineInputBorder(),
//                   ),
//                   value: tempCity,
//                   items: cityList,
//                   onChanged: (v) => setModal(() => tempCity = v),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _selectedProvinceKey = tempProvince;
//                       _selectedCityEn = tempCity;
//                     });
//                     _saveLocation(tempProvince, tempCity);
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: PatientAppColors.brandIndigo,
//                     minimumSize: const Size.fromHeight(44),
//                   ),
//                   child: Text(tr('confirm')),
//                 ),
//               ],
//             );
//           }),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isGuest = !DatabaseService().isAuthenticated;

//     if (_loadingCities) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator(color: Colors.teal)),
//       );
//     }

//     final provinceName = _selectedProvinceKey == null
//         ? ''
//         : _displayProvince(_provinceDocs
//             .firstWhere((d) => d.data()['province_key'] == _selectedProvinceKey)
//             .data());

//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F8FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: InkWell(
//           onTap: _openLocationSelector,
//           child: Row(
//             children: [
//               const Icon(Icons.location_on, color: Colors.black, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 (_selectedProvinceKey != null && _selectedCityEn != null)
//                     ? '$_selectedCityEn, $provinceName'
//                     : tr('select_city'),
//                 style: appBarLocationTextStyle,
//               ),
//               const Icon(Icons.keyboard_arrow_down),
//             ],
//           ),
//         ),
//         actions: const [_LanguageSelector()],
//       ),
//       body: Stack(
//         children: [
//           const _CurvedGradientHeader(height: 170, child: SizedBox.expand()),
//           ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               // Header content (greeting + search)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _greetingText(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     _searchBar(),
//                   ],
//                 ),
//               ),

//               if (isGuest) _guestBanner(context),

//               const SizedBox(height: 8),

//               // Six white tiles with animation
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: FadeTransition(
//                   opacity: _tilesFade,
//                   child: SlideTransition(
//                     position: _tilesSlide,
//                     child: GridView.count(
//                       crossAxisCount: 3,
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisSpacing: 12,
//                       mainAxisSpacing: 12,
//                       childAspectRatio: 1.05,
//                       children: [
//                         _quickTile(
//                           icon: Icons.category_outlined,
//                           label: 'Specialties',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.fade,
//                                 child: SpecialityScreen(
//                                   provinceKey: _selectedProvinceKey,
//                                   cityEn: _selectedCityEn,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.local_pharmacy_outlined,
//                           label: 'Pharmacy',
//                           onTap: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text('Pharmacies list coming soon')),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.biotech_outlined,
//                           label: 'Labs',
//                           onTap: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text('Labs list coming soon')),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.mail_outline,
//                           label: 'Messages',
//                           onTap: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text('Messages coming soon')),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.calendar_month_outlined,
//                           label: 'My Appointments',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.rightToLeft,
//                                 child: const MyAppointmentsPage(),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.people_outline,
//                           label: 'My Doctors',
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.rightToLeft,
//                                 child: const MyDoctorsPage(),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // Upcoming Visit (animated switcher)
//               _nextAppointmentCard(),

//               const SizedBox(height: 24),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // Search bar (unchanged)
//   Widget _searchBar() {
//     return InkWell(
//       onTap: () => Navigator.push(
//         context,
//         PageTransition(
//           type: PageTransitionType.scale,
//           alignment: Alignment.bottomCenter,
//           child: Search(city: _selectedCityEn ?? ''),
//         ),
//       ),
//       child: Container(
//         height: 46,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(28),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: Row(
//           children: const [
//             Icon(Icons.search, color: Colors.black54),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 "Search for doctors or clinics…",
//                 style: TextStyle(color: Colors.black54, fontSize: 14),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Quick tile (pure white + shadow)
//   Widget _quickTile({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white, // pure white as requested
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             )
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 26, color: const Color(0xFF4A90E2)),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style:
//                   const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Upcoming Visit (Firestore)
//   Widget _nextAppointmentCard() {
//     final user = DatabaseService().currentUser;
//     if (user == null) return _noUpcomingCard();

//     // Uses your existing composite index: status ↑, userId ↑, createdAt ↓
//     final query = FirebaseFirestore.instance
//         .collection('appointments')
//         .where('status', isEqualTo: 'Pending') // adjust if you use 'confirmed'
//         .where('userId', isEqualTo: user.uid)
//         .orderBy('createdAt', descending: true)
//         .limit(1);

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         Widget child;
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           child = const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Center(
//               child: CircularProgressIndicator(color: Colors.teal),
//             ),
//           );
//         } else if (snapshot.hasError) {
//           child = Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text('Error loading appointments: ${snapshot.error}',
//                 style: const TextStyle(color: Colors.red)),
//           );
//         } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           child = _noUpcomingCard(innerOnly: true);
//         } else {
//           final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

//           DateTime? appointmentDate;
//           try {
//             final raw = data['date'];
//             if (raw is Timestamp) {
//               appointmentDate = raw.toDate();
//             } else if (raw is String) {
//               appointmentDate = DateTime.tryParse(raw);
//             }
//           } catch (_) {}
//           appointmentDate ??= DateTime.now();

//           final doctorName = data['doctorName'] ?? 'Doctor';
//           final specialty =
//               data['doctorType'] ?? data['specialty'] ?? 'Specialty';
//           final clinic = data['clinicName'] ?? data['clinic'] ?? 'Clinic';
//           final slotTime = data['slotTime'] ?? '';
//           final status = (data['status'] ?? 'Pending').toString();

//           child = Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   _dateBadgeCustom(appointmentDate),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text('Upcoming Visit',
//                             style: TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w700)),
//                         const SizedBox(height: 4),
//                         Text('$doctorName · $specialty',
//                             style: const TextStyle(color: Colors.black87)),
//                         const SizedBox(height: 4),
//                         Text('$clinic • $slotTime',
//                             style: const TextStyle(color: Colors.black54)),
//                         const SizedBox(height: 4),
//                         Text('Status: $status',
//                             style: TextStyle(
//                               color: status.toLowerCase() == 'pending'
//                                   ? Colors.orange
//                                   : Colors.teal,
//                               fontWeight: FontWeight.w600,
//                             )),
//                         const SizedBox(height: 10),
//                         SizedBox(
//                           height: 36,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 PageTransition(
//                                   type: PageTransitionType.rightToLeft,
//                                   child: const MyAppointmentsPage(),
//                                 ),
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF4A90E2),
//                               shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(20)),
//                               elevation: 0,
//                             ),
//                             child: const Text('View Details',
//                                 style: TextStyle(color: Colors.white)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         // 300ms fade + slide via AnimatedSwitcher (no controller needed)
//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 300),
//           transitionBuilder: (child, anim) => SlideTransition(
//             position:
//                 Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
//                     .animate(anim),
//             child: FadeTransition(opacity: anim, child: child),
//           ),
//           child: child,
//         );
//       },
//     );
//   }

//   Widget _noUpcomingCard({bool innerOnly = false}) {
//     final card = Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           _dateBadgeCustom(DateTime.now()),
//           const SizedBox(width: 14),
//           const Expanded(
//             child: Text(
//               'No upcoming visits',
//               style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black54),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (innerOnly) return card;
//     return Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16), child: card);
//   }

//   // Guest banner
//   Widget _guestBanner(BuildContext context) => Container(
//         margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFF6D6),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFFFE8A3)),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.info_outline, color: Colors.black54),
//             const SizedBox(width: 8),
//             const Expanded(
//               child: Text(
//                 "You are currently browsing as a guest.",
//                 style: TextStyle(color: Colors.black87),
//               ),
//             ),
//             TextButton(
//               onPressed: () => Navigator.push(
//                 context,
//                 PageTransition(
//                   type: PageTransitionType.rightToLeft,
//                   child: const LoginScreen(),
//                 ),
//               ),
//               child: const Text("Login"),
//             ),
//           ],
//         ),
//       );

//   // Date badge
//   Widget _dateBadgeCustom(DateTime date) {
//     const months = [
//       'JAN',
//       'FEB',
//       'MAR',
//       'APR',
//       'MAY',
//       'JUN',
//       'JUL',
//       'AUG',
//       'SEP',
//       'OCT',
//       'NOV',
//       'DEC'
//     ];
//     const dows = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//     final month = months[date.month - 1];
//     final day = date.day.toString().padLeft(2, '0');
//     final dow = dows[date.weekday - 1];

//     return Container(
//       width: 64,
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFF4A90E2),
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(month,
//               style: const TextStyle(
//                   color: Colors.white, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 2),
//           Text(day,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 18)),
//           const SizedBox(height: 2),
//           Text(dow,
//               style: const TextStyle(
//                   color: Colors.white70, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
// }

// // Curved gradient header (teal → blue)
// class _CurvedGradientHeader extends StatelessWidget {
//   final Widget child;
//   final double height;
//   const _CurvedGradientHeader(
//       {required this.child, this.height = 180, Key? key})
//       : super(key: key);

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

// // Language selector (unchanged)
// class _LanguageSelector extends StatelessWidget {
//   const _LanguageSelector();

//   @override
//   Widget build(BuildContext context) {
//     final current = context.locale.languageCode;
//     return PopupMenuButton<Locale>(
//       icon: const Icon(Icons.language, color: Colors.black),
//       onSelected: (l) => context.setLocale(l),
//       itemBuilder: (_) => [
//         CheckedPopupMenuItem(
//             checked: current == 'en',
//             value: const Locale('en'),
//             child: const Text('English')),
//         CheckedPopupMenuItem(
//             checked: current == 'ar',
//             value: const Locale('ar'),
//             child: const Text('العربية')),
//         CheckedPopupMenuItem(
//             checked: current == 'ku',
//             value: const Locale('ku'),
//             child: const Text('کوردی')),
//       ],
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:trustydr/constant/constant.dart';
// import 'package:trustydr/pages/screens.dart' hide blackColor;
// import 'package:trustydr/services/database_service.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';

// import 'package:page_transition/page_transition.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:easy_localization/easy_localization.dart';

// // import 'package:http/http.dart' as http;

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
//   final _db = FirebaseFirestore.instance;

//   // Cities/provinces
//   bool _loadingCities = true;
//   List<QueryDocumentSnapshot<Map<String, dynamic>>> _provinceDocs = [];
//   String? _selectedProvinceKey;
//   String? _selectedCityEn;

//   // Greeting
//   String? _displayName;

//   // Import loading
//   bool _isImporting = false;

//   // Tiles animation (300ms fade + slight slide-up)
//   late final AnimationController _tilesCtrl;
//   late final Animation<double> _tilesFade;
//   late final Animation<Offset> _tilesSlide;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//     _tilesCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _tilesFade = CurvedAnimation(parent: _tilesCtrl, curve: Curves.easeOut);
//     _tilesSlide =
//         Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(
//       CurvedAnimation(parent: _tilesCtrl, curve: Curves.easeOut),
//     );
//     // Start tiles animation after first frame so UI is mounted
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) _tilesCtrl.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _tilesCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _init() async {
//     await DatabaseService().initialize();
//     await _loadSavedLocation();
//     await _loadCities();

//     await _loadUserName();
//   }

//   Future<void> _loadUserName() async {
//     try {
//       final u = FirebaseAuth.instance.currentUser;
//       if (u == null) return;

//       String? name = u.displayName;
//       if (name == null || name.trim().isEmpty) {
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(u.uid)
//             .get();
//         final m = doc.data() ?? {};
//         name = (m['name'] ??
//                 m['username'] ??
//                 m['fullName'] ??
//                 m['displayName'] ??
//                 '')
//             .toString();
//       }
//       if (mounted) {
//         setState(() {
//           _displayName = (name?.trim().isEmpty ?? true) ? null : name!.trim();
//         });
//       }
//     } catch (_) {}
//   }

//   String _greetingText() {
//     final h = DateTime.now().hour;

//     final baseKey = h < 12
//         ? 'greeting_morning'
//         : h < 17
//             ? 'greeting_afternoon'
//             : 'greeting_evening';

//     final who = _displayName ?? 'greeting_default'.tr();

//     return '${baseKey.tr()}, $who 👋';
//   }

//   Future<void> _loadCities() async {
//     try {
//       final snap = await _db.collection('cities').get();
//       _provinceDocs = snap.docs;
//     } catch (e) {
//       debugPrint('Cities load failed: $e');
//     } finally {
//       if (mounted) setState(() => _loadingCities = false);
//     }
//   }

//   Future<void> _loadSavedLocation() async {
//     final prefs = await SharedPreferences.getInstance();
//     _selectedProvinceKey = prefs.getString('selectedProvinceKey');
//     _selectedCityEn = prefs.getString('selectedCityEn');
//   }

//   Future<void> _saveLocation(String? provinceKey, String? cityEn) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('selectedProvinceKey', provinceKey ?? '');
//     await prefs.setString('selectedCityEn', cityEn ?? '');
//   }

//   String _displayProvince(Map<String, dynamic> p) {
//     final lang = context.locale.languageCode;
//     if (lang == 'ar') return (p['lang']?['ar'] ?? p['name_en'])!;
//     if (lang == 'ku') return (p['lang']?['ku'] ?? p['name_en'])!;
//     return p['name_en']!;
//   }

//   String _displayCity(Map<String, dynamic> c) {
//     final lang = context.locale.languageCode;
//     if (lang == 'ar') return (c['ar'] ?? c['en'])!;
//     if (lang == 'ku') return (c['ku'] ?? c['en'])!;
//     return c['en']!;
//   }

//   // /// Call Google Cloud Function to import clinics from Google Places
//   // Future<void> _importClinics(String province, String city) async {
//   //   final query = "$city $province".trim();
//   //   final encoded = Uri.encodeComponent(query);

//   //   final url =
//   //       "https://us-central1-doctorapp-7e8b3.cloudfunctions.net/fetchGooglePlacesClinics?city=$encoded";

//   //   try {
//   //     final res = await http.get(Uri.parse(url));

//   //     if (res.statusCode == 200) {
//   //       debugPrint("Clinics imported successfully → ${res.body}");
//   //     } else {
//   //       debugPrint("❌ Import failed → ${res.statusCode} : ${res.body}");
//   //     }
//   //   } catch (e) {
//   //     debugPrint("❌ Error calling import API: $e");
//   //   }
//   // }

//   void _openLocationSelector() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (ctx) {
//         String? tempProvince = _selectedProvinceKey;
//         String? tempCity = _selectedCityEn;

//         List<Map<String, dynamic>> cities() {
//           final prov = _provinceDocs
//               .where((d) => d.data()['province_key'] == tempProvince)
//               .cast<QueryDocumentSnapshot<Map<String, dynamic>>>()
//               .firstOrNull;
//           if (prov == null) return [];

//           final subs = (prov.data()['subCities'] as List?) ?? [];
//           final seen = <String>{};
//           return subs
//               .map((e) => Map<String, dynamic>.from(e as Map))
//               .where((c) => seen.add((c['en'] ?? '').toString()))
//               .toList();
//         }

//         return Padding(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//             top: 20,
//           ),
//           child: StatefulBuilder(builder: (_, setModal) {
//             final provinces = _provinceDocs
//                 .map((d) => d.data())
//                 .map((p) => DropdownMenuItem<String>(
//                       value: p['province_key'],
//                       child: Text(_displayProvince(p)),
//                     ))
//                 .toList();

//             final cityList = cities()
//                 .map((c) => DropdownMenuItem<String>(
//                       value: c['en'],
//                       child: Text(_displayCity(c)),
//                     ))
//                 .toList();

//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text('select_location'.tr(), style: blackHeadingTextStyle),
//                 const SizedBox(height: 20),
//                 DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: InputDecoration(
//                     labelText: 'province'.tr(),
//                     border: const OutlineInputBorder(),
//                   ),
//                   value: tempProvince,
//                   items: provinces,
//                   onChanged: (v) {
//                     setModal(() {
//                       tempProvince = v;
//                       tempCity = null;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: InputDecoration(
//                     labelText: 'city'.tr(),
//                     border: const OutlineInputBorder(),
//                   ),
//                   value: tempCity,
//                   items: cityList,
//                   onChanged: (v) => setModal(() => tempCity = v),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (tempProvince == null || tempCity == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('province_city_required'.tr()),
//                         ),
//                       );
//                       return;
//                     }

//                     Navigator.pop(context); // close bottom sheet

//                     setState(() => _isImporting = true);

//                     // await _importClinics(tempProvince!, tempCity!);
//                     await _saveLocation(tempProvince, tempCity);

//                     setState(() {
//                       _selectedProvinceKey = tempProvince;
//                       _selectedCityEn = tempCity;
//                     });

//                     setState(() => _isImporting = false);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'clinics_loaded_in_city'.tr(
//                             namedArgs: {'city': tempCity ?? ''},
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: PatientAppColors.brandIndigo,
//                     minimumSize: const Size.fromHeight(44),
//                   ),
//                   child: Text('confirm'.tr()),
//                 ),
//               ],
//             );
//           }),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isGuest = !DatabaseService().isAuthenticated;

//     if (_loadingCities) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator(color: Colors.teal)),
//       );
//     }

//     final provinceName = _selectedProvinceKey == null
//         ? ''
//         : _displayProvince(_provinceDocs
//             .firstWhere((d) => d.data()['province_key'] == _selectedProvinceKey)
//             .data());

//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F8FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: InkWell(
//           onTap: _openLocationSelector,
//           child: Row(
//             children: [
//               const Icon(Icons.location_on, color: Colors.black, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 (_selectedProvinceKey != null && _selectedCityEn != null)
//                     ? '$_selectedCityEn, $provinceName'
//                     : 'select_city'.tr(),
//                 style: appBarLocationTextStyle,
//               ),
//               const Icon(Icons.keyboard_arrow_down),
//             ],
//           ),
//         ),
//         actions: const [_LanguageSelector()],
//       ),
//       body: Stack(
//         children: [
//           const _CurvedGradientHeader(height: 170, child: SizedBox.expand()),
//           ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               // Header content (greeting + search)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _greetingText(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     _searchBar(),
//                   ],
//                 ),
//               ),

//               if (isGuest) _guestBanner(context),

//               const SizedBox(height: 8),

//               // Six white tiles with animation
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: FadeTransition(
//                   opacity: _tilesFade,
//                   child: SlideTransition(
//                     position: _tilesSlide,
//                     child: GridView.count(
//                       crossAxisCount: 3,
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       crossAxisSpacing: 12,
//                       mainAxisSpacing: 12,
//                       childAspectRatio: 1.05,
//                       children: [
//                         _quickTile(
//                           icon: Icons.category_outlined,
//                           label: 'specialties'.tr(),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.fade,
//                                 child: SpecialityScreen(
//                                   provinceKey: _selectedProvinceKey,
//                                   cityEn: _selectedCityEn,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.local_pharmacy_outlined,
//                           label: 'pharmacy'.tr(),
//                           onTap: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('pharmacies_coming_soon'.tr()),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.biotech_outlined,
//                           label: 'labs'.tr(),
//                           onTap: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('labs_coming_soon'.tr()),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.mail_outline,
//                           label: 'messages'.tr(),
//                           onTap: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('messages_coming_soon'.tr()),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.calendar_month_outlined,
//                           label: 'my_appointments'.tr(),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.rightToLeft,
//                                 child: const MyAppointmentsPage(),
//                               ),
//                             );
//                           },
//                         ),
//                         _quickTile(
//                           icon: Icons.people_outline,
//                           label: 'my_doctors'.tr(),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               PageTransition(
//                                 type: PageTransitionType.rightToLeft,
//                                 child: const MyDoctorsPage(),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // Upcoming Visit (animated switcher)
//               _nextAppointmentCard(),

//               const SizedBox(height: 24),
//             ],
//           ),

//           // Import loading overlay
//           if (_isImporting)
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               child: const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _noUpcomingCard({bool innerOnly = false}) {
//     final card = Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           _dateBadgeCustom(DateTime.now()),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Text(
//               'home.noUpcomingVisits'.tr(),
//               // ✅ localize this key
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (innerOnly) return card;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: card,
//     );
//   }

//   // Search bar
//   Widget _searchBar() {
//     return InkWell(
//       onTap: () => Navigator.push(
//         context,
//         PageTransition(
//           type: PageTransitionType.scale,
//           alignment: Alignment.bottomCenter,
//           child: Search(city: _selectedCityEn ?? ''),
//         ),
//       ),
//       child: Container(
//         height: 46,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(28),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: Row(
//           children: [
//             Icon(Icons.search, color: Colors.black54),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'search_doctor_or_clinic'.tr(),
//                 style: TextStyle(color: Colors.black54, fontSize: 14),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _prettyStatus(String status) {
//     final s = status.trim().toLowerCase();
//     switch (s) {
//       case 'pending':
//         return 'status.pending'.tr();
//       case 'confirmed':
//         return 'status.confirmed'.tr();
//       case 'completed':
//         return 'status.completed'.tr();
//       case 'cancelled':
//         return 'status.cancelled'.tr();
//       default:
//         return status;
//     }
//   }

//   // Quick tile (pure white + shadow)
//   Widget _quickTile({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white, // pure white as requested
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             )
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 26, color: const Color(0xFF4A90E2)),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style:
//                   const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// // Upcoming Visit (Firestore)
//   Widget _nextAppointmentCard() {
//     final user = DatabaseService().currentUser;
//     if (user == null) return _noUpcomingCard();

//     final query = FirebaseFirestore.instance
//         .collection('appointments')
//         .where('userId', isEqualTo: user.uid)
//         .where(
//           'status',
//           whereIn: ['pending', 'confirmed'], // ✅ FIX
//         )
//         .orderBy('createdAt', descending: true)
//         .limit(1);

//     return StreamBuilder<QuerySnapshot>(
//       stream: query.snapshots(),
//       builder: (context, snapshot) {
//         Widget child = const SizedBox.shrink();

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           child = const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16),
//             child: Center(
//               child: CircularProgressIndicator(color: Colors.teal),
//             ),
//           );
//         } else if (snapshot.hasError) {
//           child:
//           Text(
//             'appointments_error_loading'
//                 .tr(namedArgs: {'error': snapshot.error.toString()}),
//             style: const TextStyle(color: Colors.red),
//           );
//         } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           child = _noUpcomingCard(innerOnly: true);
//         } else {
//           final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

//           DateTime appointmentDate = DateTime.now();
//           final raw = data['date'];
//           if (raw is Timestamp) {
//             appointmentDate = raw.toDate();
//           } else if (raw is String) {
//             appointmentDate = DateTime.tryParse(raw) ?? DateTime.now();
//           }

//           final doctorName = data['doctorName'] ?? 'Doctor';
//           final specialty =
//               data['doctorType'] ?? data['specialty'] ?? 'Specialty';
//           final clinic = data['clinicName'] ?? 'Clinic';
//           final slotTime = data['slotTime'] ?? '';
//           final status = (data['status'] ?? 'pending').toString();

//           child = Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(14),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   _dateBadgeCustom(appointmentDate),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'upcoming_visit'.tr(),
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text('$doctorName · $specialty'),
//                         const SizedBox(height: 4),
//                         Text('$clinic • $slotTime'),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Status: ${_prettyStatus(status)}',
//                           style: TextStyle(
//                             color: status == 'pending'
//                                 ? Colors.orange
//                                 : Colors.teal,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         SizedBox(
//                           height: 36,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 PageTransition(
//                                   type: PageTransitionType.rightToLeft,
//                                   child: const MyAppointmentsPage(),
//                                 ),
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF4A90E2),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: Text(
//                               'view_details'.tr(),
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return AnimatedSwitcher(
//           duration: const Duration(milliseconds: 300),
//           transitionBuilder: (child, anim) => SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, .06),
//               end: Offset.zero,
//             ).animate(anim),
//             child: FadeTransition(opacity: anim, child: child),
//           ),
//           child: child,
//         );
//       },
//     );
//   }

//   // Guest banner
//   Widget _guestBanner(BuildContext context) => Container(
//         margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: const Color(0xFFFFF6D6),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFFFE8A3)),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.info_outline, color: Colors.black54),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'guest_browsing_notice'.tr(),
//                 style: const TextStyle(color: Colors.black87),
//               ),
//             ),
//             TextButton(
//               onPressed: () => Navigator.push(
//                 context,
//                 PageTransition(
//                   type: PageTransitionType.rightToLeft,
//                   child: const LoginScreen(),
//                 ),
//               ),
//               child: Text('login'.tr()),
//             ),
//           ],
//         ),
//       );

//   // Date badge
//   Widget _dateBadgeCustom(DateTime date) {
//     // const months = [
//     //   'JAN',
//     //   'FEB',
//     //   'MAR',
//     //   'APR',
//     //   'MAY',
//     //   'JUN',
//     //   'JUL',
//     //   'AUG',
//     //   'SEP',
//     //   'OCT',
//     //   'NOV',
//     //   'DEC'
//     // ];
//     // const dows = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

//     final lang = context.locale.languageCode;
//     final intlLocale = lang == 'ku' ? 'ar' : lang;

//     final month = DateFormat('MMM', intlLocale).format(date);
//     final day = DateFormat('dd', intlLocale).format(date);
//     final dow = DateFormat('EEE', intlLocale).format(date);

//     // final month = months[date.month - 1];
//     // final day = date.day.toString().padLeft(2, '0');
//     // final dow = dows[date.weekday - 1];

//     return Container(
//       width: 64,
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFF4A90E2),
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(month,
//               style: const TextStyle(
//                   color: Colors.white, fontWeight: FontWeight.w600)),
//           const SizedBox(height: 2),
//           Text(day,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 18)),
//           const SizedBox(height: 2),
//           Text(dow,
//               style: const TextStyle(
//                   color: Colors.white70, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
// }

// // Curved gradient header (teal → blue)
// class _CurvedGradientHeader extends StatelessWidget {
//   final Widget child;
//   final double height;
//   const _CurvedGradientHeader(
//       {required this.child, this.height = 180, Key? key})
//       : super(key: key);

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

// // Language selector (unchanged)
// class _LanguageSelector extends StatelessWidget {
//   const _LanguageSelector();

//   @override
//   Widget build(BuildContext context) {
//     final current = context.locale.languageCode;
//     return PopupMenuButton<Locale>(
//       icon: const Icon(Icons.language, color: Colors.black),
//       onSelected: (l) => context.setLocale(l),
//       itemBuilder: (_) => [
//         CheckedPopupMenuItem(
//             checked: current == 'en',
//             value: const Locale('en'),
//             child: const Text('English')),
//         CheckedPopupMenuItem(
//             checked: current == 'ar',
//             value: const Locale('ar'),
//             child: const Text('العربية')),
//         CheckedPopupMenuItem(
//             checked: current == 'ku',
//             value: const Locale('ku', 'IQ'),
//             child: const Text('کوردی')),
//       ],
//     );
//   }
// }

import 'package:flutter/foundation.dart';
import 'package:trustydr/pages/CentersPage.dart';
import 'package:trustydr/widget/trustydr_info_cards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustydr/core/providers/app_location_provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trustydr/constant/constant.dart';
import 'package:trustydr/pages/screens.dart' hide blackColor;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustydr/widgets/pwa_install_banner.dart';
import 'package:trustydr/widgets/web_scaffold_container.dart';
import 'package:trustydr/widgets/center_action_grid.dart';
import 'package:trustydr/widgets/health_awareness_card.dart';
import 'package:trustydr/widgets/daily_health_weather_card.dart';
import 'package:trustydr/widgets/announcements_strip.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';
import 'package:flutter/services.dart';
import 'package:trustydr/core/providers/notifications_provider.dart';
import 'package:trustydr/core/providers/patient_appointments_provider.dart';
import 'package:trustydr/models/patient_appointment_item.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home>
    with SingleTickerProviderStateMixin {
  late FirebaseFirestore _db;
  late FirebaseAuth _auth;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _provinceDocs = [];
  String? _selectedProvinceKey;
  String? _selectedCityEn;

  String? _displayName;

  bool _isGuest = true;
  User? _currentUser;

  late final AnimationController _tilesCtrl;

  @override
  void initState() {
    super.initState();
    _tilesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tilesCtrl.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _tilesCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _db = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;

    _currentUser = _auth.currentUser;
    _isGuest = _currentUser == null;

    // ✅ Keep your existing user name logic
    await _loadUserName();

    // ✅ Cities first (needed for display)
    await _loadCities();

    // ✅ Load saved location from SharedPreferences
    await _loadSavedLocation();

    // ✅ Inject into provider if valid saved location exists
    final hasSavedLocation = _selectedProvinceKey != null &&
        _selectedProvinceKey!.isNotEmpty &&
        _selectedCityEn != null &&
        _selectedCityEn!.isNotEmpty;

    if (hasSavedLocation) {
      ref.read(appLocationProvider.notifier).setLocation(
            provinceKey: _selectedProvinceKey!,
            cityEn: _selectedCityEn!,
          );
    }

    // ✅ First launch behavior: force selector only if no saved location
    if (!hasSavedLocation && mounted) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _openLocationSelector();
      });
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserName() async {
    if (_currentUser == null) return;

    try {
      final doc = await _db.collection('users').doc(_currentUser!.uid).get();

      if (!doc.exists) return;

      final data = doc.data();

      String? name = (data?['name'] ?? data?['fullName'])?.toString();

      if (name != null && name.isNotEmpty) {
        name = name.split(' ').first;
      }

      if (!mounted) return;

      setState(() {
        _displayName = name;
      });
    } catch (_) {}
  }

  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return 'greeting_morning'.tr();
    if (h < 17) return 'greeting_afternoon'.tr();
    return 'greeting_evening'.tr();
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>>? _cachedCities;

  Future<void> _loadCities() async {
    if (_cachedCities != null) {
      _provinceDocs = _cachedCities!;
      return;
    }
    try {
      final snap = await _db.collection('cities').get();
      _provinceDocs = snap.docs;
      _cachedCities = snap.docs;
    } catch (_) {
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();

    final p = prefs.getString('selectedProvinceKey');
    final c = prefs.getString('selectedCityEn');

    if (!mounted) return;

    setState(() {
      _selectedProvinceKey = (p != null && p.isNotEmpty) ? p : null;
      _selectedCityEn = (c != null && c.isNotEmpty) ? c : null;
    });
  }

  Future<void> _saveLocation(String? provinceKey, String? cityEn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedProvinceKey', provinceKey ?? '');
    await prefs.setString('selectedCityEn', cityEn ?? '');
  }

  String _displaySelectedCity() {
    if (_selectedProvinceKey == null || _selectedCityEn == null) return '';
    if (_provinceDocs.isEmpty) return _selectedCityEn!;
    final matches = _provinceDocs
        .where((d) => d.data()['province_key'] == _selectedProvinceKey);
    if (matches.isEmpty) return _selectedCityEn!;
    final prov = matches.first;
    final subs = (prov.data()['subCities'] as List?) ?? [];
    final lang = context.locale.languageCode;
    for (final raw in subs) {
      final c = Map<String, dynamic>.from(raw as Map);
      if ((c['en'] ?? '').toString() == _selectedCityEn) {
        return (c[lang] ?? c['en']).toString();
      }
    }
    return _selectedCityEn!;
  }

  String _displayProvince(Map<String, dynamic> p) {
    final lang = context.locale.languageCode;
    if (lang == 'ar') return (p['lang']?['ar'] ?? p['name_en'])!;
    if (lang == 'ku') return (p['lang']?['ku'] ?? p['name_en'])!;
    return p['name_en']!;
  }

  String _displayCity(Map<String, dynamic> c) {
    final lang = context.locale.languageCode;
    if (lang == 'ar') return (c['ar'] ?? c['en'])!;
    if (lang == 'ku') return (c['ku'] ?? c['en'])!;
    return c['en']!;
  }

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        String? tempProvince = _selectedProvinceKey;
        String? tempCityEn = _selectedCityEn;
        List<Map<String, dynamic>> citiesForProvince() {
          final matches = _provinceDocs
              .where((d) => d.data()['province_key'] == tempProvince);
          if (matches.isEmpty) return [];
          final prov = matches.first;
          final subs = (prov.data()['subCities'] as List?) ?? [];
          return subs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 20),
          child: StatefulBuilder(
            builder: (_, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text('select_location'.tr(), style: blackHeadingTextStyle),
                  const SizedBox(height: 20),
                  // PROVINCE DROPDOWN
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'province'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    value: tempProvince,
                    // Add <String> right here 👇
                    items: _provinceDocs.map((d) {
                      final p = d.data();
                      return DropdownMenuItem<String>(
                        value: p['province_key']
                            ?.toString(), // Ensure this is a string
                        child: Text(_displayProvince(p)),
                      );
                    }).toList(),
                    onChanged: (v) => setModal(() {
                      tempProvince = v;
                      tempCityEn = null;
                    }),
                  ),

                  const SizedBox(height: 12),

// CITY DROPDOWN
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'city'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    value: tempCityEn,
                    // Add <String> right here 👇
                    items: citiesForProvince().map((c) {
                      return DropdownMenuItem<String>(
                        value: c['en']?.toString(), // Ensure this is a string
                        child: Text(_displayCity(c)),
                      );
                    }).toList(),
                    onChanged: (v) => setModal(() => tempCityEn = v),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (tempProvince == null || tempCityEn == null) return;
                      Navigator.pop(context);
                      await _saveLocation(tempProvince, tempCityEn);
                      ref.read(appLocationProvider.notifier).setLocation(
                          provinceKey: tempProvince!, cityEn: tempCityEn!);
                      setState(() {
                        _selectedProvinceKey = tempProvince;
                        _selectedCityEn = tempCityEn;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: PatientAppColors.brandIndigo,
                        minimumSize: const Size.fromHeight(44)),
                    child: Text('confirm'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Play alert sound + haptic when a new unread notification arrives
    // while the home screen is in the foreground.
    ref.listen<int>(unreadNotificationCountProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.lightImpact();
      }
    });

    final provinceName = (_selectedProvinceKey == null || _provinceDocs.isEmpty)
        ? ''
        : (() {
            final matches = _provinceDocs
                .where((d) => d.data()['province_key'] == _selectedProvinceKey);
            if (matches.isEmpty) return '';
            return _displayProvince(matches.first.data());
          })();

    return Scaffold(
      backgroundColor: PatientAppColors.appBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: PatientAppColors.brandBlueAlt, // Seamless with header
        iconTheme: const IconThemeData(color: Colors.white),
        title: InkWell(
          onTap: _openLocationSelector,
          child: Row(children: [
            const Icon(Icons.location_on, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              (_selectedProvinceKey != null && _selectedCityEn != null)
                  ? '${_displaySelectedCity()}, $provinceName'
                  : 'select_city'.tr(),
              style: appBarLocationTextStyle.copyWith(color: Colors.white),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ]),
        ),
        actions: const [_NotificationBell(), _LanguageSelector()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget page = ListView(
            padding: EdgeInsets.zero,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: PatientAppColors.brandGradient,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_displayName == null || _displayName!.isEmpty)
                                ? _greetingText()
                                : '${_greetingText()}, $_displayName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedCityEn != null &&
                              _selectedCityEn!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: Color(0xCCFFFFFF)),
                                const SizedBox(width: 3),
                                Text(
                                  _displaySelectedCity(),
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          _searchBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isGuest) _guestBanner(context),
              const SizedBox(height: 8),
              CenterActionGrid(
                items: [
                  ActionItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'my_appointments'.tr(),
                    onTap: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const MyAppointmentsPage(showBack: true))),
                  ),
                  ActionItem(
                    icon: Icons.people_outline,
                    label: 'my_doctors'.tr(),
                    onTap: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const MyDoctorsPage())),
                  ),
                  ActionItem(
                    icon: Icons.local_hospital,
                    label: 'medical_centers'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: const CentersScreen(),
                      ),
                    ),
                  ),
                  ActionItem(
                    icon: Icons.category_outlined,
                    label: 'specialties'.tr(),
                    onTap: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const SpecialityScreen())),
                  ),
                  ActionItem(
                    icon: Icons.biotech_outlined,
                    label: 'labs'.tr(),
                    onTap: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const LaboratoriesScreen())),
                  ),
                  ActionItem(
                    icon: Icons.local_pharmacy_outlined,
                    label: 'pharmacies'.tr(),
                    onTap: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const PharmaciesScreen())),
                  ),
                  ActionItem(
                    icon: Icons.science_outlined,
                    label: 'my_results'.tr(),
                    onTap: () => Navigator.push(
                        context,
                        PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const MyResultsPage())),
                  ),
                  ActionItem(
                    icon: Icons.medication_outlined,
                    label: 'my_prescriptions'.tr(),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('my_prescriptions_coming_soon'.tr())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _nextAppointmentCard(),
              const SizedBox(height: 16),
              const AnnouncementsStrip(),
              const HealthAwarenessCard(),
              const SizedBox(height: 16),
              DailyHealthWeatherCard(
                provinceKey: _selectedProvinceKey,
                onSetLocation: _openLocationSelector,
              ),
              const SizedBox(height: 16),
              const TrustyDrInfoCards(),
              const SizedBox(height: 16),
              if (kIsWeb) const TrustyInstallBanner(),
              const SizedBox(height: 80),
            ],
          );

          if (constraints.maxWidth >= 768) {
            page = WebScaffoldContainer(child: page);
          }

          return page;
        },
      ),
    );
  }

  Widget _searchBar() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.scale,
          alignment: Alignment.bottomCenter,
          child: Search(city: _selectedCityEn ?? ''),
        ),
      ),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
                child: Text('search_doctor_or_clinic'.tr(),
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 14))),
          ],
        ),
      ),
    );
  }

  String localizedField(
    Map<String, dynamic> data,
    String base,
    BuildContext context,
  ) {
    final lang = context.locale.languageCode;

    final localized = data['${base}_$lang'];
    if (localized != null && localized.toString().isNotEmpty) {
      return localized.toString();
    }

    final en = data['${base}_en'];
    if (en != null && en.toString().isNotEmpty) {
      return en.toString();
    }

    return (data[base] ?? '').toString();
  }

  Widget _nextAppointmentCard() {
    if (_currentUser == null) return _noUpcomingCard();

    final allAsync = ref.watch(patientAllAppointmentsProvider);

    return allAsync.when(
      loading: () => _noUpcomingCard(innerOnly: true),
      error: (_, __) => _noUpcomingCard(innerOnly: true),
      data: (items) {
        final upcoming = items.where((i) => i.isUpcoming).toList();
        if (upcoming.isEmpty) return _noUpcomingCard(innerOnly: true);

        final item = upcoming.first;
        final lang = context.locale.languageCode;
        final intlLocale = lang == 'ku' ? 'ar' : lang;
        final monthLabel = DateFormat('MMM', intlLocale)
            .format(item.appointmentDateTime)
            .toUpperCase();
        final weekdayLabel =
            DateFormat('EEE', intlLocale).format(item.appointmentDateTime);
        final isDoctor = item.type == PatientAppointmentType.doctor;
        final itemColor = item.statusColor();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
              boxShadow: PatientAppColors.shadowCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date rail + content row
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date rail
                        Container(
                          width: 70,
                          color: PatientAppColors.appBackground,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                monthLabel,
                                style: const TextStyle(
                                  color: PatientAppColors.brandTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                item.appointmentDateTime.day.toString(),
                                style: const TextStyle(
                                  color: PatientAppColors.darkNavy,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                weekdayLabel,
                                style: const TextStyle(
                                  color: PatientAppColors.brandTeal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFEEEEEE)),
                        // Main content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (!isDoctor) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (item.type ==
                                                      PatientAppointmentType
                                                          .imaging
                                                  ? const Color(0xFF7C3AED)
                                                  : PatientAppColors.brandTeal)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.type ==
                                                  PatientAppointmentType.imaging
                                              ? 'Imaging'
                                              : 'Lab',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: item.type ==
                                                    PatientAppointmentType
                                                        .imaging
                                                ? const Color(0xFF7C3AED)
                                                : PatientAppColors.brandTeal,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        isDoctor
                                            ? 'doctor_prefix_name'.tr(
                                                args: [item.providerName(lang)])
                                            : item.providerName(lang),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: PatientAppColors.darkNavy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isDoctor
                                          ? Icons.medical_services_outlined
                                          : Icons.science_outlined,
                                      size: 13,
                                      color: Colors.black45,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        item.serviceLabel(lang),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.locationLabel(lang) != null) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.business_outlined,
                                        size: 13,
                                        color: Colors.black45,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          item.locationLabel(lang)!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0x73000000),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer: status + CTA
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'status.${item.statusKey()}'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: itemColor,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.rightToLeft,
                              child: const MyAppointmentsPage(showBack: true),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PatientAppColors.brandBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'view_details'.tr(),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _noUpcomingCard({bool innerOnly = false}) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PatientAppColors.radiusCard),
        boxShadow: PatientAppColors.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0x1A5CC6BA), // brandTeal ~10%
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: PatientAppColors.brandTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'home.noUpcomingVisits'.tr(),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
    return innerOnly
        ? card
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), child: card);
  }

  Widget _guestBanner(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: PatientAppColors.guestBannerBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PatientAppColors.guestBannerBorder)),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'guest_browsing_notice'.tr(),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.push(
                context,
                PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const LoginScreen())),
            child: Text(
              'login'.tr(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      );
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();
  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode;
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language,
          color: Colors.white), // Changed to white to match new blue AppBar
      onSelected: (l) => context.setLocale(l),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
            checked: current == 'en',
            value: const Locale('en'),
            child: const Text('English')),
        CheckedPopupMenuItem(
            checked: current == 'ar',
            value: const Locale('ar'),
            child: const Text('العربية')),
        CheckedPopupMenuItem(
            checked: current == 'ku',
            value: const Locale('ku', 'IQ'),
            child: const Text('کوردی')),
      ],
    );
  }
}

// Bell icon with unread-count badge in the home AppBar.
// Navigates to the Notifications page on tap.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      tooltip: 'home.notifications_title'.tr(),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeft,
          child: const Notifications(),
        ),
      ),
    );
  }
}
