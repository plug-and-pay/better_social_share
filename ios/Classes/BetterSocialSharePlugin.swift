import Flutter
import UIKit

/// Entry point: dispatches method-channel calls to the share targets.
public class BetterSocialSharePlugin: NSObject, FlutterPlugin {

    private let documentInteraction = DocumentInteractionSharer()
    private let smsSharer = SmsSharer()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "better_social_share", binaryMessenger: registrar.messenger())
        let instance = BetterSocialSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let message = args["message"] as? String
        let filePaths = args["filePaths"] as? [String] ?? []

        switch call.method {
        case "getInstalledApps":
            result(AppAvailability.all())

        case "isAppInstalled":
            result(AppAvailability.isInstalled(args["app"] as? String ?? ""))

        case "copyToClipboard":
            UIPasteboard.general.string = args["text"] as? String ?? ""
            result("SUCCESS")

        case "shareToWhatsApp":
            shareToWhatsApp(message: message, filePaths: filePaths, result: result)

        case "shareToTelegram":
            shareToTelegram(message: message, filePaths: filePaths, result: result)

        case "shareToInstagramDirect":
            guard AppAvailability.require(
                "instagram", displayName: "Instagram", result: result) else { return }
            UrlSharer.open(
                "instagram://sharesheet?text=\(UrlSharer.encode(message ?? ""))",
                result: result)

        case "shareToInstagramFeed":
            InstagramFeedSharer.share(filePaths: filePaths, result: result)

        case "shareToInstagramReels":
            StoryPasteboardSharer.shareReels(
                videoPath: args["videoPath"] as? String ?? "", result: result)

        case "shareToInstagramStory":
            StoryPasteboardSharer.shareStory(
                app: "instagram", args: args, result: result)

        case "shareToFacebookStory":
            StoryPasteboardSharer.shareStory(
                app: "facebook", args: args, result: result)

        case "shareToFacebook":
            result(ShareError.flutter(
                ShareError.unavailable,
                "Facebook feed sharing on iOS requires the Facebook SDK. Use the "
                    + "better_social_share_facebook package, or shareToSystem()."))

        case "shareToMessenger":
            guard AppAvailability.require(
                "messenger", displayName: "Messenger", result: result) else { return }
            UrlSharer.open(
                "fb-messenger://share?link=\(UrlSharer.encode(message ?? ""))",
                result: result)

        case "shareToTikTokStatus", "shareToTikTokPost":
            result(ShareError.flutter(
                ShareError.unavailable, "TikTok sharing is Android-only."))

        case "shareToX":
            // The tweet web intent replaces the SLComposeViewController API
            // Apple removed in iOS 16; it opens the X app when installed.
            UrlSharer.open(
                "https://twitter.com/intent/tweet?text=\(UrlSharer.encode(message ?? ""))",
                result: result)

        case "shareToSms":
            smsSharer.share(message: message, filePaths: filePaths, result: result)

        case "shareToSystem":
            SystemSharer.share(
                title: args["title"] as? String, message: message,
                filePaths: filePaths, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func shareToWhatsApp(
        message: String?, filePaths: [String], result: @escaping FlutterResult
    ) {
        // WhatsApp on iOS accepts either text (URL scheme) or a file
        // (document interaction) per share — when both are given, the file
        // wins; this is documented on the Dart side.
        if let file = filePaths.first {
            documentInteraction.shareToWhatsApp(filePath: file, result: result)
        } else {
            guard AppAvailability.require(
                "whatsapp", displayName: "WhatsApp", result: result) else { return }
            UrlSharer.open(
                "whatsapp://send?text=\(UrlSharer.encode(message ?? ""))",
                result: result)
        }
    }

    private func shareToTelegram(
        message: String?, filePaths: [String], result: @escaping FlutterResult
    ) {
        guard AppAvailability.require(
            "telegram", displayName: "Telegram", result: result) else { return }
        if !filePaths.isEmpty {
            result(ShareError.flutter(
                ShareError.unavailable,
                "Telegram on iOS only supports text via URL scheme. Use "
                    + "shareToSystem() to share files to Telegram."))
            return
        }
        UrlSharer.open(
            "tg://msg?text=\(UrlSharer.encode(message ?? ""))", result: result)
    }
}
