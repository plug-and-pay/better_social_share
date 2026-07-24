import 'dart:ui' show Color;

import '../better_social_share.dart';
import '../models/share_result.dart';
import '../models/social_app.dart';
import '../models/story_options.dart';

/// Drop-in stand-in for the `AppinioSocialShare` class, easing migration
/// from the appinio_social_share package.
///
/// Method names, signatures, and string return values ("SUCCESS", "ERROR",
/// "NOT INSTALLED") mirror appinio's API. Every member is deprecated: switch
/// to [BetterSocialShare] for typed [ShareResult]s when convenient.
class AppinioSocialShareCompat {
  /// Creates the compatibility wrapper.
  const AppinioSocialShareCompat();

  static const BetterSocialShare _share = BetterSocialShare();

  static Future<String> _legacy(Future<ShareResult> future) async {
    final ShareResult result = await future;
    return switch (result.status) {
      ShareResultStatus.success => 'SUCCESS',
      ShareResultStatus.appNotInstalled => 'NOT INSTALLED',
      _ => 'ERROR',
    };
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    String value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'ff$value';
    final int? parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  static StoryOptions _storyOptions(
    String stickerImage,
    String? backgroundImage,
    String? backgroundVideo,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
  ) {
    return StoryOptions(
      stickerImagePath: stickerImage,
      backgroundImagePath: backgroundImage,
      backgroundVideoPath: backgroundVideo,
      backgroundTopColor: _parseColor(backgroundTopColor),
      backgroundBottomColor: _parseColor(backgroundBottomColor),
      attributionUrl:
          attributionURL == null ? null : Uri.tryParse(attributionURL),
    );
  }

  /// Legacy equivalent of [BetterSocialShare.getInstalledApps].
  @Deprecated('Use BetterSocialShare.getInstalledApps')
  Future<Map<String, bool>> getInstalledApps() async {
    final Map<SocialApp, bool> apps = await _share.getInstalledApps();
    return <String, bool>{
      for (final MapEntry<SocialApp, bool> e in apps.entries) e.key.name: e.value,
      // appinio used "twitter" rather than "x".
      'twitter': apps[SocialApp.x] ?? false,
    };
  }

  /// Legacy equivalent of [BetterSocialShare.shareToWhatsApp].
  @Deprecated('Use BetterSocialShare.shareToWhatsApp')
  Future<String> shareToWhatsapp(String message, {List<String>? filePaths}) =>
      _legacy(_share.shareToWhatsApp(
          message: message, filePaths: filePaths ?? const <String>[]));

  /// Legacy iOS-only single-image WhatsApp share; now works via the unified
  /// [BetterSocialShare.shareToWhatsApp] on both platforms.
  @Deprecated('Use BetterSocialShare.shareToWhatsApp')
  Future<String> shareImageToWhatsApp(String filePath) =>
      _legacy(_share.shareToWhatsApp(filePaths: <String>[filePath]));

  /// Legacy equivalent of [BetterSocialShare.shareToTelegram].
  @Deprecated('Use BetterSocialShare.shareToTelegram')
  Future<String> shareToTelegram(String message, {List<String>? filePaths}) =>
      _legacy(_share.shareToTelegram(
          message: message, filePaths: filePaths ?? const <String>[]));

  /// Legacy equivalent of [BetterSocialShare.shareToInstagramDirect].
  @Deprecated('Use BetterSocialShare.shareToInstagramDirect')
  Future<String> shareToInstagramDirect(String message) =>
      _legacy(_share.shareToInstagramDirect(message));

  /// Legacy equivalent of [BetterSocialShare.shareToInstagramFeed].
  @Deprecated('Use BetterSocialShare.shareToInstagramFeed')
  Future<String> shareToInstagramFeed(List<String> filePaths) =>
      _legacy(_share.shareToInstagramFeed(filePaths));

  /// Legacy equivalent of [BetterSocialShare.shareToInstagramReels].
  @Deprecated('Use BetterSocialShare.shareToInstagramReels')
  Future<String> shareToInstagramReel(List<String> filePaths) {
    if (filePaths.isEmpty) {
      return Future<String>.value('ERROR');
    }
    return _legacy(_share.shareToInstagramReels(filePaths.first));
  }

  /// Legacy equivalent of [BetterSocialShare.shareToInstagramStory].
  @Deprecated('Use BetterSocialShare.shareToInstagramStory')
  Future<String> shareToInstagramStory(
    String facebookAppId,
    String stickerImage, {
    String? backgroundImage,
    String? backgroundVideo,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
  }) =>
      _legacy(_share.shareToInstagramStory(
        appId: facebookAppId,
        options: _storyOptions(stickerImage, backgroundImage, backgroundVideo,
            backgroundTopColor, backgroundBottomColor, attributionURL),
      ));

  /// Legacy equivalent of [BetterSocialShare.shareToFacebook].
  @Deprecated('Use BetterSocialShare.shareToFacebook')
  Future<String> shareToFacebook(String message, List<String> filePaths) =>
      _legacy(_share.shareToFacebook(message: message, filePaths: filePaths));

  /// Legacy equivalent of [BetterSocialShare.shareToFacebookStory].
  @Deprecated('Use BetterSocialShare.shareToFacebookStory')
  Future<String> shareToFacebookStory(
    String stickerImage,
    String appId, {
    String? backgroundImage,
    String? backgroundVideo,
    String? backgroundTopColor,
    String? backgroundBottomColor,
    String? attributionURL,
  }) =>
      _legacy(_share.shareToFacebookStory(
        appId: appId,
        options: _storyOptions(stickerImage, backgroundImage, backgroundVideo,
            backgroundTopColor, backgroundBottomColor, attributionURL),
      ));

  /// Legacy equivalent of [BetterSocialShare.shareToMessenger].
  @Deprecated('Use BetterSocialShare.shareToMessenger')
  Future<String> shareToMessenger(String message) =>
      _legacy(_share.shareToMessenger(message));

  /// Legacy equivalent of [BetterSocialShare.shareToTikTokStatus].
  @Deprecated('Use BetterSocialShare.shareToTikTokStatus')
  Future<String> shareToTiktokStatus(List<String> filePaths) =>
      _legacy(_share.shareToTikTokStatus(filePaths));

  /// Legacy equivalent of [BetterSocialShare.shareToTikTokPost].
  @Deprecated('Use BetterSocialShare.shareToTikTokPost')
  Future<String> shareToTiktokPost(String videoPath) =>
      _legacy(_share.shareToTikTokPost(videoPath));

  /// Legacy equivalent of [BetterSocialShare.shareToX].
  @Deprecated('Use BetterSocialShare.shareToX')
  Future<String> shareToTwitter(String message, {List<String>? filePaths}) =>
      _legacy(_share.shareToX(
          message: message, filePaths: filePaths ?? const <String>[]));

  /// Legacy equivalent of [BetterSocialShare.shareToSms].
  @Deprecated('Use BetterSocialShare.shareToSms')
  Future<String> shareToSMS(String message, {List<String>? filePaths}) =>
      _legacy(_share.shareToSms(
          message: message, filePaths: filePaths ?? const <String>[]));

  /// Legacy equivalent of [BetterSocialShare.copyToClipboard].
  @Deprecated('Use BetterSocialShare.copyToClipboard')
  Future<String> copyToClipBoard(String message) =>
      _legacy(_share.copyToClipboard(message));

  /// Legacy equivalent of [BetterSocialShare.shareToSystem].
  @Deprecated('Use BetterSocialShare.shareToSystem')
  Future<String> shareToSystem(String title, String message,
          {List<String>? filePaths}) =>
      _legacy(_share.shareToSystem(
          title: title,
          message: message,
          filePaths: filePaths ?? const <String>[]));
}
