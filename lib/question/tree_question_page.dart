import 'package:flutter/material.dart';
import '../pages/Person_IntroPage.dart';

class TreeQuestionPage extends StatefulWidget {
  @override
  _TreeQuestionPageState createState() => _TreeQuestionPageState();
}

class _TreeQuestionPageState extends State<TreeQuestionPage> {
  final List<TextEditingController> controllers =
  List.generate(7, (_) => TextEditingController());

  final List<String> questions = [
    "1. 이 나무의 종류는 무엇인가요?",
    "2. 이 나무는 몇 살인가요?",
    "3. 현재 계절은 어떤 계절인가요?",
    "4. 나무를 자르려고 시도한 적이 있나요?",
    "5. 근처에 자라는 다른 식물이 있나요?",
    "6. 누가 이 나무에 물을 주나요?",
    "7. 나무가 햇빛을 충분히 받고 있나요?",
  ];

  int currentQuestion = 0;

  void _nextQuestionOrSubmit() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      for (int i = 0; i < questions.length; i++) {
        debugPrint("${questions[i]} → ${controllers[i].text}");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PersonIntroPage()),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 📌 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/Question_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🟠 구름 이미지 + 질문 텍스트 (상단 12% 지점)
          Positioned(
            top: screenHeight * 0.1,
            left:0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/Cloud.png',
                  width: screenWidth * 0.8, // 너비 비율
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    questions[currentQuestion],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 네모 이미지 + 텍스트 입력 창
          Positioned(
            top: screenHeight * 0.55,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: Stack(
              children: [
                Image.asset(
                  'assets/Rectangle.png',
                  width: screenWidth * 0.9,
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextField(
                      controller: controllers[currentQuestion],
                      maxLines: null,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: "아이의 대답을 입력해주세요",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 다음으로 버튼
          Positioned(
            bottom: screenHeight * 0.05,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: ElevatedButton(
              onPressed: _nextQuestionOrSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                minimumSize: Size(screenWidth * 0.9, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                currentQuestion < questions.length - 1
                    ? "다음으로 ➡️"
                    : "제출하기 ✅",
              ),
            ),
          ),
        ],
      ),
    );
  }
}