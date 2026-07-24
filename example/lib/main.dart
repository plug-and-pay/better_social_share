import 'package:better_social_share/better_social_share.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'better_social_share example',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const ShareDemoPage(),
    );
  }
}

class ShareDemoPage extends StatefulWidget {
  const ShareDemoPage({super.key});

  @override
  State<ShareDemoPage> createState() => _ShareDemoPageState();
}

class _ShareDemoPageState extends State<ShareDemoPage> {
  final BetterSocialShare _share = const BetterSocialShare();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _message =
      TextEditingController(text: 'Hello from better_social_share!');
  final TextEditingController _appId = TextEditingController();
  final TextEditingController _attributionUrl = TextEditingController();

  Map<SocialApp, bool> _installed = {};
  List<String> _images = [];
  String? _video;

  @override
  void initState() {
    super.initState();
    _refreshInstalled();
  }

  Future<void> _refreshInstalled() async {
    final installed = await _share.getInstalledApps();
    if (mounted) setState(() => _installed = installed);
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    setState(() => _images = files.map((f) => f.path).toList());
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    setState(() => _video = file?.path);
  }

  Future<void> _run(Future<ShareResult> Function() action) async {
    ShareResult result;
    try {
      result = await action();
    } on ArgumentError catch (e) {
      result = ShareResult(ShareResultStatus.error,
          errorCode: 'INVALID_ARGUMENT', errorMessage: e.message.toString());
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.toString()),
      backgroundColor: result.isSuccess ? Colors.green.shade700 : null,
    ));
  }

  StoryOptions _storyOptions() => StoryOptions(
        stickerImagePath: _images.isNotEmpty ? _images.first : null,
        backgroundImagePath: _images.length > 1 ? _images[1] : null,
        backgroundVideoPath: _video,
        backgroundTopColor: Colors.deepPurple,
        backgroundBottomColor: Colors.orange,
        attributionUrl: _attributionUrl.text.isEmpty
            ? null
            : Uri.parse(_attributionUrl.text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('better_social_share')),
      body: RefreshIndicator(
        onRefresh: _refreshInstalled,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _installed.entries)
                  Chip(
                    label: Text(entry.key.name),
                    backgroundColor: entry.value
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              decoration: const InputDecoration(
                  labelText: 'Message', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                  label: Text('Images (${_images.length})'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: Text(_video == null ? 'Video' : 'Video ✓'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _appId,
              decoration: const InputDecoration(
                  labelText: 'Meta App ID (stories)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _attributionUrl,
              decoration: const InputDecoration(
                  labelText: 'Attribution URL (stories, optional)',
                  border: OutlineInputBorder()),
            ),
            _section('WhatsApp', [
              _btn('Text', () => _share.shareToWhatsApp(message: _message.text)),
              _btn('Text + files',
                  () => _share.shareToWhatsApp(message: _message.text, filePaths: _images)),
            ]),
            _section('Telegram', [
              _btn('Text', () => _share.shareToTelegram(message: _message.text)),
              _btn('Text + files',
                  () => _share.shareToTelegram(message: _message.text, filePaths: _images)),
            ]),
            _section('Instagram', [
              _btn('Direct', () => _share.shareToInstagramDirect(_message.text)),
              _btn('Feed', () => _share.shareToInstagramFeed(_images)),
              _btn('Reels', () => _share.shareToInstagramReels(_video ?? '')),
              _btn('Story',
                  () => _share.shareToInstagramStory(appId: _appId.text, options: _storyOptions())),
            ]),
            _section('Facebook', [
              _btn('Feed (files)',
                  () => _share.shareToFacebook(message: _message.text, filePaths: _images)),
              _btn('Story',
                  () => _share.shareToFacebookStory(appId: _appId.text, options: _storyOptions())),
              _btn('Messenger', () => _share.shareToMessenger(_message.text)),
            ]),
            _section('TikTok (Android only)', [
              _btn('Status', () => _share.shareToTikTokStatus(_images)),
              _btn('Post', () => _share.shareToTikTokPost(_video ?? '')),
            ]),
            _section('Other', [
              _btn('X', () => _share.shareToX(message: _message.text)),
              _btn('SMS', () => _share.shareToSms(message: _message.text)),
              _btn('Clipboard', () => _share.copyToClipboard(_message.text)),
              _btn('System sheet',
                  () => _share.shareToSystem(title: 'Share', message: _message.text, filePaths: _images)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
  }

  Widget _btn(String label, Future<ShareResult> Function() action) {
    return ElevatedButton(onPressed: () => _run(action), child: Text(label));
  }
}
