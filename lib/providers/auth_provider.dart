import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../service/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userRole;
  Map<String, dynamic>? _userInfo;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userRole => _userRole;
  Map<String, dynamic>? get userInfo => _userInfo;
  String? get errorMessage => _errorMessage;

  // Inicializar provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await AuthService.isAuthenticated();
      if (_isAuthenticated) {
        _userInfo = await AuthService.getCurrentUser();
        _userRole = _userInfo?['role'];
      }
    } catch (e) {
      _isAuthenticated = false;
      _userInfo = null;
      _userRole = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginRequest = LoginRequest(username: username, password: password);
      final response = await AuthService.login(loginRequest);

      if (response != null && response.success) {
        _isAuthenticated = true;
        _userInfo = {
          'userId': response.userId,
          'username': response.username,
          'role': response.role,
          'email': response.email,
          'name': response.name,
          'lastName': response.lastName,
        };
        _userRole = response.role;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response?.message ?? 'Error en el login';
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isAuthenticated = false;
    _userInfo = null;
    _userRole = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register
  Future<bool> register(RegisterRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.register(request);

      if (response != null && response.success) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _userInfo = null;
    _userRole = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Verificar disponibilidad de username
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      return await AuthService.isUsernameAvailable(username);
    } catch (e) {
      return false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Verificar si el usuario tiene un rol específico
  bool hasRole(String role) {
    return _userRole == role;
  }

  // Obtener nombre completo del usuario
  String get fullName {
    if (_userInfo != null) {
      return '${_userInfo!['name']} ${_userInfo!['lastName']}';
    }
    return '';
  }
}
