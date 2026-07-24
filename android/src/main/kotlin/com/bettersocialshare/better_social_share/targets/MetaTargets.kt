package com.bettersocialshare.better_social_share.targets

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import com.bettersocialshare.better_social_share.FileShareHelper
import com.bettersocialshare.better_social_share.InstalledApps

/** Instagram (feed/reels/story/direct), Facebook (feed/story), Messenger. */
internal object MetaTargets {

    private const val INSTAGRAM = "com.instagram.android"

    fun shareToInstagramFeed(
        activity: Activity,
        helper: FileShareHelper,
        filePaths: List<String>,
    ) {
        // Plain explicit send — appinio targeted Instagram's internal
        // ShareHandlerActivity by ComponentName, which broke on app updates.
        SimpleTargets.shareToApp(
            activity, helper, "instagram", "Instagram", null, filePaths
        )
    }

    fun shareToInstagramReels(
        activity: Activity,
        helper: FileShareHelper,
        videoPath: String,
    ) {
        val pkg = InstalledApps.requirePackage(activity, "instagram", "Instagram")
        val uris = helper.toUris(listOf(videoPath))
        val intent = Intent("com.instagram.share.ADD_TO_REEL").apply {
            setDataAndType(uris.first(), FileShareHelper.mimeType(videoPath))
            setPackage(pkg)
        }
        helper.grant(intent, uris, pkg)
        try {
            activity.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            // Older Instagram versions don't expose ADD_TO_REEL; fall back to
            // the generic composer where the user can pick Reels.
            val fallback = IntentShare.buildSend(helper, pkg, null, listOf(videoPath))
            IntentShare.launch(activity, fallback)
        }
    }

    fun shareToStory(
        activity: Activity,
        helper: FileShareHelper,
        app: String, // "instagram" | "facebook"
        args: Map<String, Any?>,
    ) {
        val isInstagram = app == "instagram"
        val displayName = if (isInstagram) "Instagram" else "Facebook"
        val pkg = InstalledApps.requirePackage(activity, app, displayName)
        val action = if (isInstagram) {
            "com.instagram.share.ADD_TO_STORY"
        } else {
            "com.facebook.stories.ADD_TO_STORY"
        }
        val appId = args["appId"] as String

        val intent = Intent(action)
        intent.setPackage(pkg)
        if (isInstagram) {
            intent.putExtra("source_application", appId)
        } else {
            intent.putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)
        }

        val grantUris = ArrayList<Uri>()

        val backgroundPath =
            (args["backgroundImage"] ?: args["backgroundVideo"]) as String?
        if (backgroundPath != null) {
            val uri = helper.toUris(listOf(backgroundPath)).first()
            grantUris.add(uri)
            intent.setDataAndType(uri, FileShareHelper.mimeType(backgroundPath))
        } else {
            intent.type = "image/*"
        }

        val stickerPath = args["stickerImage"] as String?
        if (stickerPath != null) {
            val uri = helper.toUris(listOf(stickerPath)).first()
            grantUris.add(uri)
            intent.putExtra("interactive_asset_uri", uri)
        }

        // Only non-null extras are added — empty placeholder values are what
        // produced broken/empty link stickers in appinio (#318).
        (args["backgroundTopColor"] as String?)?.let {
            intent.putExtra("top_background_color", it)
        }
        (args["backgroundBottomColor"] as String?)?.let {
            intent.putExtra("bottom_background_color", it)
        }
        (args["attributionUrl"] as String?)?.let {
            intent.putExtra("content_url", it)
        }

        helper.grant(intent, grantUris, pkg)
        IntentShare.launch(activity, intent)
    }
}
