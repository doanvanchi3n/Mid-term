import 'package:cloud_functions/cloud_functions.dart';
import 'package:ecomer/models/user_model.dart';
import 'package:ecomer/repositories/user_repository.dart';

class _UnusedFunctions implements FirebaseFunctions {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const testUsers = [
  UserModel(
    id: 'an',
    email: 'an@example.com',
    fullName: 'Nguyễn Văn An',
    imageData: '',
  ),
  UserModel(
    id: 'binh',
    email: 'binh@example.com',
    fullName: 'Trần Bình',
    imageData: '',
  ),
];

class UserTestRepository extends UserRepository {
  UserTestRepository({List<UserModel> users = testUsers})
    : values = [...users],
      super(_UnusedFunctions());
  final List<UserModel> values;
  @override
  Future<List<UserModel>> fetchAll() async => [...values];
  @override
  Future<String> save(UserModel user, String password) async =>
      user.id.isEmpty ? 'new-user' : user.id;
  @override
  Future<void> delete(String id) async {}
}
