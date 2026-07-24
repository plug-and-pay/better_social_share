import Flutter
import Photos
import UIKit

/// Instagram feed sharing: save to the photo library, then deep-link
/// Instagram to the saved asset. A denied Photos permission is reported as
/// PERMISSION_DENIED — in appinio_social_share it failed silently.
enum InstagramFeedSharer {

    static func share(filePaths: [String], result: @escaping FlutterResult) {
        guard AppAvailability.require(
            "instagram", displayName: "Instagram", result: result)
        else { return }

        for path in filePaths where !FileManager.default.fileExists(atPath: path) {
            result(ShareError.flutter(
                ShareError.fileNotFound, "File not found: \(path)"))
            return
        }

        requestAddPermission { granted in
            guard granted else {
                DispatchQueue.main.async {
                    result(ShareError.flutter(
                        ShareError.permissionDenied,
                        "Photo library access denied. Instagram feed sharing "
                            + "saves the media to Photos first — add "
                            + "NSPhotoLibraryAddUsageDescription to Info.plist "
                            + "and allow access."))
                }
                return
            }
            save(filePaths: filePaths, result: result)
        }
    }

    private static func requestAddPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                completion(status == .authorized || status == .limited)
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized)
            }
        }
    }

    private static func save(filePaths: [String], result: @escaping FlutterResult) {
        var lastIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            for path in filePaths {
                let url = URL(fileURLWithPath: path)
                let isVideo = ["mp4", "mov", "m4v"]
                    .contains(url.pathExtension.lowercased())
                let request = isVideo
                    ? PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    : PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                lastIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
            }
        }) { success, error in
            DispatchQueue.main.async {
                guard success, let identifier = lastIdentifier else {
                    result(ShareError.flutter(
                        ShareError.unknown,
                        "Saving to the photo library failed: "
                            + (error?.localizedDescription ?? "unknown error")))
                    return
                }
                let encoded = UrlSharer.encode(identifier)
                UrlSharer.open(
                    "instagram://library?LocalIdentifier=\(encoded)", result: result)
            }
        }
    }
}
