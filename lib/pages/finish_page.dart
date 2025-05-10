import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FinishPage extends StatelessWidget {
  const FinishPage({Key? key}) : super(key: key);

  void _exitApp() {
    // 앱 완전 종료
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
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

          // 하단 버튼
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _exitApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
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
          )
        ],
      ),
    );
  }
}
