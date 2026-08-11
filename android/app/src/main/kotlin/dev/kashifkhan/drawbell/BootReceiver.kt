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
        private const val ACTION_MY_PACKAGE_REPLACED =
            "android.intent.action.MY_PACKAGE_REPLACED"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != ACTION_MY_PACKAGE_REPLACED &&
            action != ACTION_QUICKBOOT_POWERON &&
            action != ACTION_HTC_QUICKBOOT_POWERON
        ) return

        val isLockedBoot = action == Intent.ACTION_LOCKED_BOOT_COMPLETED
        val now = System.currentTimeMillis()
        val ids = NativeAlarmStore.getAlarmIds(context)
        for (id in ids) {
            val entry = NativeAlarmStore.getEntry(
                context = context,
                id = id,
                allowLegacyMigration = !isLockedBoot,
            ) ?: continue
            var entryToSchedule = entry
            if (entryToSchedule.scheduledTimeMillis <= now) {
                val rebuiltFromStored =
                    NativeAlarmStore.rebuildFromStoredMetadata(entryToSchedule)
                if (rebuiltFromStored != null && rebuiltFromStored.scheduledTimeMillis > now) {
                    entryToSchedule = rebuiltFromStored
                } else {
                    if (isLockedBoot) {
                        continue
                    }
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
            }
            NativeAlarmScheduler.schedule(
                context = context,
                id = entryToSchedule.id,
                title = entryToSchedule.title,
                body = entryToSchedule.body,
                payload = entryToSchedule.payload,
                sound = entryToSchedule.sound,
                scheduledTimeMillis = entryToSchedule.scheduledTimeMillis,
                hour = entryToSchedule.hour,
                minute = entryToSchedule.minute,
                repeatDays = entryToSchedule.repeatDays,
                scheduledDate = entryToSchedule.scheduledDate,
            )
        }
    }
}
