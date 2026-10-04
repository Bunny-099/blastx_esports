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
import androidx.core.app.NotificationCompat
import java.io.File
import kotlin.math.max
import kotlin.math.min

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

    fun isRecordingActive(): Boolean = isRecording

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun <T : android.os.Parcelable> Intent.getParcelableExtraCompat(key: String, clazz: java.lang.Class<T>): T? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            this.getParcelableExtra(key, clazz)
        } else {
            @Suppress("DEPRECATION")
            this.getParcelableExtra(key)
        }
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
                Log.e(TAG, "Error starting foreground service: ${e.message}")
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        intent?.let {
            if (it.hasExtra(EXTRA_RESULT_CODE) && it.hasExtra(EXTRA_RESULT_DATA)) {
                val resultCode = it.getIntExtra(EXTRA_RESULT_CODE, 0)
                val resultData = it.getParcelableExtraCompat(EXTRA_RESULT_DATA, Intent::class.java)
                val filePath = it.getStringExtra(EXTRA_FILE_PATH)
                val screenWidth = it.getIntExtra(EXTRA_SCREEN_WIDTH, 1080)
                val screenHeight = it.getIntExtra(EXTRA_SCREEN_HEIGHT, 2400)
                val screenDensity = it.getIntExtra(EXTRA_SCREEN_DENSITY, DisplayMetrics.DENSITY_DEFAULT)

                if (resultData != null && filePath != null) {
                    startRecordingInternal(resultCode, resultData, filePath, screenWidth, screenHeight, screenDensity)
                } else {
                    Log.e(TAG, "Failed to extract resultData Intent or filePath from extras")
                }
            }
        }

        return Service.START_NOT_STICKY
    }

    fun startRecordingInternal(
        resultCode: Int,
        resultData: Intent,
        filePath: String,
        screenWidth: Int,
        screenHeight: Int,
        screenDensity: Int
    ): Boolean {
        if (isRecording) {
            Log.w(TAG, "Already recording, returning true")
            return true
        }

        try {
            this.outputPath = filePath

            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, resultData)

            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection is null")
                return false
            }

            mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.d(TAG, "MediaProjection callback onStop received")
                }
            }, null)

            var width = screenWidth
            var height = screenHeight
            val densityDpi = screenDensity

            val minDim = min(width, height)
            val maxDim = max(width, height)

            val scale = 480.0 / minDim.toDouble()
            val targetMin = 480
            var targetMax = ((maxDim * scale).toInt() / 16) * 16
            if (targetMax < 640) targetMax = 640

            if (width > height) {
                width = targetMax
                height = targetMin
            } else {
                width = targetMin
                height = targetMax
            }

            Log.i(TAG, "Configuring MediaRecorder with dimensions: ${width}x${height}, densityDpi: $densityDpi")

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
            Log.i(TAG, "Screen recording started successfully at 480p (${width}x${height}) -> $filePath")
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
        val recordedPath = outputPath
        if (!isRecording) {
            Log.w(TAG, "Stop called but not active recording, returning recordedPath: $recordedPath")
            return recordedPath
        }

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
            } else {
                Log.w(TAG, "Recorded file does not exist at path: $recordedPath")
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
                "BlastiX Arena Match Recording",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification displayed while BlastiX Arena records match gameplay"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BlastiX Arena Match Recording Active")
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
        const val EXTRA_SCREEN_WIDTH = "extra_screen_width"
        const val EXTRA_SCREEN_HEIGHT = "extra_screen_height"
        const val EXTRA_SCREEN_DENSITY = "extra_screen_density"
    }
}
