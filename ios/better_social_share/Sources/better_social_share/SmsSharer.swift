import Flutter
import MessageUI
import UIKit

/// SMS sharing via MFMessageComposeViewController, with sent/cancelled/failed
/// reported back to Dart.
final class SmsSharer: NSObject, MFMessageComposeViewControllerDelegate {

    private var pendingResult: FlutterResult?

    func share(message: String?, filePaths: [String], result: @escaping FlutterResult) {
        guard MFMessageComposeViewController.canSendText() else {
            result(ShareError.flutter(
                ShareError.unavailable, "This device cannot send SMS messages."))
            return
        }
        guard pendingResult == nil else {
            result(ShareError.flutter(
                ShareError.unknown, "Another SMS composer is still open."))
            return
        }
        guard let presenter = ViewControllerFinder.top() else {
            result(ShareError.flutter(
                ShareError.unknown, "No view controller available to present from."))
            return
        }

        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.body = message

        if !filePaths.isEmpty, MFMessageComposeViewController.canSendAttachments() {
            for path in filePaths {
                guard FileManager.default.fileExists(atPath: path) else {
                    result(ShareError.flutter(
                        ShareError.fileNotFound, "File not found: \(path)"))
                    return
                }
                let url = URL(fileURLWithPath: path)
                composer.addAttachmentURL(url, withAlternateFilename: url.lastPathComponent)
            }
        }

        pendingResult = result
        presenter.present(composer, animated: true)
    }

    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith composeResult: MessageComposeResult
    ) {
        controller.dismiss(animated: true)
        switch composeResult {
        case .sent:
            pendingResult?("SUCCESS")
        case .cancelled:
            pendingResult?("DISMISSED")
        case .failed:
            pendingResult?(ShareError.flutter(
                ShareError.unknown, "The SMS composer reported a failure."))
        @unknown default:
            pendingResult?("SUCCESS")
        }
        pendingResult = nil
    }
}
