// // import 'package:flutter/material.dart';
// // import 'package:easy_localization/easy_localization.dart';
// // import 'package:trustydr/services/database_service.dart';
// // import 'package:trustydr/pages/screens.dart' show SplashScreen;

// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await EasyLocalization.ensureInitialized();

// //   await DatabaseService.instance.initialize();

// //   runApp(
// //     EasyLocalization(
// //       supportedLocales: const [
// //         Locale('en'),
// //         Locale('ar'),
// //         Locale('ku', 'IQ'),
// //       ],
// //       path: 'lib/l10n',
// //       fallbackLocale: const Locale('en'),
// //       child: const MyApp(),
// //     ),
// //   );
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Doctor App',
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
// // // }

// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';

// import 'firebase_options.dart';
// import 'pages/splashScreen.dart';
// import 'utils/fallback_localizations.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // ✅ FIX ANDROID NAV BAR / STATUS BAR
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,

//       systemNavigationBarColor: Colors.white, // 👈 THIS FIXES THE "SHORT" BAR
//       systemNavigationBarIconBrightness: Brightness.dark,
//     ),
//   );
//   SystemChrome.setEnabledSystemUIMode(
//     SystemUiMode.manual,
//     overlays: SystemUiOverlay.values, // 👈 disables edge-to-edge
//   );

//   runApp(
//     ProviderScope(
//       child: EasyLocalization(
//         supportedLocales: const [
//           Locale('ar'),
//           Locale('ku', 'IQ'),
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

//     final ui.TextDirection direction =
//         (locale.languageCode == 'ar' || locale.languageCode == 'ku')
//             ? ui.TextDirection.rtl
//             : ui.TextDirection.ltr;

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       locale: context.locale,
//       supportedLocales: context.supportedLocales,
//       localizationsDelegates: [
//         ...context.localizationDelegates,
//         const FallbackMaterialLocalizationsDelegate(),
//         const FallbackCupertinoLocalizationsDelegate(),
//       ],
//       builder: (context, child) {
//         return Directionality(
//           textDirection: direction,
//           child: SafeArea(
//             top: false, // AppBar handles this
//             bottom: true, // 👈 REQUIRED for Android gesture nav
//             child: child!,
//           ),
//         );
//       },
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }

// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/date_symbol_data_local.dart';

// import 'firebase_options.dart';
// import 'pages/splashScreen.dart';
// import 'utils/fallback_localizations.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EasyLocalization.ensureInitialized();
//   await initializeDateFormatting();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   FlutterError.onError = (FlutterErrorDetails details) {
//     FlutterError.dumpErrorToConsole(details);
//   };

//   // ✅ Disable edge-to-edge + force white nav bar (gesture-safe)
//   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,

//       // ✅ MUST be transparent when using extendBody + gradient bottom bar
//       systemNavigationBarColor: Colors.transparent,
//       systemNavigationBarIconBrightness: Brightness.light,

//       // ✅ Prevent Android scrim
//       systemNavigationBarDividerColor: Colors.transparent,
//       systemNavigationBarContrastEnforced: false,
//     ),
//   );

//   runApp(
//     ProviderScope(
//       child: EasyLocalization(
//         supportedLocales: const [
//           Locale('ar'),
//           Locale('ku', 'IQ'),
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

//     final ui.TextDirection direction =
//         (locale.languageCode == 'ar' || locale.languageCode == 'ku')
//             ? ui.TextDirection.rtl
//             : ui.TextDirection.ltr;

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       locale: context.locale,
//       supportedLocales: context.supportedLocales,
//       localizationsDelegates: [
//         ...context.localizationDelegates,
//         const FallbackMaterialLocalizationsDelegate(),
//         const FallbackCupertinoLocalizationsDelegate(),
//       ],
//       builder: (context, child) {
//         // ✅ ONLY Directionality here — NO SafeArea globally
//         return Directionality(
//           textDirection: direction,
//           child: child!,
//         );
//       },
//       theme: ThemeData(
//         fontFamily: 'IBMPlexArabic', // ✅ THIS IS THE FIX
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }

import 'dart:ui' as ui;

import 'package:trustydr/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_options.dart';
import 'pages/splashScreen.dart';
import 'services/push_notification_service.dart';
import 'utils/fallback_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Localization init is OK (lightweight)
  await EasyLocalization.ensureInitialized();

  // ✅ Firebase is the single source of truth — initialized here before runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM: listen for token refresh while the app is running.
  // Does NOT request permission — permission is prompted post-booking or via notifications banner.
  if (kIsWeb) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await PushNotificationService.instance.onTokenRefreshed(
        newToken,
        uid: user.uid,
      );
    });

    // Foreground push: the in-app Riverpod stream already updates the UI;
    // no separate foreground handler is needed.
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('ar'),
          Locale('ku', 'IQ'),
          Locale('en'),
        ],
        path: 'lib/l10n',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        saveLocale: true,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    final ui.TextDirection direction =
        (locale.languageCode == 'ar' || locale.languageCode == 'ku')
            ? ui.TextDirection.rtl
            : ui.TextDirection.ltr;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: [
        ...context.localizationDelegates,
        const FallbackMaterialLocalizationsDelegate(),
        const FallbackCupertinoLocalizationsDelegate(),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: direction,
          child: child!,
        );
      },
      theme: ThemeData(
        fontFamily: 'Cairo',
        primarySwatch: Colors.teal,

        // 🌿 Global background
        scaffoldBackgroundColor: AppColors.appBackground,

        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.65,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.65,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: const SplashScreen(),
    );
  }
}
