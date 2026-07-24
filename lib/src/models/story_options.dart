import 'dart:ui' show Color;

/// Content and styling for an Instagram or Facebook story share.
///
/// At least one of [stickerImagePath], [backgroundImagePath], or
/// [backgroundVideoPath] must be provided.
///
/// Null fields are omitted entirely from the data sent to the native side.
/// (Sending empty/placeholder values is what caused the broken "empty link
/// sticker" bug in other share plugins.)
class StoryOptions {
  /// Creates story options.
  ///
  /// Throws an [ArgumentError] if no sticker image, background image, or
  /// background video is provided.
  StoryOptions({
    this.stickerImagePath,
    this.backgroundImagePath,
    this.backgroundVideoPath,
    this.backgroundTopColor,
    this.backgroundBottomColor,
    this.attributionUrl,
  }) {
    if (stickerImagePath == null &&
        backgroundImagePath == null &&
        backgroundVideoPath == null) {
      throw ArgumentError(
        'StoryOptions requires at least one of stickerImagePath, '
        'backgroundImagePath, or backgroundVideoPath.',
      );
    }
  }

  /// Path to an image rendered as a floating, movable sticker on the story.
  final String? stickerImagePath;

  /// Path to an image used as the full-screen story background.
  final String? backgroundImagePath;

  /// Path to a video used as the story background.
  final String? backgroundVideoPath;

  /// Top color of the background gradient, used when no background image or
  /// video is set.
  final Color? backgroundTopColor;

  /// Bottom color of the background gradient, used when no background image
  /// or video is set.
  final Color? backgroundBottomColor;

  /// Link attached to the story (availability of tappable attribution links
  /// is controlled by Meta and may require an approved app).
  final Uri? attributionUrl;

  /// Serializes non-null fields for the method channel.
  ///
  /// Null fields are omitted — never sent as empty strings.
  Map<String, Object> toMap() {
    return <String, Object>{
      if (stickerImagePath != null) 'stickerImage': stickerImagePath!,
      if (backgroundImagePath != null) 'backgroundImage': backgroundImagePath!,
      if (backgroundVideoPath != null) 'backgroundVideo': backgroundVideoPath!,
      if (backgroundTopColor != null)
        'backgroundTopColor': _toHex(backgroundTopColor!),
      if (backgroundBottomColor != null)
        'backgroundBottomColor': _toHex(backgroundBottomColor!),
      if (attributionUrl != null) 'attributionUrl': attributionUrl.toString(),
    };
  }

  static String _toHex(Color color) {
    String channel(double value) =>
        (value * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
  }
}
