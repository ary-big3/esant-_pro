// IO implementation for mobile/desktop platforms
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileSaver {
  static Future<void> saveAndOpen({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await OpenFile.open(filePath);
  }
}
