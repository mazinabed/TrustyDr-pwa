// import 'package:trustydr/pages/speciality/speciality.dart'
//     show SpecialityScreen;
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:trustydr/pages/home/home.dart';
// import 'package:trustydr/pages/patient/my_appointments_page.dart';
// import 'package:trustydr/pages/profile/profile.dart';

// class MainLayout extends StatefulWidget {
//   const MainLayout({super.key});

//   @override
//   State<MainLayout> createState() => _MainLayoutState();
// }

// class _MainLayoutState extends State<MainLayout> {
//   int _currentIndex = 0;
//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();
//     _pages = const [
//       Home(),
//       SpecialityScreen(
//         provinceKey: null,
//         cityEn: '',
//       ),
//       MyAppointmentsPage(),
//       Profile(),
//     ];
//   }

//   void _onItemTapped(int index) {
//     if (index == _currentIndex) return;
//     setState(() => _currentIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true, // ✅ REQUIRED
//       backgroundColor: Colors.transparent, // ✅ REQUIRED
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: _pages[_currentIndex],
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           gradient: const LinearGradient(
//             colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.15),
//               blurRadius: 12,
//               offset: const Offset(0, -3),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           top: false,
//           child: BottomNavigationBar(
//             type: BottomNavigationBarType.fixed,
//             currentIndex: _currentIndex,
//             onTap: _onItemTapped,
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             selectedItemColor: Colors.white,
//             unselectedItemColor: Colors.white70,
//             showUnselectedLabels: true,
//             selectedLabelStyle: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//             unselectedLabelStyle: const TextStyle(fontSize: 12),
//             items: [
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.home_outlined),
//                 activeIcon: Icon(Icons.home),
//                 label: tr('nav_home'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.local_hospital_outlined),
//                 activeIcon: Icon(Icons.local_hospital),
//                 label: tr('nav_doctors'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.calendar_today_outlined),
//                 activeIcon: Icon(Icons.calendar_today),
//                 label: tr('nav_appointments'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person_outline),
//                 activeIcon: Icon(Icons.person),
//                 label: tr('nav_profile'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
