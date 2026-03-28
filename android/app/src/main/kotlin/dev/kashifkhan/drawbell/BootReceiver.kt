package dev.kashifkhan.drawbell

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED
        ) return

        val now = System.currentTimeMillis()
        val ids = NativeAlarmStore.getAlarmIds(context)
        for (id in ids) {
            val entry = NativeAlarmStore.getEntry(context, id) ?: continue
            var entryToSchedule = entry
            if (entryToSchedule.scheduledTimeMillis <= now) {
                val rebuilt = NativeAlarmStore.rebuildEntryFromFlutterPrefs(
                    context = context,
                    id = id,
                    payload = entryToSchedule.payload,
                ) ?: continue
                if (rebuilt.scheduledTimeMillis <= now) {
                    continue
                }
                entryToSchedule = rebuilt
            }
            NativeAlarmScheduler.schedule(
                context = context,
                id = entryToSchedule.id,
                title = entryToSchedule.title,
                body = entryToSchedule.body,
                payload = entryToSchedule.payload,
                sound = entryToSchedule.sound,
                scheduledTimeMillis = entryToSchedule.scheduledTimeMillis,
            )
        }
    }
}
