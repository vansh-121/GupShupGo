// Unit tests for the pure helpers behind the mesh file path.
//
// These three functions were pulled out of `mesh_network_service.dart` so they
// could be tested at all: that file imports `nearby_connections`,
// `firebase_storage` and `device_info_plus`, none of which exist in a plain Dart
// test. Two of them guard real defects — a path-traversal write and a document
// reconciled without its key — so they are worth pinning down here rather than
// on a pair of devices.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/mesh_file_utils.dart';

void main() {
  group('sanitiseMeshFileName', () {
    test('strips a traversal prefix down to the basename', () {
      expect(sanitiseMeshFileName('../../databases/app.db'), 'app.db');
      expect(sanitiseMeshFileName('/etc/passwd'), 'passwd');
      // A tampered peer may use Windows separators regardless of its platform.
      expect(sanitiseMeshFileName(r'..\..\secrets\key.pem'), 'key.pem');
    });

    test('leaves an ordinary filename alone', () {
      expect(sanitiseMeshFileName('Invoice.pdf'), 'Invoice.pdf');
      expect(sanitiseMeshFileName('1737000000000_ab12cd.docx'),
          '1737000000000_ab12cd.docx');
    });

    test('replaces characters that have no business in a path', () {
      expect(sanitiseMeshFileName('Q3 report (final).pdf'),
          'Q3_report__final_.pdf');
      expect(sanitiseMeshFileName('résumé.pdf'), 'r_sum_.pdf');
    });

    test('refuses a leading dot, so no hidden file and no bare ..', () {
      expect(sanitiseMeshFileName('.bashrc'), 'bashrc');
      // `..` survives basename-ing, and would resolve to the parent directory.
      expect(sanitiseMeshFileName('..'), isNot(contains('..')));
      expect(sanitiseMeshFileName('..'), isNot(startsWith('.')));
    });

    test('clamps a long name but keeps its extension', () {
      final long = '${'a' * 500}.pdf';
      final out = sanitiseMeshFileName(long);
      expect(out.length, kMaxMeshFileNameChars);
      expect(out, endsWith('.pdf'));
    });

    test('falls back to a generated name when nothing usable survives', () {
      final out = sanitiseMeshFileName('');
      expect(out, isNotEmpty);
      expect(out, endsWith('.bin'));

      // `/` basenames to the empty string, and `.` is stripped by the dot rule.
      expect(sanitiseMeshFileName('/', fallbackExt: 'pdf'), endsWith('.pdf'));
      expect(sanitiseMeshFileName('.'), isNotEmpty);
    });
  });

  group('meshDirNameForType', () {
    test('gives each file type its own directory', () {
      expect(meshDirNameForType(MessageType.image), 'mesh_images');
      expect(meshDirNameForType(MessageType.audio), 'mesh_audio');
      expect(meshDirNameForType(MessageType.video), 'mesh_videos');
      expect(meshDirNameForType(MessageType.document), 'mesh_documents');
    });

    test('a non-file type falls back to the images directory', () {
      // Text and location carry no file at all, so they never reach the FILE
      // channel — but the switch has to be exhaustive for the receiver.
      expect(meshDirNameForType(MessageType.text), 'mesh_images');
      expect(meshDirNameForType(MessageType.location), 'mesh_images');
    });
  });

  group('meshMessageNeedsUpload', () {
    test('a document keys on its media key, not a URL', () {
      // The mesh never uploads a document; reconciliation encrypts it. Until the
      // bundle exists the message must stay pending — committing it would be a
      // bubble the receiver can never decrypt.
      expect(
        meshMessageNeedsUpload(MessageType.document,
            localFilePath: '/docs/mesh_documents/1_a.pdf'),
        isTrue,
      );
      expect(
        meshMessageNeedsUpload(MessageType.document,
            localFilePath: '/docs/mesh_documents/1_a.pdf',
            mediaKey: const <String, dynamic>{}),
        isTrue,
        reason: 'an empty map is not a bundle',
      );
      expect(
        meshMessageNeedsUpload(MessageType.document,
            localFilePath: '/docs/mesh_documents/1_a.pdf',
            mediaKey: const {'k': 'x', 'i': 'y', 'h': 'z', 'u': 'url', 's': 42}),
        isFalse,
      );
      expect(
        meshMessageNeedsUpload(MessageType.document,
            localFilePath: '/docs/mesh_documents/1_a.pdf',
            mediaUrl: 'https://example.com/doc'),
        isTrue,
        reason: 'a plaintext URL is not what a document is waiting for',
      );
    });

    test('image, audio and video key on the URL', () {
      for (final type in [
        MessageType.image,
        MessageType.audio,
        MessageType.video,
      ]) {
        expect(meshMessageNeedsUpload(type, localFilePath: '/docs/f'), isTrue,
            reason: '$type with no URL');
        expect(
          meshMessageNeedsUpload(type,
              localFilePath: '/docs/f', mediaUrl: 'https://example.com/f'),
          isFalse,
          reason: '$type with a URL',
        );
      }
    });

    test('a message with no local file is never waiting on an upload', () {
      expect(meshMessageNeedsUpload(MessageType.document), isFalse);
      expect(meshMessageNeedsUpload(MessageType.image), isFalse);
      expect(meshMessageNeedsUpload(MessageType.text), isFalse);
      // A location pin carries coordinates, never a file.
      expect(
        meshMessageNeedsUpload(MessageType.location,
            localFilePath: '/docs/somehow'),
        isFalse,
      );
    });
  });
}
