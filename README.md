# better_social_share

Share text, images, and videos **directly** to WhatsApp, Instagram, Facebook,
Messenger, Telegram, TikTok, X, and SMS from Flutter — with **typed results
instead of silent failures**, and **no Facebook SDK required**.

A modern replacement for the unmaintained `appinio_social_share`, fixing its
known bugs:

- ❌ appinio: methods return `Future<void>` and swallow every error → ✅ every
  method returns a `ShareResult` (`appNotInstalled`, `permissionDenied`,
  `dismissed`, `error`) so you can react in your UI.
- ❌ appinio: X/Twitter on iOS 16+ is completely broken (removed Apple API) →
  ✅ uses the tweet intent, which opens the X app when installed.
- ❌ appinio: Instagram stories show a broken empty link sticker (#318) →
  ✅ null story fields are stripped on both the Dart and native side.
- ❌ appinio: Android Instagram feed sharing targets an internal Instagram
  activity that breaks when Instagram updates → ✅ standard explicit intents.
- ❌ appinio: requires the Facebook SDK + App ID setup for everyone →
  ✅ zero SDK; stories only need your Meta App ID *string*.
- ❌ appinio: host apps must configure a FileProvider and `<queries>` →
  ✅ the plugin ships both; **zero Android setup**.

## Platform support

| Method | Android | iOS | Notes |
|---|:--:|:--:|---|
| `getInstalledApps` / `isAppInstalled` | ✅ | ✅ | iOS needs `LSApplicationQueriesSchemes` (below) |
| `shareToWhatsApp` | ✅ text+files | ✅ text *or* one file | iOS: file wins when both given |
| `shareToTelegram` | ✅ text+files | ✅ text only | |
| `shareToInstagramDirect` | ✅ | ✅ | |
| `shareToInstagramFeed` | ✅ | ✅ | iOS saves to Photos first (permission prompt) |
| `shareToInstagramReels` | ✅ | ✅ | |
| `shareToInstagramStory` | ✅ | ✅ | needs Meta App ID string, no SDK |
| `shareToFacebook` | ✅ files | ❌ `UNAVAILABLE` | FB strips pre-filled text by policy |
| `shareToFacebookStory` | ✅ | ✅ | needs Meta App ID string, no SDK |
| `shareToMessenger` | ✅ | ✅ | iOS: links only |
| `shareToTikTokStatus` / `shareToTikTokPost` | ✅ | ❌ `UNAVAILABLE` | |
| `shareToX` | ✅ text+files | ✅ text only | |
| `shareToSms` | ✅ | ✅ | |
| `copyToClipboard` | ✅ | ✅ | |
| `shareToSystem` | ✅ | ✅ | reports `dismissed` when cancelled |

Unsupported combinations return a typed `ShareResult` with code
`UNAVAILABLE` — never a silent no-op.

## Install

```yaml
dependencies:
  better_social_share: ^0.1.0
```

## Setup

### Android

**None.** The plugin ships its own `FileProvider` and the package-visibility
`<queries>` entries; the manifest merger adds them to your app automatically.

### iOS

Add the URL schemes you want to detect/share to in `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
	<string>whatsapp</string>
	<string>tg</string>
	<string>instagram</string>
	<string>instagram-stories</string>
	<string>instagram-reels</string>
	<string>fb</string>
	<string>facebook-stories</string>
	<string>fb-messenger</string>
	<string>twitter</string>
</array>
```

For Instagram **feed** sharing (which saves media to the photo library first):

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Images are saved to your photo library so they can be shared to Instagram.</string>
```

## Usage

```dart
import 'package:better_social_share/better_social_share.dart';

const share = BetterSocialShare();

// Which apps can I share to?
final apps = await share.getInstalledApps();
if (apps[SocialApp.whatsapp] ?? false) {
  final result = await share.shareToWhatsApp(message: 'Hello!');
  if (!result.isSuccess) {
    print('Share failed: ${result.status} ${result.errorMessage}');
  }
}

// Instagram story — only your Meta App ID string is needed, no Facebook SDK.
await share.shareToInstagramStory(
  appId: '1234567890',
  options: StoryOptions(
    stickerImagePath: '/path/to/sticker.png',
    backgroundTopColor: const Color(0xFF6200EE),
    backgroundBottomColor: const Color(0xFFFF9800),
    attributionUrl: Uri.parse('https://your.app/link'),
  ),
);
```

### Handling results

```dart
final result = await share.shareToInstagramFeed(['/path/to/image.jpg']);
switch (result.status) {
  case ShareResultStatus.success:
    break;
  case ShareResultStatus.appNotInstalled:
    // Offer the system share sheet instead.
    await share.shareToSystem(message: 'Look at this!', filePaths: paths);
  case ShareResultStatus.permissionDenied:
    // e.g. Photos access denied on iOS — tell the user why it's needed.
  case ShareResultStatus.dismissed:
  case ShareResultStatus.error:
    // Inspect result.errorCode / result.errorMessage.
}
```

### Stories and the Meta App ID

Instagram and Facebook require an App ID to accept story content, but **not**
the Facebook SDK — create an app at
[developers.facebook.com](https://developers.facebook.com) and pass its ID
string. Tappable attribution links (`attributionUrl`) are subject to Meta's
own rules and may require app review.

Facebook **feed** posts with a pre-filled link/quote genuinely require the
Facebook SDK `ShareDialog`; that lives in the optional companion package
`better_social_share_facebook` (coming separately) so this package stays
SDK-free.

## Migrating from appinio_social_share

Fast path — the compat layer mirrors appinio's API and string results:

```dart
// Before: import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:better_social_share/compat.dart';

// Before: final share = AppinioSocialShare();
final share = AppinioSocialShareCompat();
// shareToWhatsapp / shareToInstagramStory / copyToClipBoard etc. keep working.
```

Then migrate to the typed API at your own pace:

| appinio | better_social_share |
|---|---|
| `shareToWhatsapp(msg, filePaths)` | `shareToWhatsApp(message:, filePaths:)` |
| `shareImageToWhatsApp(path)` (iOS-only) | `shareToWhatsApp(filePaths: [path])` |
| `shareToTwitter(...)` | `shareToX(...)` |
| `shareToInstagramReel([paths])` | `shareToInstagramReels(videoPath)` |
| `shareToInstagramStory(appId, sticker, ...)` | `shareToInstagramStory(appId:, options: StoryOptions(...))` |
| `copyToClipBoard(msg)` | `copyToClipboard(text)` |
| returns `Future<String>` | returns `Future<ShareResult>` |

## Example

The [`example/`](example/) app has a button per method, file pickers, and
shows every `ShareResult` in a snackbar — it doubles as a manual QA harness.

## Issues & contributions

File issues and PRs on the repository. Sharing behavior ultimately depends on
the target apps; when Instagram/WhatsApp/TikTok change their intents or URL
schemes, an issue with device + app version details helps a lot.
