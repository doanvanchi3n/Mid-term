import 'package:ecomer/core/constants/asset_paths.dart';
import 'package:ecomer/core/theme/app_theme.dart';
import 'package:ecomer/providers/user_provider.dart';
import 'package:ecomer/screens/auth/login_screen.dart';
import 'package:ecomer/screens/home/home_screen.dart';
import 'package:ecomer/screens/users/user_detail_screen.dart';
import 'package:ecomer/screens/users/user_form_screen.dart';
import 'package:ecomer/screens/users/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/user_test_repository.dart';

Widget wrap(Widget screen, {double scale = 1, bool empty = false}) =>
    ChangeNotifierProvider(
      create: (_) =>
          UserProvider(UserTestRepository(users: empty ? [] : testUsers)),
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    );

void main() {
  testWidgets('10 SVG runtime vẫn được render sau thay đổi đề bài', (
    tester,
  ) async {
    for (final path in [
      AssetPaths.brandMark,
      ...AssetPaths.mascots.values,
      ...AssetPaths.backgrounds.values,
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SvgPicture.asset(path))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
    }
  });
  for (final width in [320.0, 1200.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'màn hình người dùng $width px / cỡ chữ $scale không overflow',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final screen in <Widget>[
            const LoginScreen(),
            Scaffold(body: HomeScreen(onViewUsers: () {})),
            const Scaffold(body: UserListScreen()),
            const UserDetailScreen(userId: 'an'),
            const UserFormScreen(),
          ]) {
            await tester.pumpWidget(wrap(screen, scale: scale));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: screen.runtimeType.toString(),
            );
            await tester.pumpWidget(const SizedBox());
          }
        },
      );
    }
  }
  testWidgets('tìm không dấu và mascot không có kết quả', (tester) async {
    await tester.pumpWidget(wrap(const Scaffold(body: UserListScreen())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'nguyen');
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Bình'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy người dùng'), findsOneWidget);
  });
  testWidgets('form validate và cuộn được khi bàn phím mở', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(wrap(const UserFormScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu người dùng'));
    await tester.tap(find.text('Lưu người dùng'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập họ tên.'), findsOneWidget);
    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dữ liệu trống có mascot Empty', (tester) async {
    await tester.pumpWidget(
      wrap(const Scaffold(body: UserListScreen()), empty: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có người dùng'), findsOneWidget);
  });
}
