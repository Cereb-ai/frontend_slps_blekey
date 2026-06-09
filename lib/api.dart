import 'package:dio/dio.dart';

abstract final class Api {
  static const String _baseUrl = 'https://dev-api.cereb.ai';
  static const String _tenantId = 'smart-lock-platform';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
        'X-Tenant-ID': _tenantId,
      },
    ),
  );

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/v3/auth/login/password',
      data: {'identity': username, 'password': password},
    );
    return response.data ?? <String, dynamic>{};
  }

  static Future<void> logout({
    required String token,
    required String refreshToken,
  }) async {
    await dio.post<void>(
      '/v3/auth/logout',
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/v3/auth/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data ?? <String, dynamic>{};
  }
}
