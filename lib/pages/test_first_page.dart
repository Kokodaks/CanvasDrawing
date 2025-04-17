import 'package:flutter/material.dart';
import '../pages/house_drawing_page.dart';

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
      MaterialPageRoute(builder: (context) => HouseDrawingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text("사용자 정보 입력"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "검사 시작 전,\n이름과 주민등록번호를 입력해주세요.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "이름",
                hintText: "홍길동",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rrnController,
              decoration: InputDecoration(
                labelText: "주민등록번호",
                hintText: "123456-1234567",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: submitInfo,
              child: const Text("확인"),
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
