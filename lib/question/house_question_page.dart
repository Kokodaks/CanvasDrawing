import 'package:flutter/material.dart';
import '../pages/tree_drawing_page.dart';


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
      MaterialPageRoute(builder: (context) => TreeDrawingPage()),
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
        title: const Text("집에 대해 이야기해볼까요? 🏠"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "🖼️ 모든 그림을 완성하느라 정말 잘했어요!\n\n이제 그린 집에 대해 몇 가지 질문에 답해주세요.",
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
                                borderRadius: BorderRadius.circular(8)),
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
