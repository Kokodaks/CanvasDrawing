import 'package:flutter/material.dart';
import '../pages/tree_IntroPage.dart';

class HouseQuestionPage extends StatefulWidget {
  @override
  _HouseQuestionPageState createState() => _HouseQuestionPageState();
}

class _HouseQuestionPageState extends State<HouseQuestionPage> {
  final List<TextEditingController> controllers =
  List.generate(5, (_) => TextEditingController());

  final List<String> questions = [
    "1. 누가 여기에 사나요?",
    "2. 이 집에 사는 사람들은 행복한가요?",
    "3. 집 안에는 어떤 것들이 있나요?",
    "4. 밤에는 이 집이 어떤가요?",
    "5. 이 집에 다른 사람들이 놀러 오나요?",
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
        MaterialPageRoute(builder: (context) => TreeIntroPage()),
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

          // 🟩 네모 이미지 + 텍스트 입력 창 (화면 아래 30% 지점)
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

          // 🟢 다음으로 버튼 (하단에서 5%)
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
