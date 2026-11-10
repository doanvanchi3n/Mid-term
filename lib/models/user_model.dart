class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.imageData,
  });
  final String id;
  final String email;
  final String fullName;
  final String imageData;

  factory UserModel.fromMap(Map<String, dynamic> data) => UserModel(
    id: data['id'] as String,
    email: data['email'] as String,
    fullName: data['hoten'] as String,
    imageData: data['hinhanh'] as String,
  );

  // ID chỉ dùng trên client; document lưu đúng bốn trường theo đề.
  Map<String, String> toFields({String password = ''}) => {
    'email': email.trim().toLowerCase(),
    'matkhau': password,
    'hoten': fullName.trim(),
    'hinhanh': imageData,
  };
}
