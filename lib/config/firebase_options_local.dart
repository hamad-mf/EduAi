import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseOptionsLocal {
  FirebaseOptionsLocal._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _macos;
      case TargetPlatform.windows:
        return _windows;
      case TargetPlatform.linux:
        return _linux;
      default:
        return _android;
    }
  }

  // Replace these placeholders with your Firebase project values.
  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'PASTE_API_KEY',
    appId: 'PASTE_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    storageBucket: 'PASTE_BUCKET',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'PASTE_API_KEY',
    appId: 'PASTE_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    storageBucket: 'PASTE_BUCKET',
    iosBundleId: 'com.eduai.eduAi',
  );

  static const FirebaseOptions _macos = FirebaseOptions(
    apiKey: 'PASTE_API_KEY',
    appId: 'PASTE_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    storageBucket: 'PASTE_BUCKET',
    iosBundleId: 'com.eduai.eduAi',
  );

  static const FirebaseOptions _windows = FirebaseOptions(
    apiKey: 'PASTE_API_KEY',
    appId: 'PASTE_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    storageBucket: 'PASTE_BUCKET',
  );

  static const FirebaseOptions _linux = FirebaseOptions(
    apiKey: 'PASTE_API_KEY',
    appId: 'PASTE_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    storageBucket: 'PASTE_BUCKET',
  );

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'PASTE_API_KEY',
    appId: 'PASTE_APP_ID',
    messagingSenderId: 'PASTE_SENDER_ID',
    projectId: 'PASTE_PROJECT_ID',
    authDomain: 'PASTE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'PASTE_BUCKET',
  );
}
