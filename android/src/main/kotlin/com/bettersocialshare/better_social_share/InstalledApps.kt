package com.bettersocialshare.better_social_share

import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony

/** Maps the Dart SocialApp enum names to Android package names. */
object InstalledApps {
    val packages: Map<String, List<String>> = mapOf(
        "whatsapp" to listOf("com.whatsapp", "com.whatsapp.w4b"),
        "telegram" to listOf("org.telegram.messenger"),
        "instagram" to listOf("com.instagram.android"),
        "facebook" to listOf("com.facebook.katana"),
        "messenger" to listOf("com.facebook.orca"),
        "tiktok" to listOf("com.zhiliaoapp.musically", "com.ss.android.ugc.trill"),
        "x" to listOf("com.twitter.android"),
    )

    /** Returns the first installed package for [app], or null if none. */
    fun installedPackage(context: Context, app: String): String? {
        if (app == "sms") {
            return Telephony.Sms.getDefaultSmsPackage(context)
        }
        return packages[app].orEmpty().firstOrNull { isPackageInstalled(context, it) }
    }

    fun isInstalled(context: Context, app: String): Boolean =
        installedPackage(context, app) != null

    fun all(context: Context): Map<String, Boolean> =
        (packages.keys + "sms").associateWith { isInstalled(context, it) }

    private fun isPackageInstalled(context: Context, packageName: String): Boolean =
        try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }

    /**
     * Returns the installed package for [app] or throws APP_NOT_INSTALLED —
     * appinio's design failed silently here; we always surface it.
     */
    fun requirePackage(context: Context, app: String, displayName: String): String =
        installedPackage(context, app)
            ?: throw ShareException(
                ShareError.APP_NOT_INSTALLED,
                "$displayName is not installed on this device."
            )
}
