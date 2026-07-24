import 'package:better_social_share/better_social_share.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('better_social_share');
  const BetterSocialShare share = BetterSocialShare();

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

  group('channel contract', () {
    test('shareToWhatsApp sends message and filePaths', () async {
      final ShareResult result = await share.shareToWhatsApp(
        message: 'hello',
        filePaths: <String>['/tmp/a.jpg'],
      );
      expect(result.isSuccess, isTrue);
      expect(calls.single.method, 'shareToWhatsApp');
      expect(calls.single.arguments, <String, Object>{
        'message': 'hello',
        'filePaths': <String>['/tmp/a.jpg'],
      });
    });

    test('optional args are omitted, not sent as null', () async {
      await share.shareToWhatsApp(message: 'hi');
      final Map<Object?, Object?> args =
          calls.single.arguments as Map<Object?, Object?>;
      expect(args.containsKey('filePaths'), isFalse);
      expect(args['message'], 'hi');
    });

    test('shareToInstagramStory flattens appId + options', () async {
      await share.shareToInstagramStory(
        appId: '1234567890',
        options: StoryOptions(
          stickerImagePath: '/tmp/sticker.png',
          attributionUrl: Uri.parse('https://example.com'),
        ),
      );
      expect(calls.single.method, 'shareToInstagramStory');
      expect(calls.single.arguments, <String, Object>{
        'appId': '1234567890',
        'stickerImage': '/tmp/sticker.png',
        'attributionUrl': 'https://example.com',
      });
    });

    test('every simple method sends the expected name and args', () async {
      final Map<String, Future<ShareResult> Function()> cases =
          <String, Future<ShareResult> Function()>{
        'shareToTelegram': () => share.shareToTelegram(message: 'm'),
        'shareToInstagramDirect': () => share.shareToInstagramDirect('m'),
        'shareToInstagramFeed': () =>
            share.shareToInstagramFeed(<String>['/tmp/a.jpg']),
        'shareToInstagramReels': () => share.shareToInstagramReels('/tmp/v'),
        'shareToFacebook': () => share.shareToFacebook(message: 'm'),
        'shareToMessenger': () => share.shareToMessenger('m'),
        'shareToTikTokStatus': () =>
            share.shareToTikTokStatus(<String>['/tmp/a.jpg']),
        'shareToTikTokPost': () => share.shareToTikTokPost('/tmp/v'),
        'shareToX': () => share.shareToX(message: 'm'),
        'shareToSms': () => share.shareToSms(message: 'm'),
        'copyToClipboard': () => share.copyToClipboard('m'),
        'shareToSystem': () => share.shareToSystem(message: 'm'),
      };
      for (final MapEntry<String, Future<ShareResult> Function()> entry
          in cases.entries) {
        calls.clear();
        final ShareResult result = await entry.value();
        expect(result.isSuccess, isTrue, reason: entry.key);
        expect(calls.single.method, entry.key);
      }
    });

    test('methods with no content throw ArgumentError before channel call',
        () async {
      expect(() => share.shareToWhatsApp(), throwsArgumentError);
      expect(() => share.shareToTelegram(filePaths: <String>[]),
          throwsArgumentError);
      expect(
          () => share.shareToInstagramFeed(<String>[]), throwsArgumentError);
      expect(
          () => share.shareToTikTokStatus(<String>[]), throwsArgumentError);
      expect(calls, isEmpty);
    });
  });

  group('error mapping (no silent failures)', () {
    test('APP_NOT_INSTALLED maps to appNotInstalled', () async {
      handler = (MethodCall call) => throw PlatformException(
          code: 'APP_NOT_INSTALLED', message: 'WhatsApp is not installed');
      final ShareResult result = await share.shareToWhatsApp(message: 'hi');
      expect(result.status, ShareResultStatus.appNotInstalled);
      expect(result.errorCode, 'APP_NOT_INSTALLED');
      expect(result.errorMessage, 'WhatsApp is not installed');
      expect(result.isSuccess, isFalse);
    });

    test('PERMISSION_DENIED maps to permissionDenied', () async {
      handler = (MethodCall call) =>
          throw PlatformException(code: 'PERMISSION_DENIED');
      final ShareResult result =
          await share.shareToInstagramFeed(<String>['/tmp/a.jpg']);
      expect(result.status, ShareResultStatus.permissionDenied);
    });

    test('DISMISSED exception maps to dismissed', () async {
      handler =
          (MethodCall call) => throw PlatformException(code: 'DISMISSED');
      final ShareResult result = await share.shareToSystem(message: 'hi');
      expect(result.status, ShareResultStatus.dismissed);
    });

    test('DISMISSED success payload maps to dismissed', () async {
      handler = (MethodCall call) => 'DISMISSED';
      final ShareResult result = await share.shareToSystem(message: 'hi');
      expect(result.status, ShareResultStatus.dismissed);
    });

    test('unknown codes map to error with details preserved', () async {
      handler = (MethodCall call) => throw PlatformException(
          code: 'FILE_NOT_FOUND', message: 'No such file');
      final ShareResult result =
          await share.shareToTelegram(filePaths: <String>['/nope.jpg']);
      expect(result.status, ShareResultStatus.error);
      expect(result.errorCode, 'FILE_NOT_FOUND');
      expect(result.errorMessage, 'No such file');
    });
  });

  group('getInstalledApps', () {
    test('decodes native map keyed by enum name', () async {
      handler = (MethodCall call) => <String, bool>{
            'whatsapp': true,
            'instagram': false,
            'x': true,
          };
      final Map<SocialApp, bool> apps = await share.getInstalledApps();
      expect(apps[SocialApp.whatsapp], isTrue);
      expect(apps[SocialApp.instagram], isFalse);
      expect(apps[SocialApp.x], isTrue);
      expect(apps[SocialApp.telegram], isFalse,
          reason: 'missing keys default to false');
      expect(apps.length, SocialApp.values.length);
    });

    test('isAppInstalled sends app name', () async {
      handler = (MethodCall call) => true;
      expect(await share.isAppInstalled(SocialApp.tiktok), isTrue);
      expect(calls.single.arguments, <String, Object>{'app': 'tiktok'});
    });
  });
}
