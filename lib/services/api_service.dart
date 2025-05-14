import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static final _baseUrl = dotenv.env['IP_ADDR'];

  static Future<void> createQnA({
    required int testId,
    required int childId,
    required String drawingType,
  }) async {
    final url = Uri.parse('$_baseUrl/test/createQnA');

    final Map<String, dynamic> body = {
      "testId": testId,
      "childId": childId,
      "drawingType": drawingType,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('[✅] QnA 생성 성공: ${response.body}');
      } else if (response.body.contains('QnA already exists')) {
        print('[ℹ️] 이미 QnA가 존재하여 생성을 건너뜁니다.');
      } else {
        print('[❌] QnA 생성 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('[❌] QnA 요청 예외 발생: $e');
    }
  }



// ⛔️ 현재 디바운싱 기능 삭제로 인해 사용되지 않음
/*
  static Future<void> sendToOpenAi(Uint8List duringPng, List<Map<String, dynamic>> allJsonData, int testId, int childId, String type)async{
    final uri = Uri.parse('$_baseUrl/ai/sendToOpenAi');

    final request = http.MultipartRequest("POST", uri);

    final currentDrawing = jsonEncode(allJsonData);
    final currentDrawingBytes = utf8.encode(currentDrawing);

    request.fields['type'] = type;
    request.fields['testId'] = testId.toString();
    request.fields['childId'] = childId.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
          'duringPng',
          duringPng,
          filename:'beforeErase.png',
          contentType: MediaType('image', 'png')
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'currentDrawing',
        currentDrawingBytes,
        filename: 'current_drawing.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    final response = await request.send();
    print("응답: ${response.statusCode}");
  }
 */


  static Future<void> sendFinalToOpenAi(Uint8List pngFinal, List<Map<String, dynamic>> finalJsonOpenAi, int testId, int childId, String type) async {
    final uri = Uri.parse('$_baseUrl/ai/sendFinalToOpenAi');
    final request = http.MultipartRequest("POST", uri);

    final finalJsonDrawing = jsonEncode(finalJsonOpenAi);
    final finalDrawingBytes = utf8.encode(finalJsonDrawing);

    request.fields['type'] = type;
    request.fields['testId'] = testId.toString();
    request.fields['childId'] = childId.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'finalDrawing',
        finalDrawingBytes,
        filename: 'final_drawing.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
          'finalImage',
          pngFinal,
          filename:'finalPng.png',
          contentType: MediaType('image', 'png')
      ),
    );
    final response = await request.send();
    print("응답: ${response.statusCode}");

  }

  static Future<void> sendStrokesWithMulter(
      List<Map<String, dynamic>> allJsonData,
      List<Map<String, dynamic>> finalJsonData,
      int testId, int childId, String type) async {
    final uri = Uri.parse('$_baseUrl/reconstruction/sendStrokeData');

    final request = http.MultipartRequest("POST", uri);

    // 🔶 일반 폼 필드로 testId와 childId 추가
    request.fields['type'] = type;
    request.fields['testId'] = testId.toString();
    request.fields['childId'] = childId.toString();

    // 🔶 drawing.json 첨부
    final jsonDrawing = jsonEncode(allJsonData);
    final drawingBytes = utf8.encode(jsonDrawing);

    request.files.add(
      http.MultipartFile.fromBytes(
        'drawing',
        drawingBytes,
        filename: 'drawing.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    // 🔶 final_drawing.json 첨부
    final finalJsonDrawing = jsonEncode(finalJsonData);
    final finalDrawingBytes = utf8.encode(finalJsonDrawing);

    request.files.add(
      http.MultipartFile.fromBytes(
        'finalDrawing',
        finalDrawingBytes,
        filename: 'final_drawing.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    // 🔶 전송 및 응답 확인
    try {
      final response = await request.send();
      print("✅ 전송 완료: 상태코드 ${response.statusCode}");
    } catch (e) {
      print("❌ 전송 실패: $e");
    }
  }
}

