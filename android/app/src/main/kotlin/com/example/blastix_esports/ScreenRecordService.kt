package com.example.blastix_esports

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.io.File

class ScreenRecordService : Service() {

    private val binder = LocalBinder()
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null

    private var isRecording = false
    private var outputPath: String? = null

    inner class LocalBinder : Binder() {
        fun getService(): ScreenRecordService = this@ScreenRecordService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error starting foreground service with type: ${e.message}")
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        intent?.let {
            if (it.hasExtra(EXTRA_RESULT_CODE) && it.hasExtra(EXTRA_RESULT_DATA)) {
                val resultCode = it.getIntExtra(EXTRA_RESULT_CODE, 0)
                val resultData = it.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
                val filePath = it.getStringExtra(EXTRA_FILE_PATH)

                if (resultData != null && filePath != null) {
                    startRecordingInternal(resultCode, resultData, filePath)
                }
            }
        }

        return START_NOT_STICKY
    }

    fun startRecordingInternal(resultCode: Int, resultData: Intent, filePath: String): Boolean {
        if (isRecording) {
            Log.w(TAG, "Already recording")
            return false
        }

        try {
            this.outputPath = filePath

            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, resultData)

            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection is null")
                return false
            }

            // Register callback for Android Q+ media projection stop
            mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.d(TAG, "MediaProjection stopped by system or user")
                    stopRecordingInternal()
                }
            }, null)

            val windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val metrics = DisplayMetrics()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display?.getRealMetrics(metrics)
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getMetrics(metrics)
            }

            var width = metrics.widthPixels
            var height = metrics.heightPixels
            val densityDpi = metrics.densityDpi

            // Scale down for 480p match recording efficiency
            val targetHeight = 480
            if (height > targetHeight) {
                val ratio = targetHeight.toDouble() / height.toDouble()
                width = ((width * ratio).toInt() / 2) * 2 // Ensure even width
                height = targetHeight
            }

            setupMediaRecorder(filePath, width, height)

            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "BlastIXScreenRecorder",
                width,
                height,
                densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mediaRecorder?.surface,
                null,
                null
            )

            mediaRecorder?.start()
            isRecording = true
            Log.i(TAG, "Screen recording started successfully at 480p -> $filePath")
            return true

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start screen recording: ${e.message}", e)
            cleanupRecording()
            return false
        }
    }

    private fun setupMediaRecorder(filePath: String, width: Int, height: Int) {
        val file = File(filePath)
        file.parentFile?.mkdirs()

        @Suppress("DEPRECATION")
        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            MediaRecorder()
        }

        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        recorder.setVideoEncodingBitRate(600000) // 600 Kbps optimized for 480p clear video & 15-min full match under 60 MB
        recorder.setVideoFrameRate(30)
        recorder.setVideoSize(width, height)
        recorder.setOutputFile(filePath)

        recorder.prepare()
        this.mediaRecorder = recorder
    }

    fun stopRecordingInternal(): String? {
        if (!isRecording) {
            Log.w(TAG, "Stop called but not recording")
            return outputPath
        }

        val recordedPath = outputPath
        Log.i(TAG, "Stopping screen recording...")

        try {
            mediaRecorder?.stop()
        } catch (e: RuntimeException) {
            Log.e(TAG, "MediaRecorder stop failed (possibly too short): ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping MediaRecorder: ${e.message}")
        }

        cleanupRecording()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()

        if (recordedPath != null) {
            val file = File(recordedPath)
            if (file.exists()) {
                Log.i(TAG, "Recording file saved successfully: ${file.absolutePath} (${file.length()} bytes)")
            }
        }

        return recordedPath
    }

    private fun cleanupRecording() {
        try {
            mediaRecorder?.reset()
            mediaRecorder?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaRecorder: ${e.message}")
        }
        mediaRecorder = null

        try {
            virtualDisplay?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing VirtualDisplay: ${e.message}")
        }
        virtualDisplay = null

        try {
            mediaProjection?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping MediaProjection: ${e.message}")
        }
        mediaProjection = null

        isRecording = false
    }

    override fun onDestroy() {
        if (isRecording) {
            cleanupRecording()
        }
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "BlastIX Match Recording",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification displayed while BlastIX records match gameplay"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BlastIX Match Recording Active")
            .setContentText("Recording Free Fire gameplay in background...")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        private const val TAG = "ScreenRecordService"
        private const val CHANNEL_ID = "blastix_screen_recording_channel"
        private const val NOTIFICATION_ID = 9921

        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_DATA = "extra_result_data"
        const val EXTRA_FILE_PATH = "extra_file_path"
    }
}
