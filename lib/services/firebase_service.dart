import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseService {
  static bool _initialized = false;
  static const useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: true,
  );
  static const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  static Future<void> initialize() async {
    if (_initialized) return;
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    if (!useEmulator &&
        [
          projectId,
          appId,
          apiKey,
          senderId,
        ].any((value) => value.isEmpty || value.startsWith('YOUR_'))) {
      throw StateError('Chưa cấu hình Firebase. Xem README.');
    }
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: useEmulator
            ? FirebaseOptions(
                apiKey: 'demo-ecomer-api-key',
                appId: kIsWeb
                    ? '1:1234567890:web:ec0e1234567890'
                    : '1:1234567890:android:ec0e1234567890',
                messagingSenderId: '1234567890',
                projectId: 'demo-ecomer',
                authDomain: 'demo-ecomer.firebaseapp.com',
              )
            : const FirebaseOptions(
                apiKey: apiKey,
                appId: appId,
                messagingSenderId: senderId,
                projectId: projectId,
                authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
              ),
      );
    }
    if (useEmulator) {
      final host = emulatorHost.isNotEmpty
          ? emulatorHost
          : (kIsWeb ? '127.0.0.1' : '10.0.2.2');
      // Host is already selected above. Preserve localhost for physical devices
      // connected with adb reverse; FlutterFire otherwise maps it to 10.0.2.2.
      await FirebaseAuth.instance.useAuthEmulator(
        host,
        9199,
        automaticHostMapping: false,
      );
      FirebaseFunctions.instance.useFunctionsEmulator(
        host,
        5001,
        automaticHostMapping: false,
      );
    }
    _initialized = true;
  }
}
