import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/feedback_dialog.dart';
import '../../widgets/mascot/app_mascot.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false, _obscured = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate() || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } catch (error) {
      if (mounted) await showFeedback(context, error: error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: AppMascot(
                      state: MascotState.welcome,
                      width: 144,
                      height: 144,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ECOMER',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: AppColors.primary, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quản lý người dùng, đơn giản mỗi ngày.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _email,
                    label: 'Email quản trị',
                    hint: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !_busy,
                  ),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscured,
                    onFieldSubmitted: (_) => _login(),
                    validator: (value) => (value?.isEmpty ?? true)
                        ? 'Vui lòng nhập mật khẩu.'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                        onPressed: () => setState(() => _obscured = !_obscured),
                        icon: Icon(
                          _obscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Đăng nhập',
                  busyLabel: 'Đang đăng nhập…',
                    icon: Icons.login_rounded,
                    busy: _busy,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sử dụng tài khoản được người quản lý cấp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  if (FirebaseService.useEmulator) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Môi trường thử nghiệm',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
