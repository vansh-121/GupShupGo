Profile links use Android's verified App Links when the app is installed. The
Firebase Hosting `/u/**` redirect sends other visitors to Google Play without
loading the Flutter web app. The static index supplies a clickable fallback.

Before publishing:

1. Copy the SHA-256 **app signing** certificate fingerprint from Play Console
   (App integrity). The upload certificate does not verify Play installations.
2. Run `node tool/generate_assetlinks.mjs "AA:BB:..."` with the full fingerprint.
   Additional fingerprints can be passed for key rotation.
3. Connect `gupshupgo.app` to this Firebase Hosting site and deploy the hosting
   configuration. Preserve any existing domain/site content when integrating.
4. Verify `https://gupshupgo.app/.well-known/assetlinks.json` returns HTTP 200,
   JSON and no redirect, then confirm `/u/example_user` redirects to Google Play.
5. On an installed Play build, run
   `adb shell pm verify-app-links --re-verify com.gupshupgo.app`, then
   `adb shell pm get-app-links com.gupshupgo.app`. The domain must be verified.
   Open a link with the app stopped and again with it running; each opens one
   profile after sign-in/onboarding. Other domains and malformed handles must
   not open a profile.

`assetlinks.json` now contains the app-signing fingerprint provided by the app
owner. Publishing it on the actual domain and verifying an installed Play build
remain required. The repository had no existing Hosting/domain configuration;
confirm the domain's host before deploying the prepared Firebase Hosting site.
