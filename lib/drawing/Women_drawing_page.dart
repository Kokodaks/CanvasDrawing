import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import '../drawing/stroke_point.dart';
import '../drawing/stroke_data.dart';
import '../services/api_service.dart';
import '../config/env_config.dart';

// ─── Recorder Bridge ─────────────────────────────────────────
class RecorderBridge {
  static const MethodChannel _channel = MethodChannel('native_recorder');
  static Future<void> startRecording() =>
      _channel.invokeMethod('startRecording');
  static Future<void> stopRecording() =>
      _channel.invokeMethod('stopRecording');
}

// ─────────────────────────────────────────────────────────────
class WomenDrawingPage extends StatefulWidget {
  final int testId;
  final int childId;
  final bool isMan;
  final VoidCallback onDrawingComplete;

  const WomenDrawingPage({
    required this.testId,
    required this.childId,
    required this.isMan,
    required this.onDrawingComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<WomenDrawingPage> createState() => _WomenDrawingPageState();
}

// ─────────────────────────────────────────────────────────────
class _WomenDrawingPageState extends State<WomenDrawingPage> {
  // ─── 드로잉 상태 ────────────────────────────────────────────
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];
  List<StrokeData> data = [];
  List<StrokeData> finalDrawingDataOnly = [];

  int    strokeStartTime = 0;
  int    strokeOrder     = 0;
  double eraserSize = 10.0;
  bool   isErasing       = false;
  Color  selectedColor   = Colors.black;

  final _canvasKey  = GlobalKey();
  final _repaintKey = GlobalKey();

  Timer?  _debounceTimer;
  bool    _modeJustChanged   = false;
  //double  _accumulatedLength = 0;

  // ─── 녹화 상태 ─────────────────────────────────────────────
  bool  isRecording = false;
  bool _onCompleteHandled = false;
  bool _recordingInProgress = false;
  bool _uploadInProgress = false;
  late Completer<void> _videoDone;

  // ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _videoDone = Completer<void>();
    _startRecording(); // ✅ 자동 녹화 시작

    const MethodChannel('native_recorder').setMethodCallHandler((call) async {
      if (call.method != 'onRecordingComplete') return;
      if (_onCompleteHandled) return;
      _onCompleteHandled = true;

      final path = call.arguments as String;
      print('[REC] onRecordingComplete path=$path');
      await uploadVideo(path);
      if (!_videoDone.isCompleted) _videoDone.complete();
      if (mounted) setState(() => isRecording = false);
      _recordingInProgress = false;
    });
  }

  Future<void> _startRecording() async {
    if (_recordingInProgress) return;
    _recordingInProgress     = true;
    _onCompleteHandled       = false;  // ← 녹화 시작할 때마다 “한 번만” 리셋

    print('[REC] startRecording() 호출');
    _videoDone = Completer<void>();
    try {
      await RecorderBridge.startRecording();
      if (mounted) setState(() => isRecording = true);
      print('[REC] startRecording() 성공');
    } catch (e) {
      print('[REC] startRecording() 예외: $e');
      _recordingInProgress = false;
    }
  }

  Future<void> _stopRecordingSafely() async {
    if (!_recordingInProgress) return;
    print('[REC] stopRecordingSafely() 호출');
    try {
      await RecorderBridge.stopRecording();
      print('[REC] stopRecording OK');
    } catch (e) {
      print('[REC] stopRecording 예외: $e');
    }
  }

  // ─── 드로잉 입력 ────────────────────────────────────────────
  void startNewStroke(Offset globalPosition, int time, double pressure) {
    if (!_isInCanvas(globalPosition)) return;
    final position = _toLocal(globalPosition);
    currentStroke = [
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: time,
      )
    ];
    if (_modeJustChanged && !isErasing) {
      // _takeScreenshotDirectly(); // 디바운싱 제거에 따라 주석 처리
      _modeJustChanged = false;
    }
    // _restartDebounceTimer(); // 디바운싱 제거
  }

  void addPointToStroke(Offset globalPosition, int time, double pressure) {
    if (!_isInCanvas(globalPosition)) return;
    final position = _toLocal(globalPosition);
    final width = _calculateStrokeWidthFromPressure(pressure);

    currentStroke.add(
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: width,
        t: time,
      ),
    );
  }

  // _handleLengthBasedCapture(); // 중간 캡처 제거
  // _restartDebounceTimer(); // 디바운싱 제거

  void endStroke() {
    if (currentStroke.isNotEmpty) {
      data.add(StrokeData(isErasing: isErasing, strokeOrder: strokeOrder, strokeStartTime: strokeStartTime, points: currentStroke, color: selectedColor));
      finalDrawingDataOnly.add(StrokeData(isErasing: isErasing, strokeOrder: strokeOrder, strokeStartTime: strokeStartTime, points: currentStroke, color: selectedColor));

      strokes.add(currentStroke);
      currentStroke = [];
    }
  }

  Future<Uint8List?> _takeScreenshotDirectly() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : Directory('/tmp');

      final path = '${dir.path}/women_drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      print('🖼️ 스크린샷 저장 완료: $path');
      return pngBytes;
    } catch (e) {
      print('스크린샷 실패: $e');
      return null;
    }
  }

  void eraseStrokeAt(Offset globalTapPosition) {
    if (!_isInCanvas(globalTapPosition)) return;
    final tapPosition = _toLocal(globalTapPosition);

    final toBeErased = strokes.firstWhereOrNull((stroke) =>
        stroke.any((point) =>
        point.offset != null &&
            (point.offset! - tapPosition).distance <= eraserSize));

    if (toBeErased != null) {
      data.add(StrokeData(isErasing: isErasing,
          strokeOrder: strokeOrder,
          strokeStartTime: strokeStartTime,
          points: toBeErased,
          color: selectedColor));
    }
    setState(() {
      strokes.removeWhere((stroke) {
        return stroke.any((point) =>
        point.offset != null &&
            (point.offset! - tapPosition).distance <= eraserSize);
      });
      finalDrawingDataOnly.removeWhere((strokeData) {
        return strokeData.points.any((point) =>
        point.offset != null &&
            (point.offset! - tapPosition).distance <= eraserSize);
      });
    });
  }
  // int afterCount = strokes.length;
//
// _takeScreenshotDirectly().then((pngBefore) {
//   if(isErasing && beforeCount > afterCount){
//     _takeScreenshotDirectly().then((pngAfter) {
//       if (pngBefore != null && pngAfter != null) {
//         final allJsonData = data.map((stroke) => stroke.toJsonOpenAi()).toList();
//         // ApiService.sendToOpenAi(pngBefore, pngAfter, allJsonData);
//       }
//     });
//   }
// });
//
// _restartDebounceTimer();

  Offset _toLocal(Offset globalPosition) {
    final renderBox =
    _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.globalToLocal(globalPosition);
  }

  bool _isInCanvas(Offset globalPosition) {
    final renderBox =
    _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final localPosition = renderBox.globalToLocal(globalPosition);
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= renderBox.size.width &&
        localPosition.dy <= renderBox.size.height;
  }

  // 디바운싱 함수 전체 주석 처리
  /*
  void _restartDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 15), () async {
      if (mounted) {
        if (strokes.isNotEmpty || currentStroke.isNotEmpty) {
          await _takeScreenshotDirectly();
        }
      }
    });
  }

  void _handleLengthBasedCapture() {
    if (_accumulatedLength > 1000) {
      _takeScreenshotDirectly();
      _accumulatedLength = 0;
    }
  }
  */

  // ─── 유틸 ───────────────────────────────────────────────────
  double _calculateStrokeWidthFromPressure(double pressure) {
    const double minWidth = 2.0;
    const double maxWidth = 10.0;
    final p = pressure.clamp(0.0, 1.0);
    return minWidth + (maxWidth - minWidth) * p;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }


  // ─── 영상 업로드 ───────────────────────────────────────────
  Future<void> uploadVideo(String path) async {
    if (_uploadInProgress) return;
    _uploadInProgress = true;

    final uri = Uri.parse('${EnvConfig.baseUrl}/video/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['testId'] = widget.testId.toString()
      ..fields['name']   = 'women_drawing_recording';

    try {
      req.files.add(await http.MultipartFile.fromPath('video', path));
      final res  = await req.send();
      final body = await res.stream.bytesToString();
      print('[API] 상태코드=${res.statusCode} body=$body');
    } catch (e) {
      print('[API] 업로드 예외: $e');
    } finally {
      _uploadInProgress = false;
    }
  }

  // ─── UI(Build) ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery
        .of(context)
        .size
        .width;
    final canvasW = sw * 0.8; // 기존 0.65보다 더 크게 확장
    final canvasH = canvasW * (297 / 210); // 비율은 유지 (A4 비율)

    return Scaffold(
      body: Stack(
        children: [
          // ─── 배경 이미지 ───
          Positioned.fill(
            child: Image.asset('assets/exercise.png', fit: BoxFit.cover),
          ),

          // ✅ 그림판 위쪽에 이미지 배치
          Positioned(
            top: 70,
            left: 45,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/house_tree.png', width: 80, height: 80),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/남자를.png', width: 60),
                    const SizedBox(height: 4),
                    Image.asset('assets/그려봐!.png', width: 80),
                  ],
                ),
              ],
            ),
          ),

          // ─── 그림판 (RepaintBoundary) ───
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Listener(
                onPointerDown: (e) {
                  strokeStartTime = DateTime
                      .now()
                      .millisecondsSinceEpoch;
                  isErasing
                      ? eraseStrokeAt(e.position)
                      : setState(() =>
                      startNewStroke(e.position, 0, e.pressure));
                },
                onPointerMove: (PointerMoveEvent event) {
                  final position = event.position;
                  final currentTime = DateTime.now().millisecondsSinceEpoch;
                  final t = currentTime - strokeStartTime;

                  if (!isErasing) {
                    setState(() => addPointToStroke(position, t, event.pressure));
                  }
                },
                onPointerUp: (_) {
                  if (!isErasing) {
                    setState(() => endStroke());
                  }
                },
                child: Container(
                  key: _canvasKey,
                  width: canvasW,
                  height: canvasH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.orange, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: StrokePainter(strokes, currentStroke),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── 도구 버튼 ───
          Positioned(
            right: 32,
            top: MediaQuery
                .of(context)
                .size
                .height / 2 - 80,
            child: Column(
              children: [
                _toolButton('assets/pencil.png', () {
                  setState(() {
                    isErasing = false;
                    selectedColor = Colors.black;
                    _modeJustChanged = true;
                  });
                }, !isErasing),
                const SizedBox(height: 24),
                _toolButton('assets/eraser.png', () {
                  setState(() {
                    isErasing = true;
                    _modeJustChanged = true;
                  });
                }, isErasing),
              ],
            ),
          ),

          // ─── 완료 버튼 ───
          Positioned(
            bottom: 40,
            left: 60,
            right: 60,
            child: ElevatedButton(
              onPressed: () async {
                await _stopRecordingSafely();
                final pngFinal = await _takeScreenshotDirectly();
                final finalJsonOpenAi = finalDrawingDataOnly.map((e) => e.toJsonOpenAi(widget.testId)).toList();
                if(pngFinal != null){
                  ApiService.sendFinalToOpenAi(pngFinal, finalJsonOpenAi, widget.testId, widget.childId, "women");
                }

                final allJson = data.map((e) => e.toJson(widget.testId)).toList();
                final finalJson = finalDrawingDataOnly.map((e) => e.toJson(widget.testId))
                    .toList();
                ApiService.sendStrokesWithMulter(
                    allJson,
                    finalJson,
                    widget.testId,
                    widget.childId,
                    "woman"
                );
                // ✅ createQnA 호출
                await ApiService.createQnA(
                  testId: widget.testId,
                  childId: widget.childId,
                  drawingType: "woman",
                );

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('다 그렸어!', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }


  // ─── 툴 버튼 헬퍼 ───────────────────────────────────────────
  Widget _toolButton(String asset, VoidCallback onTap, bool selected) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.orangeAccent, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: (selected ? Colors.orangeAccent : Colors.black26).withOpacity(0.6),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Image.asset(asset, width: 60, height: 60),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class StrokePainter extends CustomPainter {
  final List<List<StrokePoint>> strokes;
  final List<StrokePoint> currentStroke;

  StrokePainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    for (final stroke in [...strokes, currentStroke]) {
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i].offset != null && stroke[i + 1].offset != null) {
          final paint = Paint()
            ..color = stroke[i].color
            ..strokeWidth = stroke[i].strokeWidth
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.srcOver;
          canvas.drawLine(stroke[i].offset!, stroke[i + 1].offset!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}