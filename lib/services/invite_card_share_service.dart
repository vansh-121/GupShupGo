import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class InviteCardShareService {
  InviteCardShareService._();

  /// Keep the source outside share_plus/; the plugin clears its own cache then
  /// copies this file and grants a content URI through its bundled provider.
  static Future<XFile> writePng(Uint8List bytes) async {
    final temporaryDirectory = await getTemporaryDirectory();
    final directory = await Directory('${temporaryDirectory.path}/invite_cards')
        .create(recursive: true);
    final name =
        'gupshupgo_invite_${DateTime.now().microsecondsSinceEpoch}.png';
    final file =
        await File('${directory.path}/$name').writeAsBytes(bytes, flush: true);
    return XFile(file.path, name: name, mimeType: 'image/png');
  }
}
