import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/driver.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.initial;
  Driver? _driver;
  String? _errorMessage;

  AuthStatus get status => _status;
  Driver? get driver => _driver;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ─── Init: check saved token ───────────────────────────────────────
  Future<void> init() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    // Verify token with server
    final result = await _api.getMe(token);
    if (result['success'] == true) {
      _driver = Driver.fromJson({...result['driver'], 'token': token});
      _setStatus(AuthStatus.authenticated);
    } else {
      await _storage.delete(key: 'auth_token');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _api.login(email: email, password: password);
      if (result['success'] == true) {
        final token = result['token'] as String;
        await _storage.write(key: 'auth_token', value: token);
        _driver = Driver.fromJson({...result['driver'], 'token': token});
        _setStatus(AuthStatus.authenticated);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  // ─── Register ──────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _api.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
      );
      if (result['success'] == true) {
        _setStatus(AuthStatus.unauthenticated);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  // ─── Change Password ──────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    if (_driver?.token == null) {
      return {'success': false, 'message': 'Not authenticated'};
    }

    final result = await _api.changePassword(
      token: _driver!.token!,
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );

    return result;
  }

  // ─── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    if (_driver?.token != null) {
      await _api.logout(_driver!.token!);
    }
    await _storage.delete(key: 'auth_token');
    _driver = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
