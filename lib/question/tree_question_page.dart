import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../pages/Person_IntroPage.dart';
import '../config/env_config.dart';


class TreeQuestionPage extends StatefulWidget {
  final int testId;
  final int childId;

  const TreeQuestionPage({required this.testId, required this.childId, Key? key}) : super(key: key);

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
    _checkQnADocumentExists();
  }

  Future<void> _checkQnADocumentExists() async {
    final baseUri = Uri.parse(EnvConfig.baseUrl);
    final uri = baseUri.replace(
      path: '/test/getQnAByTestId',
      queryParameters: {
        'testId': widget.testId.toString(),
        'drawingType': 'tree',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200 && response.body == 'null') {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("문서 없음"),
            content: const Text("해당 검사에 대한 QnA 문서가 존재하지 않습니다.\n상담사에게 문의해주세요."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ QnA 문서 확인 중 오류 발생: $e");
    }
  }

  void _initializeSpeechRecognition() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('🎙 상태: $status'),
      onError: (error) => print('❌ 오류: $error'),
    );
    setState(() => _isInitialized = available);
  }

  void _listen() async {
    if (!_isListening && _isInitialized) {
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isListening = true);

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

  Future<void> _submitAnswers() async {
    const drawingType = "tree";
    final testId = widget.testId;
    bool allSuccess = true;

    for (int i = 0; i < questions.length; i++) {
      final answer = controllers[i].text.trim();
      if (answer.isEmpty) {
        allSuccess = false;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("답변 누락"),
            content: Text("질문 ${i + 1}에 대한 답변이 비어 있습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
        break;
      }

      final uri = Uri.parse('${EnvConfig.baseUrl}/test/addQnA');

      try {
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'testId': testId,
            'drawingType': drawingType,
            'question': questions[i],
            'answer': answer,
          }),
        );
        print('📤 질문 ${i + 1} 응답 코드: ${response.statusCode}');
        print('📦 응답 내용: ${response.body}');
        if (response.statusCode != 200) {
          allSuccess = false;
          break;
        }
      } catch (e) {
        print('🛑 질문 ${i + 1} 전송 중 예외 발생: $e');
        allSuccess = false;
        break;
      }
    }

    if (allSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PersonIntroPage(
            testId: widget.testId,
            childId: widget.childId,
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("제출 실패"),
          content: const Text("일부 질문 전송에 실패했습니다. 다시 시도해 주세요."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }

  void _nextQuestionOrSubmit() async {
    if (currentQuestion < questions.length - 1) {
      setState(() => currentQuestion++);
    } else {
      await _submitAnswers();
    }
  }

  Future<File?> _getLatestScreenshot() async {
    final dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : Directory('/tmp'); // iOS나 기타 플랫폼은 임시 디렉토리 사용
    final files = Directory(dir.path)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('tree_drawing_') && f.path.endsWith('.png'))
        .toList();

    if (files.isEmpty) return null;

    files.sort((a, b) => b.path.compareTo(a.path));
    return files.first;
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/Question_bg.png', fit: BoxFit.cover),
          ),

          // 질문 텍스트
          Align(
            alignment: const Alignment(0, -0.75),
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/Cloud.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20),
                    child: Text(
                      questions[currentQuestion],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'TJJoyofsingingEB_TTF',
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 답변 입력 필드
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
                          hintStyle: TextStyle(fontSize: 30,
                              color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 마이크 + 초기화 + 이전 그림 다시보기
          Align(
            alignment: const Alignment(0, 0.65),
            child: FutureBuilder<File?>(
              future: _getLatestScreenshot(),
              builder: (context, snapshot) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔁 이전 그림 다시보기
                    if (snapshot.hasData)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScreenshotViewerPage(
                                  imageFile: snapshot.data!),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(230),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/photo.png',
                                width: 70,
                                height: 70,
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (snapshot.hasData) const SizedBox(width: 30),

                    // 🎤 마이크
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                              'assets/mic_bg.png', width: 80, height: 80),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isListening ? Colors.green : Colors
                                    .transparent,
                                width: 4,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: GestureDetector(
                                onTap: _isInitialized ? _listen : null,
                                child: Image.asset(
                                    'assets/mic.png', fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 30),

                    // 🔄 초기화
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
                            'assets/reset_icon.png', fit: BoxFit.contain),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 다음/제출 버튼
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
                  currentQuestion < questions.length - 1 ? "다음으로 ➔" : "제출하기 ✅",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 전체화면 이미지 뷰어 ─────────────────────────────────────────
class ScreenshotViewerPage extends StatelessWidget {
  final File imageFile;
  const ScreenshotViewerPage({required this.imageFile, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Image.file(imageFile)),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}