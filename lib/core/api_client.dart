import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'storage.dart';
import 'package:flutter/material.dart';
import 'package:pos_azmi/screens/login_screen.dart';
import 'package:pos_azmi/core/navigation_service.dart';

final _logger = Logger();

class ApiClient {
  static const String pathVersion = '/api/v1';
  static late Dio dio;

  static Future<void> setup() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }

    dio = Dio(BaseOptions(
      baseUrl: '$baseUrl$pathVersion',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
      },
    ));

    final token = await Storage.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logger.i('-- REQUEST [${options.method}] => PATH: ${options.uri}');
            _logger.i('Headers: ${options.headers}');
            if (options.queryParameters.isNotEmpty) {
              _logger.i(
                  'Query Parameters: ${jsonEncode(options.queryParameters)}');
            }
            if (options.data != null) {
              _logger.i('Payload: ${_encodeIfJson(options.data)}');
            }
            return handler.next(options);
          },
          onResponse: (response, handler) {
            _logger.i(
                '-- RESPONSE [${response.statusCode}] => PATH: ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (e, handler) async {
            _logger.e(
                '-- ERROR [${e.response?.statusCode}] => PATH: ${e.requestOptions.uri}');
            if (e.response?.data != null) {
              _logger.e('Error Response: ${_encodeIfJson(e.response?.data)}');
            }

            if (e.response?.statusCode == 401) {
              await Storage.clearAll();
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }

            return handler.next(e);
          },
        ),
      );

      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          final str = obj.toString();
          if (_isJson(str)) {
            try {
              final jsonObj = json.decode(str);
              const encoder = JsonEncoder.withIndent('  ');
              final prettyJson = encoder.convert(jsonObj);
              _logger.d(prettyJson);
            } catch (_) {
              _logger.d(str);
            }
          } else {
            _logger.d(str);
          }
        },
      ));
    }
  }

  static bool _isJson(String str) {
    return (str.startsWith('{') && str.endsWith('}')) ||
        (str.startsWith('[') && str.endsWith(']'));
  }

  static String _encodeIfJson(dynamic data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
