package com.example.screen_time_reminder

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import java.util.concurrent.TimeUnit

class EyeCareWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        Log.d("EyeCare", "Worker executing - showing notification")
        showNotification(applicationContext)

        // After showing notification, schedule the NEXT one
        scheduleNextReminder(applicationContext, 20)

        return Result.success()
    }

    private fun showNotification(context: Context) {
        val channelId = "eye_care_channel"
        val notificationId = 101

        // Create notification channel (if needed)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Eye Care Reminder",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminds you to take eye breaks"
                enableVibration(true)
            }
            context.getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        // Build notification
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("👀 Eye Care Reminder")
            .setContentText("Look 20 feet away for 20 seconds!")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        // Show notification
        context.getSystemService(NotificationManager::class.java)
            .notify(notificationId, notification)
    }

    companion object {
        fun scheduleReminder(context: Context, delayMinutes: Long = 20) {
            Log.d("EyeCare", "Scheduling FIRST notification for $delayMinutes minutes")

            // Cancel any existing work
            cancelAllWork(context)

            // Create FIRST work request with delay
            val firstWorkRequest = OneTimeWorkRequestBuilder<EyeCareWorker>()
                .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
                .addTag("eye_care_reminder")
                .build()

            // Enqueue the work
            androidx.work.WorkManager.getInstance(context)
                .enqueue(firstWorkRequest)
        }

        private fun scheduleNextReminder(context: Context, delayMinutes: Long = 20) {
            Log.d("EyeCare", "Scheduling NEXT notification for $delayMinutes minutes")

            // Schedule the next notification
            val nextWorkRequest = OneTimeWorkRequestBuilder<EyeCareWorker>()
                .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
                .addTag("eye_care_reminder")
                .build()

            androidx.work.WorkManager.getInstance(context)
                .enqueue(nextWorkRequest)
        }

        fun cancelAllWork(context: Context) {
            Log.d("EyeCare", "Cancelling all scheduled work")
            androidx.work.WorkManager.getInstance(context)
                .cancelAllWorkByTag("eye_care_reminder")
        }
    }
}