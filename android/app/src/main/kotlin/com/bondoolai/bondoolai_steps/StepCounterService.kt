package com.bondoolai.bondoolai_steps

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import java.util.Locale

/**
 * Counts steps all day in the background (foreground service with a quiet,
 * ongoing notification showing today's total). Started by the app and on
 * boot, so counting never depends on the user opening the app first.
 */
class StepCounterService : Service(), SensorEventListener {
    private var sensorManager: SensorManager? = null
    private var lastNotifiedSteps = -1
    private var lastNotifiedAt = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        // startForeground() must come first: a service started with
        // startForegroundService() that stops before calling it crashes the app.
        createChannel()
        try {
            val notification = buildNotification(StepStore.today(this))
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            stopSelf()
            return
        }
        val manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        sensorManager = manager
        manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (sensorManager == null) return START_NOT_STICKY
        if (intent?.action == ACTION_REFRESH) updateNotification(StepStore.today(this), force = true)
        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent) {
        val today = StepStore.record(this, event.values[0].toLong())
        updateNotification(today, force = false)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }

    private fun updateNotification(steps: Int, force: Boolean) {
        val now = SystemClock.elapsedRealtime()
        // Notification updates are rate-limited by Android; ~every 10 steps
        // or once a minute is plenty.
        if (!force && steps == lastNotifiedSteps) return
        if (!force && steps - lastNotifiedSteps < 10 && now - lastNotifiedAt < 60_000) return
        lastNotifiedSteps = steps
        lastNotifiedAt = now
        getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, buildNotification(steps))
    }

    private fun createChannel() {
        val channel = NotificationChannel(CHANNEL_ID, "Алхам тоолуур", NotificationManager.IMPORTANCE_LOW).apply {
            description = "Өнөөдрийн алхамыг арын горимд тоолно"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(steps: Int): Notification {
        val goal = StepStore.goal(this).coerceAtLeast(1)
        val percent = (steps * 100L / goal).coerceAtMost(100)
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_walk)
            .setContentTitle("Өнөөдөр ${format(steps)} алхам")
            .setContentText("Зорилго ${format(goal)} · $percent%")
            .setProgress(goal, steps.coerceAtMost(goal), false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setContentIntent(open)
            .build()
    }

    private fun format(n: Int) = String.format(Locale.US, "%,d", n)

    companion object {
        const val CHANNEL_ID = "step_counter"
        const val NOTIFICATION_ID = 1001
        const val ACTION_REFRESH = "com.bondoolai.bondoolai_steps.REFRESH"

        fun hasActivityPermission(context: Context): Boolean =
            Build.VERSION.SDK_INT < 29 ||
                context.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED

        fun start(context: Context, action: String? = null) {
            if (!hasActivityPermission(context)) return
            val intent = Intent(context, StepCounterService::class.java).setAction(action)
            try {
                context.startForegroundService(intent)
            } catch (e: Exception) {
                // Not allowed right now (e.g. background start limits); the
                // app or the next boot will start it.
            }
        }
    }
}
