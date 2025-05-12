import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../drawing/stroke_point.dart';
import '../pages/House_IntroPage.dart';

class ExerciseDrawingPage extends StatefulWidget {
  final int testId;
  final int childId;

  const ExerciseDrawingPage({
    required this.testId,
    required this.childId,
    Key? key,
  }) : super(key: key);

  @override
  State<ExerciseDrawingPage> createState() => _ExerciseDrawingPageState();
}

class _ExerciseDrawingPageState extends State<ExerciseDrawingPage> {
  final List<List<StrokePoint>> _strokes = [];
  List<StrokePoint> _currentStroke = [];
  bool _isErasing = false;

  final GlobalKey _canvasKey = GlobalKey();

  void _startStroke(Offset position, double pressure) {
    _currentStroke = [
      StrokePoint(
        offset: position,
        color: Colors.black,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: 0,
      )
    ];
  }

  void _addPoint(Offset position, double pressure) {
    _currentStroke.add(
      StrokePoint(
        offset: position,
        color: Colors.black,
        strokeWidth: _calculateStrokeWidthFromPressure(pressure),
        t: 0,
      ),
    );
    setState(() {});
  }

  void _endStroke() {
    if (_currentStroke.isNotEmpty) {
      _strokes.add(_currentStroke);
      _currentStroke = [];
    }
  }

  void _eraseStrokeAt(Offset position) {
    const double eraseRadius = 20.0;

    final toErase = _strokes.firstWhereOrNull((stroke) {
      return stroke.any((point) =>
      point.offset != null &&
          (point.offset! - position).distance <= eraseRadius);
    });

    if (toErase != null) {
      setState(() {
        _strokes.remove(toErase);
      });
    }
  }

  double _calculateStrokeWidthFromPressure(double pressure) {
    const double minWidth = 2.0;
    const double maxWidth = 10.0;
    return minWidth + (maxWidth - minWidth) * pressure.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final canvasWidth = screenWidth * 0.8;
    final canvasHeight = canvasWidth * (297 / 210);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/exercise.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "테스트 페이지입니다",
                style: TextStyle(
                  fontFamily: 'TJJoyofsingingEB_TTF',
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2.0,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Listener(
              onPointerDown: (event) {
                if (_isErasing) {
                  _eraseStrokeAt(event.localPosition);
                } else {
                  _startStroke(event.localPosition, event.pressure);
                }
              },
              onPointerMove: (event) {
                if (!_isErasing) {
                  _addPoint(event.localPosition, event.pressure);
                }
              },
              onPointerUp: (_) {
                if (!_isErasing) {
                  _endStroke();
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
                    painter: _StrokePainter(_strokes, _currentStroke),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 32,
            top: MediaQuery.of(context).size.height / 2 - 80,
            child: Column(
              children: [
                _toolButton('assets/pencil.png', false),
                const SizedBox(height: 24),
                _toolButton('assets/eraser.png', true),
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
                  MaterialPageRoute(
                    builder: (context) => HouseIntroPage(
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
              child: const Text(
                '연습이 끝났어!!',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(String assetPath, bool eraserMode) {
    final selected = _isErasing == eraserMode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isErasing = eraserMode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.orangeAccent, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: selected ? Colors.orangeAccent.withOpacity(0.6) : Colors.black26,
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Image.asset(assetPath, width: 60, height: 60),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<StrokePoint>> strokes;
  final List<StrokePoint> currentStroke;

  _StrokePainter(this.strokes, this.currentStroke);

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
