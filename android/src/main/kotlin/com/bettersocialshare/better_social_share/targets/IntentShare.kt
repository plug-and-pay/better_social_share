package com.bettersocialshare.better_social_share.targets

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import com.bettersocialshare.better_social_share.FileShareHelper
import com.bettersocialshare.better_social_share.ShareError
import com.bettersocialshare.better_social_share.ShareException

/** Shared ACTION_SEND / ACTION_SEND_MULTIPLE plumbing for explicit-package shares. */
internal object IntentShare {

    /**
     * Builds an explicit send intent for [targetPackage]. Uses setPackage()
     * only — never a hardcoded ComponentName, which is what broke Instagram
     * feed sharing in appinio_social_share when Instagram renamed internal
     * activities.
     */
    fun buildSend(
        helper: FileShareHelper,
        targetPackage: String,
        message: String?,
        filePaths: List<String>,
    ): Intent {
        val intent: Intent
        if (filePaths.isEmpty()) {
            intent = Intent(Intent.ACTION_SEND)
            intent.type = "text/plain"
        } else {
            val uris: ArrayList<Uri> = helper.toUris(filePaths)
            if (uris.size == 1) {
                intent = Intent(Intent.ACTION_SEND)
                intent.putExtra(Intent.EXTRA_STREAM, uris.first())
            } else {
                intent = Intent(Intent.ACTION_SEND_MULTIPLE)
                intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }
            intent.type = FileShareHelper.batchMimeType(filePaths)
            helper.grant(intent, uris, targetPackage)
        }
        if (!message.isNullOrEmpty()) {
            intent.putExtra(Intent.EXTRA_TEXT, message)
        }
        intent.setPackage(targetPackage)
        return intent
    }

    /** Launches [intent], converting Android's exceptions into ShareExceptions. */
    fun launch(activity: Activity, intent: Intent) {
        try {
            activity.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            throw ShareException(
                ShareError.APP_NOT_INSTALLED,
                "No activity found to handle the share: ${e.message}"
            )
        } catch (e: SecurityException) {
            throw ShareException(
                ShareError.UNKNOWN,
                "The target app rejected the share: ${e.message}"
            )
        }
    }
}
