import 'package:cloud_functions/cloud_functions.dart';

import '../models/user_model.dart';

class UserRepository {
  UserRepository(this.functions);
  final FirebaseFunctions functions;

  Future<List<UserModel>> fetchAll() async {
    final records = await _pages('listUsers');
    return records.map(UserModel.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> exportAll() => _pages('exportUsers');

  Future<List<Map<String, dynamic>>> _pages(String name) async {
    final result = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final response = await functions.httpsCallable(name).call<dynamic>({
        'cursor': cursor,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      result.addAll(
        (data['records'] as List).map(
          (row) => Map<String, dynamic>.from(row as Map),
        ),
      );
      cursor = data['nextCursor'] as String?;
    } while (cursor != null);
    return result;
  }

  Future<String> save(UserModel user, String password) async {
    final response = await functions.httpsCallable('saveUser').call<dynamic>({
      'id': user.id.isEmpty ? null : user.id,
      'user': user.toFields(password: password),
    });
    return (response.data as Map)['id'] as String;
  }

  Future<void> delete(String id) async {
    await functions.httpsCallable('deleteUser').call<dynamic>({'id': id});
  }
}
