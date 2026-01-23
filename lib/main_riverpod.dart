// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:easy_localization/easy_localization.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'firebase_options.dart';
// // import 'pages/splashScreen.dart';

// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await EasyLocalization.ensureInitialized();
// //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// //   runApp(
// //     ProviderScope(
// //       child: EasyLocalization(
// //         supportedLocales: const [Locale('en'), Locale('ar'), Locale('ku')],
// //         path: 'lib/l10n',
// //         fallbackLocale: const Locale('en'),
// //         child: const MyApp(),
// //       ),
// //     ),
// //   );
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       localizationsDelegates: context.localizationDelegates,
// //       supportedLocales: context.supportedLocales,
// //       locale: context.locale,
// //       theme: ThemeData(
// //         primarySwatch: Colors.teal,
// //         scaffoldBackgroundColor: Colors.white,
// //         visualDensity: VisualDensity.adaptivePlatformDensity,
// //       ),
// //       home: const SplashScreen(),
// //     );
// //   }
// // }

// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_core/firebase_core.dart';

// import 'firebase_options.dart';
// import 'pages/splashScreen.dart';

// // ✅ ADD THESE
// import 'utils/fallback_localizations.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   runApp(
//     ProviderScope(
//       child: EasyLocalization(
//         supportedLocales: const [
//           Locale('ar'), // ✅ Arabic first
//           Locale('ku', 'IQ'), // ✅ Kurdish (Iraq) — IMPORTANT
//           Locale('en'),
//         ],
//         path: 'lib/l10n',
//         fallbackLocale: const Locale('ar'),
//         startLocale: const Locale('ar'),
//         saveLocale: true,
//         child: const MyApp(),
//       ),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final locale = context.locale;

//     // ✅ SAME LOGIC AS DOCTOR APP
//     final ui.TextDirection direction =
//         (locale.languageCode == 'ar' || locale.languageCode == 'ku')
//             ? ui.TextDirection.rtl
//             : ui.TextDirection.ltr;

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,

//       locale: context.locale,
//       supportedLocales: context.supportedLocales,

//       // 🔥🔥🔥 THIS FIXES THE CRASH
//       localizationsDelegates: [
//         ...context.localizationDelegates,
//         const FallbackMaterialLocalizationsDelegate(),
//         const FallbackCupertinoLocalizationsDelegate(),
//       ],

//       builder: (context, child) {
//         return Directionality(
//           textDirection: direction,
//           child: child!,
//         );
//       },

//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: Colors.white,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),

//       home: const SplashScreen(),
//     );
//   }
// }
