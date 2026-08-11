package dev.kashifkhan.drawbell

import android.app.NotificationManager
import android.content.ContentUris
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "dev.kashifkhan.drawbell/ringtones"
        private const val NATIVE_ALARM_CHANNEL = "dev.kashifkhan.drawbell/native_alarm"
    }

    private var nativeAlarmMethodChannel: MethodChannel? = null
    private var pendingLaunchPayload: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAlarmRingtones" -> {
                        try {
                            result.success(getAlarmRingtones())
                        } catch (e: Exception) {
                            result.error("RINGTONE_ERROR", e.message, null)
                        }
                    }
                    "openAppSettings" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        nativeAlarmMethodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_ALARM_CHANNEL)
        nativeAlarmMethodChannel?.setMethodCallHandler { call, result ->
            handleNativeAlarmMethodCall(call, result)
        }

        consumeLaunchIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeLaunchIntent(intent)
    }

    private fun getAlarmRingtones(): List<Map<String, String>> {
        val results = mutableListOf<Map<String, String>>()

        // Query both internal and external MediaStore URIs.
        // On Android 10+ the built-in alarm sounds (Cesium, Argon, etc.) are
        // indexed under the external URI even though they live on the system
        // partition.  The internal URI covers older devices / custom ROMs that
        // still use it.
        queryMediaStoreAlarms(MediaStore.Audio.Media.INTERNAL_CONTENT_URI, results)
        queryMediaStoreAlarms(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, results)

        // Fallback: RingtoneManager covers any tones not surfaced by MediaStore
        // (e.g., OEM alarm packs on some devices).
        if (results.isEmpty()) {
            queryRingtoneManager(results)
        }

        return results.sortedBy { it["title"] }
    }

    private fun addUniqueRingtone(
        into: MutableList<Map<String, String>>,
        title: String,
        uri: String,
    ) {
        val normalizedTitle = normalizeRingtoneTitle(title)
        val exists = into.any {
            val existingTitle = normalizeRingtoneTitle(it["title"] ?: "")
            val existingUri = it["uri"] ?: ""
            existingUri == uri || existingTitle == normalizedTitle
        }
        if (!exists) {
            into.add(mapOf("title" to title, "uri" to uri))
        }
    }

    private fun normalizeRingtoneTitle(title: String): String {
        return title.trim().lowercase().replace(Regex("\\s+"), " ")
    }

    private fun queryMediaStoreAlarms(
        baseUri: android.net.Uri,
        into: MutableList<Map<String, String>>,
    ) {
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
        )
        val selection = "${MediaStore.Audio.Media.IS_ALARM} = 1"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        try {
            contentResolver.query(baseUri, projection, selection, null, sortOrder)
                ?.use { cursor ->
                    val idCol =
                        cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
                    val titleCol =
                        cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(idCol)
                        val title = cursor.getString(titleCol) ?: continue
                        val uri =
                            ContentUris.withAppendedId(baseUri, id).toString()
                        addUniqueRingtone(into, title, uri)
                    }
                }
        } catch (_: Exception) {
        }
    }

    private fun queryRingtoneManager(into: MutableList<Map<String, String>>) {
        try {
            val rm = RingtoneManager(this)
            rm.setType(RingtoneManager.TYPE_ALARM)
            val cursor = rm.cursor
            cursor.use {
                while (it.moveToNext()) {
                    val title =
                        it.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                            ?: continue
                    val uri = rm.getRingtoneUri(it.position).toString()
                    addUniqueRingtone(into, title, uri)
                }
            }
        } catch (_: Exception) {
        }
    }

    private fun handleNativeAlarmMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "scheduleAlarm" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.error("INVALID_ARGS", "Missing args", null)
                    return
                }
                val id = (args["id"] as? Number)?.toInt() ?: run {
                    result.error("INVALID_ARGS", "Missing id", null)
                    return
                }
                val title = args["title"] as? String ?: "DrawBell"
                val body = args["body"] as? String ?: "Alarm — draw to dismiss!"
                val payload = args["payload"] as? String ?: ""
                val sound = args["sound"] as? String ?: "default"
                val scheduledTimeMillis =
                    (args["scheduledTimeMillis"] as? Number)?.toLong() ?: run {
                        result.error("INVALID_ARGS", "Missing scheduled time", null)
                        return
                    }
                NativeAlarmScheduler.schedule(
                    context = this,
                    id = id,
                    title = title,
                    body = body,
                    payload = payload,
                    sound = sound,
                    scheduledTimeMillis = scheduledTimeMillis,
                )
                result.success(null)
            }

            "cancelAlarm" -> {
                val args = call.arguments as? Map<*, *>
                val id = (args?.get("id") as? Number)?.toInt() ?: run {
                    result.error("INVALID_ARGS", "Missing id", null)
                    return
                }
                NativeAlarmScheduler.cancel(this, id)
                result.success(null)
            }

            "cancelAll" -> {
                NativeAlarmScheduler.cancelAll(this)
                result.success(null)
            }

            "stopRingingAlarm" -> {
                AlarmPlaybackService.stop(this)
                result.success(null)
            }

            "consumeLaunchPayload" -> {
                val payload = pendingLaunchPayload
                pendingLaunchPayload = null
                result.success(payload)
            }

            else -> result.notImplemented()
        }
    }

    private fun consumeLaunchIntent(intent: Intent?) {
        if (intent == null) {
            return
        }
        if (intent.action != "dev.kashifkhan.drawbell.ACTION_OPEN_ALARM") {
            return
        }
        val payload = intent.getStringExtra("alarm_payload") ?: return
        pendingLaunchPayload = payload
        nativeAlarmMethodChannel?.invokeMethod("onAlarmLaunch", payload)
        val notificationManager =
            getSystemService(NotificationManager::class.java)
        notificationManager?.cancelAll()
        intent.action = null
        intent.removeExtra("alarm_payload")
        intent.removeExtra("alarm_id")
    }
}
