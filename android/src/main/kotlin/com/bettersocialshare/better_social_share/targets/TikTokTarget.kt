package com.bettersocialshare.better_social_share.targets

import android.app.Activity
import com.bettersocialshare.better_social_share.FileShareHelper
import com.bettersocialshare.better_social_share.InstalledApps

/** TikTok status/post sharing via the generic composer (Android only). */
internal object TikTokTarget {

    fun shareStatus(activity: Activity, helper: FileShareHelper, filePaths: List<String>) {
        val pkg = InstalledApps.requirePackage(activity, "tiktok", "TikTok")
        val intent = IntentShare.buildSend(helper, pkg, null, filePaths)
        IntentShare.launch(activity, intent)
    }

    fun sharePost(activity: Activity, helper: FileShareHelper, videoPath: String) {
        shareStatus(activity, helper, listOf(videoPath))
    }
}
