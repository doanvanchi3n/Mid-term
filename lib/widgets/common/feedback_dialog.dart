import 'package:flutter/material.dart';

import '../../core/utils/app_exception.dart';
import '../mascot/app_mascot.dart';

Future<void> showFeedback(
  BuildContext context, {
  String? success,
  Object? error,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppMascot(
            state: error == null ? MascotState.success : MascotState.error,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 12),
          Text(
            error == null ? success! : errorMessage(error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đã hiểu'),
      ),
    ],
  ),
);
