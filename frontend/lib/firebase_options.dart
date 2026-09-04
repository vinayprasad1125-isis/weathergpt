// File generated for Firebase platform configuration.
// DO NOT commit API keys to public repositories.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDCI06lhotjQH365uY0tRJrRkzWpDN5bPg',
    appId: '1:420920598700:web:394eed7dcfba0f9cfa7f09',
    messagingSenderId: '420920598700',
    projectId: 'weathergpt-afbe0',
    authDomain: 'weathergpt-afbe0.firebaseapp.com',
    storageBucket: 'weathergpt-afbe0.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCI06lhotjQH365uY0tRJrRkzWpDN5bPg',
    appId: '1:420920598700:android:deec8e6c394c7b75fa7f09',
    messagingSenderId: '420920598700',
    projectId: 'weathergpt-afbe0',
    storageBucket: 'weathergpt-afbe0.firebasestorage.app',
  );
}
