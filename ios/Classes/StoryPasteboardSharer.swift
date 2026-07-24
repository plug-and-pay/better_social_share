import Flutter
import UIKit

/// Instagram/Facebook story (and Instagram Reels) sharing via the pasteboard.
///
/// Builds the sticker dictionary from non-nil values only: putting empty
/// placeholders on the pasteboard is what rendered broken "empty link"
/// stickers in appinio_social_share (#318).
enum StoryPasteboardSharer {

    static func shareStory(
        app: String, // "instagram" | "facebook"
        args: [String: Any],
        result: @escaping FlutterResult
    ) {
        let isInstagram = app == "instagram"
        let displayName = isInstagram ? "Instagram" : "Facebook"
        guard AppAvailability.require(app, displayName: displayName, result: result)
        else { return }

        guard let appId = args["appId"] as? String, !appId.isEmpty else {
            result(ShareError.flutter(
                ShareError.invalidArgument,
                "A Meta App ID is required for story sharing."))
            return
        }

        let prefix = isInstagram
            ? "com.instagram.sharedSticker"
            : "com.facebook.sharedSticker"

        var items = [String: Any]()

        do {
            if let sticker = args["stickerImage"] as? String {
                items["\(prefix).stickerImage"] = try fileData(sticker)
            }
            if let background = args["backgroundImage"] as? String {
                items["\(prefix).backgroundImage"] = try fileData(background)
            }
            if let video = args["backgroundVideo"] as? String {
                items["\(prefix).backgroundVideo"] = try fileData(video)
            }
        } catch let error as ShareFileError {
            result(ShareError.flutter(ShareError.fileNotFound, error.message))
            return
        } catch {
            result(ShareError.flutter(ShareError.unknown, error.localizedDescription))
            return
        }

        if items.isEmpty {
            result(ShareError.flutter(
                ShareError.invalidArgument,
                "Story sharing needs a sticker image, background image, or background video."))
            return
        }

        if let top = args["backgroundTopColor"] as? String {
            items["\(prefix).backgroundTopColor"] = top
        }
        if let bottom = args["backgroundBottomColor"] as? String {
            items["\(prefix).backgroundBottomColor"] = bottom
        }
        if let attribution = args["attributionUrl"] as? String {
            items["\(prefix).contentURL"] = attribution
        }
        if !isInstagram {
            items["\(prefix).appID"] = appId
        }

        UIPasteboard.general.setItems(
            [items],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        let scheme = isInstagram
            ? "instagram-stories://share?source_application=\(appId)"
            : "facebook-stories://share?appId=\(appId)"
        UrlSharer.open(scheme, result: result)
    }

    static func shareReels(videoPath: String, result: @escaping FlutterResult) {
        guard AppAvailability.require(
            "instagram", displayName: "Instagram", result: result)
        else { return }

        let data: Data
        do {
            data = try fileData(videoPath)
        } catch let error as ShareFileError {
            result(ShareError.flutter(ShareError.fileNotFound, error.message))
            return
        } catch {
            result(ShareError.flutter(ShareError.unknown, error.localizedDescription))
            return
        }

        UIPasteboard.general.setItems(
            [["com.instagram.sharedSticker.backgroundVideo": data]],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )
        UrlSharer.open("instagram-reels://share", result: result)
    }

    private static func fileData(_ path: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ShareFileError(message: "File not found: \(path)")
        }
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
}

struct ShareFileError: Error {
    let message: String
}
