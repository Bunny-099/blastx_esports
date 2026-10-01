package com.example.blastix_esports

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val GAME_LAUNCHER_CHANNEL = "com.blastix.esports/game_launcher"
    private val SCREEN_RECORDER_CHANNEL = "com.blastix.esports/screen_recorder"

    private val REQUEST_CODE_SCREEN_CAPTURE = 9981

    private var pendingFilePath: String? = null
    private var pendingResult: MethodChannel.Result? = null

    private var screenRecordService: ScreenRecordService? = null
    private var isBound = false

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, service: IBinder) {
            val binder = service as ScreenRecordService.LocalBinder
            screenRecordService = binder.getService()
            isBound = true
        }

        override fun onServiceDisconnected(arg0: ComponentName) {
            screenRecordService = null
            isBound = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    val filePath = call.argument<String>("filePath")
                    if (filePath.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                        return@setMethodCallHandler
                    }

                    pendingFilePath = filePath
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

                else -> result.notImplemented()
            }
        }
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
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }

                bindService(serviceIntent, connection, Context.BIND_AUTO_CREATE)

                // Return true immediately as mediaProjection permission is granted
                result?.success(true)
            } else {
                Log.w("MainActivity", "Screen capture permission denied or canceled by user")
                result?.success(false)
            }
        }
    }

    private fun stopScreenRecording(): String? {
        val path = screenRecordService?.stopRecordingInternal()
        if (isBound) {
            try {
                unbindService(connection)
            } catch (e: Exception) {
                // Ignore if already unbound
            }
            isBound = false
        }
        screenRecordService = null
        return path
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
