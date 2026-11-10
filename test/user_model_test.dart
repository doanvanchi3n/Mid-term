import 'package:ecomer/core/utils/validators.dart';
import 'package:ecomer/core/utils/formatters.dart';
import 'package:ecomer/models/user_model.dart';
import 'package:ecomer/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/user_test_repository.dart';

void main() {
  test('schema ánh xạ đúng bốn trường, ID không nằm trong dữ liệu', () {
    expect(testUsers.first.toFields(password: 'secret123').keys.toSet(), {
      'email',
      'matkhau',
      'hoten',
      'hinhanh',
    });
  });
  test('validation họ tên, email, mật khẩu và tìm không dấu', () {
    expect(Validators.fullName('   '), isNotNull);
    expect(Validators.fullName('a' * 121), isNotNull);
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.email('an@example.com'), isNull);
    expect(Validators.password('short'), isNotNull);
    expect(Validators.password('', optional: true), isNull);
    expect(Validators.password('goodpass123'), isNull);
    expect(normalizeSearch(' Nguyễn VĂN An '), 'nguyen van an');
  });
  test(
    'Provider tìm kiếm và cập nhật ngay dữ liệu sau CRUD thành công',
    () async {
      final provider = UserProvider(UserTestRepository());
      addTearDown(provider.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(provider.filtered('nguyen').single.id, 'an');
      expect(provider.filtered('binh@example.com').single.id, 'binh');
      expect(provider.filtered('absent'), isEmpty);
      expect(provider.filtered('', withImage: true), isEmpty);
      final id = await provider.save(
        const UserModel(
          id: '',
          email: 'new@example.com',
          fullName: 'Mới',
          imageData: '',
        ),
        'goodpass123',
      );
      expect(provider.byId(id)?.email, 'new@example.com');
      await provider.delete(id);
      expect(provider.byId(id), isNull);
    },
  );
}
