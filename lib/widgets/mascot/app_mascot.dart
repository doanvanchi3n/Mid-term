import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/asset_paths.dart';
export '../../core/constants/asset_paths.dart' show MascotState;

class AppMascot extends StatelessWidget {
  const AppMascot({
    super.key,
    required this.state,
    this.width = 160,
    this.height = 160,
    this.fit = BoxFit.contain,
  });
  final MascotState state;
  final double width, height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AssetPaths.mascots[state]!,
    width: width,
    height: height,
    fit: fit,
    excludeFromSemantics: true,
  );
}
