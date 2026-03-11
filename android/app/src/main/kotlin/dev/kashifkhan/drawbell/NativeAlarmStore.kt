package dev.kashifkhan.drawbell

import android.content.Context
import org.json.JSONObject

object NativeAlarmStore {
    private const val PREFS_NAME = "drawbell_native_alarms"
    private const val KEY_IDS = "alarm_ids"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun putAlarm(
        context: Context,
        id: Int,
        title: String,
        body: String,
        payload: String,
        sound: String,
        scheduledTimeMillis: Long,
    ) {
        val entry = JSONObject().apply {
            put("title", title)
            put("body", body)
            put("payload", payload)
            put("sound", sound)
            put("scheduledTimeMillis", scheduledTimeMillis)
        }.toString()
        prefs(context).edit()
            .putString("entry_$id", entry)
            .apply()
        val ids = getAlarmIds(context).toMutableSet()
        ids.add(id)
        saveAlarmIds(context, ids)
    }

    fun getEntry(context: Context, id: Int): AlarmEntry? {
        val raw = prefs(context).getString("entry_$id", null) ?: return null
        return try {
            val obj = JSONObject(raw)
            AlarmEntry(
                id = id,
                title = obj.getString("title"),
                body = obj.getString("body"),
                payload = obj.getString("payload"),
                sound = obj.getString("sound"),
                scheduledTimeMillis = obj.getLong("scheduledTimeMillis"),
            )
        } catch (_: Exception) {
            null
        }
    }

    fun removeAlarm(context: Context, id: Int) {
        prefs(context).edit().remove("entry_$id").apply()
        val ids = getAlarmIds(context).toMutableSet()
        ids.remove(id)
        saveAlarmIds(context, ids)
    }

    fun getAlarmIds(context: Context): Set<Int> {
        val raw = prefs(context).getStringSet(KEY_IDS, emptySet()) ?: emptySet()
        return raw.mapNotNull { it.toIntOrNull() }.toSet()
    }

    fun clearAll(context: Context) {
        val ids = getAlarmIds(context)
        val editor = prefs(context).edit()
        for (id in ids) {
            editor.remove("entry_$id")
        }
        editor.remove(KEY_IDS)
        editor.apply()
    }

    private fun saveAlarmIds(context: Context, ids: Set<Int>) {
        prefs(context).edit()
            .putStringSet(KEY_IDS, ids.map { it.toString() }.toSet())
            .apply()
    }

    data class AlarmEntry(
        val id: Int,
        val title: String,
        val body: String,
        val payload: String,
        val sound: String,
        val scheduledTimeMillis: Long,
    )
}
