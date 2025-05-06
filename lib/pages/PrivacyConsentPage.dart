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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

          // 체크박스 위치 조절
          Positioned(
            top: screenHeight * 0.66,
            left: screenWidth * 0.38,
            child: Checkbox(
              value: isAgreed,
              activeColor: const Color(0xFFFFA726),
              onChanged: (val) {
                setState(() => isAgreed = val!);
              },
            ),
          ),

          // "동의하기" 버튼
          Align(
            alignment: const Alignment(0.0, 0.75),
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isAgreed
                      ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HouseIntroPage(),
                      ),
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
                  child: const Text(
                    "동의하기",
                    style: TextStyle(fontSize: 16),
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
