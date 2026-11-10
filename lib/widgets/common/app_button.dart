import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = 'Đang lưu…',
    this.icon = Icons.check_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String busyLabel;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: busy ? null : onPressed,
    icon: busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    label: Text(busy ? busyLabel : label, textAlign: TextAlign.center),
  );
}
