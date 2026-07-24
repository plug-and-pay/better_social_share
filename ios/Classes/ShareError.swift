import Flutter

/// Error codes shared with the Dart side; keep in sync with Android.
enum ShareError {
    static let appNotInstalled = "APP_NOT_INSTALLED"
    static let permissionDenied = "PERMISSION_DENIED"
    static let fileNotFound = "FILE_NOT_FOUND"
    static let invalidArgument = "INVALID_ARGUMENT"
    static let unavailable = "UNAVAILABLE"
    static let unknown = "UNKNOWN"

    static func flutter(_ code: String, _ message: String) -> FlutterError {
        return FlutterError(code: code, message: message, details: nil)
    }
}
