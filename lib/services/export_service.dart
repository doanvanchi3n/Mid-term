import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import '../repositories/user_repository.dart';

class ExportService {
  Future<void> saveUsers(UserRepository repository) async {
    final records = await repository.exportAll();
    final content = const JsonEncoder.withIndent('  ').convert(records);
    await FileSaver.instance.saveFile(
      name: 'users',
      bytes: Uint8List.fromList(utf8.encode(content)),
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
  }
}
