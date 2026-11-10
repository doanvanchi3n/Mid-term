import 'package:flutter/material.dart';

import '../mascot/app_mascot.dart';

class AppLoading extends StatefulWidget {
  const AppLoading({super.key});
  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -6 * _controller.value),
              child: child,
            ),
            child: const AppMascot(state: MascotState.loading),
          ),
          const SizedBox(height: 16),
          const Text('Đang tải dữ liệu…'),
          const SizedBox(height: 16),
          const SizedBox(width: 100, child: LinearProgressIndicator()),
        ],
      ),
    ),
  );
}
