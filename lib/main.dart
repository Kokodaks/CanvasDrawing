import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

Future<void> main() async{
  await dotenv.load();
  runApp(DrawingApp());
  //실기기와 백엔드 (컴퓨터 로컬 포트 실행) 테스트
  // runApp(ApiTestApp());
}

class DrawingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}


class _DrawingPageState extends State<DrawingPage> {
  List<Map<String, dynamic>> currentStrokePoints = [];
  List<Map<String, dynamic>> allStrokes = [];
  int strokeStartTime = 0;
  int strokeOrder = 0;
  int startTime = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Canvas Drawing')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);

                if(currentStrokePoints.isEmpty){
                  strokeStartTime = DateTime.now().millisecondsSinceEpoch;
                }

                final currentTime = DateTime.now().millisecondsSinceEpoch;
                final relativeT = currentTime - strokeStartTime;

                setState(() {
                  currentStrokePoints.add({
                    "x": localPosition.dx,
                    "y": localPosition.dy,
                    "t": relativeT,
                  });
                });
              },
              onPanEnd: (_) {
                final strokeJson = {
                  "strokeOrder": strokeOrder,
                  "timestamp": strokeStartTime - startTime,
                  "color": "#000000",
                  "strokeWidth":4,
                  "points": List<Map<String, dynamic>>.from(currentStrokePoints)
                };

                setState((){
                  allStrokes.add(strokeJson);
                  currentStrokePoints.clear();
                  strokeOrder++;
                });

                print(jsonEncode(strokeJson));
              },
              child: CustomPaint(
                painter: MyPainter(
                  [
                    ...allStrokes.map((stroke) =>
                      (stroke['points'] as List).map<Offset>(
                          (p) => Offset(p['x'], p['y'])
                      ).toList()
                    ),
                    if(currentStrokePoints.isNotEmpty)
                      ...[currentStrokePoints.map((p) => Offset(p['x'], p['y'])).toList()]
                  ]
                ),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final response = await sendAllStrokes(allStrokes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response)),
          );
        },
        child: Icon(Icons.send),
      ),
    );
  }

  Future<String> sendAllStrokes(List<Map<String, dynamic>> strokes) async{
    final url = Uri.parse('${dotenv.env['IP_ADDR']}/upload');
    final headers = {'Content-Type': 'application/json'};
    try{
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"strokes": strokes}),
      );
      return response.statusCode == 200
          ? '서버 전송 성공!'
          : '서버 오류: {$response.statusCode}';
    }catch(e){
      return '전송 실패: $e';
    }
  }
}

class MyPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  MyPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (var stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) => true;
}
