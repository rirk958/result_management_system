
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';
import '../models/app_user.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'ist_auth_token';
  static const _userKey = 'ist_auth_user';

  String? _token;
  AppUser? _user;
  bool _initialized = false;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isInitialized => _initialized;

  bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty &&
          _user != null && _user!.hasValidRole;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (_token != null && userJson != null) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          final candidate = AppUser.fromJson(decoded);
          if (candidate.hasValidRole) {
            _user = candidate;
          } else {
            await logout();
          }
        } else {
          await logout();
        }
      } catch (_) {
        await logout();
      }
    } else {
      _token = null;
      _user = null;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    final response = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    )
        .timeout(ApiConfig.timeout);

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      body = {};
    }

    if (response.statusCode != 200) {
      throw Exception(
        (body['message'] ?? body['error'] ?? 'Login failed').toString(),
      );
    }

    final receivedToken = body['token'];
    final receivedUser = body['user'];

    if (receivedToken is! String ||
        receivedToken.isEmpty ||
        receivedUser is! Map<String, dynamic>) {
      throw Exception('The server returned an invalid login response.');
    }

    final candidate = AppUser.fromJson(receivedUser);

    if (!candidate.hasValidRole) {
      throw Exception('This account has an unsupported role.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, receivedToken);
    await prefs.setString(
      _userKey,
      jsonEncode(receivedUser),
    );

    _token = receivedToken;
    _user = candidate;
    _initialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    _token = null;
    _user = null;
    _initialized = true;
    notifyListeners();
  }

  // Use this when an authenticated API returns HTTP 401.
  Future<void> handleUnauthorized() async {
    await logout();
  }
}

final AuthService authService = AuthService();
