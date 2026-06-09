import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class GlobalUser extends ChangeNotifier {
  GlobalUser._();

  static final GlobalUser instance = GlobalUser._();

  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUsername = 'auth_username';
  static const _keyRememberMe = 'auth_remember_me';
  static const _keySavedUsername = 'auth_saved_username';

  String? token;
  String? refreshToken;
  String? username;
  String? email;
  bool rememberMe = false;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_keyToken);
    refreshToken = prefs.getString(_keyRefreshToken);
    username = prefs.getString(_keyUsername);
    rememberMe = prefs.getBool(_keyRememberMe) ?? false;
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
    final nextToken = (body['access_token'] ?? body['token'] ?? '') as String;
    final nextRefreshToken =
        (body['refresh_token'] ?? body['refreshToken'] ?? '') as String;

    if (nextToken.isEmpty) {
      throw Exception('服务器未返回有效 token');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, nextToken);
    if (nextRefreshToken.isNotEmpty) {
      await prefs.setString(_keyRefreshToken, nextRefreshToken);
    }
    await prefs.setString(_keyUsername, username);
    await prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_keySavedUsername, username);
    } else {
      await prefs.remove(_keySavedUsername);
    }

    token = nextToken;
    refreshToken = nextRefreshToken;
    this.username = username;
    this.rememberMe = rememberMe;

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
    if (profileEmail != null && profileEmail.toString().isNotEmpty) {
      email = profileEmail.toString();
    }
    if (profileAlias != null && profileAlias.toString().isNotEmpty) {
      username = profileAlias.toString();
    }
    notifyListeners();
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
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUsername);

    token = null;
    refreshToken = null;
    username = null;
    email = null;
    notifyListeners();
  }
}
