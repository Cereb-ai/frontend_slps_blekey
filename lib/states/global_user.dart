import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class GlobalUser extends ChangeNotifier {
  GlobalUser._();

  static final GlobalUser instance = GlobalUser._();

  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUsername = 'auth_username';
  static const _keyUserId = 'auth_user_id';
  static const _keyRememberMe = 'auth_remember_me';
  static const _keySavedUsername = 'auth_saved_username';

  String? token;
  String? refreshToken;
  String? username;
  String? email;
  String? userId;
  bool rememberMe = false;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_keyToken);
    refreshToken = prefs.getString(_keyRefreshToken);
    username = prefs.getString(_keyUsername);
    userId = prefs.getString(_keyUserId);
    rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    debugPrint(
      '[GlobalUser] loadFromStorage token=${_preview(token)} refresh=${_preview(refreshToken)} user=$username rememberMe=$rememberMe',
    );
    notifyListeners();
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_keyRememberMe) ?? false;
    if (!remembered) return null;
    return prefs.getString(_keySavedUsername);
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<void> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final body = await Api.login(username: username, password: password);
    final nextToken = _readTokenValue(body, ['access_token', 'token']) ?? '';
    final nextRefreshToken =
        _readTokenValue(body, ['refresh_token', 'refreshToken']) ?? '';
    debugPrint(
      '[GlobalUser] login parsed access=${_preview(nextToken)} refresh=${_preview(nextRefreshToken)}',
    );

    if (nextToken.isEmpty) {
      throw Exception('服务器未返回有效 token');
    }

    await persistTokens(
      accessToken: nextToken,
      refreshToken: nextRefreshToken,
      username: username,
      rememberMe: rememberMe,
    );

    try {
      await fetchProfile();
    } catch (_) {}

    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (token == null || token!.isEmpty) return;
    final profile = await Api.getProfile(token: token!);
    final profileEmail = profile['email'];
    final profileAlias = profile['alias'];
    final profileId = profile['id'] ?? profile['userId'] ?? profile['user_id'];
    if (profileEmail != null && profileEmail.toString().isNotEmpty) {
      email = profileEmail.toString();
    }
    if (profileAlias != null && profileAlias.toString().isNotEmpty) {
      username = profileAlias.toString();
    }
    if (profileId != null && profileId.toString().isNotEmpty) {
      userId = profileId.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId!);
    }
    notifyListeners();
  }

  Future<void> persistTokens({
    required String accessToken,
    String? refreshToken,
    String? username,
    bool? rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }
    if (username != null) {
      await prefs.setString(_keyUsername, username);
      this.username = username;
    }
    if (rememberMe != null) {
      await prefs.setBool(_keyRememberMe, rememberMe);
      this.rememberMe = rememberMe;
      if (rememberMe && username != null) {
        await prefs.setString(_keySavedUsername, username);
      } else if (!rememberMe) {
        await prefs.remove(_keySavedUsername);
      }
    }

    token = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      this.refreshToken = refreshToken;
    }
    debugPrint(
      '[GlobalUser] persistTokens access=${_preview(token)} refresh=${_preview(this.refreshToken)}',
    );
    notifyListeners();
  }

  String? _readTokenValue(Map<String, dynamic> body, List<String> keys) {
    for (final key in keys) {
      final value = body[key]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<void> logout() async {
    final currentToken = token;
    final currentRefreshToken = refreshToken;

    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentRefreshToken != null &&
        currentRefreshToken.isNotEmpty) {
      try {
        await Api.logout(
          token: currentToken,
          refreshToken: currentRefreshToken,
        );
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await _clearLocalSession(prefs);
  }

  Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearLocalSession(prefs);
  }

  Future<void> _clearLocalSession(SharedPreferences prefs) async {
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyUserId);

    token = null;
    refreshToken = null;
    username = null;
    email = null;
    userId = null;
    debugPrint('[GlobalUser] local session cleared');
    notifyListeners();
  }

  String _preview(String? value) {
    if (value == null || value.isEmpty) return '<empty>';
    final head = value.length <= 12 ? value : value.substring(0, 12);
    return '$head...(${value.length})';
  }
}
