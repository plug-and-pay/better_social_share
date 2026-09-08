import Flutter
import UIKit

/// URL-scheme based shares with real completion reporting.
enum UrlSharer {
    /// Opens [urlString] and reports success/failure through [result] —
    /// never a silent no-op.
    static func open(_ urlString: String, result: @escaping FlutterResult) {
        guard let url = URL(string: urlString) else {
            result(ShareError.flutter(
                ShareError.invalidArgument, "Could not build share URL."))
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                result("SUCCESS")
            } else {
                result(ShareError.flutter(
                    ShareError.unknown, "iOS refused to open \(url.scheme ?? "")://"))
            }
        }
    }

    static func encode(_ text: String) -> String {
        return text.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? text
    }
}

/// Finds the view controller to present share UI from.
enum ViewControllerFinder {
    static func top() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        var controller = keyWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
