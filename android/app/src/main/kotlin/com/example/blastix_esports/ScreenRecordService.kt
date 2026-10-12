package com.example.blastix_esports

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max
import kotlin.math.min

class ScreenRecordService : Service() {

    private val binder = LocalBinder()
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null

    private var isRecording = false
    private var outputPath: String? = null

    // Recording config parameters
    private var videoBitrate = 2500000
    private var maxHeight = 720
    private var fps = 30
    private var maxDurationMinutes = 60
    private var minFreeSpaceMb = 1500L

    // Match metadata
    private var tournamentId: String? = null
    private var matchKey: String? = null
    private var clientRecordingId: String? = null
    private var startedAtIso: String? = null
    private var startTimeMillis: Long = 0L
    private var actualWidth = 1280
    private var actualHeight = 720

    private var maxDurationHandler: Handler? = null
    private var maxDurationRunnable: Runnable? = null

    private var eventSink: EventChannel.EventSink? = null

    inner class LocalBinder : Binder() {
        fun getService(): ScreenRecordService = this@ScreenRecordService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    fun isRecordingActive(): Boolean = isRecording

    fun setEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

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
        if (intent?.action == ACTION_STOP_RECORDING) {
            Log.i(TAG, "Notification stop recording action triggered")
            stopRecordingInternal("notification_action")
            return START_NOT_STICKY
        }

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

                videoBitrate = it.getIntExtra(EXTRA_VIDEO_BITRATE, 2500000)
                maxHeight = it.getIntExtra(EXTRA_MAX_HEIGHT, 720)
                fps = it.getIntExtra(EXTRA_FPS, 30)
                maxDurationMinutes = it.getIntExtra(EXTRA_MAX_DURATION_MINUTES, 60)
                minFreeSpaceMb = it.getLongExtra(EXTRA_MIN_FREE_SPACE_MB, 1500L)

                tournamentId = it.getStringExtra(EXTRA_TOURNAMENT_ID)
                matchKey = it.getStringExtra(EXTRA_MATCH_KEY)
                clientRecordingId = it.getStringExtra(EXTRA_CLIENT_RECORDING_ID)

                if (resultData != null && filePath != null) {
                    startRecordingInternal(resultCode, resultData, filePath, screenWidth, screenHeight, screenDensity)
                } else {
                    Log.e(TAG, "Failed to extract resultData Intent or filePath from extras")
                    emitEvent("recordingFailed", mapOf(
                        "clientRecordingId" to (clientRecordingId ?: ""),
                        "errorCode" to "INVALID_EXTRAS",
                        "reason" to "Missing resultData or filePath"
                    ))
                }
            }
        }

        return START_NOT_STICKY
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
            Log.w(TAG, "Already recording")
            return true
        }

        // Storage Check
        val targetFile = File(filePath)
        val targetDir = targetFile.parentFile ?: filesDir
        val freeSpaceBytes = targetDir.freeSpace
        val minRequiredBytes = minFreeSpaceMb * 1024L * 1024L

        if (freeSpaceBytes < minRequiredBytes) {
            Log.e(TAG, "Insufficient disk space: $freeSpaceBytes bytes free, required $minRequiredBytes bytes")
            emitEvent("recordingFailed", mapOf(
                "clientRecordingId" to (clientRecordingId ?: ""),
                "errorCode" to "LOW_STORAGE",
                "reason" to "Free space ($freeSpaceBytes bytes) is below minimum required ($minRequiredBytes bytes)"
            ))
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return false
        }

        try {
            this.outputPath = filePath

            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, resultData)

            if (mediaProjection == null) {
                Log.e(TAG, "MediaProjection is null")
                emitEvent("recordingFailed", mapOf(
                    "clientRecordingId" to (clientRecordingId ?: ""),
                    "errorCode" to "PROJECTION_NULL",
                    "reason" to "MediaProjection service returned null"
                ))
                return false
            }

            // Android 14/15 Requirement: Register callback before creating VirtualDisplay
            mediaProjection?.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    Log.d(TAG, "MediaProjection callback onStop received")
                    if (isRecording) {
                        stopRecordingInternal("projection_stopped")
                    }
                }
            }, Handler(Looper.getMainLooper()))

            val densityDpi = screenDensity
            val minDim = min(screenWidth, screenHeight)
            val maxDim = max(screenWidth, screenHeight)

            // Dynamic resolution based on maxHeight config (default 720p)
            val targetMin = maxHeight
            val scale = targetMin.toDouble() / minDim.toDouble()
            var targetMax = ((maxDim * scale).toInt() / 2) * 2
            if (targetMax < 1280) targetMax = 1280

            // Always enforce LANDSCAPE orientation (width > height)
            actualWidth = targetMax
            actualHeight = targetMin

            Log.i(TAG, "Configuring MediaRecorder with landscape dimensions: ${actualWidth}x${actualHeight}, bitrate: $videoBitrate, fps: $fps")

            setupMediaRecorder(filePath, actualWidth, actualHeight)

            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "BlastIXScreenRecorder",
                actualWidth,
                actualHeight,
                densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                mediaRecorder?.surface,
                null,
                null
            )

            mediaRecorder?.start()
            isRecording = true
            startTimeMillis = System.currentTimeMillis()
            startedAtIso = getIsoTimestamp(startTimeMillis)

            scheduleMaxDurationTimer(maxDurationMinutes)

            Log.i(TAG, "Screen recording started successfully at ${actualWidth}x${actualHeight} -> $filePath")

            emitEvent("recordingStarted", mapOf(
                "clientRecordingId" to (clientRecordingId ?: ""),
                "filePath" to filePath,
                "startedAt" to (startedAtIso ?: "")
            ))

            return true

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start screen recording: ${e.message}", e)
            cleanupRecording()
            emitEvent("recordingFailed", mapOf(
                "clientRecordingId" to (clientRecordingId ?: ""),
                "errorCode" to "START_ERROR",
                "reason" to (e.message ?: "Unknown error starting recording")
            ))
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
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
        recorder.setVideoEncodingBitRate(videoBitrate)
        recorder.setVideoFrameRate(fps)
        recorder.setVideoSize(width, height)
        recorder.setOutputFile(filePath)

        recorder.prepare()
        this.mediaRecorder = recorder
    }

    private fun scheduleMaxDurationTimer(minutes: Int) {
        cancelMaxDurationTimer()
        if (minutes <= 0) return

        val delayMs = minutes * 60 * 1000L
        maxDurationHandler = Handler(Looper.getMainLooper())
        maxDurationRunnable = Runnable {
            if (isRecording) {
                Log.i(TAG, "Max recording duration ($minutes minutes) reached. Auto-stopping...")
                stopRecordingInternal("max_duration_reached")
                showAutoStoppedNotification("Max recording duration reached ($minutes mins).")
            }
        }
        maxDurationHandler?.postDelayed(maxDurationRunnable!!, delayMs)
    }

    private fun cancelMaxDurationTimer() {
        maxDurationRunnable?.let { maxDurationHandler?.removeCallbacks(it) }
        maxDurationHandler = null
        maxDurationRunnable = null
    }

    fun stopRecordingInternal(trigger: String = "manual"): String? {
        cancelMaxDurationTimer()
        val recordedPath = outputPath

        if (!isRecording) {
            Log.w(TAG, "Stop called but not active recording, returning recordedPath: $recordedPath")
            return recordedPath
        }

        val stopTimeMillis = System.currentTimeMillis()
        val stoppedAtIso = getIsoTimestamp(stopTimeMillis)
        val durationSeconds = max(1, ((stopTimeMillis - startTimeMillis) / 1000).toInt())

        Log.i(TAG, "Stopping screen recording (trigger: $trigger, duration: ${durationSeconds}s)...")

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

        var sizeBytes = 0L
        if (recordedPath != null) {
            val file = File(recordedPath)
            if (file.exists()) {
                sizeBytes = file.length()
                Log.i(TAG, "Recording file saved successfully: ${file.absolutePath} ($sizeBytes bytes)")
            } else {
                Log.w(TAG, "Recorded file does not exist at path: $recordedPath")
            }
        }

        val recData = mapOf(
            "file_path" to (recordedPath ?: ""),
            "started_at" to (startedAtIso ?: getIsoTimestamp(startTimeMillis)),
            "stopped_at" to stoppedAtIso,
            "duration_seconds" to durationSeconds,
            "size_bytes" to sizeBytes,
            "tournament_id" to (tournamentId ?: ""),
            "match_key" to (matchKey ?: ""),
            "recording_client_id" to (clientRecordingId ?: ""),
            "resolution" to "${actualWidth}x${actualHeight}",
            "trigger" to trigger
        )

        // Persist to SharedPreferences so upload survives app restarts
        persistPendingRecording(recData)

        // Broadcast event to Flutter if EventChannel is active
        emitEvent("recordingStopped", mapOf("recording" to recData))

        return recordedPath
    }

    private fun persistPendingRecording(data: Map<String, Any>) {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString("recordings_list", "[]") ?: "[]"
            val array = JSONArray(existingJson)

            val jsonObj = JSONObject()
            data.forEach { (key, value) ->
                jsonObj.put(key, value)
            }

            array.put(jsonObj)
            prefs.edit().putString("recordings_list", array.toString()).apply()
            Log.i(TAG, "Saved recording metadata to SharedPreferences ($PREFS_NAME)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist pending recording to SharedPreferences: ${e.message}")
        }
    }

    private fun emitEvent(eventType: String, data: Map<String, Any>) {
        val payload = HashMap<String, Any>(data)
        payload["event"] = eventType
        try {
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(payload)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error emitting event $eventType over EventChannel: ${e.message}")
        }
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
        cancelMaxDurationTimer()
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
        val stopIntent = Intent(this, ScreenRecordService::class.java).apply {
            action = ACTION_STOP_RECORDING
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val stopPendingIntent = PendingIntent.getService(this, 1001, stopIntent, flags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BlastiX Arena Match Recording Active")
            .setContentText("Recording Free Fire gameplay in background...")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(
                android.R.drawable.ic_media_pause,
                "STOP RECORDING",
                stopPendingIntent
            )
            .build()
    }

    private fun showAutoStoppedNotification(message: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BlastiX Match Recording Saved")
            .setContentText(message)
            .setSmallIcon(applicationInfo.icon)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        manager.notify(AUTO_STOP_NOTIFICATION_ID, notification)
    }

    private fun getIsoTimestamp(millis: Long): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date(millis))
    }

    companion object {
        private const val TAG = "ScreenRecordService"
        private const val CHANNEL_ID = "blastix_screen_recording_channel"
        private const val NOTIFICATION_ID = 9921
        private const val AUTO_STOP_NOTIFICATION_ID = 9922

        const val ACTION_STOP_RECORDING = "com.blastix.esports.ACTION_STOP_RECORDING"
        const val PREFS_NAME = "blastix_pending_recordings"

        const val EXTRA_RESULT_CODE = "extra_result_code"
        const val EXTRA_RESULT_DATA = "extra_result_data"
        const val EXTRA_FILE_PATH = "extra_file_path"
        const val EXTRA_SCREEN_WIDTH = "extra_screen_width"
        const val EXTRA_SCREEN_HEIGHT = "extra_screen_height"
        const val EXTRA_SCREEN_DENSITY = "extra_screen_density"

        const val EXTRA_VIDEO_BITRATE = "extra_video_bitrate"
        const val EXTRA_MAX_HEIGHT = "extra_max_height"
        const val EXTRA_FPS = "extra_fps"
        const val EXTRA_MAX_DURATION_MINUTES = "extra_max_duration_minutes"
        const val EXTRA_MIN_FREE_SPACE_MB = "extra_min_free_space_mb"

        const val EXTRA_TOURNAMENT_ID = "extra_tournament_id"
        const val EXTRA_MATCH_KEY = "extra_match_key"
        const val EXTRA_CLIENT_RECORDING_ID = "extra_client_recording_id"
    }
}
