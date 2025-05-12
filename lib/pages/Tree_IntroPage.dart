import 'package:flutter/material.dart';
import '../drawing/tree_drawing_page.dart';

class TreeIntroPage extends StatelessWidget {
  final int testId;
  final int childId;

  const TreeIntroPage({
    required this.testId,
    required this.childId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/tree_intro_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreeDrawingPage(
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
