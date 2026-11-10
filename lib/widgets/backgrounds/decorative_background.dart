import 'package:flutter/material.dart';

import 'app_background.dart';

class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      AppBackground(style: BackgroundStyle.headerPattern, child: child);
}
