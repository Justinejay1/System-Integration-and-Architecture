// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyA3VSUX7MeI1EzRsK4p9l1fJ_FCU89wtYA',
    appId: '1:187522698641:web:bb7cf189b6480477641e30',
    messagingSenderId: '187522698641',
    projectId: 'lodgepilot-97d8f',
    authDomain: 'lodgepilot-97d8f.firebaseapp.com',
    storageBucket: 'lodgepilot-97d8f.appspot.com',
    measurementId: 'G-3PHW059Z49',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4VBu6aV9hSDx2rUk-DmO5i7tCl-bh7sM',
    appId: '1:187522698641:android:91dd1061b841dfdb641e30',
    messagingSenderId: '187522698641',
    projectId: 'lodgepilot-97d8f',
    storageBucket: 'lodgepilot-97d8f.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIFsJ5pzmoDf0tENVPcvBKVYIN4WiFxBY',
    appId: '1:187522698641:ios:ef924db559769d93641e30',
    messagingSenderId: '187522698641',
    projectId: 'lodgepilot-97d8f',
    storageBucket: 'lodgepilot-97d8f.appspot.com',
    iosBundleId: 'com.example.airbnbScheduler',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDIFsJ5pzmoDf0tENVPcvBKVYIN4WiFxBY',
    appId: '1:187522698641:ios:88555dfb75b97d7a641e30',
    messagingSenderId: '187522698641',
    projectId: 'lodgepilot-97d8f',
    storageBucket: 'lodgepilot-97d8f.appspot.com',
    iosBundleId: 'com.example.airbnbScheduler.RunnerTests',
  );
}