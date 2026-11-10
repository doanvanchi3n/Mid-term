import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

String errorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is FormatException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'already-exists' => 'Email này đã được sử dụng.',
      'invalid-argument' => error.message ?? 'Dữ liệu chưa hợp lệ.',
      'permission-denied' => 'Tài khoản chưa có quyền quản trị. Liên hệ người quản lý để được cấp quyền.',
      'unavailable' ||
      'network-request-failed' ||
      'deadline-exceeded' => 'Không thể kết nối. Kiểm tra mạng và thử lại.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' => 'Email hoặc mật khẩu chưa đúng.',
      'too-many-requests' => 'Có quá nhiều yêu cầu. Vui lòng thử lại sau.',
      'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
      'not-found' => 'Dữ liệu không còn tồn tại. Vui lòng tải lại.',
      'aborted' => 'Dữ liệu vừa thay đổi. Vui lòng thử lại.',
      _ => 'Không thể hoàn tất thao tác (${error.code}). Vui lòng thử lại.',
    };
  }
  return 'Có lỗi xảy ra. Vui lòng thử lại.';
}
