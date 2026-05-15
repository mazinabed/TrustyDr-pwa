import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyBhbQAQZboBJd90lSqJNZuBOVcEOGJ3E',
    appId: '1:423685278731:web:767c5e00bb075e532e8b0e',
    messagingSenderId: '423685278731',
    projectId: 'doctorapp-7e8b3',
    authDomain: 'doctorapp-7e8b3.firebaseapp.com',
    storageBucket: 'doctorapp-7e8b3.firebasestorage.app',
    measurementId: 'G-2LYMM056XZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyQqsOQNHRdQASw2zYC-8uGx2jLpFkbdw',
    appId: '1:423685278731:android:990247b984742c982e8b0e',
    messagingSenderId: '423685278731',
    projectId: 'doctorapp-7e8b3',
    storageBucket: 'doctorapp-7e8b3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC66TrtGIhQz529lyN9cWN5f-AUd7uvu6M',
    appId: '1:423685278731:ios:5b69c9a4a5adb0552e8b0e',
    messagingSenderId: '423685278731',
    projectId: 'doctorapp-7e8b3',
    storageBucket: 'doctorapp-7e8b3.firebasestorage.app',
    androidClientId:
        '423685278731-qjq4g1bqgkb5trb6i19ld06d9l10o9g7.apps.googleusercontent.com',
    iosClientId:
        '423685278731-vcat1s4k2a1o5sjq5o8r4ukev8d90s9f.apps.googleusercontent.com',
    iosBundleId: 'com.trustydr.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC66TrtGIhQz529lyN9cWN5f-AUd7uvu6M',
    appId: '1:423685278731:ios:85917477f8b8c7492e8b0e',
    messagingSenderId: '423685278731',
    projectId: 'doctorapp-7e8b3',
    storageBucket: 'doctorapp-7e8b3.firebasestorage.app',
    androidClientId:
        '423685278731-qjq4g1bqgkb5trb6i19ld06d9l10o9g7.apps.googleusercontent.com',
    iosClientId:
        '423685278731-c0itpa3ei1udv4qe8iprr281v0qj6af6.apps.googleusercontent.com',
    iosBundleId: 'com.example.doctorAppV2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAyBhbQAQZboBJd90lSqJNZuBOVcEOGJ3E',
    appId: '1:423685278731:web:ccd90c33645310812e8b0e',
    messagingSenderId: '423685278731',
    projectId: 'doctorapp-7e8b3',
    authDomain: 'doctorapp-7e8b3.firebaseapp.com',
    storageBucket: 'doctorapp-7e8b3.firebasestorage.app',
    measurementId: 'G-NS7G29X0GS',
  );
}
