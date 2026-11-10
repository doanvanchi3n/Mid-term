import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.imageData, this.size = 52});
  final String imageData;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_outline_rounded,
      size: size * .48,
      color: AppColors.primary,
    );
    Widget image = fallback;
    if (imageData.startsWith('data:image/')) {
      try {
        image = Image.memory(
          base64Decode(imageData.split(',').last),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => fallback,
          semanticLabel: 'Ảnh đại diện người dùng',
        );
      } on FormatException {
        image = fallback;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 80 ? 24 : 14),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: AppColors.paleBlue,
          child: Center(child: image),
        ),
      ),
    );
  }
}
