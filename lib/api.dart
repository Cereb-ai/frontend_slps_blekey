import 'package:dio/dio.dart';

typedef JsonMap = Map<String, dynamic>;

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

  static Future<List<JsonMap>> listLockKeys({
    required String token,
    Map<String, dynamic> query = const <String, dynamic>{},
  }) async {
    final response = await dio.get<dynamic>(
      '/slps/keys',
      queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final items = map['items'] ?? map['list'] ?? map['data'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const <JsonMap>[];
  }

  static Future<List<JsonMap>> listLockDevices({
    required String token,
    Map<String, dynamic> query = const <String, dynamic>{},
  }) async {
    final response = await dio.get<dynamic>(
      '/slps/locks',
      queryParameters: query,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final items = map['items'] ?? map['list'] ?? map['data'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const <JsonMap>[];
  }
}
