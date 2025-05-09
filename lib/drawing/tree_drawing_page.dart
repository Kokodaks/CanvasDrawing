import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import '../question/Tree_question_page.dart';
import '../drawing/stroke_point.dart';
import '../drawing/stroke_data.dart';
import '../services/api_service.dart';

class TreeDrawingPage extends StatefulWidget {
  @override
  _TreeDrawingPageState createState() => _TreeDrawingPageState();
}

class _TreeDrawingPageState extends State<TreeDrawingPage> {
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];
  double eraserSize = 20.0;

  List<StrokeData> data = [];
  List<StrokeData> finalDrawingDataOnly = [];

  int strokeStartTime = 0;
  int strokeOrder = 0;

  bool isErasing = false;
  Color selectedColor = Colors.black;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();

  Timer? _debounceTimer;
  bool _modeJustChanged = false;

  double _accumulatedLength = 0.0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void startNewStroke(Offset globalPosition, int time, double pressure) {
    if (!_isInCanvas(globalPosition)) return;
    final position = _toLocal(globalPosition);  // 글로벌 좌표를 로컬 좌표로 변환
    currentStroke = [
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: time,
      )
    ];
    if (_modeJustChanged && !isErasing) {
      _takeScreenshotDirectly();
      _modeJustChanged = false;
    }
    _restartDebounceTimer();
  }

  void addPointToStroke(Offset globalPosition, int time, double pressure) {
    if (!_isInCanvas(globalPosition)) return;
    final position = _toLocal(globalPosition);  // 글로벌 좌표를 로컬 좌표로 변환
    final width = _calculateStrokeWidthFromPressure(pressure);

    if (currentStroke.isNotEmpty) {
      final prev = currentStroke.last.offset!;
      _accumulatedLength += (position - prev).distance;
    }

    currentStroke.add(
      StrokePoint(
          offset: position,
          color: selectedColor,
          strokeWidth: width,
          t: time
      ),
    );

    _handleLengthBasedCapture();
    _restartDebounceTimer();
  }

  void _endStroke() {
    if (currentStroke.isNotEmpty) {
      data.add(StrokeData(
        isErasing: isErasing,
        strokeOrder: strokeOrder,
        strokeStartTime: strokeStartTime,
        points: currentStroke,
        color: selectedColor,
      ));
      finalDrawingDataOnly.add(data.last);

      strokes.add(currentStroke);
      currentStroke = [];
    }
  }

  void eraseStrokeAt(Offset globalTapPosition) {
    if (!_isInCanvas(globalTapPosition)) return;
    final tapPosition = _toLocal(globalTapPosition);  // 글로벌 좌표를 로컬 좌표로 변환

    int beforeCount = strokes.length;

    final toBeErased = strokes.firstWhereOrNull((stroke) {
      return stroke.any((point) =>
      point.offset != null &&
          (point.offset! - tapPosition).distance <= eraserSize);
    });

    if(toBeErased != null){
      data.add(StrokeData(isErasing: isErasing, strokeOrder: strokeOrder, strokeStartTime: strokeStartTime, points: toBeErased, color: selectedColor));
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

    int afterCount = strokes.length;

    if (_modeJustChanged && isErasing && beforeCount > afterCount) {
      _takeScreenshotDirectly();
      _modeJustChanged = false;
    }

    _restartDebounceTimer();
  }

  void _restartDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
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

  double _calculateStrokeWidthFromPressure(double pressure) {
    const double minWidth = 2.0;
    const double maxWidth = 20.0;
    return minWidth + (maxWidth - minWidth) * pressure.clamp(0.0, 1.0);
  }

  Offset _toLocal(Offset globalPosition) {
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.globalToLocal(globalPosition);  // 글로벌 좌표를 로컬 좌표로 변환
  }

  bool _isInCanvas(Offset globalPosition) {
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final localPosition = renderBox.globalToLocal(globalPosition);  // 글로벌 좌표를 로컬 좌표로 변환
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= renderBox.size.width &&
        localPosition.dy <= renderBox.size.height;
  }

  Future<void> _takeScreenshotDirectly() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      String path;
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        path = '${directory.path}/Tree_drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/Tree_drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      } else {
        final directory = Directory('./');
        path = '${directory.path}/Tree_drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      }

      await File(path).writeAsBytes(pngBytes);
      print("✅ 저장 완료: $path");
    } catch (e) {
      print("❌ 스크린샷 실패: $e");
    }
  }

  void _triggerFlash() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildToolButton(String assetPath, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.orangeAccent, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.orangeAccent.withOpacity(0.6) : Colors.black26,
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Image.asset(
          assetPath,
          width: 60,
          height: 60,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final canvasWidth = screenWidth * 0.65;
    final canvasHeight = canvasWidth * (297 / 210); // A4 비율

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/tree_drawing_bg.png', fit: BoxFit.cover),
          ),
          Center(
            child: RepaintBoundary(
                key: _repaintKey,
                child:
                Listener(
                  onPointerDown: (PointerDownEvent event) {
                    final position = event.position;
                    strokeStartTime = DateTime.now().millisecondsSinceEpoch;
                    strokeOrder++;

                    if (isErasing) {
                      eraseStrokeAt(position);
                    } else {
                      setState(() => startNewStroke(position, 0, event.pressure));
                    }
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
                      setState(() => _endStroke());
                    }
                  },
                  child: Container(
                    key: _canvasKey,
                    width: canvasWidth,
                    height: canvasHeight,
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
                )
            ),
          ),
          Positioned(
            right: 32,
            top: screenHeight / 2 - 80,
            child: Column(
              children: [
                _buildToolButton('assets/pencil.png', () {
                  setState(() {
                    isErasing = false;
                    selectedColor = Colors.black;
                    _modeJustChanged = true;
                    _triggerFlash();
                  });
                }, !isErasing),
                const SizedBox(height: 24),
                _buildToolButton('assets/eraser.png', () {
                  setState(() {
                    isErasing = true;
                    _modeJustChanged = true;
                    _triggerFlash();
                  });
                }, isErasing),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 60,
            right: 60,
            child: ElevatedButton(
              onPressed: () async {
                // 스크린샷을 먼저 저장
                await _takeScreenshotDirectly();

                // JSON 데이터 보내기
                final allJsonData = data.map((stroke) => stroke.toJson()).toList();
                final finalJsonData =
                finalDrawingDataOnly.map((stroke) => stroke.toJson()).toList();
                ApiService.sendStrokesWithMulter(allJsonData, finalJsonData);

                // 그 후 화면 전환
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TreeQuestionPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('다 그렸어!', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

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
        final paint = Paint()
          ..color = p1.color
          ..strokeWidth = p1.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1.offset!, p2.offset!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
