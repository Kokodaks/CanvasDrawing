package com.example.project

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
        val metrics = DisplayMetrics()
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager.defaultDisplay.getRealMetrics(metrics)

        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        savedFile = File(context.getExternalFilesDir(null), "recording_${System.currentTimeMillis()}.mp4")

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
                super.onStop()
                stopRecording()
            }
        }, null)

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenRecorder",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mediaRecorder?.surface, null, null
        )
    }

    fun stopRecording() {
        mediaRecorder?.apply {
            stop()
            reset()
            release()
        }
        virtualDisplay?.release()
        mediaProjection?.stop()

        val path = savedFile?.absolutePath ?: return
        val intent = Intent("com.example.project.RECORDING_COMPLETE")
        intent.putExtra("filePath", path)
        context.sendBroadcast(intent)
        Log.d("ScreenRecorder", "녹화 종료됨. 저장 위치: $path")
    }
}
