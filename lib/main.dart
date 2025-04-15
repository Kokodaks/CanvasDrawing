import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/drawing_page.dart';
import 'pages/home_page.dart';
import 'tests/api_test.dart';

Future<void> main() async{
  await dotenv.load();
  runApp(MyApp());
  //실기기와 백엔드 (컴퓨터 로컬 포트 실행) 테스트
  // runApp(ApiTestApp());
}

//라우팅만 담당
class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Drawingi',
      home: HomePage(),
      routes:{
        '/home': (context) => HomePage(),
        '/drawing': (context) => DrawingPage(),
      },
    );
  }
}
