package com.example.canvasdrawing

import android.app.Activity
import android.content.*
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "native_recorder"
    private val REQUEST_CODE = 1001
    private var projectionManager: MediaProjectionManager? = null
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val captureIntent = projectionManager?.createScreenCaptureIntent()
                    if (captureIntent != null) {
                        startActivityForResult(captureIntent, REQUEST_CODE)
                        result.success(null)
                    } else {
                        Log.e("MainActivity", "❌ Failed to create capture intent")
                        result.error("NO_INTENT", "Failed to create screen capture intent", null)
                    }
                }
                "stopRecording" -> {
                    stopService(Intent(this, ScreenRecordService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "com.example.canvasdrawing.RECORDING_COMPLETE") {
                    val path = intent.getStringExtra("filePath")
                    Log.d("MainActivity", "📹 영상 녹화 완료 path: $path")
                    if (::methodChannel.isInitialized) {
                        methodChannel.invokeMethod("onRecordingComplete", path)
                    } else {
                        Log.e("MainActivity", "❌ MethodChannel is not initialized")
                    }
                }
            }
        }

        val filter = IntentFilter("com.example.canvasdrawing.RECORDING_COMPLETE")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        Log.d("MainActivity", "📥 onActivityResult() 진입함")
        Log.d("MainActivity", "📦 requestCode=$requestCode, resultCode=$resultCode, data=$data")

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK && data != null) {
            Log.d("MainActivity", "✅ 조건 통과 → ScreenRecordService 시작")
            val serviceIntent = Intent(this, ScreenRecordService::class.java)
            serviceIntent.putExtra("resultCode", resultCode)
            serviceIntent.putExtra("data", data)
            startForegroundService(serviceIntent)
        } else {
            Log.e("MainActivity", "❌ 조건 불만족 → 서비스 실행 안 함")
        }
    }
}
