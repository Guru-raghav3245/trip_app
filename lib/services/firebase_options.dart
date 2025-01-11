// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBSEBMK8xKwnUxtWVoWUoP2sCZWSGbfoiE',
    appId: '1:1071563203317:web:72062941866cdbbfa11bbc',
    messagingSenderId: '1071563203317',
    projectId: 'trip-app-377ad',
    authDomain: 'trip-app-377ad.firebaseapp.com',
    storageBucket: 'trip-app-377ad.firebasestorage.app',
    measurementId: 'G-XTGWTVFCG6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCCX926LwkqcfuTTBxQvrBKBPHD-cUufEU',
    appId: '1:1071563203317:android:fc6ea7ca5b3aac41a11bbc',
    messagingSenderId: '1071563203317',
    projectId: 'trip-app-377ad',
    storageBucket: 'trip-app-377ad.firebasestorage.app',
  );
}
