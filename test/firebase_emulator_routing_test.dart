import 'package:cloud_functions/cloud_functions.dart';
import 'package:ecomer/services/firebase_service.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingAuthPlatform extends FirebaseAuthPlatform {
  String? host;
  int? port;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  Future<void> useAuthEmulator(String host, int port) async {
    this.host = host;
    this.port = port;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Run with config/emulator-usb.json to cover physical Android over adb reverse.
  // Without a host override this also covers the Android Emulator default.
  test(
    'Android Auth and Functions preserve the selected emulator host',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      setupFirebaseCoreMocks();
      await Firebase.initializeApp();
      final auth = RecordingAuthPlatform();
      FirebaseAuthPlatform.instance = auth;

      await FirebaseService.initialize();

      final expectedHost = FirebaseService.emulatorHost.isNotEmpty
          ? FirebaseService.emulatorHost
          : '10.0.2.2';
      expect(auth.host, expectedHost);
      expect(auth.port, 9199);
      expect(
        FirebaseFunctions.instance.httpsCallable('listUsers').delegate.origin,
        'http://$expectedHost:5001',
      );
    },
  );
}
