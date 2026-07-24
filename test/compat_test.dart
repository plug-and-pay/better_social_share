// ignore_for_file: deprecated_member_use_from_same_package

import 'package:better_social_share/compat.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('better_social_share');
  const AppinioSocialShareCompat compat = AppinioSocialShareCompat();

  final List<MethodCall> calls = <MethodCall>[];
  Object? Function(MethodCall call)? handler;

  setUp(() {
    calls.clear();
    handler = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return handler?.call(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('legacy names delegate to the new channel methods', () async {
    expect(await compat.shareToWhatsapp('hi'), 'SUCCESS');
    expect(calls.single.method, 'shareToWhatsApp');

    calls.clear();
    expect(await compat.shareToTwitter('tweet'), 'SUCCESS');
    expect(calls.single.method, 'shareToX');

    calls.clear();
    expect(await compat.copyToClipBoard('text'), 'SUCCESS');
    expect(calls.single.method, 'copyToClipboard');

    calls.clear();
    expect(await compat.shareImageToWhatsApp('/tmp/a.jpg'), 'SUCCESS');
    expect(calls.single.method, 'shareToWhatsApp');
    expect((calls.single.arguments as Map<Object?, Object?>)['filePaths'],
        <String>['/tmp/a.jpg']);
  });

  test('legacy string results map from ShareResult statuses', () async {
    handler = (MethodCall call) =>
        throw PlatformException(code: 'APP_NOT_INSTALLED');
    expect(await compat.shareToTelegram('hi'), 'NOT INSTALLED');

    handler = (MethodCall call) => throw PlatformException(code: 'UNKNOWN');
    expect(await compat.shareToMessenger('hi'), 'ERROR');
  });

  test('legacy story share converts hex colors and flattens args', () async {
    final String result = await compat.shareToInstagramStory(
      '12345',
      '/tmp/sticker.png',
      backgroundTopColor: '#FF0000',
      attributionURL: 'https://example.com',
    );
    expect(result, 'SUCCESS');
    expect(calls.single.method, 'shareToInstagramStory');
    expect(calls.single.arguments, <String, Object>{
      'appId': '12345',
      'stickerImage': '/tmp/sticker.png',
      'backgroundTopColor': '#ff0000',
      'attributionUrl': 'https://example.com',
    });
  });

  test('getInstalledApps exposes legacy twitter key', () async {
    handler = (MethodCall call) => <String, bool>{'x': true};
    final Map<String, bool> apps = await compat.getInstalledApps();
    expect(apps['twitter'], isTrue);
    expect(apps['x'], isTrue);
  });
}
