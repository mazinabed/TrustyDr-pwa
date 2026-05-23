// Demo Firebase configuration — trustydr-demo project.
// Used by main_demo.dart for demo builds only.
// DO NOT import this file from main.dart or any production code path.
//
// Production config: lib/firebase_options.dart (doctorapp-7e8b3)
// Demo config:       lib/firebase_options_demo.dart (trustydr-demo)  ← this file
//
// App registered: "TrustyDr Patient (Demo)"
// appId (web):    1:995834780496:web:ebb7ff5bd6212ea3abaa55

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseDemoOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseDemoOptions: Android is not configured for the demo build. '
          'Demo builds target web only.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseDemoOptions: iOS is not configured for the demo build. '
          'Demo builds target web only.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseDemoOptions: macOS is not configured for the demo build. '
          'Demo builds target web only.',
        );
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseDemoOptions: Linux is not configured for the demo build.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseDemoOptions: Unknown platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBV08iwa6I3QPFNfyBtmRzP_tAaCxD-Rc0',
    appId: '1:995834780496:web:ebb7ff5bd6212ea3abaa55',
    messagingSenderId: '995834780496',
    projectId: 'trustydr-demo',
    authDomain: 'trustydr-demo.firebaseapp.com',
    storageBucket: 'trustydr-demo.firebasestorage.app',
  );
}
