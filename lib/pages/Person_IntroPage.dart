import 'package:flutter/material.dart';
import '../pages/person_drawing_page.dart';

class PersonIntroPage extends StatelessWidget {
  const PersonIntroPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/person_intro_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // 하단 버튼
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PersonDrawingPage()),
                  );
                },
                child: const Text(
                  '그림 그리기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
