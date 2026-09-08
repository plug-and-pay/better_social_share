import Flutter
import MessageUI
import UIKit

/// Detects installed apps via canOpenURL. The host app must list these
/// schemes in LSApplicationQueriesSchemes (see README) or every check
/// returns false.
enum AppAvailability {
    static let schemes: [String: String] = [
        "whatsapp": "whatsapp://",
        "telegram": "tg://",
        "instagram": "instagram://",
        "facebook": "fb://",
        "messenger": "fb-messenger://",
        "tiktok": "snssdk1233://",
        "x": "twitter://",
    ]

    static func isInstalled(_ app: String) -> Bool {
        if app == "sms" {
            return MFMessageComposeViewController.canSendText()
        }
        guard let scheme = schemes[app], let url = URL(string: scheme) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }

    static func all() -> [String: Bool] {
        var result = [String: Bool]()
        for app in schemes.keys {
            result[app] = isInstalled(app)
        }
        result["sms"] = isInstalled("sms")
        return result
    }

    /// Reports APP_NOT_INSTALLED through [result] when [app] is missing —
    /// the silent no-op on a failed canOpenURL is the core appinio bug.
    static func require(
        _ app: String, displayName: String, result: @escaping FlutterResult
    ) -> Bool {
        if isInstalled(app) { return true }
        result(ShareError.flutter(
            ShareError.appNotInstalled,
            "\(displayName) is not installed (or its URL scheme is missing from "
                + "LSApplicationQueriesSchemes in your Info.plist)."
        ))
        return false
    }
}
