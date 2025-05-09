import 'package:flutter/material.dart';
import '../pages/PrivacyConsentPage.dart';
import 'dart:ui' as ui;

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
        const SnackBar(content: Text("이름과 주민등록번호를 모두 입력해주세요.")),
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
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = screenWidth > 600 ? 80 : 40;

    return Scaffold(
      // resizeToAvoidBottomInset을 false로 설정하여 키보드가 올라와도 UI 요소가 밀리지 않도록 함
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32), // 로고 제거 후 여백만 유지

                    const Text(
                      '피검사자 정보 입력',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),

                    _buildTextField(controller: nameController, hint: '이름'),
                    const SizedBox(height: 12),
                    _buildTextField(controller: rrnController, hint: '주민등록번호'),
                    const SizedBox(height: 30),

                    SizedBox(
                      height: 44,
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
                        child: const Text("로그인", style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
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
