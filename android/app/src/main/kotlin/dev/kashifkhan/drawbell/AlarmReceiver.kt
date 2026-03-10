package dev.kashifkhan.drawbell

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AlarmPlaybackService::class.java).apply {
            putExtras(intent.extras ?: return)
        }
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}
