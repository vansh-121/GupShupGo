// Image compression before encrypt+upload.
//
// Status/chat photos straight from the gallery are typically 3-8 MB on
// modern phones, which dominates the encrypt+upload wall time. Resizing
// to a max edge of 1600px and re-encoding at JPEG quality 75 brings the
// payload down to ~150-400 KB — a 10-20× reduction with no visible
// quality drop on a phone screen.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_chat_app/models/subscription_model.dart';

class ImageCompressor {
  /// Compress [src]. Returns the original file on any failure so callers
  /// never get stuck just because compression hit a codec edge case.
  ///
  /// [pro] selects the GupShupGo Pro quality tier. The free path is byte-for-byte
  /// what shipped before the tier existed, so no existing user sees a
  /// regression — Pro adds headroom rather than free losing any. The numbers
  /// themselves live in [PlanLimits] so plan behaviour stays in one place.
  static Future<File> compressForStatus(File src, {bool pro = false}) =>
      _compress(
        src,
        maxEdge: PlanLimits.statusImageMaxEdge(pro),
        quality: PlanLimits.statusImageQuality(pro),
      );

  /// Slightly smaller for chat — phones display chat thumbnails at a
  /// fraction of status-viewer size, so quality 70 is plenty.
  static Future<File> compressForChat(File src, {bool pro = false}) =>
      _compress(
        src,
        maxEdge: PlanLimits.chatImageMaxEdge(pro),
        quality: PlanLimits.chatImageQuality(pro),
      );

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

  /// Byte-in/byte-out variant for the link-preview micro-thumbnail.
  ///
  /// Unlike the file-based helpers above this returns **null** rather than the
  /// input on failure: the caller's fallback is a text-only preview card, and
  /// handing back a multi-megabyte original would be far worse than no
  /// thumbnail at all — every byte here is duplicated once per recipient device
  /// inside the encrypted payload.
  ///
  /// Bytes rather than a file because the source arrives straight off an HTTP
  /// response and never needs to touch disk. Returns null for anything the
  /// platform codec can't read (SVG favicons, for instance).
  static Future<Uint8List?> compressThumbnailBytes(
    Uint8List src, {
    int maxEdge = 200,
    int quality = 55,
  }) async {
    try {
      final out = await FlutterImageCompress.compressWithList(
        src,
        minWidth: maxEdge,
        minHeight: maxEdge,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }
}
