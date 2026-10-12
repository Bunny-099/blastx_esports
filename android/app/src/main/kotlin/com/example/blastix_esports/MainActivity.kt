package com.example.blastix_esports

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.SharedPreferences
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    private val GAME_LAUNCHER_CHANNEL = "com.blastix.esports/game_launcher"
    private val SCREEN_RECORDER_CHANNEL = "com.blastix.esports/screen_recorder"
    private val SCREEN_RECORDER_EVENTS_CHANNEL = "com.blastix.esports/screen_recorder_events"

    private val REQUEST_CODE_SCREEN_CAPTURE = 9981

    private var pendingFilePath: String? = null
    private var pendingResult: MethodChannel.Result? = null

    // Config parameters saved before screen capture intent
    private var pendingVideoBitrate = 2500000
    private var pendingMaxHeight = 720
    private var pendingFps = 30
    private var pendingMaxDurationMinutes = 60
    private var pendingMinFreeSpaceMb = 1500L
    private var pendingTournamentId: String? = null
    private var pendingMatchKey: String? = null
    private var pendingClientRecordingId: String? = null

    private var screenRecordService: ScreenRecordService? = null
    private var isBound = false
    private var eventSink: EventChannel.EventSink? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as ScreenRecordService.LocalBinder
            screenRecordService = binder.getService()
            screenRecordService?.setEventSink(eventSink)
            isBound = true
            Log.i("MainActivity", "ScreenRecordService bound successfully")
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            screenRecordService?.setEventSink(null)
            screenRecordService = null
            isBound = false
            Log.i("MainActivity", "ScreenRecordService unbound")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel for recording events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_RECORDER_EVENTS_CHANNEL)
            .setStreamHandler(this)

        // Game Launcher MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GAME_LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPackageInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        result.success(checkPackageInstalled(packageName))
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                "launchPackage" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        result.success(launchAppPackage(packageName))
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Screen Recorder MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_RECORDER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    var filePath = call.argument<String>("filePath")
                    val minFreeSpaceMb = call.argument<Number>("minFreeSpaceMb")?.toLong() ?: 1500L

                    // Resolve default app-specific directory if path is null/empty
                    if (filePath.isNullOrEmpty()) {
                        val moviesDir = getExternalFilesDir(Environment.DIRECTORY_MOVIES) ?: filesDir
                        val timestamp = System.currentTimeMillis()
                        filePath = "${moviesDir.absolutePath}/match_record_${timestamp}.mp4"
                    }

                    // Disk storage check before requesting screen capture permission
                    val targetDir = java.io.File(filePath).parentFile ?: filesDir
                    val freeSpaceBytes = targetDir.freeSpace
                    val minRequiredBytes = minFreeSpaceMb * 1024L * 1024L

                    if (freeSpaceBytes < minRequiredBytes) {
                        Log.e("MainActivity", "Storage check failed: free $freeSpaceBytes bytes < required $minRequiredBytes bytes")
                        result.error("LOW_STORAGE", "Insufficient storage space ($freeSpaceBytes bytes free, minimum required is $minRequiredBytes bytes)", null)
                        return@setMethodCallHandler
                    }

                    pendingFilePath = filePath
                    pendingVideoBitrate = call.argument<Number>("videoBitrate")?.toInt() ?: 2500000
                    pendingMaxHeight = call.argument<Number>("maxHeight")?.toInt() ?: 720
                    pendingFps = call.argument<Number>("fps")?.toInt() ?: 30
                    pendingMaxDurationMinutes = call.argument<Number>("maxDurationMinutes")?.toInt() ?: 60
                    pendingMinFreeSpaceMb = minFreeSpaceMb
                    pendingTournamentId = call.argument<String>("tournamentId")
                    pendingMatchKey = call.argument<String>("matchKey")
                    pendingClientRecordingId = call.argument<String>("clientRecordingId")

                    pendingResult = result

                    val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    val captureIntent = projectionManager.createScreenCaptureIntent()
                    startActivityForResult(captureIntent, REQUEST_CODE_SCREEN_CAPTURE)
                }

                "stopRecording" -> {
                    val path = stopScreenRecording()
                    result.success(path)
                }

                "isRecording" -> {
                    val active = screenRecordService?.isRecordingActive() ?: false
                    result.success(active)
                }

                "getPendingRecordings" -> {
                    result.success(getPendingRecordingsFromPrefs())
                }

                "clearPendingRecording" -> {
                    val id = call.argument<String>("clientRecordingId")
                    if (!id.isNullOrEmpty()) {
                        clearPendingRecordingFromPrefs(id)
                    }
                    result.success(true)
                }

                "getRecordingDirectory" -> {
                    val moviesDir = getExternalFilesDir(Environment.DIRECTORY_MOVIES) ?: filesDir
                    result.success(moviesDir.absolutePath)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        screenRecordService?.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
        screenRecordService?.setEventSink(null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_SCREEN_CAPTURE) {
            val filePath = pendingFilePath
            val result = pendingResult

            pendingFilePath = null
            pendingResult = null

            if (resultCode == Activity.RESULT_OK && data != null && filePath != null) {
                val metrics = DisplayMetrics()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    display?.getRealMetrics(metrics)
                } else {
                    @Suppress("DEPRECATION")
                    windowManager.defaultDisplay.getMetrics(metrics)
                }

                val serviceIntent = Intent(this, ScreenRecordService::class.java).apply {
                    putExtra(ScreenRecordService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(ScreenRecordService.EXTRA_RESULT_DATA, data)
                    putExtra(ScreenRecordService.EXTRA_FILE_PATH, filePath)
                    putExtra(ScreenRecordService.EXTRA_SCREEN_WIDTH, metrics.widthPixels)
                    putExtra(ScreenRecordService.EXTRA_SCREEN_HEIGHT, metrics.heightPixels)
                    putExtra(ScreenRecordService.EXTRA_SCREEN_DENSITY, metrics.densityDpi)

                    putExtra(ScreenRecordService.EXTRA_VIDEO_BITRATE, pendingVideoBitrate)
                    putExtra(ScreenRecordService.EXTRA_MAX_HEIGHT, pendingMaxHeight)
                    putExtra(ScreenRecordService.EXTRA_FPS, pendingFps)
                    putExtra(ScreenRecordService.EXTRA_MAX_DURATION_MINUTES, pendingMaxDurationMinutes)
                    putExtra(ScreenRecordService.EXTRA_MIN_FREE_SPACE_MB, pendingMinFreeSpaceMb)

                    putExtra(ScreenRecordService.EXTRA_TOURNAMENT_ID, pendingTournamentId)
                    putExtra(ScreenRecordService.EXTRA_MATCH_KEY, pendingMatchKey)
                    putExtra(ScreenRecordService.EXTRA_CLIENT_RECORDING_ID, pendingClientRecordingId)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }

                bindService(serviceIntent, connection, Context.BIND_AUTO_CREATE)

                // Return true immediately as MediaProjection permission was granted
                result?.success(true)
            } else {
                Log.w("MainActivity", "Screen capture permission denied or canceled by user")
                result?.success(false)
            }
        }
    }

    private fun stopScreenRecording(): String? {
        val path = screenRecordService?.stopRecordingInternal("method_channel")
        if (isBound) {
            try {
                unbindService(connection)
            } catch (e: Exception) {
                // Ignore
            }
            isBound = false
        }
        screenRecordService = null
        return path
    }

    private fun getPendingRecordingsFromPrefs(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        try {
            val prefs = getSharedPreferences(ScreenRecordService.PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString("recordings_list", "[]") ?: "[]"
            val array = JSONArray(existingJson)

            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val map = mutableMapOf<String, Any>()
                val keys = obj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    map[k] = obj.get(k)
                }
                list.add(map)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error reading pending recordings from SharedPreferences: ${e.message}")
        }
        return list
    }

    private fun clearPendingRecordingFromPrefs(clientRecordingId: String) {
        try {
            val prefs = getSharedPreferences(ScreenRecordService.PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString("recordings_list", "[]") ?: "[]"
            val array = JSONArray(existingJson)
            val newArray = JSONArray()

            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.optString("recording_client_id") != clientRecordingId) {
                    newArray.put(obj)
                }
            }
            prefs.edit().putString("recordings_list", newArray.toString()).apply()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error clearing pending recording from SharedPreferences: ${e.message}")
        }
    }

    private fun checkPackageInstalled(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent != null
        } catch (e: Exception) {
            false
        }
    }

    private fun launchAppPackage(packageName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    override fun onDestroy() {
        if (isBound) {
            try {
                unbindService(connection)
            } catch (e: Exception) {
                // Ignore
            }
            isBound = false
        }
        super.onDestroy()
    }
}
