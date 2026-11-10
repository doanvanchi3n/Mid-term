abstract final class Validators {
  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập họ tên.';
    if (text.length > 120) return 'Họ tên không quá 120 ký tự.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    return text.length <= 254 &&
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : 'Nhập email hợp lệ.';
  }

  static String? password(String? value, {bool optional = false}) {
    final text = value ?? '';
    if (optional && text.isEmpty) return null;
    if (text.length < 8 || text.length > 128) {
      return 'Mật khẩu phải từ 8 đến 128 ký tự.';
    }
    return null;
  }
}
