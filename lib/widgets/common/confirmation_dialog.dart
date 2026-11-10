import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

Future<bool> confirmDelete(
  BuildContext context, {
  required String name,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu?'),
        content: Text('Bạn muốn xóa “$name”? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    ) ??
    false;
