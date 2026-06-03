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
    apiKey: 'AIzaSyCrnXI42hERpMIW4VJCGvcOYUb5yffFdp8',
    appId: '1:350079474652:web:ef38523224743bc7eb0d19',
    messagingSenderId: '350079474652',
    projectId: 'vision-sos-5df6a',
    authDomain: 'vision-sos-5df6a.firebaseapp.com',
    storageBucket: 'vision-sos-5df6a.firebasestorage.app',
    databaseURL: 'https://vision-sos-5df6a-default-rtdb.firebaseio.com',
    measurementId: 'G-7TE6X3CS1Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUz3mi77A2On92kqxV4mAJOTKP_WEskEw',
    appId: '1:350079474652:android:039eba7d14d20d24eb0d19',
    messagingSenderId: '350079474652',
    projectId: 'vision-sos-5df6a',
    storageBucket: 'vision-sos-5df6a.firebasestorage.app',
    databaseURL: 'https://vision-sos-5df6a-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBuNwpO5LJfaml70u-qB2Xrffwu5L6A6es',
    appId: '1:350079474652:ios:6b1494f4a46a98e4eb0d19',
    messagingSenderId: '350079474652',
    projectId: 'vision-sos-5df6a',
    storageBucket: 'vision-sos-5df6a.firebasestorage.app',
    databaseURL: 'https://vision-sos-5df6a-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.visionsos',
  );
}
