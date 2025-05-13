import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get baseUrl {
    final url = dotenv.env['IP_ADDR'];
    if (url == null || url.isEmpty) {
      throw Exception("IP_ADDR not found in .env");
    }
    return url;
  }
}