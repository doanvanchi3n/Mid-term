import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/asset_paths.dart';
import '../widgets/common/feedback_dialog.dart';
import 'home/home_screen.dart';
import 'users/user_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= 1000 &&
        MediaQuery.textScalerOf(context).scale(1) < 1.5;
    final content = IndexedStack(
      index: _index,
      children: [
        HomeScreen(onViewUsers: () => setState(() => _index = 1)),
        const UserListScreen(),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AssetPaths.brandMark,
              width: 36,
              height: 44,
              semanticsLabel: 'ECOMER',
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('ECOMER', overflow: TextOverflow.ellipsis),
            ),
            if (wide) ...[
              const SizedBox(width: 16),
              Text(
                'Quản lý người dùng',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (error) {
                if (context.mounted) await showFeedback(context, error: error);
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    extended: true,
                    minExtendedWidth: 208,
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Tổng quan'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text('Người dùng'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Người dùng',
                ),
              ],
            ),
    );
  }
}
