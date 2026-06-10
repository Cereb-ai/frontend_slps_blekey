import 'dart:developer' as developer;

import 'package:dio/dio.dart';

typedef JsonMap = Map<String, dynamic>;

abstract final class Api {
  static const String _baseUrl = 'https://dev-api.cereb.ai';
  static const String _tenantHeader = 'X-Tenant-Id';
  static const String _tenantHeaderCompat = 'X-Tenant-ID';
  static const String _tenantId = 'smart-lock-platform';
  static const String _authTenantId = 'smart-lock-platform';
  static const String _skipUnauthorizedHandlerKey = 'skipUnauthorizedHandler';
  static const String _skipAuthRefreshKey = 'skipAuthRefresh';
  static const String _retriedWithFreshTokenKey = 'retriedWithFreshToken';

  static Future<void> Function()? _onUnauthorized;
  static String? Function()? _getAccessToken;
  static String? Function()? _getRefreshToken;
  static Future<void> Function({
    required String accessToken,
    String? refreshToken,
  })?
  _persistTokens;
  static bool _handlingUnauthorized = false;
  static Future<String?>? _refreshingAccessToken;
  static bool enableAuthDebugLog = true;

  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
        _tenantHeader: _tenantId,
      },
    ),
  );

  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: const {
              'Content-Type': 'application/json',
              _tenantHeader: _tenantId,
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final accessToken = _getAccessToken?.call();
              final skipAuthRefresh =
                  options.extra[_skipAuthRefreshKey] == true;
              final tenant = options.path.startsWith('/v3/auth/')
                  ? _authTenantId
                  : _tenantId;
              _applyTenantHeader(options.headers, tenant);
              if (options.path.startsWith('/v3/auth/')) {
                _applyTenantHeader(options.headers, _authTenantId);
              }
              if (!skipAuthRefresh &&
                  accessToken != null &&
                  accessToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $accessToken';
              }
              _authLog('request', {
                'method': options.method,
                'path': options.path,
                'tenant': _readTenantHeader(options.headers),
                'hasAuth': (options.headers['Authorization'] ?? '')
                    .toString()
                    .isNotEmpty,
                'skipRefresh': skipAuthRefresh,
                'retried': options.extra[_retriedWithFreshTokenKey] == true,
              });
              handler.next(options);
            },
            onError: (error, handler) {
              _handleError(error, handler);
            },
          ),
        );

  static void registerUnauthorizedHandler(Future<void> Function() handler) {
    _onUnauthorized = handler;
  }

  static void registerAuthStateHandlers({
    String? Function()? getAccessToken,
    String? Function()? getRefreshToken,
    Future<void> Function({required String accessToken, String? refreshToken})?
    persistTokens,
  }) {
    _getAccessToken = getAccessToken;
    _getRefreshToken = getRefreshToken;
    _persistTokens = persistTokens;
  }

  static bool _shouldSkipAuthRefresh(RequestOptions options) {
    if (options.extra[_skipAuthRefreshKey] == true) return true;
    final path = options.path;
    return path.contains('/v3/auth/login/password') ||
        path.contains('/v3/auth/refresh');
  }

  static Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;
    final requestOptions = error.requestOptions;
    final skipUnauthorizedHandler =
        requestOptions.extra[_skipUnauthorizedHandlerKey] == true;

    _authLog('response-error', {
      'status': statusCode,
      'path': requestOptions.path,
      'method': requestOptions.method,
      'tenant': _readTenantHeader(requestOptions.headers),
      'retried': requestOptions.extra[_retriedWithFreshTokenKey] == true,
      'body': _short(error.response?.data),
    });

    final canRetryWithRefresh =
        (statusCode == 401 || statusCode == 403) &&
        !skipUnauthorizedHandler &&
        !_shouldSkipAuthRefresh(requestOptions) &&
        requestOptions.extra[_retriedWithFreshTokenKey] != true;

    if (canRetryWithRefresh) {
      try {
        _authLog('refresh-attempt', {
          'path': requestOptions.path,
          'reasonStatus': statusCode,
        });
        final freshToken = await ensureFreshAccessToken();
        if (freshToken != null && freshToken.isNotEmpty) {
          _authLog('refresh-success', {'token': _tokenPreview(freshToken)});
          requestOptions.headers['Authorization'] = 'Bearer $freshToken';
          requestOptions.extra[_retriedWithFreshTokenKey] = true;
          final response = await dio.fetch<dynamic>(requestOptions);
          _authLog('retry-success', {
            'status': response.statusCode,
            'path': requestOptions.path,
            'method': requestOptions.method,
          });
          handler.resolve(response);
          return;
        }
      } catch (e) {
        _authLog('refresh-failed', {'error': e.toString()});
      }
    }

    if ((statusCode == 401 || statusCode == 403) && !skipUnauthorizedHandler) {
      _triggerUnauthorizedHandler();
    }
    handler.next(error);
  }

  static Future<String?> ensureFreshAccessToken() {
    return _refreshingAccessToken ??= _refreshAccessToken().whenComplete(() {
      _refreshingAccessToken = null;
    });
  }

  static Future<String?> _refreshAccessToken() async {
    final refreshToken = _getRefreshToken?.call();
    _authLog('refresh-enter', {'refreshToken': _tokenPreview(refreshToken)});
    if (refreshToken == null || refreshToken.isEmpty) {
      _authLog('refresh-skip-empty-token');
      return null;
    }

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/v3/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(
        extra: {_skipUnauthorizedHandlerKey: true, _skipAuthRefreshKey: true},
      ),
    );
    final body = response.data ?? <String, dynamic>{};
    _authLog('refresh-response', {
      'status': response.statusCode,
      'body': _short(body),
    });
    final nextAccessToken = _readTokenValue(body, ['access_token', 'token']);
    final nextRefreshToken =
        _readTokenValue(body, ['refresh_token', 'refreshToken']) ??
        refreshToken;

    if (nextAccessToken == null || nextAccessToken.isEmpty) {
      _authLog('refresh-empty-access-token', {'body': _short(body)});
      return null;
    }

    await _persistTokens?.call(
      accessToken: nextAccessToken,
      refreshToken: nextRefreshToken,
    );
    return nextAccessToken;
  }

  static String? _readTokenValue(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static void _triggerUnauthorizedHandler() {
    if (_handlingUnauthorized) return;
    final callback = _onUnauthorized;
    if (callback == null) return;

    _handlingUnauthorized = true;
    Future<void>(() async {
      try {
        await callback();
      } finally {
        _handlingUnauthorized = false;
      }
    });
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    _authLog('login-request', {'identity': username});
    final response = await dio.post<Map<String, dynamic>>(
      '/v3/auth/login/password',
      data: {'identity': username, 'password': password},
      options: Options(
        extra: {_skipUnauthorizedHandlerKey: true, _skipAuthRefreshKey: true},
      ),
    );
    final body = response.data ?? <String, dynamic>{};
    _authLog('login-response', {
      'status': response.statusCode,
      'body': _short(body),
    });
    return body;
  }

  static Future<void> logout({
    required String token,
    required String refreshToken,
  }) async {
    await dio.post<void>(
      '/v3/auth/logout',
      data: {'refresh_token': refreshToken},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        extra: {_skipUnauthorizedHandlerKey: true, _skipAuthRefreshKey: true},
      ),
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

  static Future<JsonMap> createLockKey({
    required String token,
    required JsonMap payload,
  }) async {
    final response = await dio.post<dynamic>(
      '/slps/keys',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _asJsonMap(response.data);
  }

  static Future<JsonMap> updateLockKey({
    required String token,
    required String id,
    required JsonMap payload,
  }) async {
    final response = await dio.patch<dynamic>(
      '/slps/keys/$id',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _asJsonMap(response.data);
  }

  static Future<void> deleteLockKey({
    required String token,
    required String id,
  }) async {
    await dio.delete<void>(
      '/slps/keys/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static Future<JsonMap> createLockDevice({
    required String token,
    required JsonMap payload,
  }) async {
    final response = await dio.post<dynamic>(
      '/slps/locks',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _asJsonMap(response.data);
  }

  static Future<JsonMap> updateLockDevice({
    required String token,
    required String id,
    required JsonMap payload,
  }) async {
    final response = await dio.patch<dynamic>(
      '/slps/locks/$id',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _asJsonMap(response.data);
  }

  static Future<JsonMap> decideAccess({
    required String token,
    required String keyId,
    required String lockId,
    DateTime? at,
    bool? geofenceSatisfied,
    String? clientTraceId,
  }) async {
    final payload = <String, dynamic>{'keyId': keyId, 'lockId': lockId};
    if (at != null) payload['at'] = at.toIso8601String();
    if (geofenceSatisfied != null) {
      payload['geofenceSatisfied'] = geofenceSatisfied;
    }
    if (clientTraceId?.isNotEmpty ?? false) {
      payload['clientTraceId'] = clientTraceId;
    }
    final response = await dio.post<dynamic>(
      '/slps/access/decide',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _asJsonMap(response.data);
  }

  static Future<void> deleteLockDevice({
    required String token,
    required String id,
  }) async {
    await dio.delete<void>(
      '/slps/locks/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  static JsonMap _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  static void _authLog(String event, [Map<String, dynamic>? fields]) {
    if (!enableAuthDebugLog) return;
    developer.log(fields == null ? event : '$event | $fields', name: 'ApiAuth');
  }

  static void _applyTenantHeader(Map<String, dynamic> headers, String tenant) {
    headers[_tenantHeader] = tenant;
    headers[_tenantHeaderCompat] = tenant;
  }

  static Object? _readTenantHeader(Map<String, dynamic> headers) {
    return headers[_tenantHeader] ?? headers[_tenantHeaderCompat];
  }

  static String _tokenPreview(String? token) {
    if (token == null || token.isEmpty) return '<empty>';
    final head = token.length <= 12 ? token : token.substring(0, 12);
    return '$head...(${token.length})';
  }

  static String _short(dynamic value) {
    final text = value?.toString() ?? 'null';
    if (text.length <= 220) return text;
    return '${text.substring(0, 220)}...';
  }
}
