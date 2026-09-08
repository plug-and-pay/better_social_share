## 0.1.1

* iOS: add Swift Package Manager support. The plugin now ships a
  `Package.swift` alongside the podspec, so it works with Flutter's SPM
  integration as well as CocoaPods.

## 0.1.0

Initial release — a modern replacement for `appinio_social_share`.

* Share to WhatsApp, Telegram, Instagram (direct, feed, reels, story),
  Facebook (feed on Android, story on both), Messenger, TikTok (Android),
  X, SMS, clipboard, and the system share sheet.
* Every method returns a typed `ShareResult` (`success`, `appNotInstalled`,
  `permissionDenied`, `dismissed`, `error`) — no silent failures.
* Instagram/Facebook story sharing needs only a Meta App ID string — no
  Facebook SDK dependency.
* Zero Android host setup: the plugin ships its own `FileProvider` and
  package-visibility `<queries>`.
* X sharing on iOS uses the tweet intent (the `SLComposeViewController` API
  used by older plugins was removed in iOS 16).
* Null story fields are stripped on both the Dart and native side, fixing the
  broken "empty link sticker" seen with other plugins.
* Opt-in `compat.dart` layer mirroring the `appinio_social_share` API for
  one-line migration.
