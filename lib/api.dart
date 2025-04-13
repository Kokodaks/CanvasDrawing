import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() => runApp(ApiTestApp());

class ApiTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ApiTestPage(),
    );
  }
}

class ApiTestPage extends StatelessWidget {
  final String apiUrl = "${dotenv.env['IP_ADDR']}/ping";

  Future<void> testConnection(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("서버 응답"),
          content: Text("응답: ${response.body}"),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("에러"),
          content: Text("접속 실패: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("API Ping Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => testConnection(context),
          child: Text("서버 연결 테스트"),
        ),
      ),
    );
  }
}
