/// The outcome category of a share attempt.
enum ShareResultStatus {
  /// The content was handed off to the target app (or the user completed the
  /// share, where the platform reports completion).
  success,

  /// The target app is not installed on the device.
  appNotInstalled,

  /// A required permission was denied (e.g. Photos access for Instagram
  /// feed sharing on iOS).
  permissionDenied,

  /// The user dismissed a share sheet or composer without sharing.
  ///
  /// Only reported for targets that use an in-app UI the plugin can observe
  /// (system share sheet, SMS composer, WhatsApp file menu on iOS). Targets
  /// launched via URL scheme or intent cannot report dismissal.
  dismissed,

  /// The share failed for another reason; see [ShareResult.errorCode] and
  /// [ShareResult.errorMessage].
  error,
}

/// The result of a share attempt.
///
/// Every `BetterSocialShare` method returns one of these instead of failing
/// silently: check [isSuccess], or switch on [status] to distinguish a
/// missing app from a denied permission from a genuine error.
class ShareResult {
  /// Creates a result with the given [status] and optional error details.
  const ShareResult(this.status, {this.errorCode, this.errorMessage});

  /// A successful result.
  const ShareResult.success()
      : status = ShareResultStatus.success,
        errorCode = null,
        errorMessage = null;

  /// The outcome category.
  final ShareResultStatus status;

  /// Machine-readable error code reported by the native side, if any.
  ///
  /// One of: `APP_NOT_INSTALLED`, `PERMISSION_DENIED`, `FILE_NOT_FOUND`,
  /// `INVALID_ARGUMENT`, `UNAVAILABLE`, `DISMISSED`, `UNKNOWN`.
  final String? errorCode;

  /// Human-readable detail from the native side, if any.
  final String? errorMessage;

  /// Whether the share attempt succeeded.
  bool get isSuccess => status == ShareResultStatus.success;

  @override
  String toString() => isSuccess
      ? 'ShareResult(success)'
      : 'ShareResult(${status.name}, code: $errorCode, message: $errorMessage)';
}
