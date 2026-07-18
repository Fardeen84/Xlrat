import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions currentPlatform(Map<String, String> env) {
    final apiKey = env['FIREBASE_API_KEY'] ?? '';
    final projectId = env['FIREBASE_PROJECT_ID'] ?? 'xlrat-garage';
    final senderId = env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    final storageBucket = env['FIREBASE_STORAGE_BUCKET'];

    if (kIsWeb) {
      final rawAppId = env['FIREBASE_APP_ID_WEB'] ?? '';
      return FirebaseOptions(
        apiKey: apiKey,
        appId: rawAppId.isNotEmpty ? rawAppId : '1:282837372288:web:a1b2c3d4e5f6g7h8i9j0k1',
        messagingSenderId: senderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final rawAppIdAndroid = env['FIREBASE_APP_ID_ANDROID'] ?? '';
        return FirebaseOptions(
          apiKey: apiKey,
          appId: rawAppIdAndroid.isNotEmpty ? rawAppIdAndroid : '1:282837372288:android:a1b2c3d4e5f6g7h8i9j0k1',
          messagingSenderId: senderId,
          projectId: projectId,
          storageBucket: storageBucket,
        );
      case TargetPlatform.iOS:
        final rawAppIdIos = env['FIREBASE_APP_ID_IOS'] ?? '';
        return FirebaseOptions(
          apiKey: apiKey,
          appId: rawAppIdIos.isNotEmpty ? rawAppIdIos : '1:282837372288:ios:a1b2c3d4e5f6g7h8i9j0k1',
          messagingSenderId: senderId,
          projectId: projectId,
          storageBucket: storageBucket,
          iosBundleId: 'com.example.xlrat',
        );
      case TargetPlatform.macOS:
        final rawAppIdIos = env['FIREBASE_APP_ID_IOS'] ?? '';
        return FirebaseOptions(
          apiKey: apiKey,
          appId: rawAppIdIos.isNotEmpty ? rawAppIdIos : '1:282837372288:ios:a1b2c3d4e5f6g7h8i9j0k1',
          messagingSenderId: senderId,
          projectId: projectId,
          storageBucket: storageBucket,
          iosBundleId: 'com.example.xlrat',
        );
      case TargetPlatform.windows:
        final rawAppId = env['FIREBASE_APP_ID_WINDOWS'] ?? '';
        return FirebaseOptions(
          apiKey: apiKey,
          appId: rawAppId.isNotEmpty ? rawAppId : '1:282837372288:web:a1b2c3d4e5f6g7h8i9j0k1',
          messagingSenderId: senderId,
          projectId: projectId,
          storageBucket: storageBucket,
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
