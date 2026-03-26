package dev.kashifkhan.drawbell

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

object NativeAlarmStore {
    private const val PREFS_NAME = "drawbell_native_alarms"
    private const val KEY_IDS = "alarm_ids"
    private const val ENTRY_PREFIX = "entry_"
    private const val LEGACY_PAYLOAD_PREFIX = "payload_"
    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val FLUTTER_ALARMS_KEY = "flutter.alarms"

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
            .putString("$ENTRY_PREFIX$id", entry)
            .apply()
        val ids = getAlarmIds(context).toMutableSet()
        ids.add(id)
        saveAlarmIds(context, ids)
    }

    fun getEntry(context: Context, id: Int): AlarmEntry? {
        val raw = prefs(context).getString("$ENTRY_PREFIX$id", null)
        val parsed = parseEntry(id, raw)
        if (parsed != null) {
            return parsed
        }

        val legacyPayload =
            prefs(context).getString("$LEGACY_PAYLOAD_PREFIX$id", null)
                ?: return null
        val migrated = buildEntryFromFlutterPrefs(context, id, legacyPayload)
            ?: return null

        putAlarm(
            context = context,
            id = migrated.id,
            title = migrated.title,
            body = migrated.body,
            payload = migrated.payload,
            sound = migrated.sound,
            scheduledTimeMillis = migrated.scheduledTimeMillis,
        )
        prefs(context).edit().remove("$LEGACY_PAYLOAD_PREFIX$id").apply()
        return migrated
    }

    private fun parseEntry(id: Int, raw: String?): AlarmEntry? {
        if (raw == null) {
            return null
        }
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

    private fun buildEntryFromFlutterPrefs(
        context: Context,
        id: Int,
        legacyPayload: String,
    ): AlarmEntry? {
        val rawAlarms = context
            .getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            .getString(FLUTTER_ALARMS_KEY, null)
            ?: return null

        return try {
            val alarms = JSONArray(rawAlarms)
            for (index in 0 until alarms.length()) {
                val alarm = alarms.optJSONObject(index) ?: continue
                val alarmId = alarm.optString("id", "")
                if (alarmId.isEmpty()) {
                    continue
                }

                val nativeId = alarmId.hashCode() and 0x7FFFFFFF
                if (nativeId != id) {
                    continue
                }
                if (!alarm.optBoolean("isEnabled", true)) {
                    return null
                }

                val hour = alarm.optInt("hour", -1)
                val minute = alarm.optInt("minute", -1)
                if (hour !in 0..23 || minute !in 0..59) {
                    return null
                }

                val repeatDays = mutableSetOf<Int>()
                val repeatDaysArray = alarm.optJSONArray("repeatDays")
                if (repeatDaysArray != null) {
                    for (dayIndex in 0 until repeatDaysArray.length()) {
                        val day = repeatDaysArray.optInt(dayIndex, -1)
                        if (day in 0..6) {
                            repeatDays.add(day)
                        }
                    }
                }

                val scheduledDate = parseScheduledDate(
                    alarm.optString("scheduledDate", ""),
                )
                val scheduledTimeMillis = computeNextFireTimeMillis(
                    hour = hour,
                    minute = minute,
                    repeatDays = repeatDays,
                    scheduledDate = scheduledDate,
                )
                val label = alarm.optString("label", "")
                val title = if (label.isNotEmpty()) label else "DrawBell"
                val body = "Alarm at ${formatTime(hour, minute)} - draw to dismiss!"
                val sound = alarm.optString("sound", "default")

                return AlarmEntry(
                    id = id,
                    title = title,
                    body = body,
                    payload = legacyPayload,
                    sound = sound,
                    scheduledTimeMillis = scheduledTimeMillis,
                )
            }
            null
        } catch (_: Exception) {
            null
        }
    }

    private fun parseScheduledDate(raw: String): Triple<Int, Int, Int>? {
        if (raw.length < 10) {
            return null
        }
        return try {
            val year = raw.substring(0, 4).toInt()
            val month = raw.substring(5, 7).toInt()
            val day = raw.substring(8, 10).toInt()
            Triple(year, month, day)
        } catch (_: Exception) {
            null
        }
    }

    private fun computeNextFireTimeMillis(
        hour: Int,
        minute: Int,
        repeatDays: Set<Int>,
        scheduledDate: Triple<Int, Int, Int>?,
    ): Long {
        val nowMillis = System.currentTimeMillis()

        if (scheduledDate != null) {
            val candidate = Calendar.getInstance().apply {
                set(Calendar.YEAR, scheduledDate.first)
                set(Calendar.MONTH, scheduledDate.second - 1)
                set(Calendar.DAY_OF_MONTH, scheduledDate.third)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis
            if (candidate > nowMillis) {
                return candidate
            }
            return nowMillis + 60_000L
        }

        val todayCandidate = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (repeatDays.isEmpty()) {
            if (todayCandidate.timeInMillis > nowMillis) {
                return todayCandidate.timeInMillis
            }
            todayCandidate.add(Calendar.DAY_OF_YEAR, 1)
            return todayCandidate.timeInMillis
        }

        for (offset in 0..7) {
            val check = todayCandidate.clone() as Calendar
            check.add(Calendar.DAY_OF_YEAR, offset)
            val dayOfWeek = check.get(Calendar.DAY_OF_WEEK)
            val appDay = (dayOfWeek - Calendar.MONDAY + 7) % 7
            if (repeatDays.contains(appDay)) {
                if (offset == 0 && check.timeInMillis <= nowMillis) {
                    continue
                }
                return check.timeInMillis
            }
        }

        todayCandidate.add(Calendar.DAY_OF_YEAR, 1)
        return todayCandidate.timeInMillis
    }

    private fun formatTime(hour: Int, minute: Int): String {
        val hourOfPeriod = hour % 12
        val displayHour = if (hourOfPeriod == 0) 12 else hourOfPeriod
        val displayMinute = minute.toString().padStart(2, '0')
        val period = if (hour < 12) "AM" else "PM"
        return "$displayHour:$displayMinute $period"
    }

    fun removeAlarm(context: Context, id: Int) {
        prefs(context).edit()
            .remove("$ENTRY_PREFIX$id")
            .remove("$LEGACY_PAYLOAD_PREFIX$id")
            .apply()
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
            editor.remove("$ENTRY_PREFIX$id")
            editor.remove("$LEGACY_PAYLOAD_PREFIX$id")
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
