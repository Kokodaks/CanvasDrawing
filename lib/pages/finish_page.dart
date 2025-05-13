import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class FinishPage extends StatelessWidget {
  final int testId;

  const FinishPage({Key? key, required this.testId}) : super(key: key);

  Future<void> _markAsCompletedAndExit(BuildContext context) async {
    try {
      final uri = Uri.parse('${EnvConfig.baseUrl}/test/markTestAsCompleted');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'testid': testId}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ 검사 완료 상태 전송 성공");
      } else {
        debugPrint("⚠️ 전송 실패: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ 예외 발생: $e");
    } finally {
      SystemNavigator.pop(); // 전송이 끝났든 아니든 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/End.png',
              fit: BoxFit.cover,
            ),
          ),

          // 하단 버튼 (Android만 표시)
          if (isAndroid)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _markAsCompletedAndExit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '앱 종료하기',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}