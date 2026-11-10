import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/asset_paths.dart';
export '../../core/constants/asset_paths.dart' show BackgroundStyle;

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.style,
    required this.child,
    this.fit = BoxFit.cover,
  });
  final BackgroundStyle style;
  final Widget child;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: SvgPicture.asset(
            AssetPaths.backgrounds[style]!,
            fit: fit,
            excludeFromSemantics: true,
          ),
        ),
      ),
      child,
    ],
  );
}
