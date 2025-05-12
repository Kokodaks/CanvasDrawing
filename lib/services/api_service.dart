import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static final _baseUrl = dotenv.env['IP_ADDR'];

  static Future<void> sendToOpenAi(Uint8List pngBefore, Uint8List pngAfter,List<Map<String, dynamic>> allJsonData)async{
    final uri = Uri.parse('$_baseUrl/ai/sendToOpenAi');

    final request = http.MultipartRequest("POST", uri);

    final currentDrawing = jsonEncode(allJsonData);
    final currentDrawingBytes = utf8.encode(currentDrawing);

    request.files.add(
      http.MultipartFile.fromBytes(
          'beforeErase',
          pngBefore,
          filename:'beforeErase.png',
          contentType: MediaType('image', 'png')
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
          'afterErase',
          pngAfter,
          filename:'afterErase.png',
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



  static Future<void> sendFinalToOpenAi(Uint8List pngFinal, List<Map<String, dynamic>> finalJsonOpenAi) async {
    final uri = Uri.parse('$_baseUrl/ai/sendFinalToOpenAi');
    final request = http.MultipartRequest("POST", uri);

    final finalJsonDrawing = jsonEncode(finalJsonOpenAi);
    final finalDrawingBytes = utf8.encode(finalJsonDrawing);

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
      List<Map<String, dynamic>> finalJsonData, {
        required int testId, // 여기 int 타입
        required int childId,
      }) async {
    final uri = Uri.parse('$_baseUrl/reconstruction/sendStrokeData');

    final request = http.MultipartRequest("POST", uri);

    // 🔶 일반 폼 필드로 testId와 childId 추가
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
