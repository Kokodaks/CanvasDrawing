package com.example.project

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.IBinder
import android.util.Log

class ScreenRecordService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundService()

        val resultCode = intent?.getIntExtra("resultCode", Activity.RESULT_CANCELED) ?: return START_NOT_STICKY
        val data = intent.getParcelableExtra<Intent>("data") ?: return START_NOT_STICKY

        val recorder = ScreenRecorder(this, resultCode, data)
        recorder.startRecording()

        return START_NOT_STICKY
    }

    private fun startForegroundService() {
        val notificationChannelId = "screen_record_channel"
        val channel = NotificationChannel(
            notificationChannelId,
            "Screen Recording",
            NotificationManager.IMPORTANCE_LOW
        )
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)

        val notification = Notification.Builder(this, notificationChannelId)
            .setContentTitle("Recording screen...")
            .setContentText("Screen recording is in progress.")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .build()

        startForeground(1, notification)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
