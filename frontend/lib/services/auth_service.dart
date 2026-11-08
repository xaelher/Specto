import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── SharedPreferences keys ────────────────────
  static const _kAccessToken  = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUser         = 'user_json';

  // ── In-memory cache ───────────────────────────
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // ─────────────────────────────────────────────
  // Token management
  // ─────────────────────────────────────────────

  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken,  access);
    await prefs.setString(_kRefreshToken, refresh);
  }

  Future<void> _saveUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUser);
  }

  // ─────────────────────────────────────────────
  // getCurrentUser — restore from prefs on cold start
  // ─────────────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      _currentUser = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if we have a saved access token.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken) ?? '';
    return token.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────

  /// Throws [DioException] on error, returns [UserModel] on success.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await dio.post('/auth/login/', data: {
      'username': username,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _saveTokens(data['access'] as String, data['refresh'] as String);
    await _saveUser(user);
    return user;
  }

  // ─────────────────────────────────────────────
  // Register
  // ─────────────────────────────────────────────

  Future<UserModel> register({
    required String username,
    required String firstName,
    required String lastName,
    required String role,
    required String password,
    required String passwordConfirm,
    String schoolGrade = '',
  }) async {
    final response = await dio.post('/auth/register/', data: {
      'username':         username,
      'first_name':       firstName,
      'last_name':        lastName,
      'role':             role,
      'school_grade':     schoolGrade,
      'password':         password,
      'password_confirm': passwordConfirm,
    });
    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _saveTokens(data['access'] as String, data['refresh'] as String);
    await _saveUser(user);
    return user;
  }

  // ─────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────

  Future<void> logout() async {
    await _clearSession();
  }
}
