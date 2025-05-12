import 'package:flutter/material.dart';
import '../drawing/Men_drawing_page.dart';
import '../drawing/Women_drawing_page.dart';
import '../question/person_question_page.dart';
import '../pages/finish_page.dart';
import '../pages/Men_IntroPage.dart';
import '../pages/Women_IntroPage.dart';

class PersonIntroPage extends StatelessWidget {
  final int testId;
  final int childId;

  const PersonIntroPage({
    required this.testId,
    required this.childId,
    Key? key,
  }) : super(key: key);

  void _showGenderChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("누구부터 그릴까요?"),
        content: const Text("남자 또는 여자 중 먼저 그리고 싶은 사람을 선택해주세요."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startWithMan(context);
            },
            child: const Text("남자"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startWithWoman(context);
            },
            child: const Text("여자"),
          ),
        ],
      ),
    );
  }

  void _startWithMan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenDrawingPage(
          testId: testId,
          childId: childId,
          isMan: true,
          onDrawingComplete: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonQuestionPage(
                  testId: testId,
                  childId: childId,
                  isMan: true,
                  onQuestionComplete: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WomenIntroPage(
                          testId: testId,
                          childId: childId,
                          onStartDrawing: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WomenDrawingPage(
                                  testId: testId,
                                  childId: childId,
                                  isMan: false,
                                  onDrawingComplete: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PersonQuestionPage(
                                          testId: testId,
                                          childId: childId,
                                          isMan: false,
                                          onQuestionComplete: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FinishPage(testId: testId),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startWithWoman(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WomenDrawingPage(
          testId: testId,
          childId: childId,
          isMan: false,
          onDrawingComplete: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonQuestionPage(
                  testId: testId,
                  childId: childId,
                  isMan: false,
                  onQuestionComplete: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenIntroPage(
                          testId: testId,
                          childId: childId,
                          onStartDrawing: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MenDrawingPage(
                                  testId: testId,
                                  childId: childId,
                                  isMan: true,
                                  onDrawingComplete: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PersonQuestionPage(
                                          testId: testId,
                                          childId: childId,
                                          isMan: true,
                                          onQuestionComplete: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FinishPage(testId: testId),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/person_intro_background.png',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _showGenderChoiceDialog(context),
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
