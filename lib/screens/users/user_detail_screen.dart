import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/navigation.dart';
import '../../providers/user_provider.dart';
import '../../widgets/backgrounds/decorative_background.dart';
import '../../widgets/common/content_container.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/feedback_dialog.dart';
import '../../widgets/mascot/app_mascot.dart';
import '../../widgets/mascot/mascot_state_widget.dart';
import '../../widgets/users/user_avatar.dart';
import 'user_form_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId});
  final String userId;
  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late String _id = widget.userId;
  bool _busy = false;
  Future<void> _delete(String name) async {
    if (_busy || !await confirmDelete(context, name: name) || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<UserProvider>().delete(_id);
      if (!mounted) return;
      await showFeedback(context, success: 'Đã xóa người dùng.');
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.pop(context);
    } catch (error) {
      if (mounted) await showFeedback(context, error: error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().byId(_id);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Thông tin người dùng')),
        body: SafeArea(
          child: ContentContainer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: user == null
                  ? const MascotStateWidget(
                      state: MascotState.empty,
                      title: 'Hồ sơ không còn trong danh sách',
                      message: 'Hãy quay lại và tải lại dữ liệu.',
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: DecorativeBackground(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: UserAvatar(
                                      imageData: user.imageData,
                                      size: 144,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(user.email),
                            const SizedBox(height: 24),
                            Text(
                              'Mật khẩu',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text('••••••••'),
                            const SizedBox(height: 8),
                            Text(
                              'Mật khẩu được bảo vệ. Chọn Chỉnh sửa để đặt mật khẩu mới.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          final id = await openScreen<String>(
                                            context,
                                            UserFormScreen(user: user),
                                          );
                                          if (mounted && id != null) {
                                            setState(() => _id = id);
                                          }
                                        },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Chỉnh sửa'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _delete(user.fullName),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    _busy ? 'Đang xóa…' : 'Xóa người dùng',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
