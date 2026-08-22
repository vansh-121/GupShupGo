// Custody classification for the vault PIN.
//
// The bug being guarded against: a build generated a random 6-digit vault PIN
// when the user tapped "Setup with Fingerprint", never showed it to them, and
// kept the only copy in secure storage — which uninstall wipes while the
// Firestore salt + verifier survive. Those users end up locked out of their own
// history with nothing but a destructive reset available.
//
// classifyPinCustody is the single branch that decides who gets rescued, so it
// is tested exhaustively: all 8 combinations of its three booleans. Deliberately
// a pure-function test, matching the convention the rest of the crypto suite
// follows (see test/services/chat_recovery_test.dart) — the surrounding flow
// needs Firestore, secure storage and local_auth, so it is covered by the manual
// matrix instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/crypto/vault_pin_custody.dart';

void main() {
  group('classifyPinCustody', () {
    test('no config → notSetUp, whatever else is true', () {
      // A stale stored PIN from a reset vault must not resurrect a prompt:
      // with no config doc there is nothing to unlock or re-key.
      for (final chosen in [false, true]) {
        for (final stored in [false, true]) {
          expect(
            classifyPinCustody(
              configExists: false,
              pinIsUserChosen: chosen,
              hasStoredPin: stored,
            ),
            VaultPinCustody.notSetUp,
            reason: 'chosen=$chosen stored=$stored',
          );
        }
      }
    });

    test('flag set → ok, with or without a stored PIN', () {
      // The no-stored-PIN half is the reinstalling user who already knows
      // their PIN. Getting this wrong nags every one of them.
      for (final stored in [false, true]) {
        expect(
          classifyPinCustody(
            configExists: true,
            pinIsUserChosen: true,
            hasStoredPin: stored,
          ),
          VaultPinCustody.ok,
          reason: 'stored=$stored',
        );
      }
    });

    test('flag unset but PIN still readable → rescueAvailable', () {
      // The affected install, caught before uninstall. Getting this wrong
      // means nobody is ever rescued.
      expect(
        classifyPinCustody(
          configExists: true,
          pinIsUserChosen: false,
          hasStoredPin: true,
        ),
        VaultPinCustody.rescueAvailable,
      );
    });

    test('flag unset and nothing stored → ownerMustSupply', () {
      // Nothing to re-key from; the unlock dialog already asks for the PIN,
      // so this must NOT be treated as rescueAvailable.
      expect(
        classifyPinCustody(
          configExists: true,
          pinIsUserChosen: false,
          hasStoredPin: false,
        ),
        VaultPinCustody.ownerMustSupply,
      );
    });

    test('only rescueAvailable ever triggers the blocking prompt', () {
      // Locks in the property the home_screen gate relies on: exactly one of
      // the eight input combinations may interrupt the user at launch.
      final blocking = <String>[];
      for (final config in [false, true]) {
        for (final chosen in [false, true]) {
          for (final stored in [false, true]) {
            final state = classifyPinCustody(
              configExists: config,
              pinIsUserChosen: chosen,
              hasStoredPin: stored,
            );
            if (state == VaultPinCustody.rescueAvailable) {
              blocking.add('config=$config chosen=$chosen stored=$stored');
            }
          }
        }
      }
      expect(blocking, ['config=true chosen=false stored=true']);
    });
  });
}
