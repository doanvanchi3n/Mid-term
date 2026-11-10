import 'package:flutter/material.dart';

import '../backgrounds/app_background.dart';
import 'app_mascot.dart';

class MascotStateWidget extends StatelessWidget {
  const MascotStateWidget({
    super.key,
    required this.state,
    required this.title,
    this.message,
    this.action,
  });
  final MascotState state;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBackground(
              style: BackgroundStyle.emptyState,
              child: AppMascot(state: state, width: 160, height: 160),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ),
  );
}
