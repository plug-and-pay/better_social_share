package com.bettersocialshare.better_social_share.targets

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.bettersocialshare.better_social_share.FileShareHelper
import com.bettersocialshare.better_social_share.InstalledApps

/** WhatsApp, Telegram, X, Messenger, Instagram Direct: plain explicit sends. */
internal object SimpleTargets {

    fun shareToApp(
        activity: Activity,
        helper: FileShareHelper,
        app: String,
        displayName: String,
        message: String?,
        filePaths: List<String>,
    ) {
        val pkg = InstalledApps.requirePackage(activity, app, displayName)
        val intent = IntentShare.buildSend(helper, pkg, message, filePaths)
        IntentShare.launch(activity, intent)
    }

    fun copyToClipboard(context: Context, text: String) {
        val clipboard =
            context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("better_social_share", text))
    }

    fun shareToSystem(
        activity: Activity,
        helper: FileShareHelper,
        title: String?,
        message: String?,
        filePaths: List<String>,
    ) {
        val intent: Intent
        if (filePaths.isEmpty()) {
            intent = Intent(Intent.ACTION_SEND)
            intent.type = "text/plain"
        } else {
            val uris = helper.toUris(filePaths)
            if (uris.size == 1) {
                intent = Intent(Intent.ACTION_SEND)
                intent.putExtra(Intent.EXTRA_STREAM, uris.first())
            } else {
                intent = Intent(Intent.ACTION_SEND_MULTIPLE)
                intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }
            intent.type = FileShareHelper.batchMimeType(filePaths)
            // Chooser targets are unknown ahead of time; the read flag on the
            // intent (propagated by the chooser) grants access.
            helper.grant(intent, uris, null)
        }
        if (!message.isNullOrEmpty()) intent.putExtra(Intent.EXTRA_TEXT, message)
        if (!title.isNullOrEmpty()) intent.putExtra(Intent.EXTRA_TITLE, title)
        IntentShare.launch(activity, Intent.createChooser(intent, title))
    }

    fun shareToSms(
        activity: Activity,
        helper: FileShareHelper,
        message: String?,
        filePaths: List<String>,
    ) {
        if (filePaths.isEmpty()) {
            val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:"))
            if (!message.isNullOrEmpty()) intent.putExtra("sms_body", message)
            IntentShare.launch(activity, intent)
        } else {
            val pkg = InstalledApps.requirePackage(activity, "sms", "An SMS app")
            val intent = IntentShare.buildSend(helper, pkg, message, filePaths)
            if (!message.isNullOrEmpty()) intent.putExtra("sms_body", message)
            IntentShare.launch(activity, intent)
        }
    }
}
