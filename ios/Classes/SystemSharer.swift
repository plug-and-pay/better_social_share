import Flutter
import UIKit

/// System share sheet with completion reporting and an iPad-safe popover
/// anchor (a missing anchor crashes on iPad — a common plugin bug).
enum SystemSharer {

    static func share(
        title: String?, message: String?, filePaths: [String],
        result: @escaping FlutterResult
    ) {
        guard let presenter = ViewControllerFinder.top() else {
            result(ShareError.flutter(
                ShareError.unknown, "No view controller available to present from."))
            return
        }

        var items = [Any]()
        if let message = message, !message.isEmpty {
            items.append(message)
        }
        for path in filePaths {
            guard FileManager.default.fileExists(atPath: path) else {
                result(ShareError.flutter(
                    ShareError.fileNotFound, "File not found: \(path)"))
                return
            }
            items.append(URL(fileURLWithPath: path))
        }
        guard !items.isEmpty else {
            result(ShareError.flutter(
                ShareError.invalidArgument, "Nothing to share."))
            return
        }

        let activity = UIActivityViewController(
            activityItems: items, applicationActivities: nil)
        if let title = title {
            activity.setValue(title, forKey: "subject")
        }
        activity.completionWithItemsHandler = { _, completed, _, error in
            if let error = error {
                result(ShareError.flutter(ShareError.unknown, error.localizedDescription))
            } else {
                result(completed ? "SUCCESS" : "DISMISSED")
            }
        }
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX, y: presenter.view.bounds.midY,
                width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(activity, animated: true)
    }
}
