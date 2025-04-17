import 'package:flutter/material.dart';
import '../pages/another_person_drawing_page.dart';

class PersonQuestionPage extends StatefulWidget {
  @override
  _PersonQuestionPageState createState() => _PersonQuestionPageState();
}

class _PersonQuestionPageState extends State<PersonQuestionPage> {
  final List<TextEditingController> controllers =
  List.generate(9, (_) => TextEditingController());

  final List<String> questions = [
    "1. 이 사람의 성별은 무엇인가요?",
    "2. 이 사람은 누구인가요?" ,
    "3. 이 사람은 몇 살인가요?",
    "4. 누군가가 이 사람에게 상처를 준 적이 있나요?",
    "5. 누가 이 사람을 보살피나요?",
    "6. 이 사람은 행복합니까? 불행합니까?",
    "7. 이 사람에게는 무엇이 필요합니까?",
    "8. 당신은 이 사람이 어떻습니까? 좋습니까? 싫습니까?",
    "9. 이 사람은 당신을 닮았습니까?",
  ];


  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void submitAnswers() {
    for (int i = 0; i < questions.length; i++) {
      debugPrint("${questions[i]} → ${controllers[i].text}");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("답변이 제출되었습니다!")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnotherPersonDrawingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("그린 사람에 대해 이야기해볼까요? 👤"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "멋진 사람을 그려주셨네요!\n이제 그린 사람에 대해 몇 가지 질문에 답해주세요.\n\n🖼️ 모든 그림을 완성하느라 정말 잘했어요!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questions[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: controllers[index],
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "여기에 답변을 적어주세요...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: submitAnswers,
              child: const Text("답변 제출하기 ✍️"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
