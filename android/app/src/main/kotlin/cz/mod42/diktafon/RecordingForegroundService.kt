package cz.mod42.diktafon

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * D13 keep-alive: capture itself runs in the Flutter process (the `record`
 * plugin's AudioRecord); this microphone-type foreground service only makes
 * the OS treat that process as foreground — mic keeps delivering with the
 * screen off or the app backgrounded, and the required notification tells
 * the user a recording is live. Started/stopped over `diktafon/system`
 * around every capture; notification copy arrives pre-localized from Dart
 * (a bare Service can't reach gen-l10n).
 */
class RecordingForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "recording"
        // Download notifications use 100/200 id bases (download_notifier.dart).
        const val NOTIFICATION_ID = 300
        const val EXTRA_TITLE = "title"
        const val EXTRA_CHANNEL_NAME = "channelName"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Recording"
        val channelName = intent?.getStringExtra(EXTRA_CHANNEL_NAME) ?: "Recording"

        val manager = getSystemService(NotificationManager::class.java)
        // LOW: visible but silent — the user just pressed record themselves.
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_LOW))

        val tapIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE)
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentIntent(tapIntent)
            .setOngoing(true)
            // Live elapsed time without ever updating the notification.
            .setUsesChronometer(true)
            .setWhen(System.currentTimeMillis())
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        // Capture state lives in Dart — a service the OS restarts on its own
        // would guard nothing.
        return START_NOT_STICKY
    }
}
