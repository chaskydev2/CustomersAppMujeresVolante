// File customized for Android only.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDl4WDw1SnIgnWkVLwVxrtqYBhzMu8VgvY',
    appId: '1:439845573858:android:ade7789fcb3ddcbbe33abb',
    messagingSenderId: '439845573858',
    projectId: 'mav2025-bd18e',
    databaseURL: 'https://mav2025-bd18e-default-rtdb.firebaseio.com',
    storageBucket: 'mav2025-bd18e.firebasestorage.app',
  );
}
