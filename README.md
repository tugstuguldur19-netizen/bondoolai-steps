# Бондоолой

A step-counter game: a chubby character in the center of the screen slims
down as you walk. Set a daily step goal (default 10,000), watch rewarded
ads to earn coins, and spend coins on clothes for him in the shop.

## Features implemented

- **Live step counter** using the phone's hardware step sensor
  (`pedometer` package), reset automatically each day.
- **Daily goal** (default 10,000 steps), editable in Settings, with quick
  presets.
- **Character** that visibly slims down as today's steps approach the goal
  (`lib/widgets/character_painter.dart`). It's drawn procedurally (no image
  assets) so it's trivial to swap in real artwork later — see below.
- **Coins**: watch a rewarded video ad, get 25 coins.
- **Shop**: 12 clothing items (hats, tops, bottoms, shoes, glasses) to buy
  with coins and equip/unequip on the character.
- All state (goal, coins, owned/equipped items, today's steps) persists
  locally via `shared_preferences`.

## ⚠️ About the ads

The app ships with **Google's official public test ad unit IDs**
(`lib/state/ad_service.dart` and the `AndroidManifest.xml` App ID). These
show real placeholder test ads and are safe to use for testing — they will
**not** earn real money. Before publishing:

1. Create an AdMob account and app at https://admob.google.com
2. Replace the App ID in `android/app/src/main/AndroidManifest.xml`
   (`com.google.android.gms.ads.APPLICATION_ID`) with your real AdMob App ID.
3. Replace `rewardedAdUnitId` in `lib/state/ad_service.dart` with your real
   rewarded ad unit ID.

## Building the APK (automatic, via GitHub Actions)

Every push to `main`/`master` triggers `.github/workflows/build-apk.yml`,
which builds both a debug and release APK on GitHub's servers and uploads
them as workflow artifacts. To get the APK:

1. Go to this repo's **Actions** tab → the latest "Build APK" run.
2. Scroll to **Artifacts** and download `bondoolai-debug-apk` (simplest —
   pre-signed, installs straight onto a device) or `bondoolai-release-apk`.
3. Unzip the download to get the `.apk`, then install it on your phone
   (see "Installing on your phone" below).

You can also trigger a build manually from the Actions tab
("Run workflow") without pushing new code.

## Building the APK (locally)

This project is a standard Flutter app. It could not be compiled in the
sandbox that generated it (no network access to Google's Android SDK/Maven
servers), so build it on a machine with normal internet access:

1. Install Flutter: https://docs.flutter.dev/get-started/install
   (this also requires the Android SDK — Android Studio's installer sets
   this up for you, or use `sdkmanager` directly).
2. From the project root:

   ```bash
   flutter pub get
   flutter build apk --debug
   ```

   The APK will be at `build/app/outputs/flutter-apk/app-debug.apk`.
   Debug builds are pre-signed with the Flutter debug key, so they install
   straight onto a device with no extra setup — ideal for testing.

   For a smaller, optimized build instead, run `flutter build apk --release`
   (this project's `android/app/build.gradle` is configured to sign release
   builds with the debug key too, so it stays installable without setting
   up your own signing key).

3. Run `flutter doctor` first if either command complains about missing
   tooling — it tells you exactly what's missing (Android SDK, licenses,
   etc.) and how to fix it.

## Installing on your phone

- **Via USB + adb**: enable Developer Options → USB debugging on the
  phone, connect it, then run `adb install build/app/outputs/flutter-apk/app-debug.apk`.
- **Without a cable**: copy the `.apk` file to the phone (e.g. via a
  messaging app, cloud drive, or `adb push`), open it on the phone, and
  allow "install from unknown sources" when prompted.

The app will ask for the **Physical activity** permission on first launch
(required on Android 10+ to read the step sensor) — allow it, or step
counting won't update.

## Where to plug in real character art later

`lib/widgets/character_painter.dart` draws the character with a
`CustomPainter` driven by a single `chubbiness` value (0.15 = slimmest,
1.0 = chubbiest) and a map of equipped clothing per slot. To swap in real
artwork (sprite sheets, Rive, or layered PNGs), replace `CharacterWidget`'s
body — everything else (`GameState.chubbiness`, the shop, persistence)
stays the same since they only depend on that one value and the equipped-
items map.
