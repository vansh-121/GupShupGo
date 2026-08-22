// Character-class detection for the vault PIN.
//
// isNumericPin decides one thing: the value written to the `pinIsNumeric` flag,
// which in turn decides which keyboard the unlock field opens with. Nothing is
// enforced on the field itself — every PIN field in the app accepts any
// characters, because the PIN is an Argon2id passphrase and older vaults were
// created with letters in them. So a wrong answer here costs one tap on the
// "Use letters instead" toggle, never access.
//
// It is still worth pinning down, because the failure it prevents is invisible
// until reinstall: the flag is read on a cold start, months after the PIN was
// set, and a false positive there shows a number pad — which on some Android
// keyboards has no ABC key — to someone whose PIN contains a letter.
//
// Pure-function test, matching the convention the rest of the crypto suite
// follows (see vault_pin_custody_test.dart) — the writes around it need
// Firestore and are covered by the manual matrix instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/crypto/vault_cipher.dart';

void main() {
  group('VaultCipher.isNumericPin', () {
    test('all-digit PINs are numeric', () {
      for (final pin in ['123456', '0', '000000', '9876543210', '1111111111']) {
        expect(VaultCipher.isNumericPin(pin), isTrue, reason: pin);
      }
    });

    test('a single non-digit anywhere disqualifies the whole PIN', () {
      // Position matters for the implementation (it scans every rune), so probe
      // the front, the middle and the tail.
      for (final pin in ['a12345', '123a56', '12345a']) {
        expect(VaultCipher.isNumericPin(pin), isFalse, reason: pin);
      }
    });

    test('passphrases and mixed PINs are not numeric', () {
      for (final pin in ['hunter2', 'correct horse', 'P@ssw0rd', 'abcdef']) {
        expect(VaultCipher.isNumericPin(pin), isFalse, reason: pin);
      }
    });

    test('an empty PIN is not numeric', () {
      // Never reachable through the UI — every field rejects empty on submit —
      // but "no characters" must not read as "all characters are digits", which
      // is what a bare `every` would return.
      expect(VaultCipher.isNumericPin(''), isFalse);
    });

    test('characters that merely look numeric are not digits', () {
      // The check is on ASCII 0x30–0x39, not on Unicode numeric-ness. A number
      // pad cannot produce any of these, so treating them as digits would open
      // the wrong keyboard for a PIN that needs the full one.
      for (final pin in [
        '١٢٣٤٥٦', // Arabic-Indic digits
        '１２３４５６', // fullwidth digits
        '½', // vulgar fraction
        '12 34', // space
        '12.34', // decimal point
        '-1234', // sign
      ]) {
        expect(VaultCipher.isNumericPin(pin), isFalse, reason: pin);
      }
    });

    test('emoji do not slip through the range check', () {
      // Runes above the BMP are single runes with very high code points, so a
      // naive per-code-unit check could disagree with a per-rune one here.
      expect(VaultCipher.isNumericPin('🔑'), isFalse);
      expect(VaultCipher.isNumericPin('1234🔑'), isFalse);
    });
  });
}
