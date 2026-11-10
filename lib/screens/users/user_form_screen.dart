import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/avatar_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/content_container.dart';
import '../../widgets/common/feedback_dialog.dart';
import '../../widgets/users/user_avatar.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.user});
  final UserModel? user;
  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.fullName);
  late final _email = TextEditingController(text: widget.user?.email);
  final _password = TextEditingController();
  late String _image = widget.user?.imageData ?? '';
  bool _busy = false, _picking = false, _obscured = true;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final value = await AvatarService().pickImage();
      if (mounted && value != null) setState(() => _image = value);
    } catch (error) {
      if (mounted) await showFeedback(context, error: error);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _picking || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final id = await context.read<UserProvider>().save(
        UserModel(
          id: widget.user?.id ?? '',
          email: _email.text,
          fullName: _name.text,
          imageData: _image,
        ),
        _password.text,
      );
      if (!mounted) return;
      await showFeedback(
        context,
        success: widget.user == null
            ? 'Đã thêm người dùng.'
            : 'Đã cập nhật người dùng.',
      );
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.pop(context, id);
    } catch (error) {
      if (mounted) await showFeedback(context, error: error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Thêm người dùng' : 'Sửa người dùng'),
      ),
      body: SafeArea(
        child: ContentContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _form,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: UserAvatar(imageData: _image, size: 112)),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy || _picking ? null : _pick,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: Text(_picking ? 'Đang xử lý…' : 'Chọn ảnh'),
                          ),
                          if (_image.isNotEmpty)
                            TextButton(
                              onPressed: _busy || _picking
                                  ? null
                                  : () => setState(() => _image = ''),
                              child: const Text('Xóa ảnh'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ảnh JPEG, PNG hoặc WebP sẽ được thu nhỏ tự động.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _name,
                        label: 'Họ tên *',
                        hint: 'Nguyễn Văn An',
                        validator: Validators.fullName,
                        enabled: !_busy,
                      ),
                      AppTextField(
                        controller: _email,
                        label: 'Email *',
                        hint: 'email@example.com',
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_busy,
                      ),
                      Text(
                        widget.user == null ? 'Mật khẩu *' : 'Mật khẩu mới',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscured,
                        enabled: !_busy,
                        validator: (value) => Validators.password(
                          value,
                          optional: widget.user != null,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.user == null
                              ? 'Từ 8 đến 128 ký tự'
                              : 'Để trống để giữ mật khẩu hiện tại',
                          errorMaxLines: 2,
                          suffixIcon: IconButton(
                            tooltip: _obscured
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
                            onPressed: () =>
                                setState(() => _obscured = !_obscured),
                            icon: Icon(
                              _obscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        label: 'Lưu người dùng',
                        busy: _busy,
                        onPressed: _picking ? null : _save,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
