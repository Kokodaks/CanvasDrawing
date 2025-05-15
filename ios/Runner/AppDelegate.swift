//
//  AppDelegate.swift
//  Runner
//

import UIKit
import Flutter
import ReplayKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var recorderChannel: FlutterMethodChannel!
  private var assetWriter: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var audioInput: AVAssetWriterInput?
  private var isRecording = false
  private var isSessionStarted = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    recorderChannel = FlutterMethodChannel(
      name: "native_recorder",
      binaryMessenger: controller.binaryMessenger
    )

    recorderChannel.setMethodCallHandler(handleRecorderCall)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleRecorderCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startRecording":
      startCapture(result: result)
    case "stopRecording":
      stopCapture(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startCapture(result: @escaping FlutterResult) {
    guard !isRecording else {
      result(nil)
      return
    }

    isRecording = true
    isSessionStarted = false

    let fileName = "rec_\(Int(Date().timeIntervalSince1970 * 1000)).mp4"
    let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try? FileManager.default.removeItem(at: outputURL)

    do {
      assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

      let screenSize = UIScreen.main.bounds.size
      let videoSettings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: screenSize.width * UIScreen.main.scale,
        AVVideoHeightKey: screenSize.height * UIScreen.main.scale
      ]
      videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
      videoInput?.expectsMediaDataInRealTime = true
      if let vInput = videoInput, assetWriter!.canAdd(vInput) {
        assetWriter!.add(vInput)
      }

      let audioSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 44100,
        AVEncoderBitRateKey: 128000
      ]
      audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
      audioInput?.expectsMediaDataInRealTime = true
      if let aInput = audioInput, assetWriter!.canAdd(aInput) {
        assetWriter!.add(aInput)
      }

    } catch {
      result(FlutterError(code: "WRITER_ERROR", message: error.localizedDescription, details: nil))
      return
    }

    RPScreenRecorder.shared().startCapture(
      handler: { [weak self] (sampleBuffer: CMSampleBuffer, sampleType: RPSampleBufferType, error: Error?) in
        guard let self = self, error == nil, self.isRecording else { return }

        if self.assetWriter?.status == .unknown && sampleType == .video {
          let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
          self.assetWriter?.startWriting()
          self.assetWriter?.startSession(atSourceTime: startTime)
          self.isSessionStarted = true
        }

        switch sampleType {
        case .video:
          if self.videoInput?.isReadyForMoreMediaData == true {
            self.videoInput?.append(sampleBuffer)
          }
        case .audioApp, .audioMic:
          if self.audioInput?.isReadyForMoreMediaData == true {
            self.audioInput?.append(sampleBuffer)
          }
        @unknown default:
          break
        }
      },
      completionHandler: { error in
        if let error = error {
          result(FlutterError(code: "CAPTURE_START_FAILED", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    )
  }

  private func stopCapture(result: @escaping FlutterResult) {
    guard isRecording else {
      result(nil)
      return
    }
    isRecording = false

    RPScreenRecorder.shared().stopCapture { [weak self] error in
      guard let self = self else { return }
      self.videoInput?.markAsFinished()
      self.audioInput?.markAsFinished()

      self.assetWriter?.finishWriting {
        if let url = self.assetWriter?.outputURL {
          print("🎬 녹화 완료 파일 경로:", url.path)
          if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
             let size = attrs[.size] as? UInt64 {
            print("🎬 파일 크기:", size, "bytes")
          }
          self.recorderChannel?.invokeMethod("onRecordingComplete", arguments: url.path)
        }
        result(nil)
      }
    }
  }
}
