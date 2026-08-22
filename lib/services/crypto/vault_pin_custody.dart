// VaultPinCustody — decides whether the app still needs to establish that the
// user actually knows their own vault PIN.
//
// Why this exists: a build shipped where tapping "Setup with Fingerprint" on a
// fresh install did not ask for a PIN — it generated a random 6-digit one,
// stored it in secure storage, and never showed it to the user. Because
// `allowBackup="false"` wipes local storage on uninstall while the salt +
// verifier survive in Firestore, those installs reach a state where the vault
// demands a PIN that nobody has ever seen, and the only remaining action is a
// full history-destroying reset.
//
// The signal we cannot use is "is a PIN stored locally?" — the old dialog wrote
// the PIN to secure storage after *every* successful unlock, so a stored PIN
// says nothing about where it came from. Guessing from its shape ("6 digits, all
// numeric") misfires in both directions: it flags a user whose real PIN is
// 123456, and nagging someone who knows their PIN is as harmful as stranding
// someone who does not.
//
// So custody is recorded positively instead, via `pinIsUserChosen` on the
// vaultMeta/config doc, set only at the moments that *prove* the user supplied
// the PIN (setup, changePin, or a typed unlock). This function maps that flag
// plus the two facts around it onto exactly one course of action.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The one secure-storage configuration every biometric-PIN caller must use.
///
/// The options are part of the addressing on both platforms: a caller that
/// builds its own `FlutterSecureStorage` with different options reads a
/// *different* store and silently finds no PIN. Share this instance rather
/// than re-declaring it.
const FlutterSecureStorage biometricPinStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Secure-storage key holding the user's PIN so biometrics can unwrap it on
/// this device. Its presence is the single source of truth for "fingerprint
/// unlock is enabled" — deliberately not a second flag that could drift out of
/// agreement with it.
///
/// The literal must not change: existing opted-in installs would stop finding
/// their PIN and be sent back to typing it.
String biometricPinKey(String uid) => 'vault_pin_$uid';

/// Marks that the user has already been offered fingerprint unlock and said no
/// (or later switched it off). Keeps the opt-in from reappearing after every
/// unlock; Vault settings stays the way back in.
String biometricOfferDismissedKey(String uid) => 'vault_bio_dismissed_$uid';

/// What, if anything, the app must do to put a user-known PIN in charge of the
/// vault.
enum VaultPinCustody {
  /// No vault config exists yet. The ordinary setup flow owns this case and
  /// will require a typed PIN, so there is nothing to repair.
  notSetUp,

  /// Custody is proven. Never prompt.
  ok,

  /// Custody unproven, but a PIN is still readable from secure storage — so it
  /// can be handed to `changePin` as the old PIN and the vault re-keyed onto
  /// one the user chooses, without losing a single entry.
  ///
  /// This window closes permanently the next time such an install is removed:
  /// the stored PIN goes with it and no rescue is possible afterwards.
  rescueAvailable,

  /// Custody unproven and no stored PIN to re-key from. Only the user can
  /// supply the secret now, and the unlock dialog is already asking for it —
  /// so this state shows no additional prompt. A second modal would add
  /// friction without adding any capability.
  ownerMustSupply,
}

/// Pure decision function — see [VaultPinCustody] for why each state exists.
///
/// [configExists] whether `vaultMeta/config` is present (i.e. the vault has
/// ever been set up). [pinIsUserChosen] the flag from that doc. [hasStoredPin]
/// whether `vault_pin_$uid` is readable from secure storage on this device.
VaultPinCustody classifyPinCustody({
  required bool configExists,
  required bool pinIsUserChosen,
  required bool hasStoredPin,
}) {
  if (!configExists) return VaultPinCustody.notSetUp;
  if (pinIsUserChosen) return VaultPinCustody.ok;
  return hasStoredPin
      ? VaultPinCustody.rescueAvailable
      : VaultPinCustody.ownerMustSupply;
}
