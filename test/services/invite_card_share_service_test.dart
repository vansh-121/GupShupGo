import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/invite_card_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temporaryDirectory;
  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('gup_invite_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return temporaryDirectory.path;
      }
      throw StateError('Unexpected path request: ${call.method}');
    });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await temporaryDirectory.delete(recursive: true);
  });

  test('writes complete PNG to temporary storage with explicit image MIME',
      () async {
    final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    final file = await InviteCardShareService.writePng(bytes);
    expect(file.path.startsWith(temporaryDirectory.path), isTrue);
    expect(file.path.endsWith('.png'), isTrue);
    expect(file.mimeType, 'image/png');
    expect(await File(file.path).readAsBytes(), bytes);
    // share_plus clears its own share_plus/ folder before copying the source.
    expect(
        file.path.contains(
            '${Platform.pathSeparator}share_plus${Platform.pathSeparator}'),
        isFalse);
    final second = await InviteCardShareService.writePng(bytes);
    expect(second.path, isNot(file.path));
    expect(await File(file.path).exists(), isTrue);
  });
}
