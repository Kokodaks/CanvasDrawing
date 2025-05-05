import 'package:flutter/material.dart';
import '../pages/House_IntroPage.dart';

class PrivacyConsentPage extends StatefulWidget {
  @override
  _PrivacyConsentPageState createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/Privacy.png',
              fit: BoxFit.cover,
            ),
          ),

          // 체크박스와 버튼을 상대 위치로 배치
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // 체크박스
                  Positioned(
                    top: constraints.maxHeight * 0.66,
                    left: constraints.maxWidth * 0.355,
                    child: Checkbox(
                      value: isAgreed,
                      activeColor: const Color(0xFFFFA726),
                      onChanged: (val) {
                        setState(() => isAgreed = val!);
                      },
                    ),
                  ),

                  // 동의하기 버튼
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isAgreed
                            ? () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HouseIntroPage()),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text("동의하기", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
