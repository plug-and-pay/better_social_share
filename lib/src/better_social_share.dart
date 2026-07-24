import 'package:flutter/services.dart';

import 'models/share_result.dart';
import 'models/social_app.dart';
import 'models/story_options.dart';

/// Share text, images, and videos directly to installed social apps.
///
/// Every method returns a [ShareResult] describing what actually happened —
/// a missing target app, a denied permission, or a native error is reported
/// instead of failing silently.
///
/// The class is const-constructible so it can be injected and mocked; for
/// quick use, `const BetterSocialShare()` anywhere is equivalent.
class BetterSocialShare {
  /// Creates a sharer backed by the default method channel.
  const BetterSocialShare();

  static const MethodChannel _channel = MethodChannel('better_social_share');

  /// Returns which supported social apps are installed on this device.
  ///
  /// On iOS this relies on `canOpenURL`, which requires the host app's
  /// `Info.plist` to list the corresponding `LSApplicationQueriesSchemes`
  /// entries (see package README); apps missing from that list are reported
  /// as not installed.
  Future<Map<SocialApp, bool>> getInstalledApps() async {
    final Map<Object?, Object?>? raw = await _channel
        .invokeMethod<Map<Object?, Object?>>('getInstalledApps');
    return <SocialApp, bool>{
      for (final SocialApp app in SocialApp.values)
        app: raw?[app.name] == true,
    };
  }

  /// Returns whether a single [app] is installed.
  ///
  /// Subject to the same iOS `LSApplicationQueriesSchemes` requirement as
  /// [getInstalledApps].
  Future<bool> isAppInstalled(SocialApp app) async {
    final bool? installed =
        await _channel.invokeMethod<bool>('isAppInstalled', <String, Object>{
      'app': app.name,
    });
    return installed ?? false;
  }

  /// Shares [message] and/or files to WhatsApp.
  ///
  /// Android supports text, text + files, and multiple files. iOS supports
  /// text (via URL scheme) or a single file (via WhatsApp's document
  /// interaction menu) per call; when both are given on iOS, the file wins
  /// because WhatsApp cannot accept both at once.
  Future<ShareResult> shareToWhatsApp({
    String? message,
    List<String> filePaths = const <String>[],
  }) {
    _requireContent(message, filePaths);
    return _invoke('shareToWhatsApp', <String, Object>{
      if (message != null) 'message': message,
      if (filePaths.isNotEmpty) 'filePaths': filePaths,
    });
  }

  /// Shares [message] and/or files to Telegram.
  Future<ShareResult> shareToTelegram({
    String? message,
    List<String> filePaths = const <String>[],
  }) {
    _requireContent(message, filePaths);
    return _invoke('shareToTelegram', <String, Object>{
      if (message != null) 'message': message,
      if (filePaths.isNotEmpty) 'filePaths': filePaths,
    });
  }

  /// Opens Instagram Direct with [message] ready to send.
  Future<ShareResult> shareToInstagramDirect(String message) {
    return _invoke('shareToInstagramDirect', <String, Object>{
      'message': message,
    });
  }

  /// Shares one or more images to the Instagram feed composer.
  ///
  /// On iOS the images are first saved to the photo library (requires
  /// `NSPhotoLibraryAddUsageDescription` in the host `Info.plist`); a denied
  /// permission is reported as [ShareResultStatus.permissionDenied].
  Future<ShareResult> shareToInstagramFeed(List<String> filePaths) {
    if (filePaths.isEmpty) {
      throw ArgumentError('shareToInstagramFeed requires at least one file.');
    }
    return _invoke('shareToInstagramFeed', <String, Object>{
      'filePaths': filePaths,
    });
  }

  /// Shares a video to the Instagram Reels composer.
  Future<ShareResult> shareToInstagramReels(String videoPath) {
    return _invoke('shareToInstagramReels', <String, Object>{
      'videoPath': videoPath,
    });
  }

  /// Shares to the Instagram story composer.
  ///
  /// [appId] is your Meta (Facebook) App ID — required by Instagram to
  /// accept story content. No Facebook SDK is needed, only the ID string.
  Future<ShareResult> shareToInstagramStory({
    required String appId,
    required StoryOptions options,
  }) {
    return _invoke('shareToInstagramStory', <String, Object>{
      'appId': appId,
      ...options.toMap(),
    });
  }

  /// Shares files (and best-effort [message]) to the Facebook app.
  ///
  /// Facebook strips pre-filled text from third-party shares by policy, so
  /// [message] is generally ignored by the Facebook composer. For link+quote
  /// posts via the official ShareDialog, use the companion
  /// `better_social_share_facebook` package.
  Future<ShareResult> shareToFacebook({
    String? message,
    List<String> filePaths = const <String>[],
  }) {
    _requireContent(message, filePaths);
    return _invoke('shareToFacebook', <String, Object>{
      if (message != null) 'message': message,
      if (filePaths.isNotEmpty) 'filePaths': filePaths,
    });
  }

  /// Shares to the Facebook story composer.
  ///
  /// [appId] is your Meta (Facebook) App ID; no Facebook SDK is needed.
  Future<ShareResult> shareToFacebookStory({
    required String appId,
    required StoryOptions options,
  }) {
    return _invoke('shareToFacebookStory', <String, Object>{
      'appId': appId,
      ...options.toMap(),
    });
  }

  /// Opens Facebook Messenger with [message] ready to send.
  Future<ShareResult> shareToMessenger(String message) {
    return _invoke('shareToMessenger', <String, Object>{'message': message});
  }

  /// Shares images/videos to TikTok's status composer. Android only; on iOS
  /// this resolves to [ShareResultStatus.error] with code `UNAVAILABLE`.
  Future<ShareResult> shareToTikTokStatus(List<String> filePaths) {
    if (filePaths.isEmpty) {
      throw ArgumentError('shareToTikTokStatus requires at least one file.');
    }
    return _invoke('shareToTikTokStatus', <String, Object>{
      'filePaths': filePaths,
    });
  }

  /// Shares a video to the TikTok post composer. Android only; on iOS this
  /// resolves to [ShareResultStatus.error] with code `UNAVAILABLE`.
  Future<ShareResult> shareToTikTokPost(String videoPath) {
    return _invoke('shareToTikTokPost', <String, Object>{
      'videoPath': videoPath,
    });
  }

  /// Shares to X (formerly Twitter).
  ///
  /// Android supports text and files via the X app. iOS uses the tweet web
  /// intent (opens the X app when installed): text only — [filePaths] are
  /// ignored on iOS.
  Future<ShareResult> shareToX({
    String? message,
    List<String> filePaths = const <String>[],
  }) {
    _requireContent(message, filePaths);
    return _invoke('shareToX', <String, Object>{
      if (message != null) 'message': message,
      if (filePaths.isNotEmpty) 'filePaths': filePaths,
    });
  }

  /// Opens the SMS composer with [message] and optional attachments.
  Future<ShareResult> shareToSms({
    String? message,
    List<String> filePaths = const <String>[],
  }) {
    _requireContent(message, filePaths);
    return _invoke('shareToSms', <String, Object>{
      if (message != null) 'message': message,
      if (filePaths.isNotEmpty) 'filePaths': filePaths,
    });
  }

  /// Copies [text] to the system clipboard.
  Future<ShareResult> copyToClipboard(String text) {
    return _invoke('copyToClipboard', <String, Object>{'text': text});
  }

  /// Opens the system share sheet with [message] and/or files.
  Future<ShareResult> shareToSystem({
    String? title,
    String? message,
    List<String> filePaths = const <String>[],
  }) {
    _requireContent(message, filePaths);
    return _invoke('shareToSystem', <String, Object>{
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (filePaths.isNotEmpty) 'filePaths': filePaths,
    });
  }

  static void _requireContent(String? message, List<String> filePaths) {
    if ((message == null || message.isEmpty) && filePaths.isEmpty) {
      throw ArgumentError('Provide a message and/or filePaths to share.');
    }
  }

  Future<ShareResult> _invoke(String method, Map<String, Object> args) async {
    try {
      final String? code = await _channel.invokeMethod<String>(method, args);
      if (code == 'DISMISSED') {
        return const ShareResult(ShareResultStatus.dismissed);
      }
      return const ShareResult.success();
    } on PlatformException catch (e) {
      return ShareResult(
        switch (e.code) {
          'APP_NOT_INSTALLED' => ShareResultStatus.appNotInstalled,
          'PERMISSION_DENIED' => ShareResultStatus.permissionDenied,
          'DISMISSED' => ShareResultStatus.dismissed,
          _ => ShareResultStatus.error,
        },
        errorCode: e.code,
        errorMessage: e.message,
      );
    } on MissingPluginException {
      return const ShareResult(
        ShareResultStatus.error,
        errorCode: 'UNAVAILABLE',
        errorMessage: 'better_social_share is not available on this platform.',
      );
    }
  }
}
