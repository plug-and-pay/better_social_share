# Plan: `better_social_share` — a modern, bug-free replacement for `appinio_social_share`

## Context

The user wants a Flutter plugin like [appinio_social_share](https://pub.dev/packages/appinio_social_share) with all the same social targets, but without its bugs (Instagram and WhatsApp sharing silently fail). Research confirmed appinio is effectively unmaintained (last release ~2 years ago) and its bugs have identifiable root causes. We build a new plugin, `better_social_share`, and publish it to pub.dev.

**Decisions made with the user:** Android + iOS only · Facebook SDK optional/hybrid · publish to pub.dev.

**Current state:** `/Users/kees/Documents/dev/Packages/BetterSocialShare/better_social_share` is a blank `flutter create --template=package` scaffold (boilerplate `Calculator` only, no plugin declaration, no android/ or ios/ dirs). Greenfield build.

## Root causes of appinio's bugs → design fixes

1. **Silent failures**: all methods `Future<void>`, native errors swallowed → every method returns `Future<ShareResult>`; native code always calls `result.error(code,…)` on failure.
2. **iOS WhatsApp** broken/inconsistent (text-only URL scheme + separate single-image method) → one unified method, routes internally.
3. **iOS Twitter** uses `SLComposeViewController` (removed in iOS 16, dead) → `https://twitter.com/intent/tweet` universal link.
4. **Instagram story broken link sticker (#318/#332)**: nil/empty pasteboard keys included → strip null keys in Dart AND native.
5. **iOS Instagram feed** silently fails on denied Photos permission → request `.addOnly` auth, report `PERMISSION_DENIED`.
6. **Android Instagram feed** hardcodes Instagram's internal `ComponentName` (breaks on IG updates) → plain `ACTION_SEND` + `setPackage()`.
7. **Facebook SDK forced on everyone** → zero-SDK main package (stories only need an App ID string, not the SDK); SDK isolated in optional add-on package.
8. **Outdated tooling** (compileSdk 31, minSdk 16, Java) → Kotlin, compileSdk 35, minSdk 21, AGP 8.x, Swift, iOS 13+.

## Architecture

**Single plugin + optional companion plugin** (federation rejected as overhead; compile-time flags rejected as un-expressible in pubspec):

- **`better_social_share`** (this dir): everything incl. IG/FB stories with attribution — zero Facebook SDK. `shareToFacebook` uses plain `ACTION_SEND` to `com.facebook.katana` (documented caveat: FB strips pre-filled text).
- **`better_social_share_facebook`** (sibling dir, built last, ships after 0.1.0): standalone plugin with its own channel; only what genuinely needs FBSDKShareKit/facebook-share — Facebook feed `ShareDialog` (link + quote + hashtag). Zero coupling to main package.

## Public Dart API

```
lib/better_social_share.dart          # barrel
lib/compat.dart                       # opt-in appinio compatibility layer (not in barrel)
lib/src/better_social_share.dart      # main API class, channel 'better_social_share'
lib/src/models/{share_result,social_app,story_options}.dart
lib/src/compat/appinio_social_share_compat.dart
```

- `enum ShareResultStatus { success, appNotInstalled, permissionDenied, dismissed, error }`; `class ShareResult { status, errorCode, errorMessage, isSuccess }`. Dart maps `PlatformException.code` (`APP_NOT_INSTALLED`, `PERMISSION_DENIED`, `FILE_NOT_FOUND`, `INVALID_ARGUMENT`, `UNAVAILABLE`, `UNKNOWN`) → status. Never throws for runtime conditions; `ArgumentError` only for programmer errors.
- `enum SocialApp { whatsapp, telegram, instagram, facebook, messenger, tiktok, x, sms }`
- `class BetterSocialShare` (const-constructible instance, mockable): `getInstalledApps() → Map<SocialApp,bool>`, `isAppInstalled(app)`, `shareToWhatsApp({message, filePaths})`, `shareToTelegram(…)`, `shareToInstagramDirect(message)`, `shareToInstagramFeed(filePaths)`, `shareToInstagramReels(videoPath)`, `shareToInstagramStory({appId, options})`, `shareToFacebook(…)`, `shareToFacebookStory({appId, options})`, `shareToMessenger(message)`, `shareToTikTokStatus(filePaths)` / `shareToTikTokPost(videoPath)` (Android-only → `UNAVAILABLE` on iOS), `shareToX(…)`, `shareToSms(…)`, `copyToClipboard(text)`, `shareToSystem({title, message, filePaths})`.
- `class StoryOptions { stickerImagePath, backgroundImagePath, backgroundVideoPath, backgroundTopColor/BottomColor (Color→#RRGGBB), attributionUrl }` — asserts ≥1 content field; `toMap()` **omits null keys** (fix for appinio #318).
- Compat layer `AppinioSocialShareCompat`: appinio's exact names + `Future<String>` returns ("SUCCESS"/"ERROR"/"NOT INSTALLED"), all `@Deprecated`, delegating to new API → one-line migration.
- Channel method names mirror Dart names 1:1; args as maps with null keys omitted.

## Android native (Kotlin)

- `android/build.gradle`: AGP 8.7+, Kotlin 2.0+, compileSdk 35, minSdk 21, namespace `com.bettersocialshare.better_social_share`; only dep `androidx.core`.
- Files under `android/src/main/kotlin/com/bettersocialshare/better_social_share/`: `BetterSocialSharePlugin.kt` (FlutterPlugin + ActivityAware, dispatch), `ShareError.kt`, `FileShareHelper.kt`, `InstalledApps.kt`, and `targets/{WhatsApp,Telegram,Instagram,Facebook,Messenger,TikTok,X,Sms,System,Clipboard}Target.kt`.
- Per-target pattern: check installed via PackageManager → `result.error("APP_NOT_INSTALLED")`; explicit intent with `setPackage()` (never ComponentName); try/catch `ActivityNotFoundException`/`SecurityException` → `result.error`; success after launch.
- Intent matrix: WhatsApp/Telegram/X/Messenger/IG-direct/IG-feed = `ACTION_SEND(_MULTIPLE)` + `setPackage`; IG reels = `com.instagram.share.ADD_TO_REEL`; IG story = `com.instagram.share.ADD_TO_STORY` with `source_application`, optional `interactive_asset_uri`/`top_background_color`/`bottom_background_color`/`content_url` (**only non-null extras**); FB story = `com.facebook.stories.ADD_TO_STORY` + `com.facebook.platform.extra.APPLICATION_ID`; TikTok = ACTION_SEND to `com.zhiliaoapp.musically` (fallback `com.ss.android.ugc.trill`); SMS = `ACTION_SENDTO smsto:` or default-SMS-app ACTION_SEND for files; System = `Intent.createChooser`.
- **Zero host-app setup**: plugin manifest ships its own FileProvider (authority `${applicationId}.better_social_share.fileprovider`, cache-path xml) — `FileShareHelper` copies inputs to `cacheDir/better_social_share/` then grants URI permissions; plugin manifest also ships the full `<queries>` block (manifest merger handles both).

## iOS native (Swift, iOS 13+, no deps)

- `ios/Classes/`: `BetterSocialSharePlugin.swift`, `ShareError.swift` (codes match Android), `AppAvailability.swift` (scheme map + `canOpenURL`), `StoryPasteboardSharer.swift`, `targets/{WhatsApp,Telegram,Instagram,Facebook,Messenger,X,Sms,System,Clipboard}Sharer.swift`. Podspec + optional SPM support.
- Every method: `canOpenURL` check → `APP_NOT_INSTALLED` (host must add `LSApplicationQueriesSchemes` — copy-paste block in README; a plugin cannot inject Info.plist keys).
- WhatsApp: text via `whatsapp://send?text=`; files via `UIDocumentInteractionController` (UTI `net.whatsapp.image`/`.video`, strong ref held, cancel → `dismissed`). X: `https://twitter.com/intent/tweet` (app opens if installed, web otherwise). IG feed: `PHPhotoLibrary` `.addOnly` auth (denied → `PERMISSION_DENIED`) → save → `instagram://library?LocalIdentifier=`. Stories: `StoryPasteboardSharer` builds nil-safe `com.instagram.sharedSticker.*`/`com.facebook.sharedSticker.*` dict, `UIPasteboard.setItems` with 5-min expiration, open `instagram-stories://share?source_application=APPID` / `facebook-stories://share?appId=APPID`. SMS: `MFMessageComposeViewController` with delegate → success/dismissed/error. System: `UIActivityViewController` with completion handler + iPad popover anchor (avoids iPad crash). TikTok: `UNAVAILABLE`.

## Example app (`example/`)

Flutter app (android+ios) with: installed-apps chips, message TextField, `image_picker` for images/video, FB App ID + attribution URL fields, one button per API method grouped per app, every `ShareResult` shown in a SnackBar. Its manifest/Info.plist follow the README setup exactly (dogfoods the docs). Doubles as the manual QA harness.

## Testing

- Dart unit tests with mocked method channel: method-name/argument contracts, `PlatformException` → status mapping, **StoryOptions null-key omission (regression test for appinio #318)**, color serialization, compat-layer delegation.
- Android: Robolectric tests for `FileShareHelper` + intent construction. iOS: XCTest for `StoryPasteboardSharer` dict building.
- Manual QA matrix in `example/README.md` (app × content type × OS) — external-app launches can't be automated.
- CI (GitHub Actions): analyze, test, example builds (apk + ios --no-codesign), `dart pub publish --dry-run`.

## pub.dev readiness

- pubspec: description, repository/issue_tracker, `topics`, `flutter.plugin.platforms` block, env `sdk: ^3.3.0` / `flutter: >=3.19.0`, version 0.1.0.
- README: feature/platform table with caveats (TikTok Android-only, FB text stripped, X iOS no files) → install → setup (iOS plist blocks; Android "no setup needed") → usage per target → ShareResult handling → stories/App ID explainer → migration-from-appinio table.
- CHANGELOG 0.1.0, MIT LICENSE (replace TODO placeholder), `analysis_options.yaml` with flutter_lints + `public_member_api_docs`, dartdoc on all public members.

## Ordered milestones

1. **Scaffold → plugin**: rewrite pubspec (plugin block), delete Calculator, create models + main API class + barrel, analysis_options, MIT LICENSE.
2. **Dart unit tests** (locks channel contract before native work).
3. **Android**: gradle + manifest (provider/paths/queries) → plugin/helpers → targets in order System+Clipboard → WhatsApp/Telegram/X/SMS → Instagram (all modes) → Facebook/Messenger → TikTok.
4. **Example app** alongside Android; manual device test per target.
5. **iOS**: podspec → plugin/helpers → same target order → XCTest for story sharer; manual device test (URL schemes need real device + apps).
6. **Compat layer** + tests.
7. **Docs & release**: README, CHANGELOG, CI, `dart pub publish --dry-run`, publish 0.1.0.
8. **`better_social_share_facebook` add-on** (sibling package, post-0.1.0): FBSDKShareKit/facebook-share `ShareDialog` feed posts, own README (FB App ID + client token setup).

Open items flagged for verification during implementation (not blockers): exact current params for `fb-messenger://share` and `instagram-reels://share`, Telegram iOS file support, TikTok Android package fallbacks — validate on device, adjust docs/`UNAVAILABLE` accordingly.

## Verification

- `flutter analyze` and `flutter test` clean in the plugin (all channel-contract + regression tests green).
- Android: `cd example && flutter build apk --debug`; run on device/emulator, exercise each button, confirm SnackBar shows `success` for installed apps and `appNotInstalled` (not silence) for missing ones.
- iOS: `flutter build ios --no-codesign`; manual run on a real device with WhatsApp/Instagram installed — verify WhatsApp text+image, IG feed (incl. denied-permission → `permissionDenied`), IG story with and without attribution URL (no empty link sticker).
- `dart pub publish --dry-run` passes with no warnings.
