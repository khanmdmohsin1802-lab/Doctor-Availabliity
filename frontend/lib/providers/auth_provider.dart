import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curasync/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  String? _userId;
  String? _name;
  String? _email;
  String? _role;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get name => _name;
  String? get email => _email;
  String? get role => _role;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _token != null;
  bool get isDoctor => _role == 'doctor';
  bool get isPatient => _role == 'patient';

  // Load saved session on app start
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _name = prefs.getString('name');
    _email = prefs.getString('email');
    _role = prefs.getString('role');
    notifyListeners();
  }

  // Save session to local storage
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    _token = data['token'];
    _userId = data['_id'];
    _name = data['name'];
    _email = data['email'];
    _role = data['role'];

    await prefs.setString('token', _token!);
    await prefs.setString('userId', _userId!);
    await prefs.setString('name', _name!);
    await prefs.setString('email', _email!);
    await prefs.setString('role', _role!);
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? extraFields,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        extraFields: extraFields,
      );

      if (response.containsKey('token')) {
        await _saveSession(response);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response.containsKey('token')) {
        await _saveSession(response);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _userId = null;
    _name = null;
    _email = null;
    _role = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
