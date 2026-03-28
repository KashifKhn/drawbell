package dev.kashifkhan.drawbell

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    private companion object {
        private const val ACTION_QUICKBOOT_POWERON =
            "android.intent.action.QUICKBOOT_POWERON"
        private const val ACTION_HTC_QUICKBOOT_POWERON =
            "com.htc.intent.action.QUICKBOOT_POWERON"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != ACTION_QUICKBOOT_POWERON &&
            action != ACTION_HTC_QUICKBOOT_POWERON
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
