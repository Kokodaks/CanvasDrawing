//
//  AppDelegate.swift
//  Runner
//
//  Created by YourName on 2025-05-11.
//

import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  // MethodChannel을 여기서도 참조할 수 있게 필드로 보관
  private var recorderChannel: FlutterMethodChannel!
  // 더미(또는 실녹화) 파일 경로
  private var outputURL: URL!

  // ──────────────────────────────────────────────
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1. 기본 Flutter 설정
    let controller = window.rootViewController as! FlutterViewController

    // 2. MethodChannel 생성 (이름 반드시 Flutter와 동일: native_recorder)
    recorderChannel = FlutterMethodChannel(
      name: "native_recorder",
      binaryMessenger: controller.binaryMessenger)

    // 3. Dart → iOS 호출 처리
    recorderChannel.setMethodCallHandler(handleRecorderCall)

    // 4. Flutter 플러그인 자동 등록
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application,
                             didFinishLaunchingWithOptions: launchOptions)
  }

  // ──────────────────────────────────────────────
  /// Dart 쪽에서 호출되는 startRecording / stopRecording 처리
  private func handleRecorderCall(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult) {
    switch call.method {

    case "startRecording":
      NSLog("✅ iOS startRecording")
      startDummyRecording()
      result(nil)               // Dart Future complete

    case "stopRecording":
      NSLog("🛑 iOS stopRecording")
      stopDummyRecording()      // 내부에서 invokeMethod 호출
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // ──────────────────────────────────────────────
  //  아래는 '더미' 녹화 구현입니다.
  //  실제 녹화를 하려면 ReplayKit 또는 AVAssetWriter 로 교체하세요.
  // ──────────────────────────────────────────────

  /// 녹화 시작: 임시 파일 경로만 만들어 둠
  private func startDummyRecording() {
    let tmp = FileManager.default.temporaryDirectory
    let fileName = "rec_\(Int(Date().timeIntervalSince1970)).mov"
    outputURL = tmp.appendingPathComponent(fileName)
    // 실제 녹화를 한다면 여기서 세션을 시작
  }

  /// 녹화 종료: 1초 지연 후 onRecordingComplete 콜백 전송
  private func stopDummyRecording() {
      // 1) 빈 파일 생성 (한 바이트라도 쓰면 OK)
      do {
          try Data().write(to: outputURL)      // 0-byte 파일
      } catch {
          NSLog("❌ dummy file write error \(error)")
      }

      // 2) onRecordingComplete 콜백
      DispatchQueue.main.async {
          self.recorderChannel.invokeMethod("onRecordingComplete",
                                            arguments: self.outputURL.path)
          NSLog("📤 onRecordingComplete \(self.outputURL!.path)")
      }
  }

}
