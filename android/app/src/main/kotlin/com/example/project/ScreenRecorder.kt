package com.example.canvasdrawing

import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import java.io.File

class ScreenRecorder(
    private val context: Context,
    private val resultCode: Int,
    private val data: Intent
) {
    private val mediaProjectionManager =
        context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var mediaRecorder: MediaRecorder? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var savedFile: File? = null

    fun startRecording() {
        Log.d("ScreenRecorder", "📹 startRecording() 호출됨")

        val metrics = DisplayMetrics()
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager.defaultDisplay.getRealMetrics(metrics)

        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        savedFile = File(
            context.getExternalFilesDir(null),
            "recording_${System.currentTimeMillis()}.mp4"
        )
        Log.d("ScreenRecorder", "✅ 저장 파일 경로: ${savedFile?.absolutePath}")

        mediaRecorder = MediaRecorder().apply {
            setVideoSource(MediaRecorder.VideoSource.SURFACE)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setOutputFile(savedFile!!.absolutePath)
            setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            setVideoEncodingBitRate(512 * 1000)
            setVideoFrameRate(30)
            setVideoSize(width, height)
            prepare()
            start()
        }

        mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                Log.d("ScreenRecorder", "📴 mediaProjection onStop 호출됨")
                stopRecording()
            }
        }, null)

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenRecorder",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mediaRecorder?.surface, null, null
        )

        Log.d("ScreenRecorder", "✅ VirtualDisplay 생성 완료")
    }

    fun stopRecording() {
        Log.d("ScreenRecorder", "🛑 stopRecording() 호출됨")

        try {
            mediaRecorder?.apply {
                stop()
                reset()
                release()
            }
            Log.d("ScreenRecorder", "✅ mediaRecorder 정상 종료")
        } catch (e: Exception) {
            Log.e("ScreenRecorder", "❌ mediaRecorder 중지 중 예외: $e")
        }

        virtualDisplay?.release()
        mediaProjection?.stop()
        Log.d("ScreenRecorder", "🧹 VirtualDisplay 및 mediaProjection 정리 완료")

        val path = savedFile?.absolutePath ?: run {
            Log.e("ScreenRecorder", "❌ 저장된 파일 경로가 null입니다.")
            return
        }

        val intent = Intent("com.example.canvasdrawing.RECORDING_COMPLETE")  // ✅ 여기 수정됨
        intent.putExtra("filePath", path)
        context.sendBroadcast(intent)

        Log.d("ScreenRecorder", "📤 Broadcast 전송 완료: path=$path")
    }
}
