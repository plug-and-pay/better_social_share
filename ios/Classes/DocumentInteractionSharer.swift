import Flutter
import UIKit

/// Shares a file to WhatsApp via its document-interaction UTI. Holds the
/// controller strongly until the interaction ends and reports the outcome —
/// including user dismissal — instead of silently dropping it.
final class DocumentInteractionSharer: NSObject, UIDocumentInteractionControllerDelegate {

    private var controller: UIDocumentInteractionController?
    private var pendingResult: FlutterResult?
    private var sent = false

    func shareToWhatsApp(filePath: String, result: @escaping FlutterResult) {
        guard AppAvailability.require(
            "whatsapp", displayName: "WhatsApp", result: result)
        else { return }

        guard FileManager.default.fileExists(atPath: filePath) else {
            result(ShareError.flutter(
                ShareError.fileNotFound, "File not found: \(filePath)"))
            return
        }
        guard pendingResult == nil else {
            result(ShareError.flutter(
                ShareError.unknown, "Another WhatsApp share is still in progress."))
            return
        }
        guard let sourceView = ViewControllerFinder.top()?.view else {
            result(ShareError.flutter(
                ShareError.unknown, "No view controller available to present from."))
            return
        }

        let isVideo = ["mp4", "mov", "m4v"]
            .contains((filePath as NSString).pathExtension.lowercased())
        let interaction = UIDocumentInteractionController(
            url: URL(fileURLWithPath: filePath))
        interaction.uti = isVideo ? "net.whatsapp.video" : "net.whatsapp.image"
        interaction.delegate = self

        controller = interaction
        pendingResult = result
        sent = false

        let presented = interaction.presentOpenInMenu(
            from: CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY,
                         width: 0, height: 0),
            in: sourceView,
            animated: true
        )
        if !presented {
            finish(ShareError.flutter(
                ShareError.unknown, "Could not present the WhatsApp share menu."))
        }
    }

    func documentInteractionController(
        _ controller: UIDocumentInteractionController,
        willBeginSendingToApplication application: String?
    ) {
        sent = true
    }

    func documentInteractionController(
        _ controller: UIDocumentInteractionController,
        didEndSendingToApplication application: String?
    ) {
        finish("SUCCESS")
    }

    func documentInteractionControllerDidDismissOpenInMenu(
        _ controller: UIDocumentInteractionController
    ) {
        if !sent {
            finish("DISMISSED")
        }
    }

    private func finish(_ value: Any) {
        pendingResult?(value)
        pendingResult = nil
        controller = nil
    }
}
