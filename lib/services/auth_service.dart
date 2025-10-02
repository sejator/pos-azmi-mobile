import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/user_model.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    try {
      final res = await ApiClient.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final auth = AuthResponse.fromJson(res.data);

      await Storage.saveToken(auth.accessToken);

      ApiClient.dio.options.headers['Authorization'] =
          'Bearer ${auth.accessToken}';

      await Storage.saveUser(auth.user);
      await Storage.saveSetting(auth.setting);

      return true;
    } on DioException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
