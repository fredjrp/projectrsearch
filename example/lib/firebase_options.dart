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
    apiKey: 'AIzaSyAk9DOEc_hmyeAJEob8QBAyQkiZCp_CPuI',
    appId: '1:805708188196:web:5e2468013a04774e19a6b1',
    messagingSenderId: '805708188196',
    projectId: 'uberzo',
    authDomain: 'uberzo.firebaseapp.com',
    databaseURL: 'https://uberzo-default-rtdb.firebaseio.com',
    storageBucket: 'uberzo.firebasestorage.app',
    measurementId: 'G-YHNT6CC1NN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-kXeu9e9rgshR31cDi1rM5nOGKaflkq8',
    appId: '1:805708188196:android:016756c8de3f655b19a6b1',
    messagingSenderId: '805708188196',
    projectId: 'uberzo',
    storageBucket: 'uberzo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-kXeu9e9rgshR31cDi1rM5nOGKaflkq8',
    appId: '1:805708188196:ios:016756c8de3f655b19a6b1', // Placeholder
    messagingSenderId: '805708188196',
    projectId: 'uberzo',
    storageBucket: 'uberzo.firebasestorage.app',
    iosBundleId: 'com.example.uber_drivers_app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB-kXeu9e9rgshR31cDi1rM5nOGKaflkq8',
    appId: '1:805708188196:ios:016756c8de3f655b19a6b1', // Placeholder
    messagingSenderId: '805708188196',
    projectId: 'uberzo',
    storageBucket: 'uberzo.firebasestorage.app',
    iosBundleId: 'com.example.uber_drivers_app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAk9DOEc_hmyeAJEob8QBAyQkiZCp_CPuI',
    appId: '1:805708188196:web:5e2468013a04774e19a6b1',
    messagingSenderId: '805708188196',
    projectId: 'uberzo',
    authDomain: 'uberzo.firebaseapp.com',
    databaseURL: 'https://uberzo-default-rtdb.firebaseio.com',
    storageBucket: 'uberzo.firebasestorage.app',
    measurementId: 'G-YHNT6CC1NN',
  );
}
