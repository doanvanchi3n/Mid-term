import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../core/utils/app_exception.dart';

class AvatarService {
  Future<String?> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 384,
      maxHeight: 384,
      imageQuality: 80,
    );
    if (file == null) return null;
    if (await file.length() > 10 * 1024 * 1024) {
      throw const AppException('Ảnh gốc quá 10 MB. Hãy chọn ảnh nhỏ hơn.');
    }
    return encodeAvatar(await file.readAsBytes());
  }

  static Future<String> encodeAvatar(Uint8List bytes) async {
    // Giải mã thật trước khi lưu; tạo PNG nhỏ, không giữ EXIF từ ảnh gốc.
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 192,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null || data.lengthInBytes > 150 * 1024) {
          throw const AppException(
            'Ảnh sau thu nhỏ vẫn quá 150 KB. Hãy chọn ảnh ít chi tiết hơn.',
          );
        }
        return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes))}';
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
