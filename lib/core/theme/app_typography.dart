import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  // Roboto có sẵn trên Android; không tải font từ mạng lúc chạy.
  static const fontFamily = 'Roboto';
  static const textTheme = TextTheme(
    headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}
