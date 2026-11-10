import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../backgrounds/app_background.dart';
import 'app_mascot.dart';

class MascotBanner extends StatelessWidget {
  const MascotBanner({super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: AppBackground(
      style: BackgroundStyle.homeBanner,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 300;
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chào mừng đến ECOMER',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(color: const Color(0xFF173B7A)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Quản lý người dùng dễ dàng',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Hồ sơ • Hình ảnh • Thông tin',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AppMascot(
                  state: MascotState.welcome,
                  width: narrow ? 88 : 120,
                  height: narrow ? 110 : 140,
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
