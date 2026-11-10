import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

Future<T?> openScreen<T>(BuildContext context, Widget screen) {
  final users = context.read<UserProvider>();
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: users, child: screen),
    ),
  );
}
