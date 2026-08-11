package dev.kashifkhan.drawbell

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat

class AlarmPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val alarmId = intent.getIntExtra("alarm_id", -1)
        if (alarmId <= 0) {
            stopSelf()
            return START_NOT_STICKY
        }

        val title = intent.getStringExtra("title") ?: "DrawBell"
        val body = intent.getStringExtra("body") ?: "Alarm — draw to dismiss!"
        val payload = intent.getStringExtra("payload") ?: ""
        val sound = intent.getStringExtra("sound") ?: "default"

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = "dev.kashifkhan.drawbell.ACTION_OPEN_ALARM"
            setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("alarm_payload", payload)
            putExtra("alarm_id", alarmId)
        }
        val launchPendingIntent = PendingIntent.getActivity(
            this,
            alarmId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        ensurePlaybackChannel()
        val notification = buildForegroundNotification(
            title = title,
            body = body,
            launchPendingIntent = launchPendingIntent,
        )
        startForeground(70000 + (alarmId % 10000), notification)

        startAudio(sound)
        startVibration()

        launchPendingIntent.send()

        return START_STICKY
    }

    override fun onDestroy() {
        stopAudioAndVibration()
        super.onDestroy()
    }

    private fun startAudio(sound: String) {
        stopAudioAndVibration()

        val uri = parseSoundUri(sound)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            isLooping = true
            setDataSource(this@AlarmPlaybackService, uri)
            prepare()
            start()
        }
    }

    private fun startVibration() {
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        val pattern = longArrayOf(0, 600, 400, 600)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(
                VibrationEffect.createWaveform(pattern, 0),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopAudioAndVibration() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        vibrator?.cancel()
    }

    private fun buildForegroundNotification(
        title: String,
        body: String,
        launchPendingIntent: PendingIntent,
    ): Notification {
        return NotificationCompat.Builder(this, PLAYBACK_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(launchPendingIntent)
            .setFullScreenIntent(launchPendingIntent, true)
            .build()
    }

    private fun ensurePlaybackChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(PLAYBACK_CHANNEL_ID)
        if (existing != null) {
            return
        }

        val channel = NotificationChannel(
            PLAYBACK_CHANNEL_ID,
            "DrawBell Active Alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Foreground alarm playback"
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun parseSoundUri(sound: String): Uri? {
        if (
            sound.startsWith("content://") ||
                sound.startsWith("file://") ||
                sound.startsWith("http")
        ) {
            return Uri.parse(sound)
        }
        return null
    }

    companion object {
        private const val PLAYBACK_CHANNEL_ID = "drawbell_alarm_playback"

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmPlaybackService::class.java))
        }
    }
}
