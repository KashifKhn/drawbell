package dev.kashifkhan.drawbell

import android.content.Context

object NativeAlarmStore {
    private const val PREFS_NAME = "drawbell_native_alarms"
    private const val KEY_IDS = "alarm_ids"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun putAlarm(context: Context, id: Int, payload: String) {
        prefs(context).edit()
            .putString("payload_$id", payload)
            .apply()
        val ids = getAlarmIds(context).toMutableSet()
        ids.add(id)
        saveAlarmIds(context, ids)
    }

    fun getPayload(context: Context, id: Int): String? {
        return prefs(context).getString("payload_$id", null)
    }

    fun removeAlarm(context: Context, id: Int) {
        prefs(context).edit().remove("payload_$id").apply()
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
            editor.remove("payload_$id")
        }
        editor.remove(KEY_IDS)
        editor.apply()
    }

    private fun saveAlarmIds(context: Context, ids: Set<Int>) {
        prefs(context).edit()
            .putStringSet(KEY_IDS, ids.map { it.toString() }.toSet())
            .apply()
    }
}
