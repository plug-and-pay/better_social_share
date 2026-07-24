package com.bettersocialshare.better_social_share

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import java.io.File

/**
 * Turns caller-supplied file paths into content:// URIs the target app can
 * read. Files are copied into the plugin's own cache subdirectory first, so
 * sharing works no matter where the source file lives (fixes the
 * "file outside FileProvider paths" failure class).
 */
class FileShareHelper(private val context: Context) {

    private val authority: String
        get() = "${context.packageName}.better_social_share.fileprovider"

    fun toUris(paths: List<String>): ArrayList<Uri> {
        val cacheDir = File(context.cacheDir, "better_social_share").apply { mkdirs() }
        val uris = ArrayList<Uri>(paths.size)
        for (path in paths) {
            val source = File(path)
            if (!source.exists()) {
                throw ShareException(ShareError.FILE_NOT_FOUND, "File not found: $path")
            }
            val target = File(cacheDir, source.name)
            source.copyTo(target, overwrite = true)
            uris.add(FileProvider.getUriForFile(context, authority, target))
        }
        return uris
    }

    /** Grants [targetPackage] read access to every URI, both via flags and explicitly. */
    fun grant(intent: Intent, uris: List<Uri>, targetPackage: String?) {
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (targetPackage != null) {
            for (uri in uris) {
                context.grantUriPermission(
                    targetPackage, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            }
        }
    }

    companion object {
        fun mimeType(path: String): String {
            val extension = path.substringAfterLast('.', "").lowercase()
            return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                ?: "application/octet-stream"
        }

        /** Common MIME for a batch: image, video, or full wildcard when mixed. */
        fun batchMimeType(paths: List<String>): String {
            val types = paths.map { mimeType(it).substringBefore('/') }.toSet()
            return when {
                types == setOf("image") -> "image/*"
                types == setOf("video") -> "video/*"
                else -> "*/*"
            }
        }
    }
}
