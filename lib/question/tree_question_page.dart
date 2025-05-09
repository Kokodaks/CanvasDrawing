import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../pages/person_IntroPage.dart';

class TreeQuestionPage extends StatefulWidget {
  @override
  _TreeQuestionPageState createState() => _TreeQuestionPageState();
}

class _TreeQuestionPageState extends State<TreeQuestionPage> {
  final List<TextEditingController> controllers = List.generate(7, (_) => TextEditingController());
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
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeechRecognition();
  }

  void _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('상태: $status'),
      onError: (error) => print('오류: $error'),
    );
    setState(() {
      _isInitialized = available;
    });
  }

  void _listen() async {
    if (!_isListening && _isInitialized) {
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isListening = true;
        controllers[currentQuestion].clear();
      });

      _speech.listen(
        localeId: 'ko_KR',
        listenMode: stt.ListenMode.dictation,
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
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Question_bg.png', fit: BoxFit.cover),
          ),
          Align(
            alignment: const Alignment(0, -0.75),
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
          Align(
            alignment: const Alignment(0, 0.3),
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
                        enabled: !_isListening,
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
          Align(
            alignment: const Alignment(0, 0.65),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/mic_bg.png',
                        width: 80,
                        height: 80,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isListening ? Colors.green : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: GestureDetector(
                            onTap: _isInitialized ? _listen : null,
                            child: Image.asset(
                              'assets/mic.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: !_isListening
                      ? () {
                    setState(() {
                      controllers[currentQuestion].clear();
                    });
                  }
                      : null,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.asset(
                      'assets/reset_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.9),
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
