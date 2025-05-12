import 'package:flutter/material.dart';
import '../drawing/house_drawing_page.dart';

class HouseIntroPage extends StatelessWidget {
  final int testId;
  final int childId;

  const HouseIntroPage({
    required this.testId,
    required this.childId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/house_intro_background.png',
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
                    MaterialPageRoute(
                      builder: (context) => HouseDrawingPage(
                        testId: testId,
                        childId: childId,
                      ),
                    ),
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
