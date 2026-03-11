package dev.kashifkhan.drawbell

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.LOCKED_BOOT_COMPLETED"
        ) return

        val now = System.currentTimeMillis()
        val ids = NativeAlarmStore.getAlarmIds(context)
        for (id in ids) {
            val entry = NativeAlarmStore.getEntry(context, id) ?: continue
            if (entry.scheduledTimeMillis <= now) continue
            NativeAlarmScheduler.schedule(
                context = context,
                id = entry.id,
                title = entry.title,
                body = entry.body,
                payload = entry.payload,
                sound = entry.sound,
                scheduledTimeMillis = entry.scheduledTimeMillis,
            )
        }
    }
}
