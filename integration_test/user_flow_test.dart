import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:ecomer/core/constants/asset_paths.dart';
import 'package:ecomer/main.dart' as app;
import 'package:ecomer/models/user_model.dart';
import 'package:ecomer/providers/user_provider.dart';
import 'package:ecomer/repositories/user_repository.dart';
import 'package:ecomer/screens/home/home_screen.dart';
import 'package:ecomer/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Không tìm thấy widget: $finder');
  }
  testWidgets('Android đăng nhập, tạo hồ sơ có ảnh, hiển thị và xóa', (tester) async {
    expect(FirebaseService.useEmulator, isTrue);
    await FirebaseService.initialize();
    await FirebaseAuth.instance.signOut();
    app.main();
    await waitFor(tester, find.text('Đăng nhập'));
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@ecomer.local');
    await tester.enterText(find.byType(TextFormField).at(1), 'EcomerDemo123!');
    await tester.tap(find.text('Đăng nhập'));
    await waitFor(tester, find.byType(HomeScreen));
    final picture = await vg.loadPicture(SvgAssetLoader(AssetPaths.mascots[MascotState.welcome]!), null);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(192 / picture.size.width);
    canvas.drawPicture(picture.picture);
    final recording = recorder.endRecording();
    final rendered = await recording.toImage(192, 192);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    final imageData = 'data:image/png;base64,${base64Encode(bytes!.buffer.asUint8List())}';
    picture.picture.dispose(); recording.dispose(); rendered.dispose();
    final repository = UserRepository(FirebaseFunctions.instance);
    String? id;
    try {
      id = await repository.save(UserModel(id: '', email: 'android-${DateTime.now().millisecondsSinceEpoch}@example.com',
        fullName: 'Người dùng Android', imageData: imageData), 'AndroidDemo123!');
      final context = tester.element(find.byType(HomeScreen));
      await context.read<UserProvider>().refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Người dùng Android').first);
      await tester.pumpAndSettle();
      expect(find.text('Thông tin người dùng'), findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('09-profile-android');
      expect(tester.takeException(), isNull);
    } finally {
      if (id != null) await repository.delete(id);
    }
  });
}
