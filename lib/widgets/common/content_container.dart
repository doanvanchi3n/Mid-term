import 'package:flutter/material.dart';

class ContentContainer extends StatelessWidget {
  const ContentContainer({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: child,
    ),
  );
}
