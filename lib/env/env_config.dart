import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> load({bool isProd = false}) async {
    await dotenv.load(fileName: isProd ? '.env.prod' : '.env.dev');
  }
}
