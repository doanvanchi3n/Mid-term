# ECOMER — Phân hệ admin quản lý người dùng

Flutter **Web + Android**, Firebase Authentication, Cloud Firestore và Cloud Functions. Giữ bộ mascot/background ECOMER; đã chuyển chức năng từ quản lý sản phẩm sang quản lý người dùng theo đề giữa kỳ mới.

## Đáp ứng đề bài

| Yêu cầu | Triển khai |
|---|---|
| Thêm, hiển thị người dùng trên web (8 điểm) | Form tạo hồ sơ, bảng web, chi tiết, Firestore |
| Đăng nhập, sửa, xóa, nâng cao (1,5 điểm) | Admin đăng nhập Firebase Auth, sửa/xóa có xác nhận, tìm không dấu, lọc có ảnh, sắp xếp, xuất JSON |
| Nhập ảnh, hiển thị trên di động (0,5 điểm) | ImagePicker, xem trước, thu nhỏ ảnh, card và chi tiết responsive Android |
| CSDL chỉ bốn trường | `users/{documentId}`: **email, matkhau, hoten, hinhanh** |
| Báo cáo, CSDL, source, video | Thư mục `docs/`, `submission/`; xem `submission/README.md` |

ID document không nằm trong dữ liệu. Không thêm `role`, `createdAt` hay trường phụ. Quyền admin là **custom claim trong Firebase Auth**, không tạo collection quyền trong Firestore.

Mật khẩu hồ sơ được băm **scrypt có salt ngẫu nhiên phía Cloud Functions**. Giao diện chỉ hiển thị `••••••••`. Để trống mật khẩu khi sửa sẽ giữ nguyên hash. `hinhanh` là data URI PNG/JPEG/WebP tối đa 150 KB; app giải mã và thu nhỏ ảnh trước khi lưu. JSON mang theo cả ảnh, không cần Firebase Storage.

**Phạm vi đăng nhập:** admin dùng tài khoản Firebase Auth được cấp sẵn để quản lý hồ sơ. Các hồ sơ tạo trong `users` chưa phải tài khoản Firebase Auth và không tự đăng nhập vào phân hệ admin.

## Chạy cục bộ bằng Emulator

Cần Flutter/Dart (Dart >= 3.13.4), Node.js 20, Java 21, Chrome và Android SDK nếu chạy Android.

```bash
cd ecomer
flutter pub get
npm ci
npm ci --prefix functions
npm run emulators
```

Giữ terminal trên mở. Terminal khác:

```bash
npm run seed:admin
flutter run -d chrome --web-port=7357 --dart-define-from-file=config/emulator.json
```

Đăng nhập **admin@ecomer.local / EcomerDemo123!**. Script chỉ tạo tài khoản admin trên Emulator, không tự thêm hồ sơ mẫu. Tạo người dùng từ giao diện. Dữ liệu app là dữ liệu Firebase thật của Emulator.

| Dịch vụ | Địa chỉ |
|---|---|
| Emulator UI | http://127.0.0.1:4400 |
| Auth | 127.0.0.1:9199 |
| Firestore | 127.0.0.1:8180 |
| Functions | 127.0.0.1:5001 |
| Project local | demo-ecomer |

`npm run emulators` import/export vào `.emulator-users`. Dừng bằng Ctrl+C để lưu dữ liệu. Dữ liệu đề cũ trong `.emulator-data` không được tự động import. Nếu mới chạy, cảnh báo chưa có file import là bình thường. `npm run emulators:fresh` khởi tạo phiên tạm không lưu.

Android Emulator:

```bash
flutter devices
flutter run -d emulator-5554 --dart-define-from-file=config/emulator.json
```

App tự chọn host `10.0.2.2` trên Android, `127.0.0.1` trên web. Máy Android thật qua USB:

Để cài APK có sẵn và quay phần nhập ảnh trên điện thoại, xem [hướng dẫn cài APK qua USB](docs/CAI_APK_DIEN_THOAI.md).

```bash
adb reverse tcp:9199 tcp:9199
adb reverse tcp:5001 tcp:5001
flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

## Kiểm thử và build

```bash
flutter analyze
flutter test
npm test --prefix functions
npm run test:backend
flutter build web --dart-define-from-file=config/emulator.json
flutter build apk --debug --dart-define-from-file=config/emulator.json
```

Backend tests chạy trên project riêng `demo-ecomer-users-test`, cổng 8280/9299/5002; không xóa dữ liệu demo. Test bao gồm Auth thực, callable Functions, transaction Firestore, schema bốn trường, email trùng đồng thời, validation và xuất JSON. Dữ liệu fixture chỉ nằm trong test; kết quả xuất thật ở `submission/users.json` được ghi rõ là dữ liệu kiểm thử.

Xem [kết quả chạy thực tế](docs/KIEM_THU.md). Không suy diễn từ mã nguồn rằng đã kiểm thử Android vật lý hay Firebase cloud.

## Cấu trúc

- `lib/models/user_model.dart`: ánh xạ tên tiếng Anh sang đúng bốn trường đề bài.
- `lib/repositories/user_repository.dart`: gọi các callable Functions.
- `lib/providers/user_provider.dart`: dữ liệu, tìm kiếm, lọc, trạng thái loading/error.
- `lib/screens/users/`: danh sách, form và chi tiết.
- `lib/services/avatar_service.dart`: chọn, giải mã, thu nhỏ và đóng gói ảnh.
- `functions/src/user_service.js`: validation, scrypt, transaction tạo/sửa/xóa, xuất dữ liệu.
- `functions/src/index.js`: bốn endpoint callable, đều bắt buộc custom claim `admin=true`.
- `assets/mascots`, `assets/backgrounds`: tài nguyên gốc tiếp tục dùng.
- `archive/catalog-before-user-management.zip`: bản lưu đề cũ, không được app mới sử dụng.

Firestore chặn mọi truy cập client trực tiếp; chỉ backend đã kiểm tra admin dùng Admin SDK. Email chuẩn hóa chữ thường; document ID là SHA-256 của email để chống trùng bằng transaction mà không thêm field phụ. Đổi email được thực hiện bằng một transaction chuyển document, không làm mất hồ sơ khi email đích đã tồn tại.

## Chuyển lên Firebase cloud

Chưa triển khai cloud vì chưa có project. Khi có:

1. Tạo project, Firestore production mode, bật Auth Email/Password. Tạo admin trong Firebase Auth.
2. Đăng ký app Web và Android (`vn.ecomer.ecomer`), lấy FirebaseOptions tương ứng mỗi nền tảng. Sao chép `config/production.example.json` thành file cấu hình riêng cho web/Android và điền giá trị thật.
3. Cấp custom claim `admin: true` bằng Admin SDK trong môi trường quản trị đáng tin cậy. Không đưa service-account key vào app; không tự cấp quyền từ client.
4. Triển khai Functions và Rules vào đúng project; triển khai Functions cần plan hỗ trợ dịch vụ này. Không mở Rules public để chữa lỗi.

```bash
npx firebase login
npx firebase deploy --only functions,firestore:rules --project YOUR_PROJECT_ID
flutter build web --dart-define-from-file=config/production.json
npx firebase deploy --only hosting --project YOUR_PROJECT_ID
```

Bản web production phải dùng Firebase Web appId. Android dùng Android appId. Đây là hướng dẫn triển khai, không phải bằng chứng đã có site public.

## Giới hạn hiện tại

App tải dữ liệu theo các trang callable rồi tìm kiếm trên tập đã tải, phù hợp bài giữa kỳ và danh sách nhỏ. Với dữ liệu lớn cần tìm kiếm/phân trang phía server và chuyển ảnh sang Storage. Hai admin sửa cùng hồ sơ áp dụng lần ghi cuối; email trùng vẫn được transaction bảo vệ. Xuất JSON nhiều trang không phải snapshot nguyên tử nếu admin khác đang sửa cùng lúc; nên tạm ngừng chỉnh sửa khi chốt dữ liệu nộp bài. Mật khẩu hash không thể xem lại hay khôi phục dạng rõ.

Tài liệu: [báo cáo](docs/BAO_CAO_HUONG_DAN.md), [demo](docs/KICH_BAN_DEMO.md), [assets](docs/ASSETS.md), [hồ sơ nộp bài](submission/README.md).
