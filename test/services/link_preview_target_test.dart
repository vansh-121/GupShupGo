// Which destinations the link-preview fetcher is allowed to contact.
//
// This is the one part of the unfurler an attacker chooses. The user pastes a
// link; the service then requests whatever that page's redirects and `og:image`
// name. A GET fired from inside the user's network at an address they never
// typed is the thing being prevented here, so the interesting assertions are the
// ones that say *blocked* — and specifically the encodings of "localhost" that
// look public until you decode them: an IPv4-mapped IPv6 address, a NAT64
// prefix, the cloud metadata link-local.
//
// Only the address predicate is exercised. `_isPermittedTarget`'s other half is
// a DNS lookup, which a unit test must not depend on; the seam is that hostnames
// are judged by this same function once resolved.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/link_preview_service.dart';

/// Judges a URL the way the fetcher does for an IP-literal host: parse the
/// authority out of the URI, then run the address predicate over it. Fails
/// loudly rather than returning a bool if the host was not a literal, so a typo
/// in a test case cannot read as "allowed".
bool blocksLiteral(String url) {
  final host = Uri.parse(url).host;
  final address = InternetAddress.tryParse(host);
  expect(address, isNotNull, reason: '$host did not parse as an IP literal');
  return LinkPreviewService.isBlockedAddress(address!);
}

bool blocks(String ip) =>
    LinkPreviewService.isBlockedAddress(InternetAddress(ip));

void main() {
  group('blocks non-routable IPv4', () {
    test('loopback', () {
      expect(blocks('127.0.0.1'), isTrue);
      expect(blocks('127.1.2.3'), isTrue);
    });

    test('RFC1918 private ranges', () {
      expect(blocks('10.0.0.1'), isTrue);
      expect(blocks('172.16.0.1'), isTrue);
      expect(blocks('172.31.255.255'), isTrue);
      expect(blocks('192.168.1.1'), isTrue);
    });

    test('link-local, including the cloud metadata address', () {
      expect(blocks('169.254.0.1'), isTrue);
      expect(blocks('169.254.169.254'), isTrue);
    });

    test('CGNAT', () {
      expect(blocks('100.64.0.1'), isTrue);
      expect(blocks('100.127.255.255'), isTrue);
    });

    test('this-network, multicast, broadcast', () {
      expect(blocks('0.0.0.0'), isTrue);
      expect(blocks('224.0.0.1'), isTrue);
      expect(blocks('255.255.255.255'), isTrue);
    });

    test('documentation and benchmarking ranges', () {
      expect(blocks('192.0.2.1'), isTrue);
      expect(blocks('198.18.0.1'), isTrue);
      expect(blocks('198.51.100.1'), isTrue);
      expect(blocks('203.0.113.1'), isTrue);
    });
  });

  group('allows ordinary public IPv4', () {
    test('addresses just outside each blocked range', () {
      expect(blocks('8.8.8.8'), isFalse);
      expect(blocks('1.1.1.1'), isFalse);
      // 172.15/172.32 and 100.63/100.128 bracket the two ranges whose bounds
      // are easy to fencepost.
      expect(blocks('172.15.0.1'), isFalse);
      expect(blocks('172.32.0.1'), isFalse);
      expect(blocks('100.63.255.255'), isFalse);
      expect(blocks('100.128.0.1'), isFalse);
      expect(blocks('192.167.1.1'), isFalse);
      expect(blocks('192.169.1.1'), isFalse);
      expect(blocks('223.255.255.255'), isFalse);
    });
  });

  group('blocks non-routable IPv6', () {
    test('loopback and unspecified', () {
      expect(blocks('::1'), isTrue);
      expect(blocks('::'), isTrue);
    });

    test('link-local and unique-local', () {
      expect(blocks('fe80::1'), isTrue);
      expect(blocks('fd00::1'), isTrue);
      expect(blocks('fc00::1'), isTrue);
    });

    test('an IPv4-mapped private address is judged as IPv4', () {
      expect(blocks('::ffff:127.0.0.1'), isTrue);
      expect(blocks('::ffff:192.168.1.1'), isTrue);
      expect(blocks('::ffff:169.254.169.254'), isTrue);
    });

    test('a NAT64-embedded private address is judged as IPv4', () {
      expect(blocks('64:ff9b::127.0.0.1'), isTrue);
      expect(blocks('64:ff9b::10.0.0.1'), isTrue);
    });

    test('but a mapped public address is still allowed', () {
      expect(blocks('::ffff:8.8.8.8'), isFalse);
      expect(blocks('64:ff9b::8.8.8.8'), isFalse);
    });
  });

  group('allows public IPv6', () {
    test('documented public addresses', () {
      expect(blocks('2001:4860:4860::8888'), isFalse);
      expect(blocks('2606:4700:4700::1111'), isFalse);
    });
  });

  group('as reached through a URL', () {
    test('bracketed IPv6 literals are judged, not skipped', () {
      expect(blocksLiteral('http://[::1]/admin'), isTrue);
      expect(blocksLiteral('http://[::ffff:127.0.0.1]:8080/'), isTrue);
      expect(blocksLiteral('https://[2001:4860:4860::8888]/'), isFalse);
    });

    test('a router admin page behind a plausible path', () {
      expect(blocksLiteral('http://192.168.1.1/setup.cgi?reset=1'), isTrue);
    });

    test('a port does not change the verdict', () {
      expect(blocksLiteral('http://127.0.0.1:3000/'), isTrue);
      expect(blocksLiteral('http://8.8.8.8:8080/'), isFalse);
    });
  });
}
