// Demo entry point — connects to trustydr-demo Firebase project.
// Run: flutter run -d chrome --target lib/main_demo.dart
// Build: flutter build web --target lib/main_demo.dart
//
// Identical to main.dart except Firebase config:
//   production → DefaultFirebaseOptions    (firebase_options.dart,      doctorapp-7e8b3)
//   demo       → DefaultFirebaseDemoOptions (firebase_options_demo.dart, trustydr-demo)
//
// DO NOT import this file from production code paths.

import 'dart:ui' as ui;

import 'package:trustydr/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/services.dart';

import 'firebase_options_demo.dart';
import 'pages/splashScreen.dart';
import 'utils/fallback_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseDemoOptions.currentPlatform,
  );

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
      home: const SplashScreen(),
    );
  }
}
