import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:collection/collection.dart';
import '../question/house_question_page.dart';
import '../drawing/stroke_point.dart';
import '../drawing/stroke_data.dart';
import '../services/api_service.dart';

class HouseDrawingPage extends StatefulWidget {
  @override
  _HouseDrawingPageState createState() => _HouseDrawingPageState();
}

class _HouseDrawingPageState extends State<HouseDrawingPage> {
  List<StrokeData> data = [];
  List<StrokeData> finalDrawingDataOnly = [];
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];

  int strokeStartTime = 0;
  int strokeOrder = 0;
  int startTime = DateTime.now().millisecondsSinceEpoch;

  double fixedBrushSize = 10.0;
  double eraserSize = 10.0;
  bool isErasing = false;
  Color selectedColor = Colors.black;

  GlobalKey _repaintKey = GlobalKey();
  GlobalKey _canvasKey = GlobalKey();
  Timer? _debounceTimer;

  double _accumulatedArea = 0;
  bool _modeJustChanged = false;

  void startNewStroke(Offset globalPosition, int time) {
    if (!_isInCanvas(globalPosition)) return;
    final position = _toLocal(globalPosition);
    currentStroke = [
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: fixedBrushSize,
        t: time,
      )
    ];
    if (_modeJustChanged && !isErasing) {
      _takeScreenshotDirectly();
      _modeJustChanged = false;
    }
    _restartDebounceTimer();
  }

  void addPointToStroke(Offset globalPosition, int time) {
    if (!_isInCanvas(globalPosition)) return;
    final position = _toLocal(globalPosition);
    currentStroke.add(
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: fixedBrushSize,
        t: time
      ),
    );
    _accumulateArea();
    _handleAreaBasedCapture();
    _restartDebounceTimer();
  }

  void endStroke() {
    if (currentStroke.isNotEmpty) {
      data.add(StrokeData(isErasing: isErasing, strokeOrder: strokeOrder, strokeStartTime: strokeStartTime, points: currentStroke));
      finalDrawingDataOnly.add(StrokeData(isErasing: isErasing, strokeOrder: strokeOrder, strokeStartTime: strokeStartTime, points: currentStroke));

      strokes.add(currentStroke);
      currentStroke = [];
    }
  }

  void eraseStrokeAt(Offset globalTapPosition) {
    if (!_isInCanvas(globalTapPosition)) return;
    final tapPosition = _toLocal(globalTapPosition);

    int beforeCount = strokes.length;

    final toBeErased = strokes.firstWhereOrNull((stroke) {
      return stroke.any((point) =>
      point.offset != null &&
          (point.offset! - tapPosition).distance <= eraserSize);
    });

    if(toBeErased != null){
      data.add(StrokeData(isErasing: isErasing, strokeOrder: strokeOrder, strokeStartTime: strokeStartTime, points: toBeErased));
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

  void _handleAreaBasedCapture() {
    if (_accumulatedArea > 50000) {
      _takeScreenshotDirectly();
      _accumulatedArea = 0;
    }
  }

  void _accumulateArea() {
    _accumulatedArea += fixedBrushSize * fixedBrushSize;
  }

  Future<void> _takeScreenshotDirectly() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = Directory('/storage/emulated/0/Download');
      final path =
          '${directory.path}/capture_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      print('🖼️ 스크린샷 저장 완료: $path');
    } catch (e) {
      print('스크린샷 실패: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "집 그리기 안내",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          _buildToolbar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      color: Colors.white,
                      child: GestureDetector(
                        onPanStart: (details) {
                          final position = details.globalPosition;
                          strokeStartTime = DateTime.now().millisecondsSinceEpoch;
                          strokeOrder++;

                          if (isErasing) {
                            eraseStrokeAt(position);
                          } else {
                            setState(() => startNewStroke(position, 0));
                          }

                        },
                        onPanUpdate: (details) {
                          final position = details.globalPosition;
                          final currentTime = DateTime.now().millisecondsSinceEpoch;
                          final t = currentTime - strokeStartTime;
                          if (!isErasing) {
                            setState(() => addPointToStroke(position, t));
                          }
                        },
                        onPanEnd: (_) {
                          if (!isErasing) {
                            setState(() => endStroke());
                          }
                        },
                        child: CustomPaint(
                          painter: StrokePainter(strokes, currentStroke),
                          size: Size.infinite,
                          child: Container(
                            key: _canvasKey,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text("펜: ", style: TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.create),
            tooltip: "펜",
            color: !isErasing ? Colors.black : Colors.grey,
            onPressed: () {
              setState(() {
                isErasing = false;
                _modeJustChanged = true;
              });
            },
          ),
          const SizedBox(width: 20),
          const Text("지우개: "),
          IconButton(
            icon: const Icon(Icons.auto_fix_off),
            tooltip: "지우개",
            color: isErasing ? Colors.red : Colors.grey,
            onPressed: () {
              setState(() {
                isErasing = true;
                _modeJustChanged = true;
              });
            },
          ),
          const SizedBox(width: 10),
          const Text("펜 두께:"),
          Expanded(
            child: Slider(
              value: fixedBrushSize,
              min: 2,
              max: 50,
              onChanged: (value) => setState(() => fixedBrushSize = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ElevatedButton(
        onPressed: () async {
          final allJsonData = data.map((stroke) => stroke.toJson()).toList();
          final finalDrawingJsonData = finalDrawingDataOnly.map((stroke) => stroke.toJson()).toList();
          final result = await ApiService.sendAllStrokes(allJsonData, finalDrawingJsonData);
          debugPrint(result);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HouseQuestionPage()),
          );
        },
        child: const Text("다음으로 넘어가기 →", style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA726),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
