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
    apiKey: 'AIzaSyBbKfchN7LX1pIMX1glJBEYRy-GFxm13SY',
    appId: '1:559384641747:web:bf9a6e03f3d19f172bd426',
    messagingSenderId: '559384641747',
    projectId: 'comma-9018a',
    authDomain: 'comma-9018a.firebaseapp.com',
    storageBucket: 'comma-9018a.appspot.com',
    measurementId: 'G-ZSXQMZMB7G',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJKoJP8f0BWFQ9zoVfCic_tchszB6Y_B4',
    appId: '1:559384641747:android:bae996c6904e595c2bd426',
    messagingSenderId: '559384641747',
    projectId: 'comma-9018a',
    storageBucket: 'comma-9018a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAgtrmJBoFKv3iizES4cgCEPc-06OTjqr4',
    appId: '1:559384641747:ios:3d60218fdca995c12bd426',
    messagingSenderId: '559384641747',
    projectId: 'comma-9018a',
    storageBucket: 'comma-9018a.appspot.com',
    iosBundleId: 'com.example.flutterPlugin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAgtrmJBoFKv3iizES4cgCEPc-06OTjqr4',
    appId: '1:559384641747:ios:3d60218fdca995c12bd426',
    messagingSenderId: '559384641747',
    projectId: 'comma-9018a',
    storageBucket: 'comma-9018a.appspot.com',
    iosBundleId: 'com.example.flutterPlugin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBbKfchN7LX1pIMX1glJBEYRy-GFxm13SY',
    appId: '1:559384641747:web:1f3d31a459e60b442bd426',
    messagingSenderId: '559384641747',
    projectId: 'comma-9018a',
    authDomain: 'comma-9018a.firebaseapp.com',
    storageBucket: 'comma-9018a.appspot.com',
    measurementId: 'G-V1TB27TRYM',
  );
}
