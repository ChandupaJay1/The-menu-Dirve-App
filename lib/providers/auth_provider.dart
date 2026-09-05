import 'package:flutter/foundation.dart';
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
      final driverData = result['driver'] ?? result['user'] ?? result;
      if (driverData is Map) {
        _driver = Driver.fromJson({
          ...Map<String, dynamic>.from(driverData),
          'token': token,
        });
        _setStatus(AuthStatus.authenticated);
        return;
      }
    }
    await _storage.delete(key: 'auth_token');
    _setStatus(AuthStatus.unauthenticated);
  }

  // ─── Login ─────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _api.login(email: email, password: password);
      if (result['success'] == true) {
        final token = (result['token'] ?? result['access_token'])?.toString();
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'auth_token', value: token);
          final driverData = result['driver'] ?? result['user'] ?? result;
          if (driverData is Map) {
            _driver = Driver.fromJson({
              ...Map<String, dynamic>.from(driverData),
              'token': token,
            });
          }
          _setStatus(AuthStatus.authenticated);
          return true;
        }
      }
      _errorMessage = result['message'] ?? 'Login failed';
      _setStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      if (kDebugMode) print('DEBUG: Login exception: $e');
      _errorMessage = 'Network or server error. Please check connection.';
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

  // ─── Reset Password (Forgot Password) ──────────────────────────────
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final result = await _api.resetPassword(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _setStatus(AuthStatus.unauthenticated);
      return result;
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _setStatus(AuthStatus.unauthenticated);
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  // ─── Refresh Current Driver (Realtime Sync) ───────────────────────
  Future<void> refreshProfile() async {
    if (_driver?.token == null) return;
    try {
      final result = await _api.getMe(_driver!.token!);
      if (result['success'] == true) {
        final driverData = result['driver'] ?? result['user'] ?? result;
        if (driverData is Map) {
          _driver = Driver.fromJson({
            ...Map<String, dynamic>.from(driverData),
            'token': _driver!.token,
          });
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // ─── Update Driver Status Locally & Remotely ──────────────────────
  Future<bool> setStatus(String newStatus) async {
    if (_driver?.token == null || _driver?.id == null) return false;
    try {
      await _api.updateDriverStatus(
        token: _driver!.token!,
        driverId: _driver!.id!,
        status: newStatus,
      );
      _driver = Driver(
        id: _driver!.id,
        name: _driver!.name,
        email: _driver!.email,
        phone: _driver!.phone,
        vehicleType: _driver!.vehicleType,
        vehicleNumber: _driver!.vehicleNumber,
        token: _driver!.token,
        status: newStatus,
        isActive: newStatus != 'offline',
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
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
