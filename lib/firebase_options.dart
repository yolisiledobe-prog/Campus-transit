// File: lib/firebase_options.dart
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDmR2cvBBzOKHrMYtNz1ts30p36BiDP8Ic',
    appId: '1:214654954299:web:75645f04aa07bea636e51e',
    messagingSenderId: '214654954299',
    projectId: 'campustransit-26c45',
    authDomain: 'campustransit-26c45.firebaseapp.com',
    storageBucket: 'campustransit-26c45.firebasestorage.app',
    measurementId: 'G-3LSXVK42K3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmR2cvBBzOKHrMYtNz1ts30p36BiDP8Ic',
    appId: '1:214654954299:android:placeholder',
    messagingSenderId: '214654954299',
    projectId: 'campustransit-26c45',
    storageBucket: 'campustransit-26c45.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmR2cvBBzOKHrMYtNz1ts30p36BiDP8Ic',
    appId: '1:214654954299:ios:placeholder',
    messagingSenderId: '214654954299',
    projectId: 'campustransit-26c45',
    storageBucket: 'campustransit-26c45.firebasestorage.app',
  );
}