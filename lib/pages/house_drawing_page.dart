import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../question/house_question_page.dart';

class HouseDrawingPage extends StatefulWidget {
  @override
  _HouseDrawingPageState createState() => _HouseDrawingPageState();
}

class _HouseDrawingPageState extends State<HouseDrawingPage> {
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];

  double fixedBrushSize = 10.0;
  double eraserSize = 10.0;
  bool isErasing = false;
  Color selectedColor = Colors.black;

  GlobalKey _repaintKey = GlobalKey();
  GlobalKey _canvasKey = GlobalKey();
  Timer? _debounceTimer;

  double _accumulatedArea = 0;
  bool _modeJustChanged = false;

  void startNewStroke(Offset position) {
    if (!_isInCanvas(position)) return;
    currentStroke = [
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: fixedBrushSize,
      )
    ];
    if (_modeJustChanged && !isErasing) {
      _takeScreenshotDirectly();
      _modeJustChanged = false;
    }
    _restartDebounceTimer();
  }

  void addPointToStroke(Offset position) {
    if (!_isInCanvas(position)) return;
    currentStroke.add(
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: fixedBrushSize,
      ),
    );
    _accumulateArea();
    _handleAreaBasedCapture();
    _restartDebounceTimer();
  }

  void endStroke() {
    if (currentStroke.isNotEmpty) {
      strokes.add(currentStroke);
      currentStroke = [];
    }
  }

  void eraseStrokeAt(Offset tapPosition) {
    if (!_isInCanvas(tapPosition)) return;

    int beforeCount = strokes.length;

    setState(() {
      strokes.removeWhere((stroke) {
        return stroke.any((point) =>
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

  bool _isInCanvas(Offset position) {
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final localPosition = renderBox.globalToLocal(position);
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
      final path = '${directory.path}/capture_${DateTime.now().millisecondsSinceEpoch}.png';
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
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: (details) {
                    final position = details.localPosition;
                    if (isErasing) {
                      eraseStrokeAt(position);
                    } else {
                      setState(() => startNewStroke(position));
                    }
                  },
                  onPanUpdate: (details) {
                    final position = details.localPosition;
                    if (!isErasing) {
                      setState(() => addPointToStroke(position));
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
        onPressed: () {
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

class StrokePoint {
  final Offset? offset;
  final Color color;
  final double strokeWidth;

  StrokePoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
  });
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
