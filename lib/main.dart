import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/test_first_page.dart';
import 'package:flutter/services.dart';
import 'tests/api_test.dart';

Future<void> main() async {
  await dotenv.load(); // 환경 변수 로드
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawingi',
      debugShowCheckedModeBanner: false,
      home: TestFirstPage(),

    );
  }
}
