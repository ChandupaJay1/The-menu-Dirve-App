import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://127.0.0.1:8000 for Web/Windows
  // Use your COMPUTER'S IP (e.g. 192.168.1.XX) for physical mobile devices
  static const String baseUrl =
      kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.8.101:8000/api';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // ─── Register ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    try {
      print('DEBUG: Attempting register at $baseUrl/register');
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: Register error: $e');
      rethrow;
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG: Attempting login at $baseUrl/login');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('DEBUG: Login error: $e');
      rethrow;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response);
  }

  // ─── Get current user ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response);
  }

  // ─── Change Password ──────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      }),
    );
    return _handleResponse(response);
  }

  // ─── Orders ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getLatestOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders-latest'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String token,
    required int orderId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(response);
  }

  // ─── Response handler ──────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('DEBUG: API Response (${response.statusCode}): ${response.body}');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, ...body};
    } else {
      return {
        'success': false,
        'message': body['message'] ?? 'Something went wrong',
        'errors': body['errors'],
      };
    }
  }
}
