import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Order> _allOrders = [];
  List<Order> _latestOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get allOrders => _allOrders;
  List<Order> get latestOrders => _latestOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllOrders(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.getOrders(token);
      if (result['success'] == true) {
        final List<dynamic> ordersJson = result['orders'];
        _allOrders = ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch orders';
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLatestOrders(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.getLatestOrders(token);
      if (result['success'] == true) {
        final List<dynamic> ordersJson = result['orders'];
        _latestOrders = ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch latest orders';
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String token, int orderId, String status) async {
    try {
      final result = await _api.updateOrderStatus(
        token: token,
        orderId: orderId,
        status: status,
      );

      if (result['success'] == true) {
        // Refresh orders locally
        await fetchLatestOrders(token);
        await fetchAllOrders(token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
