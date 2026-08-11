package dev.kashifkhan.drawbell

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object NativeAlarmScheduler {
    private const val ACTION_TRIGGER = "dev.kashifkhan.drawbell.ACTION_TRIGGER_ALARM"

    fun schedule(
        context: Context,
        id: Int,
        title: String,
        body: String,
        payload: String,
        sound: String,
        scheduledTimeMillis: Long,
    ) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER
            putExtra("alarm_id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("payload", payload)
            putExtra("sound", sound)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        NativeAlarmStore.putAlarm(context, id, payload)

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            scheduledTimeMillis,
            pendingIntent,
        )
    }

    fun cancel(context: Context, id: Int) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        NativeAlarmStore.removeAlarm(context, id)
    }

    fun cancelAll(context: Context) {
        val ids = NativeAlarmStore.getAlarmIds(context)
        for (id in ids) {
            cancel(context, id)
        }
        NativeAlarmStore.clearAll(context)
    }
}
