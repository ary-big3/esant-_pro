// Stub for web platform - uses browser download
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class FileSaver {
  static Future<void> saveAndOpen({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
