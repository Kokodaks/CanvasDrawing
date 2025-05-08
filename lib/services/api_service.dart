import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final _baseUrl = dotenv.env['IP_ADDR'];

  static Future<String> sendAllStrokes(List<Map<String, dynamic>> allJsonData, List<Map<String, dynamic>> finalDrawingJsonData) async {
    final url = Uri.parse('$_baseUrl/reconstruction/sendStrokeData');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"drawing": allJsonData, "finalDrawing": finalDrawingJsonData}),
      );
      return response.statusCode == 200
          ? '서버 전송 성공!'
          : '서버 오류: ${response.statusCode}';
    } catch (e) {
      return '전송 실패: $e';
    }
  }
}
