// Image compression before encrypt+upload.
//
// Status/chat photos straight from the gallery are typically 3-8 MB on
// modern phones, which dominates the encrypt+upload wall time. Resizing
// to a max edge of 1600px and re-encoding at JPEG quality 75 brings the
// payload down to ~150-400 KB — a 10-20× reduction with no visible
// quality drop on a phone screen.

import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Compress [src]. Returns the original file on any failure so callers
  /// never get stuck just because compression hit a codec edge case.
  static Future<File> compressForStatus(File src) =>
      _compress(src, maxEdge: 1600, quality: 75);

  /// Slightly smaller for chat — phones display chat thumbnails at a
  /// fraction of status-viewer size, so quality 70 is plenty.
  static Future<File> compressForChat(File src) =>
      _compress(src, maxEdge: 1280, quality: 70);

  static Future<File> _compress(File src,
      {required int maxEdge, required int quality}) async {
    try {
      final dir = await getTemporaryDirectory();
      final base = p.basenameWithoutExtension(src.path);
      final out =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$base.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        src.absolute.path,
        out,
        quality: quality,
        minWidth: maxEdge,
        minHeight: maxEdge,
        format: CompressFormat.jpeg,
      );
      if (result == null) return src;
      return File(result.path);
    } catch (_) {
      return src;
    }
  }
}
