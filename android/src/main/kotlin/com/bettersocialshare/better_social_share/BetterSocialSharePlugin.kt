package com.bettersocialshare.better_social_share

import android.app.Activity
import android.content.Context
import com.bettersocialshare.better_social_share.targets.MetaTargets
import com.bettersocialshare.better_social_share.targets.SimpleTargets
import com.bettersocialshare.better_social_share.targets.TikTokTarget
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Entry point: dispatches method-channel calls to the share targets. */
class BetterSocialSharePlugin :
    FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private lateinit var appContext: Context
    private lateinit var helper: FileShareHelper

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        helper = FileShareHelper(binding.applicationContext)
        channel = MethodChannel(binding.binaryMessenger, "better_social_share")
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            dispatch(call, result)
        } catch (e: ShareException) {
            result.error(e.code, e.message, null)
        } catch (e: Exception) {
            // Never swallow: every native failure reaches Dart as a typed error.
            result.error(ShareError.UNKNOWN, e.message ?: e.toString(), null)
        }
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        val activity = this.activity

        when (call.method) {
            "getInstalledApps" -> {
                result.success(InstalledApps.all(appContext))
                return
            }
            "isAppInstalled" -> {
                result.success(
                    InstalledApps.isInstalled(appContext, call.argument<String>("app")!!)
                )
                return
            }
            "copyToClipboard" -> {
                SimpleTargets.copyToClipboard(appContext, call.argument<String>("text")!!)
                result.success("SUCCESS")
                return
            }
        }

        if (activity == null) {
            throw ShareException(
                ShareError.NO_ACTIVITY,
                "Sharing requires a foreground activity."
            )
        }

        val message = call.argument<String>("message")
        val filePaths = call.argument<List<String>>("filePaths") ?: emptyList()

        when (call.method) {
            "shareToWhatsApp" ->
                SimpleTargets.shareToApp(activity, helper, "whatsapp", "WhatsApp", message, filePaths)
            "shareToTelegram" ->
                SimpleTargets.shareToApp(activity, helper, "telegram", "Telegram", message, filePaths)
            "shareToInstagramDirect" ->
                SimpleTargets.shareToApp(activity, helper, "instagram", "Instagram", message, emptyList())
            "shareToInstagramFeed" ->
                MetaTargets.shareToInstagramFeed(activity, helper, filePaths)
            "shareToInstagramReels" ->
                MetaTargets.shareToInstagramReels(activity, helper, call.argument<String>("videoPath")!!)
            "shareToInstagramStory" ->
                MetaTargets.shareToStory(activity, helper, "instagram", callArguments(call))
            "shareToFacebook" ->
                SimpleTargets.shareToApp(activity, helper, "facebook", "Facebook", message, filePaths)
            "shareToFacebookStory" ->
                MetaTargets.shareToStory(activity, helper, "facebook", callArguments(call))
            "shareToMessenger" ->
                SimpleTargets.shareToApp(activity, helper, "messenger", "Messenger", message, emptyList())
            "shareToTikTokStatus" ->
                TikTokTarget.shareStatus(activity, helper, filePaths)
            "shareToTikTokPost" ->
                TikTokTarget.sharePost(activity, helper, call.argument<String>("videoPath")!!)
            "shareToX" ->
                SimpleTargets.shareToApp(activity, helper, "x", "X", message, filePaths)
            "shareToSms" ->
                SimpleTargets.shareToSms(activity, helper, message, filePaths)
            "shareToSystem" ->
                SimpleTargets.shareToSystem(
                    activity, helper, call.argument<String>("title"), message, filePaths
                )
            else -> {
                result.notImplemented()
                return
            }
        }
        result.success("SUCCESS")
    }

    @Suppress("UNCHECKED_CAST")
    private fun callArguments(call: MethodCall): Map<String, Any?> =
        call.arguments as? Map<String, Any?> ?: emptyMap()
}
