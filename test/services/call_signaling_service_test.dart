import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';

void main() {
  test('generated call channel ids are CallKit-compatible UUID v4 values', () {
    final ids =
        List.generate(100, (_) => CallSignalingService.generateChannelId());

    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(_isUuidV4(id), isTrue, reason: id);
    }
  });
}

bool _isUuidV4(String value) {
  final parts = value.split('-');
  if (parts.length != 5 ||
      parts[0].length != 8 ||
      parts[1].length != 4 ||
      parts[2].length != 4 ||
      parts[3].length != 4 ||
      parts[4].length != 12) {
    return false;
  }
  if (!parts[2].startsWith('4') || !'89ab'.contains(parts[3][0])) {
    return false;
  }
  // UUIDs contain 128 bits; Dart's native int cannot parse that entire value.
  return RegExp(r'^[0-9a-f]+$').hasMatch(parts.join());
}
