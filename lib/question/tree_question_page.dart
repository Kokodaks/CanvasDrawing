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
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/Question_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 질문 구름 + 텍스트
          Align(
            alignment: const Alignment(0, -0.75), // 위쪽에 고정
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/Cloud.png'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      questions[currentQuestion],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 텍스트 입력 박스
          Align(
            alignment: const Alignment(0, 0.3), // 중간 아래쪽
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: Stack(
                children: [
                  Image.asset('assets/Rectangle.png'),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        controller: controllers[currentQuestion],
                        maxLines: null,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 30),
                        decoration: const InputDecoration(
                          hintText: "아이의 대답을 입력해주세요",
                          hintStyle: TextStyle(
                            fontSize: 30,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 다음 버튼
          Align(
            alignment: const Alignment(0, 0.9), // 하단
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: ElevatedButton(
                onPressed: _nextQuestionOrSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
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
          ),
        ],
      ),
    );
  }
}
