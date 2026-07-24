import 'dart:ui' show Color;

import 'package:better_social_share/better_social_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryOptions', () {
    test('omits null fields entirely (appinio #318 regression)', () {
      final Map<String, Object> map =
          StoryOptions(stickerImagePath: '/tmp/sticker.png').toMap();
      expect(map, <String, Object>{'stickerImage': '/tmp/sticker.png'});
      expect(map.containsKey('attributionUrl'), isFalse);
      expect(map.containsKey('backgroundImage'), isFalse);
      expect(map.containsKey('backgroundVideo'), isFalse);
      expect(map.containsKey('backgroundTopColor'), isFalse);
      expect(map.containsKey('backgroundBottomColor'), isFalse);
      expect(map.values.any((Object v) => v == ''), isFalse,
          reason: 'no empty-string placeholders');
    });

    test('serializes all fields when set', () {
      final Map<String, Object> map = StoryOptions(
        stickerImagePath: '/s.png',
        backgroundImagePath: '/b.png',
        backgroundVideoPath: '/b.mp4',
        backgroundTopColor: const Color(0xFFFF0000),
        backgroundBottomColor: const Color(0xFF0000FF),
        attributionUrl: Uri.parse('https://example.com/a'),
      ).toMap();
      expect(map, <String, Object>{
        'stickerImage': '/s.png',
        'backgroundImage': '/b.png',
        'backgroundVideo': '/b.mp4',
        'backgroundTopColor': '#ff0000',
        'backgroundBottomColor': '#0000ff',
        'attributionUrl': 'https://example.com/a',
      });
    });

    test('throws when no content is provided', () {
      expect(
        () => StoryOptions(backgroundTopColor: const Color(0xFF000000)),
        throwsArgumentError,
      );
      expect(() => StoryOptions(), throwsArgumentError);
    });

    test('color serialization pads single-digit channels', () {
      final Map<String, Object> map = StoryOptions(
        stickerImagePath: '/s.png',
        backgroundTopColor: const Color(0xFF010203),
      ).toMap();
      expect(map['backgroundTopColor'], '#010203');
    });
  });
}
