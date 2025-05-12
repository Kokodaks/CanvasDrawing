import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../pages/PrivacyConsentPage.dart';

class TestFirstPage extends StatefulWidget {
  @override
  _TestFirstPageState createState() => _TestFirstPageState();
}

class _TestFirstPageState extends State<TestFirstPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rrnController = TextEditingController();
  bool _isHidden = true;
  String _rrnRaw = '';

  void submitInfo() async {
    print('✅ [submitInfo] 함수 호출됨');

    final name = nameController.text.trim();
    final rrn = _rrnRaw;
    print('📨 입력 받은 name: $name / rrn: $rrn');

    if (name.isEmpty || rrn.length != 13) {
      print('⚠️ 입력값 부족: name 또는 주민번호가 비어 있음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이름과 주민등록번호(13자리)를 입력해주세요.")),
      );
      return;
    }

    try {
      final uri = Uri.http(
        '10.30.122.19:3000',
        '/test/getTestBySsn',
        {'name': name, 'ssn': rrn},
      );
      print('🌐 [요청 전송] GET $uri');

      final response = await http.get(uri);
      print('📬 [응답 도착] 상태코드: ${response.statusCode}');
      print('📦 [응답 내용] ${response.body}');

      if (response.statusCode == 200) {
        final List responseData = jsonDecode(response.body);

        if (responseData.isEmpty) {
          print('⚠️ 검사 데이터 없음');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('검사 데이터가 없습니다.')),
          );
          return;
        }

        final test = responseData.first;
        final testId = test['id'];
        final childId = test['childid'];
        print('✅ 검사 있음 → testId: $testId, childId: $childId');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivacyConsentPage(
              testId: testId,
              childId: childId,
            ),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        print('⚠️ 검사 없음 또는 서버 오류');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? '검사를 찾을 수 없습니다.')),
        );
      }
    } catch (e) {
      print('🛑 예외 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버와 통신할 수 없습니다.')),
      );
    }
  }

  void _onRrnChanged(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) return;

    setState(() {
      _rrnRaw = digits;
      rrnController.text = digits;
      rrnController.selection = TextSelection.fromPosition(
        TextPosition(offset: rrnController.text.length),
      );
    });
  }

  void _toggleVisibility() {
    setState(() {
      _isHidden = !_isHidden;
      rrnController.selection = TextSelection.fromPosition(
        TextPosition(offset: rrnController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 100, 40, 40), // ⬅ 위로부터 100만큼 내려서 전체 위치 조정
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    '피검사자 정보 입력',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(controller: nameController, hint: '이름'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rrnController,
                    keyboardType: TextInputType.number,
                    maxLength: 13,
                    obscureText: _isHidden,
                    obscuringCharacter: '•',
                    onChanged: _onRrnChanged,
                    decoration: InputDecoration(
                      hintText: '주민등록번호 (13자리)',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isHidden ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleVisibility,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
