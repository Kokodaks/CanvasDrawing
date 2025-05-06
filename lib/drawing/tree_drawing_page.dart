import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../question/tree_question_page.dart';
import '../drawing/stroke_point.dart';

class TreeDrawingPage extends StatefulWidget {
  @override
  _TreeDrawingPageState createState() => _TreeDrawingPageState();
}

class _TreeDrawingPageState extends State<TreeDrawingPage> {
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];

  bool isErasing = false;
  Color selectedColor = Colors.black;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();

  Timer? _debounceTimer;
  bool _modeJustChanged = false;
  bool _buttonFlash = false;

  double _accumulatedLength = 0.0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _restartDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
      if (mounted) await _takeScreenshot();
    });
  }

  Future<void> _takeScreenshot() async {
    try {
      RenderRepaintBoundary boundary =
      _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = Directory.systemTemp;
      final path = '${directory.path}/Tree_drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(pngBytes);
      print("✅ 저장 완료: $path");
    } catch (e) {
      print("❌ 스크린샷 실패: $e");
    }
  }

  void _startStroke(Offset position, double pressure) {
    if (!_isInDrawingArea(position)) return;
    Offset local = _toLocal(position);
    int t = DateTime.now().millisecondsSinceEpoch;
    currentStroke = [
      StrokePoint(
        offset: local,
        color: selectedColor,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: t,
      )
    ];
    if (_modeJustChanged) {
      _takeScreenshot();
      _modeJustChanged = false;
    }
    _restartDebounceTimer();
  }

  void _addPoint(Offset position, double pressure) {
    if (!_isInDrawingArea(position)) return;
    Offset local = _toLocal(position);
    int t = DateTime.now().millisecondsSinceEpoch;

    if (currentStroke.isNotEmpty) {
      Offset last = currentStroke.last.offset;
      _accumulatedLength += (local - last).distance;
      if (_accumulatedLength > 500) {
        _takeScreenshot();
        print('📏 누적 길이 초과: 500px. 현재 stroke 좌표:');
        for (final point in currentStroke) {
          print('🖊️ 좌표: (${point.offset.dx.toStringAsFixed(2)}, ${point.offset.dy.toStringAsFixed(2)}) 굵기: ${point.strokeWidth.toStringAsFixed(2)}');
        }
        _accumulatedLength = 0;
      }
    }

    currentStroke.add(
      StrokePoint(
        offset: local,
        color: selectedColor,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: t,
      ),
    );

    _restartDebounceTimer();
  }

  void _endStroke() {
    if (currentStroke.isNotEmpty) {
      strokes.add(currentStroke);
      print('✏️ Stroke 완료. 총 ${currentStroke.length}개 점');
      for (final point in currentStroke) {
        print('🖊️ 좌표: (${point.offset.dx.toStringAsFixed(2)}, ${point.offset.dy.toStringAsFixed(2)}) 굵기: ${point.strokeWidth.toStringAsFixed(2)}');
      }
      currentStroke = [];
    }
  }

  double _calculateStrokeWidthFromPressure(double pressure) {
    const double minWidth = 2.0;
    const double maxWidth = 20.0;
    return minWidth + (maxWidth - minWidth) * pressure.clamp(0.0, 1.0);
  }

  Offset _toLocal(Offset globalPosition) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition) ?? Offset.zero;
  }

  bool _isInDrawingArea(Offset globalPosition) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return false;
    final local = box.globalToLocal(globalPosition);
    return local.dx >= 0 &&
        local.dy >= 0 &&
        local.dx <= box.size.width &&
        local.dy <= box.size.height;
  }

  void _eraseStrokeAtPosition(Offset position) {
    final local = _toLocal(position);
    const double eraseRadius = 20.0;

    setState(() {
      strokes.removeWhere((stroke) {
        return stroke.any((point) => (point.offset - local).distance <= eraseRadius);
      });
    });

    if (_modeJustChanged) {
      _takeScreenshot();
      _modeJustChanged = false;
    }

    _restartDebounceTimer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final canvasWidth = screenWidth * 0.65;
    final canvasHeight = canvasWidth * (297 / 210);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/tree_drawing_bg.png', fit: BoxFit.cover),
          ),
          Center(
            child: RepaintBoundary(
              key: _repaintKey,
              child: Listener(
                onPointerDown: (event) {
                  if (isErasing) {
                    _eraseStrokeAtPosition(event.position);
                  } else {
                    setState(() => _startStroke(event.position, event.pressure));
                  }
                },
                onPointerMove: (event) {
                  if (!isErasing) {
                    setState(() => _addPoint(event.position, event.pressure));
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
              ),
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
              onPressed: () {
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

  void _triggerFlash() {
    _buttonFlash = true;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _buttonFlash = false;
        });
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
        child: Opacity(
          opacity: _buttonFlash && isSelected ? 0.6 : 1.0,
          child: Image.asset(
            assetPath,
            width: 60,
            height: 60,
          ),
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
        final p1 = stroke[i];
        final p2 = stroke[i + 1];
        final paint = Paint()
          ..color = p1.color
          ..strokeWidth = p1.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1.offset, p2.offset, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
