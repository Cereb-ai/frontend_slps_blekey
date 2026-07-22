import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../states/global_user.dart';

/// Persists the signed-in user's offline working set.
///
/// Server data remains authoritative. A successful request replaces the local
/// snapshot; a failed request leaves the last known-good snapshot untouched.
abstract final class OfflineDataStore {
  static const _prefix = 'slps_offline_v1';
  static final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  static int _activeSyncCount = 0;

  static String _accountScope() {
    final user = GlobalUser.instance;
    final identity = user.userId ?? user.username ?? 'unknown';
    return base64Url.encode(utf8.encode(identity));
  }

  static String _key(String collection) =>
      '${_prefix}_${_accountScope()}_$collection';

  static Future<void> syncAll({String? token}) async {
    final accessToken = token ?? GlobalUser.instance.token;
    if (accessToken == null || accessToken.isEmpty) return;
    _beginSync();
    try {
      await Future.wait<void>([
        _refreshList('keys', () => Api.listLockKeys(token: accessToken)),
        _refreshList('locks', () => Api.listLockDevices(token: accessToken)),
        _refreshList(
          'tasks',
          () => Api.listAuthorizationTasks(token: accessToken),
        ),
        _refreshObject(
          'provisioning_config',
          () => Api.getProvisioningConfig(token: accessToken),
        ),
      ]);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _key('synced_at'),
        DateTime.now().toUtc().toIso8601String(),
      );
    } finally {
      _endSync();
    }
  }

  static void _beginSync() {
    _activeSyncCount++;
    if (_activeSyncCount == 1) isSyncing.value = true;
  }

  static void _endSync() {
    if (_activeSyncCount > 0) _activeSyncCount--;
    if (_activeSyncCount == 0) isSyncing.value = false;
  }

  static Future<void> _refreshList(
    String collection,
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    try {
      await saveList(collection, await fetch());
    } catch (error) {
      debugPrint('Offline sync $collection skipped: $error');
    }
  }

  static Future<void> _refreshObject(
    String collection,
    Future<Map<String, dynamic>> Function() fetch,
  ) async {
    try {
      await saveObject(collection, await fetch());
    } catch (error) {
      debugPrint('Offline sync $collection skipped: $error');
    }
  }

  static Future<void> saveList(
    String collection,
    List<Map<String, dynamic>> values,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(collection), jsonEncode(values));
  }

  static Future<List<Map<String, dynamic>>> readList(String collection) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_key(collection));
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveObject(
    String collection,
    Map<String, dynamic> value,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(collection), jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> readObject(String collection) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_key(collection));
      final decoded = raw == null ? null : jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> lastSyncedAt() async {
    final preferences = await SharedPreferences.getInstance();
    return DateTime.tryParse(preferences.getString(_key('synced_at')) ?? '');
  }
}
