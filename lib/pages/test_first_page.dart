import 'package:flutter/material.dart';
import '../pages/PrivacyConsentPage.dart';

class TestFirstPage extends StatefulWidget {
  @override
  _TestFirstPageState createState() => _TestFirstPageState();
}

class _TestFirstPageState extends State<TestFirstPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rrnController = TextEditingController();

  void submitInfo() {
    final name = nameController.text.trim();
    final rrn = rrnController.text.trim();

    if (name.isEmpty || rrn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이름과 생년월일을 모두 입력해주세요.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyConsentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseWidth = 800.0; // 기준 너비
    final baseHeight = 1280.0; // 기준 높이

    final widthScale = screenSize.width / baseWidth;
    final heightScale = screenSize.height / baseHeight;
    final scale = widthScale < heightScale ? widthScale : heightScale;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 320, // 고정된 기준 박스
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 64), // 상단 여백

                  const Text(
                    '피검사자 정보 입력',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(controller: nameController, hint: '이름'),
                  const SizedBox(height: 16),
                  _buildTextField(controller: rrnController, hint: '생년월일'),
                  const SizedBox(height: 30),

                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA726),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("로그인", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.orange),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
    );
  }
}
