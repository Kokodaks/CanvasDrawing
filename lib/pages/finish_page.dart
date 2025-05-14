import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class FinishPage extends StatefulWidget {
  final int testId;

  const FinishPage({Key? key, required this.testId}) : super(key: key);

  @override
  _FinishPageState createState() => _FinishPageState();
}

class _FinishPageState extends State<FinishPage> {
  bool _hasSent = false;  // 중복 전송 방지

  @override
  void initState() {
    super.initState();
    // 페이지에 진입하자마자 한 번만 API 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSent) {
        _hasSent = true;
        _markAsCompletedAndExit();
      }
    });
  }

  Future<void> _markAsCompletedAndExit() async {
    try {

      final uri = Uri.parse('${EnvConfig.baseUrl}/test/complete');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'testid': widget.testId}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ 검사 완료 상태 전송 성공");
      } else {
        debugPrint("⚠️ 전송 실패: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ 예외 발생: $e");
    } finally {
      // 전송 여부 상관없이 앱 종료
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Android일 때만 버튼을 보여주되, 이미 initState에서 한 번 전송했으니
    // 백업용으로 남겨둡니다.
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

          // 수동 전송 버튼 (Android만 표시)
          if (isAndroid)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _markAsCompletedAndExit,
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
