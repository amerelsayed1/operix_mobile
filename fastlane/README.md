# Fastlane — Android screenshots

Captures Espresso-driven screenshots of the Operix mobile app via
[fastlane screengrab](https://docs.fastlane.tools/getting-started/android/screenshots/).

## One-time setup

1. Install the Android SDK + an emulator image (API 30+ recommended) and make
   sure `adb`, `emulator`, and `ANDROID_HOME` are on your `PATH`.
2. Install Ruby (3.x) and bundler, then from the repo root:
   ```bash
   bundle install
   ```
3. Boot an emulator (or plug in a device with USB debugging):
   ```bash
   emulator -avd <YourAvd> &
   adb wait-for-device
   ```

## Capture screenshots

From the repo root, with exactly one device/emulator attached:

```bash
bundle exec fastlane android screenshots
```

This will:

1. `./gradlew composeApp:clean composeApp:assembleDebug composeApp:assembleDebugAndroidTest`
2. Install both APKs on the connected device
3. Run `me.amermahsoub.bfm.ScreenshotTest#captureAppTour`, which seeds a fake
   session and walks Dashboard → POS → Clients → Products → More → Settings,
   calling `Screengrab.screenshot(...)` at each stop
4. Pull the PNGs to `fastlane/metadata/android/en-US/images/phoneScreenshots/`

If you've already built the APKs and only want to re-run the tour:

```bash
bundle exec fastlane android capture
```

## What the screenshots show

The test seeds a synthetic session with broad permissions, so every bottom-nav
tab is visible. Because there is no live backend by default, list-heavy screens
(Clients, Products, Dashboard) render their empty / error states — that is
expected. To get populated screenshots, point the debug build at a real tenant
backend:

1. Put `BASE_URL=https://your-tenant.example.com` in `local.properties` (or
   however the `TenantAwareApiUrlBuilder` is configured in this repo).
2. Edit `ScreenshotTest.seedSession()` to call
   `TenantRepository.loginAndBootstrapSession(slug, username, password)`
   instead of seeding a fake `SessionBootstrap`.
3. Re-run the lane.

## Adding more screens

`ScreenshotTest.captureAppTour()` is the whole tour. To grab a detail screen,
tap through to it with `composeRule.onNodeWithText(...).performClick()` and
add another `Screengrab.screenshot("07_my_detail")` call. Names prefixed with
zero-padded numbers control the order in generated deliverables.

## Locales

The Screengrabfile is pinned to `en-US` for now. To also capture Arabic + RTL,
add `"ar-AE"` to the `locales([...])` array and grant
`android.permission.CHANGE_CONFIGURATION` in the debug manifest — already done.
You'll also want a `LocaleTestRule` in `ScreenshotTest` if you need per-test
locale switching beyond what screengrab handles at the framework level.
