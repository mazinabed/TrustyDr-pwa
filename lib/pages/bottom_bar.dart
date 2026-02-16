// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';

// import 'package:trustydr/pages/screens.dart'
//     show Home, SpecialityScreen, MyAppointmentsPage, Profile;

// class BottomBar extends StatefulWidget {
//   const BottomBar({super.key});

//   @override
//   State<BottomBar> createState() => _BottomBarState();
// }

// class _BottomBarState extends State<BottomBar> {
//   int _selectedIndex = 0;

//   // ✅ Pages stay alive (NO rebuild / NO flicker)
//   final List<Widget> _pages = [
//     Home(),
//     SpecialityScreen(
//       provinceKey: null,
//       cityEn: null,
//       showBack: false, // 🚫 tab root → no back arrow
//     ),
//     MyAppointmentsPage(
//       showBack: false, // 🚫 tab root → no back arrow
//     ),
//     Profile(),
//   ];

//   @override
//   // Widget build(BuildContext context) {
//   //   return Scaffold(
//   //     extendBody: true,
//   //     backgroundColor: const Color(0xFFF2F5F9),

//   //     // 🔥 THE FIX
//   //     body: IndexedStack(
//   //       index: _selectedIndex,
//   //       children: _pages,
//   //     ),

//   //     bottomNavigationBar: Container(
//   //       decoration: const BoxDecoration(
//   //         color: Colors.white,
//   //         boxShadow: [
//   //           BoxShadow(
//   //             color: Colors.black12,
//   //             blurRadius: 10,
//   //             offset: Offset(0, -2),
//   //           ),
//   //         ],
//   //       ),
//   //       child: SafeArea(
//   //         top: false,
//   //         child: BottomNavigationBar(
//   //           backgroundColor: Colors.white,
//   //           elevation: 0,
//   //           type: BottomNavigationBarType.fixed,
//   //           currentIndex: _selectedIndex,
//   //           onTap: (index) => setState(() => _selectedIndex = index),
//   //           iconSize: 26,
//   //           selectedItemColor: const Color(0xFF2563EB),
//   //           unselectedItemColor: const Color(0xFF6B7280),
//   //           selectedLabelStyle: const TextStyle(
//   //             fontSize: 12,
//   //             fontWeight: FontWeight.w600,
//   //           ),
//   //           unselectedLabelStyle: const TextStyle(
//   //             fontSize: 12,
//   //             fontWeight: FontWeight.w500,
//   //           ),
//   //           showUnselectedLabels: true,
//   //           items: [
//   //             BottomNavigationBarItem(
//   //               icon: Icon(Icons.home_rounded),
//   //               label: tr('nav_home'),
//   //             ),
//   //             BottomNavigationBarItem(
//   //               icon: Icon(Icons.local_hospital_rounded),
//   //               label: tr('nav_doctors'),
//   //             ),
//   //             BottomNavigationBarItem(
//   //               icon: Icon(Icons.calendar_today_rounded),
//   //               label: tr('nav_appointments'),
//   //             ),
//   //             BottomNavigationBarItem(
//   //               icon: Icon(Icons.person_rounded),
//   //               label: tr('nav_profile'),
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     // 🔥 Pages are built HERE so locale changes are respected
//     final pages = [
//       const Home(),
//       SpecialityScreen(
//         provinceKey: null,
//         cityEn: null,
//         showBack: false, // tab root → no back arrow
//       ),
//       const MyAppointmentsPage(
//         showBack: false, // tab root → no back arrow
//       ),
//       Profile(
//         key: ValueKey(
//             context.locale.languageCode), // 🔥 FIX: rebuild on language change
//       ),
//     ];

//     return Scaffold(
//       extendBody: true,
//       backgroundColor: const Color(0xFFF2F5F9),

//       // 🔥 IndexedStack = smooth tabs, no rebuild flicker
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: pages,
//       ),

//       bottomNavigationBar: Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           top: false,
//           child: BottomNavigationBar(
//             backgroundColor: Colors.white,
//             elevation: 0,
//             type: BottomNavigationBarType.fixed,
//             currentIndex: _selectedIndex,
//             onTap: (index) => setState(() => _selectedIndex = index),
//             iconSize: 26,
//             selectedItemColor: const Color(0xFF2563EB),
//             unselectedItemColor: const Color(0xFF6B7280),
//             selectedLabelStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//             unselectedLabelStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//             showUnselectedLabels: true,
//             items: [
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.home_rounded),
//                 label: tr('nav_home'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.local_hospital_rounded),
//                 label: tr('nav_doctors'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.calendar_today_rounded),
//                 label: tr('nav_appointments'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person_rounded),
//                 label: tr('nav_profile'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// This is working version but we are improving the logout behaour.
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import 'package:trustydr/pages/screens.dart'
//     show Home, SpecialityScreen, MyAppointmentsPage, Profile;

// /// ✅ GLOBAL AUTH PROVIDER
// final authStateProvider = StreamProvider<User?>((ref) {
//   return FirebaseAuth.instance.authStateChanges();
// });

// class BottomBar extends ConsumerStatefulWidget {
//   const BottomBar({super.key});

//   @override
//   ConsumerState<BottomBar> createState() => _BottomBarState();
// }

// class _BottomBarState extends ConsumerState<BottomBar> {
//   int _selectedIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     final auth = ref.watch(authStateProvider);

//     /// 🔒 AUTH LOADING GUARD (NO FLICKER)
//     if (auth.isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final user = auth.value;

//     final pages = [
//       const Home(),
//       SpecialityScreen(
//         provinceKey: null,
//         cityEn: null,
//         showBack: false,
//       ),
//       const MyAppointmentsPage(
//         showBack: false,
//       ),
//       Profile(
//         key: ValueKey(
//           '${context.locale.languageCode}_${user == null ? 'guest' : 'user'}',
//         ),
//       ),
//     ];

//     return Scaffold(
//       extendBody: true,
//       backgroundColor: const Color(0xFFF2F5F9),

//       /// ✅ IndexedStack = NO rebuild / NO reload
//       body: IndexedStack(
//         index: _selectedIndex,
//         children: pages,
//       ),

//       bottomNavigationBar: Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SafeArea(
//           top: false,
//           child: BottomNavigationBar(
//             backgroundColor: Colors.white,
//             elevation: 0,
//             type: BottomNavigationBarType.fixed,
//             currentIndex: _selectedIndex,
//             onTap: (index) => setState(() => _selectedIndex = index),
//             iconSize: 26,
//             selectedItemColor: const Color(0xFF2563EB),
//             unselectedItemColor: const Color(0xFF6B7280),
//             selectedLabelStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//             unselectedLabelStyle: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//             showUnselectedLabels: true,
//             items: [
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.home_rounded),
//                 label: tr('nav_home'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.local_hospital_rounded),
//                 label: tr('nav_doctors'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.calendar_today_rounded),
//                 label: tr('nav_appointments'),
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person_rounded),
//                 label: tr('nav_profile'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:trustydr/pages/screens.dart'
    show Home, SpecialityScreen, MyAppointmentsPage, Profile;

/// ✅ GLOBAL AUTH PROVIDER (KEEP)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class BottomBar extends ConsumerStatefulWidget {
  const BottomBar({super.key});

  @override
  ConsumerState<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<BottomBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    // 🔥 IMPORTANT: DO NOT block UI on loading
    final user = auth.value; // may be null → OK

    final pages = [
      const Home(),

      // 🔒 GUARD: do not build SpecialityScreen without city
      const SpecialityScreen(
        showBack: false,
      ),

     MyAppointmentsPage(
  key: ValueKey(context.locale.languageCode),
  showBack: false,
),

Profile(
  key: ValueKey(
    '${context.locale.languageCode}_${user?.uid ?? 'guest'}',
  ),
),

    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF2F5F9),

      /// ✅ IndexedStack = smooth tabs, no rebuilds
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            iconSize: 26,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: const Color(0xFF6B7280),
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: tr('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_hospital_rounded),
                label: tr('nav_doctors'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_rounded),
                label: tr('nav_appointments'),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: tr('nav_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
