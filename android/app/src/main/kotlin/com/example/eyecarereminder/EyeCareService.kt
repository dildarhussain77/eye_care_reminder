package com.example.screen_time_reminder

import android.app.*
import android.content.*
import android.os.*
import androidx.core.app.NotificationCompat

class EyeCareService : Service() {

    private lateinit var screenReceiver: BroadcastReceiver
    private val CHANNEL_ID = "eye_care_service_channel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        // Create and register screen receiver
        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        // Screen turned ON - schedule notification
                        EyeCareWorker.scheduleReminder(context, 20)
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        // Screen turned OFF - cancel pending notifications
                        EyeCareWorker.cancelAllWork(context)
                    }
                }
            }
        }

        // Register receiver
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Create persistent notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Eye Care Monitor")
            .setContentText("Monitoring screen time for 20-20-20 rule")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

        startForeground(1, notification)

        // Start immediately
        EyeCareWorker.scheduleReminder(this, 20)

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister receiver
        unregisterReceiver(screenReceiver)
        EyeCareWorker.cancelAllWork(this)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Eye Care Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when eye care monitoring is active"
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    companion object {
        fun startService(context: Context) {
            val intent = Intent(context, EyeCareService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            context.stopService(Intent(context, EyeCareService::class.java))
        }
    }
}