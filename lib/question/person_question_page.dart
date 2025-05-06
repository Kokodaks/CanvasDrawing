import 'package:flutter/material.dart';

class PersonQuestionPage extends StatefulWidget {
  final bool isMan;
  final VoidCallback onQuestionComplete;

  const PersonQuestionPage({
    Key? key,
    required this.isMan,
    required this.onQuestionComplete,
  }) : super(key: key);

  @override
  _PersonQuestionPageState createState() => _PersonQuestionPageState();
}

class _PersonQuestionPageState extends State<PersonQuestionPage> {
  final List<TextEditingController> controllers =
  List.generate(9, (_) => TextEditingController());

  late final List<String> questions;
  int currentQuestion = 0;

  @override
  void initState() {
    super.initState();
    questions = widget.isMan ? _manQuestions : _womanQuestions;
  }

  final List<String> _manQuestions = [
    "1. 이 남자는 어떤 일을 하나요?",
    "2. 그는 어디에 살고 있나요?",
    "3. 이 남자는 기분이 좋아보이나요?",
    "4. 남자는 무엇을 하고 있나요?",
    "5. 주변 사람들과 어떤 관계인가요?",
    "6. 그는 몇 살인가요?",
    "7. 그는 어떤 옷을 입고 있나요?",
  ];

  final List<String> _womanQuestions = [
    "1. 이 여자는 어떤 일을 하나요?",
    "2. 그녀는 어디에 살고 있나요?",
    "3. 이 여자는 기분이 좋아보이나요?",
    "4. 여자는 무엇을 하고 있나요?",
    "5. 주변 사람들과 어떤 관계인가요?",
    "6. 그녀는 몇 살인가요?",
    "7. 그녀는 어떤 옷을 입고 있나요?",
  ];

  void _nextQuestionOrSubmit() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      for (int i = 0; i < questions.length; i++) {
        debugPrint("${questions[i]} → ${controllers[i].text}");
      }

      widget.onQuestionComplete();
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Image.asset(
              'assets/Question_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 질문 구름
          Positioned(
            top: screenHeight * 0.12,
            left: screenWidth * 0.07,
            right: screenWidth * 0.07,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/Cloud.png'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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

          // 텍스트 입력 박스 (네모)
          Positioned(
            top: screenHeight * 0.72,
            left: screenWidth * 0.07,
            right: screenWidth * 0.07,
            child: Stack(
              children: [
                Image.asset(
                  'assets/Rectangle.png',
                  width: screenWidth * 0.85,
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

          // 다음 버튼
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _nextQuestionOrSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(currentQuestion < questions.length - 1 ? "다음으로 ➡️" : "제출하기 ✅"),
            ),
          ),
        ],
      ),
    );
  }
}
