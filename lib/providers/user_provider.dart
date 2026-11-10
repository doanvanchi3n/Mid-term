import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../core/utils/formatters.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

enum UserSort { name, email }

class UserProvider extends ChangeNotifier {
  UserProvider(this.repository) {
    refresh();
  }
  final UserRepository repository;
  List<UserModel> _items = [];
  List<UserModel> get items => List.unmodifiable(_items);
  bool loading = true;
  String? error;
  bool _disposed = false;
  int _generation = 0;

  UserModel? byId(String id) {
    for (final user in _items) {
      if (user.id == id) return user;
    }
    return null;
  }

  List<UserModel> filtered(
    String query, {
    bool withImage = false,
    UserSort sort = UserSort.name,
  }) {
    final key = normalizeSearch(query);
    final result = _items
        .where(
          (user) =>
              normalizeSearch('${user.fullName} ${user.email}').contains(key) &&
              (!withImage || user.imageData.isNotEmpty),
        )
        .toList();
    result.sort(
      (a, b) => sort == UserSort.email
          ? a.email.compareTo(b.email)
          : normalizeSearch(a.fullName).compareTo(normalizeSearch(b.fullName)),
    );
    return result;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    if (!_disposed) notifyListeners();
    try {
      final result = await repository.fetchAll();
      if (_disposed || generation != _generation) return;
      _items = result;
    } catch (exception) {
      if (_disposed || generation != _generation) return;
      error = errorMessage(exception);
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<String> save(UserModel user, String password) async {
    final id = await repository.save(user, password);
    // Cập nhật ngay bản ghi đã được server xác nhận, tránh lỗi tải lại làm người dùng lưu trùng.
    _generation++;
    _items.removeWhere((item) => item.id == user.id || item.id == id);
    _items.add(
      UserModel(
        id: id,
        email: user.email.trim().toLowerCase(),
        fullName: user.fullName.trim(),
        imageData: user.imageData,
      ),
    );
    loading = false;
    error = null;
    if (!_disposed) notifyListeners();
    return id;
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    _generation++;
    _items.removeWhere((item) => item.id == id);
    loading = false;
    error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
