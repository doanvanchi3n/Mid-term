import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/navigation.dart';
import '../../providers/user_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/common/app_loading.dart';
import '../../widgets/common/content_container.dart';
import '../../widgets/common/feedback_dialog.dart';
import '../../widgets/mascot/app_mascot.dart';
import '../../widgets/mascot/mascot_state_widget.dart';
import '../../widgets/users/user_avatar.dart';
import '../../widgets/users/user_card.dart';
import 'user_form_screen.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});
  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _search = TextEditingController();
  bool _withImage = false, _exporting = false;
  UserSort _sort = UserSort.name;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await ExportService().saveUsers(context.read<UserProvider>().repository);
      if (mounted) {
        await showFeedback(
          context,
          success:
              'Đã xuất users.json. File chứa đủ bốn trường và dữ liệu ảnh.',
        );
      }
    } catch (error) {
      if (mounted) await showFeedback(context, error: error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final items = users.filtered(
      _search.text,
      withImage: _withImage,
      sort: _sort,
    );
    return ContentContainer(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách người dùng',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${users.items.length} hồ sơ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton(
                    tooltip: 'Tải lại dữ liệu',
                    onPressed: users.loading ? null : users.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _export,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(_exporting ? 'Đang xuất…' : 'Xuất JSON'),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        openScreen(context, const UserFormScreen()),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Thêm người dùng'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm theo họ tên hoặc email…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa từ khóa',
                      onPressed: () => setState(_search.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: const Text('Có ảnh đại diện'),
                selected: _withImage,
                onSelected: (value) => setState(() => _withImage = value),
              ),
              PopupMenuButton<UserSort>(
                tooltip: 'Sắp xếp',
                initialValue: _sort,
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: UserSort.name,
                    child: Text('Họ tên A–Z'),
                  ),
                  PopupMenuItem(
                    value: UserSort.email,
                    child: Text('Email A–Z'),
                  ),
                ],
                child: Chip(
                  avatar: const Icon(Icons.sort, size: 18),
                  label: Text(
                    _sort == UserSort.name ? 'Họ tên A–Z' : 'Email A–Z',
                  ),
                ),
              ),
              Text(
                '${items.length} kết quả',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (users.loading)
            const AppLoading()
          else if (users.error != null)
            MascotStateWidget(
              state: MascotState.error,
              title: 'Chưa tải được người dùng',
              message: users.error,
              action: FilledButton(
                onPressed: users.refresh,
                child: const Text('Thử lại'),
              ),
            )
          else if (items.isEmpty)
            MascotStateWidget(
              state: users.items.isEmpty
                  ? MascotState.empty
                  : MascotState.search,
              title: users.items.isEmpty
                  ? 'Chưa có người dùng'
                  : 'Không tìm thấy người dùng',
              message: users.items.isEmpty
                  ? 'Thêm hồ sơ đầu tiên để bắt đầu quản lý.'
                  : 'Thử họ tên, email khác hoặc bỏ bộ lọc.',
              action: users.items.isEmpty
                  ? FilledButton(
                      onPressed: () =>
                          openScreen(context, const UserFormScreen()),
                      child: const Text('Tạo hồ sơ đầu tiên'),
                    )
                  : OutlinedButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _withImage = false;
                      }),
                      child: const Text('Xóa bộ lọc'),
                    ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4) {
                  return Column(
                    children: items
                        .map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: UserCard(
                              user: user,
                              onTap: () => openScreen(
                                context,
                                UserDetailScreen(userId: user.id),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }
                return Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 56,
                      dataRowMinHeight: 76,
                      dataRowMaxHeight: 88,
                      columns: const [
                        DataColumn(label: Text('Hình ảnh')),
                        DataColumn(label: Text('Họ tên')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Mật khẩu')),
                        DataColumn(label: Text('Thao tác')),
                      ],
                      rows: items
                          .map(
                            (user) => DataRow(
                              onSelectChanged: (_) => openScreen(
                                context,
                                UserDetailScreen(userId: user.id),
                              ),
                              cells: [
                                DataCell(
                                  UserAvatar(
                                    imageData: user.imageData,
                                    size: 44,
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 168,
                                    child: Text(
                                      user.fullName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Text(
                                      user.email,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const DataCell(Text('••••••••')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Xem ${user.fullName}',
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        onPressed: () => openScreen(
                                          context,
                                          UserDetailScreen(userId: user.id),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Sửa ${user.fullName}',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => openScreen(
                                          context,
                                          UserFormScreen(user: user),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
