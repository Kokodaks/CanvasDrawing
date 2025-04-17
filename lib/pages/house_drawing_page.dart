import 'package:flutter/material.dart';
import '../question/house_question_page.dart';
import 'dart:math';

class HouseDrawingPage extends StatefulWidget {
  @override
  _HouseDrawingPageState createState() => _HouseDrawingPageState();
}

class _HouseDrawingPageState extends State<HouseDrawingPage> {
  List<List<StrokePoint>> strokes = [];
  List<StrokePoint> currentStroke = [];

  double fixedBrushSize = 4.0;
  double eraserSize = 10.0;
  bool isErasing = false;
  Color selectedColor = Colors.black;

  void startNewStroke(Offset position) {
    currentStroke = [
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: fixedBrushSize,
      )
    ];
  }

  void addPointToStroke(Offset position) {
    currentStroke.add(
      StrokePoint(
        offset: position,
        color: selectedColor,
        strokeWidth: fixedBrushSize,
      ),
    );
  }

  void endStroke() {
    if (currentStroke.isNotEmpty) {
      strokes.add(currentStroke);
      currentStroke = [];
    }
  }

  void eraseStrokeAt(Offset tapPosition) {
    setState(() {
      strokes.removeWhere((stroke) {
        return stroke.any((point) =>
        point.offset != null &&
            (point.offset! - tapPosition).distance <= eraserSize);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  InstructionItem("1. 색상 선택하기", "색상 선택 도구를 원하는 색으로 바꿀 수 있어요"),
                  InstructionItem("2. 선 굵기 조절하기", "슬라이더를 이용해서 선의 굵기를 조절하세요"),
                  InstructionItem("3. 지우개 사용하기", "지우개 도구를 사용해 실수한 부분을 지워보세요"),
                  InstructionItem("4. 완료하기", "그림이 다 끝나면 '다음' 버튼을 눌러주세요"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text("펜: ", style: TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.create),
                  tooltip: "펜",
                  color: !isErasing ? Colors.black : Colors.grey,
                  onPressed: () => setState(() => isErasing = false),
                ),
                const SizedBox(width: 20),
                const Text("지우개: "),
                IconButton(
                  icon: const Icon(Icons.auto_fix_off),
                  tooltip: "지우개",
                  color: isErasing ? Colors.red : Colors.grey,
                  onPressed: () => setState(() => isErasing = true),
                ),
                const SizedBox(width: 4),
                const Text("지우개 크기:"),
                SizedBox(
                  width: 100,
                  child: Slider(
                    value: eraserSize,
                    min: 5,
                    max: 30,
                    onChanged: (value) => setState(() => eraserSize = value),
                  ),
                )
              ],
            ),
          ),
          Expanded(
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
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: StrokePainter(strokes, currentStroke),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          Padding(
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
          ),
        ],
      ),
    );
  }
}

class InstructionItem extends StatelessWidget {
  final String title;
  final String description;
  const InstructionItem(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(description, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
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
