package com.bettersocialshare.better_social_share

/** Error codes shared with the Dart side; keep in sync with ShareResult docs. */
object ShareError {
    const val APP_NOT_INSTALLED = "APP_NOT_INSTALLED"
    const val PERMISSION_DENIED = "PERMISSION_DENIED"
    const val FILE_NOT_FOUND = "FILE_NOT_FOUND"
    const val INVALID_ARGUMENT = "INVALID_ARGUMENT"
    const val UNAVAILABLE = "UNAVAILABLE"
    const val NO_ACTIVITY = "NO_ACTIVITY"
    const val UNKNOWN = "UNKNOWN"
}

/** Thrown by share targets; the plugin converts it to a MethodChannel error. */
class ShareException(val code: String, message: String) : Exception(message)
