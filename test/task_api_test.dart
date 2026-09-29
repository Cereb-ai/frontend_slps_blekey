import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_demo_blekey/api.dart';

void main() {
  late Interceptor mock;
  late List<RequestOptions> requests;
  setUp(() {
    requests = [];
    Api.enableAuthDebugLog = false;
    mock = InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );
      },
    );
    Api.dio.interceptors.add(mock);
  });
  tearDown(() => Api.dio.interceptors.remove(mock));
  test(
    'task package uses platform UUID and existing JWT/tenant headers',
    () async {
      await Api.getCurrentTaskPackage(
        token: 'test-token',
        keyId: 'platform-key-uuid',
      );
      expect(
        requests.single.path,
        '/slps/keys/platform-key-uuid/current-task-package',
      );
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
      expect(requests.single.headers['X-Tenant-ID'], 'smart-lock-platform');
    },
  );
  test('online decisions always serialize a timezone', () async {
    await Api.decideAccess(
      token: 'test-token',
      keyId: 'platform-key',
      lockId: 'platform-lock',
      at: DateTime(2026, 9, 29, 10),
      geofenceSatisfied: false,
    );
    final data = requests.single.data as Map;
    expect(data['at'], endsWith('Z'));
    expect(data['keyId'], 'platform-key');
    expect(data['lockId'], 'platform-lock');
    expect(data['geofenceSatisfied'], false);
  });
}
