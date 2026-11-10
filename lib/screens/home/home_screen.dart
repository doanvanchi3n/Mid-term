import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/navigation.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/content_container.dart';
import '../../widgets/mascot/app_mascot.dart';
import '../../widgets/mascot/mascot_banner.dart';
import '../../widgets/mascot/mascot_state_widget.dart';
import '../../widgets/users/user_card.dart';
import '../users/user_detail_screen.dart';
import '../users/user_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onViewUsers});
  final VoidCallback onViewUsers;
  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final withImage = users.items
        .where((user) => user.imageData.isNotEmpty)
        .length;
    return ContentContainer(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const MascotBanner(),
          const SizedBox(height: 24),
          if (users.loading)
            const AppLoading()
          else if (users.error != null)
            MascotStateWidget(
              state: MascotState.error,
              title: 'Chưa tải được dữ liệu',
              message: users.error,
              action: FilledButton(
                onPressed: users.refresh,
                child: const Text('Thử lại'),
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    width: (constraints.maxWidth - 16) / 2,
                    count: users.items.length,
                    label: 'Người dùng',
                    icon: Icons.people_outline,
                    onTap: onViewUsers,
                  ),
                  _StatCard(
                    width: (constraints.maxWidth - 16) / 2,
                    count: withImage,
                    label: 'Có ảnh đại diện',
                    icon: Icons.portrait_outlined,
                    onTap: onViewUsers,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Hồ sơ người dùng',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: onViewUsers,
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (users.items.isEmpty)
              MascotStateWidget(
                state: MascotState.empty,
                title: 'Bắt đầu với hồ sơ đầu tiên',
                message: 'Quản lý họ tên, email và hình ảnh ở cùng một nơi.',
                action: FilledButton.icon(
                  onPressed: () => openScreen(context, const UserFormScreen()),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Thêm người dùng'),
                ),
              )
            else
              ...users
                  .filtered('')
                  .take(5)
                  .map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UserCard(
                        user: user,
                        onTap: () => openScreen(
                          context,
                          UserDetailScreen(userId: user.id),
                        ),
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.count,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final double width;
  final int count;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: AppColors.primary),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
