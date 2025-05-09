import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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

  // STT 관련 변수
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeechRecognition();
  }

  // 음성 인식 초기화
  void _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('상태: $status'),
      onError: (error) => print('오류: $error'),
    );
    setState(() {
      _isInitialized = available;
    });
  }

  // 음성 인식 시작/중단
  void _listen() async {
    if (!_isListening && _isInitialized) {
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isListening = true;
      });

      _speech.listen(
        localeId: 'ko_KR',
        listenMode: stt.ListenMode.dictation,
        partialResults: true, // ✅ 실시간 결과 허용
        onResult: (result) {
          setState(() {
            controllers[currentQuestion].text = result.recognizedWords;
          });
        },
      );
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  // 다음 질문 또는 제출
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
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,  // 키보드 올라와도 화면 크기 조정하지 않음
      body: Stack(
        children: [
          // 📌 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/Question_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🟠 질문 텍스트
          Positioned(
            top: screenHeight * 0.1,
            left: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/Cloud.png',
                  width: screenWidth * 0.8,
                ),
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

          // 🟩 입력 박스
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
                      enabled: !_isListening, // 🔒 음성 인식 중에는 직접 입력 불가
                      style: const TextStyle(fontSize: 25),
                      textAlign: TextAlign.center, // 텍스트를 가운데 정렬
                      decoration: const InputDecoration(
                        hintText: "아이의 대답을 입력해주세요",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          // 🔊 마이크 버튼 및 녹음 상태 표시
          Positioned(
            bottom: screenHeight * 0.14,
            left: screenWidth * 0.5 - 30,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isInitialized ? _listen : null,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isListening ? Colors.green : Colors.transparent,
                        width: 4,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/mic_bg.png'),
                        Image.asset('assets/mic.png', width: 30, height: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_isListening)
                  const Text(
                    "듣는 중...",
                    style: TextStyle(color: Colors.green, fontSize: 16),
                  ),
              ],
            ),
          ),

          // 🟢 다음 버튼
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
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
              child: Text(currentQuestion < questions.length - 1
                  ? "다음으로 ➡️"
                  : "제출하기 ✅"),
            ),
          ),
        ],
      ),
    );
  }
}
