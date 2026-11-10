import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'repositories/user_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/app_shell.dart';
import 'services/firebase_service.dart';
import 'widgets/common/app_loading.dart';
import 'widgets/mascot/app_mascot.dart';
import 'widgets/mascot/mascot_state_widget.dart';

class EcomerApp extends StatelessWidget {
  const EcomerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ECOMER • Quản lý người dùng',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _Bootstrap(),
  );
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<void> _initialization = FirebaseService.initialize();
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: MascotStateWidget(
                state: MascotState.error,
                title: 'Chưa thể khởi động ECOMER',
                message:
                    'Kiểm tra cấu hình Firebase và kết nối, sau đó thử lại.',
                action: FilledButton(
                  onPressed: () => setState(
                    () => _initialization = FirebaseService.initialize(),
                  ),
                  child: const Text('Thử lại'),
                ),
              ),
            ),
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: AppLoading());
      }
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, auth) {
          if (auth.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: AppLoading());
          }
          if (auth.data == null) return const LoginScreen();
          return _AdminGate(key: ValueKey(auth.data!.uid), user: auth.data!);
        },
      );
    },
  );
}

class _AdminGate extends StatefulWidget {
  const _AdminGate({super.key, required this.user});
  final User user;
  @override
  State<_AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<_AdminGate> {
  late Future<IdTokenResult> _token = widget.user.getIdTokenResult(true);
  @override
  Widget build(BuildContext context) => FutureBuilder<IdTokenResult>(
    future: _token,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: AppLoading());
      }
      if (snapshot.hasError || snapshot.data?.claims?['admin'] != true) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: MascotStateWidget(
                state: MascotState.error,
                title: snapshot.hasError
                    ? 'Chưa xác thực được quyền'
                    : 'Tài khoản chưa có quyền quản trị',
                message: 'Liên hệ người quản lý để được cấp quyền truy cập.',
                action: Wrap(
                  spacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => setState(
                        () => _token = widget.user.getIdTokenResult(true),
                      ),
                      child: const Text('Thử lại'),
                    ),
                    TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return ChangeNotifierProvider(
        create: (_) => UserProvider(UserRepository(FirebaseFunctions.instance)),
        child: const AppShell(),
      );
    },
  );
}
