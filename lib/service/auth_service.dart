import 'dart:convert';
import '../models/auth_models.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  // Login
  static Future<LoginResponse?> login(LoginRequest request) async {
    try {
      final response = await ApiService.post(
        ApiConfig.loginEndpoint,
        request.toJson(),
      );

      final data = jsonDecode(response.body);
      final loginResponse = LoginResponse.fromJson(data);

      if (response.statusCode == 200 && loginResponse.success) {
        // Guardar token y información del usuario
        if (loginResponse.token != null) {
          await ApiService.saveToken(loginResponse.token!);
          await ApiService.saveUserInfo({
            'userId': loginResponse.userId,
            'username': loginResponse.username,
            'role': loginResponse.role,
            'email': loginResponse.email,
            'name': loginResponse.name,
            'lastName': loginResponse.lastName,
          });
        }
        return loginResponse;
      } else {
        return loginResponse; // Devolver la respuesta con success = false y mensaje de error
      }
    } catch (e) {
      return LoginResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  // Register
  static Future<RegisterResponse?> register(RegisterRequest request) async {
    try {
      final response = await ApiService.post(
        ApiConfig.registerEndpoint,
        request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RegisterResponse.fromJson(data);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error en el registro');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Validar token
  static Future<bool> validateToken() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return false;

      // Simplemente verificar si el token existe y no está vacío
      // En un entorno de producción, podrías hacer una llamada a un endpoint específico de validación
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.clearStorage();
  }

  // Obtener usuario actual
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await ApiService.getUserInfo();
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await ApiService.getToken();
    if (token == null) return false;
    return await validateToken();
  }

  // Obtener rol del usuario
  static Future<String?> getUserRole() async {
    final userInfo = await getCurrentUser();
    return userInfo?['role'];
  }

  // Verificar si el usuario tiene un rol específico
  static Future<bool> hasRole(String role) async {
    final userRole = await getUserRole();
    return userRole == role;
  }

  // Verificar username disponible
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.authBasePath}/validate/username/$username',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return !(data['exists'] ??
            true); // Si exists es true, NO está disponible
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
