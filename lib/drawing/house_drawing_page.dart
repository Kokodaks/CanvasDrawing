import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import '../question/house_question_page.dart';
import '../drawing/stroke_point.dart';
import '../drawing/stroke_data.dart';
import '../services/api_service.dart';

// ─── Recorder Bridge ─────────────────────────────────────────
class RecorderBridge {
  static const MethodChannel _channel = MethodChannel('native_recorder');
  static Future<void> startRecording() =>
      _channel.invokeMethod('startRecording');
  static Future<void> stopRecording() =>
      _channel.invokeMethod('stopRecording');
}

// ─────────────────────────────────────────────────────────────
class HouseDrawingPage extends StatefulWidget {
  final int testId;
  final int childId;
  const HouseDrawingPage({
    required this.testId,
    required this.childId,
    Key? key,
  }) : super(key: key);

  @override
  State<HouseDrawingPage> createState() => _HouseDrawingPageState();
}

// ─────────────────────────────────────────────────────────────
class _HouseDrawingPageState extends State<HouseDrawingPage> {
  // ─── 드로잉 상태 ────────────────────────────────────────────
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];
  List<StrokeData> data = [];
  List<StrokeData> finalDrawingDataOnly = [];

  int    strokeStartTime = 0;
  int    strokeOrder     = 0;
  bool   isErasing       = false;
  Color  selectedColor   = Colors.black;

  final _canvasKey  = GlobalKey();
  final _repaintKey = GlobalKey();

  Timer?  _debounceTimer;
  bool    _modeJustChanged   = false;
  double  _accumulatedLength = 0;

  // ─── 녹화 상태 ─────────────────────────────────────────────
  bool              isRecording = false;
  bool _onCompleteHandled = false;
  bool              _recordingInProgress = false;
  bool              _uploadInProgress    = false;
  late Completer<void> _videoDone;

  // ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _videoDone = Completer<void>();

    const MethodChannel('native_recorder').setMethodCallHandler((call) async {
      if (call.method != 'onRecordingComplete') return;

      // ◀️ 이 가드가 없으면 계속 반복 처리됩니다!
      if (_onCompleteHandled) return;
      _onCompleteHandled = true;

      final path = call.arguments as String;
      print('[REC] onRecordingComplete path=$path');

      await uploadVideo(path);
      if (!_videoDone.isCompleted) _videoDone.complete();

      // 녹화 상태 해제 (UI 표시용)
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
  void startNewStroke(Offset globalPos, int time, double pressure) {
    if (!_isInCanvas(globalPos)) return;
    final position = _toLocal(globalPos);
    currentStroke = [
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: time,
      )
    ];
    print('[PTR] newStroke (#${strokeOrder + 1}) at $position  erase=$isErasing');
    if (_modeJustChanged && !isErasing) {
      _takeScreenshotDirectly();
      _modeJustChanged = false;
    }
    _restartDebounceTimer();
  }

  void addPointToStroke(Offset globalPos, int time, double pressure) {
    if (!_isInCanvas(globalPos)) return;
    final position = _toLocal(globalPos);
    final width    = _calculateStrokeWidthFromPressure(pressure);

    if (currentStroke.isNotEmpty) {
      final prev = currentStroke.last.offset!;
      _accumulatedLength += (position - prev).distance;
    }

    currentStroke.add(
      StrokePoint(offset: position, color: selectedColor, strokeWidth: width, t: time),
    );
    _handleLengthBasedCapture();
    _restartDebounceTimer();
  }

  void _endStroke() {
    if (currentStroke.isEmpty) return;
    strokeOrder++;

    final sd = StrokeData(
      isErasing: isErasing,
      strokeOrder: strokeOrder,
      strokeStartTime: strokeStartTime,
      points: currentStroke,
      color: selectedColor,
    );

    data.add(sd);
    finalDrawingDataOnly.add(sd);
    strokes.add(currentStroke);

    print('[DRAW] endStroke #$strokeOrder  totalStrokes=${strokes.length}');
    currentStroke = [];
  }

  void eraseStrokeAt(Offset globalTapPos) {
    if (!_isInCanvas(globalTapPos)) return;
    final tap = _toLocal(globalTapPos);

    final target = strokes.firstWhereOrNull(
          (stroke) => stroke.any(
            (p) => p.offset != null && (p.offset! - tap).distance <= 20,
      ),
    );

    if (target != null) {
      data.add(
        StrokeData(
          isErasing: true,
          strokeOrder: ++strokeOrder,
          strokeStartTime: DateTime.now().millisecondsSinceEpoch,
          points: target,
          color: selectedColor,
        ),
      );
      strokes.remove(target);
      finalDrawingDataOnly.removeWhere((sd) => identical(sd.points, target));
      print('[DRAW] eraseStroke len=${target.length}  remain=${strokes.length}');
    }


    setState(() {
      // UI 갱신을 강제로 호출하여 바로 지운 내용이 반영되도록 함
    });

      _restartDebounceTimer();
    }


  // ─── 캡처 타이머 & 길이 기반 캡처 ───────────────────────────
  void _restartDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && (strokes.isNotEmpty || currentStroke.isNotEmpty)) {
        _takeScreenshotDirectly();
      }
    });
  }

  void _handleLengthBasedCapture() {
    if (_accumulatedLength > 1000) {
      _takeScreenshotDirectly();
      _accumulatedLength = 0;
    }
  }

  // ─── 유틸 ───────────────────────────────────────────────────
  double _calculateStrokeWidthFromPressure(double pressure) {
    const double minWidth = 2.0;
    const double maxWidth = 20.0;
    return minWidth + (maxWidth - minWidth) * pressure.clamp(0.0, 1.0);
  }

  Offset _toLocal(Offset global) {
    final rb = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return rb?.globalToLocal(global) ?? Offset.zero;
  }

  bool _isInCanvas(Offset global) {
    final rb = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return false;
    final local = rb.globalToLocal(global);
    return local.dx >= 0 &&
        local.dy >= 0 &&
        local.dx <= rb.size.width &&
        local.dy <= rb.size.height;
  }

  // ─── 스크린샷 저장 ─────────────────────────────────────────
  Future<void> _takeScreenshotDirectly() async {
    try {
      final boundary =
      _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png   = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer.asUint8List();

      final dir = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : Directory('/storage/emulated/0/Download');
      final path = '${dir.path}/House_drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(png);
      print('🖼️ 스크린샷 저장 완료: $path');
    } catch (e) {
      print('스크린샷 실패: $e');
    }
  }

  // ─── 영상 업로드 ───────────────────────────────────────────
  Future<void> uploadVideo(String path) async {
    if (_uploadInProgress) return;
    _uploadInProgress = true;

    final uri = Uri.parse('http://10.30.122.19:3000/video/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['testId'] = widget.testId.toString()
      ..fields['name']   = 'house_drawing_recording';

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
                    Image.asset('assets/집을.png', width: 60),
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
                onPointerMove: (e) {
                  if (!isErasing) {
                    final t = DateTime
                        .now()
                        .millisecondsSinceEpoch - strokeStartTime;
                    setState(() => addPointToStroke(e.position, t, e.pressure));
                  }
                },
                onPointerUp: (_) {
                  if (!isErasing) setState(_endStroke);
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

          // ─── 녹화 버튼 ───
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: isRecording ? null : _startRecording,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRecording ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isRecording ? Icons.videocam : Icons.fiber_manual_record,
                  color: Colors.white,
                  size: 30,
                ),
              ),
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
                await _takeScreenshotDirectly();

                final allJson = data.map((e) => e.toJson()).toList();
                final finalJson = finalDrawingDataOnly.map((e) => e.toJson())
                    .toList();
                ApiService.sendStrokesWithMulter(
                  allJson,
                  finalJson,
                  testId: widget.testId,
                  childId: widget.childId,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HouseQuestionPage(
                          testId: widget.testId,
                          childId: widget.childId,
                        ),
                  ),
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
    for (final stroke in [...strokes, currentStroke]) {
      for (int i = 0; i < stroke.length - 1; i++) {
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        canvas.drawLine(
          p1.offset!,
          p2.offset!,
          Paint()
            ..color = p1.color
            ..strokeWidth = p1.strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
