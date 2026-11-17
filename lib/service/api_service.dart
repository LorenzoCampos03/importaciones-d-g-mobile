import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Headers
  static Map<String, String> get defaultHeaders => ApiConfig.defaultHeaders;

  static Future<Map<String, String>> get authenticatedHeaders async {
    final token = await getToken();
    print(
      '🔐 Token obtenido: ${token != null ? 'EXISTE (${token.length} chars)' : 'NULL'}',
    ); // Debug
    return {
      ...ApiConfig.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // User info management
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    await _storage.write(key: 'user_info', value: jsonEncode(userInfo));
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final userInfoStr = await _storage.read(key: 'user_info');
    if (userInfoStr != null) {
      return jsonDecode(userInfoStr);
    }
    return null;
  }

  static Future<void> deleteUserInfo() async {
    await _storage.delete(key: 'user_info');
  }

  static Future<void> clearStorage() async {
    await _storage.deleteAll();
  }

  // HTTP methods
  static Future<http.Response> get(
    String endpoint, {
    bool authenticated = false,
  }) async {
    final headers = authenticated ? await authenticatedHeaders : defaultHeaders;
    final url = ApiConfig.buildUrl(endpoint);

    print('🌐 GET Request: $url');
    print('🔒 Authenticated: $authenticated');
    if (authenticated) {
      print('📝 Headers: ${headers.keys.toList()}');
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    print('📊 Response: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('❌ Error body: ${response.body}');
    }

    return response;
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final headers = authenticated ? await authenticatedHeaders : defaultHeaders;
    final url = ApiConfig.buildUrl(endpoint);

    print('🌐 POST Request: $url');
    print('🔒 Authenticated: $authenticated');
    print('📝 Body: ${jsonEncode(body)}');
    if (authenticated) {
      print('📝 Headers: ${headers.keys.toList()}');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('📊 Response: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      print('❌ Error body: ${response.body}');
    }

    return response;
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final headers = authenticated ? await authenticatedHeaders : defaultHeaders;
    return await http.put(
      Uri.parse(ApiConfig.buildUrl(endpoint)),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(
    String endpoint, {
    bool authenticated = false,
  }) async {
    final headers = authenticated ? await authenticatedHeaders : defaultHeaders;
    return await http.delete(
      Uri.parse(ApiConfig.buildUrl(endpoint)),
      headers: headers,
    );
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final headers = authenticated ? await authenticatedHeaders : defaultHeaders;
    return await http.patch(
      Uri.parse(ApiConfig.buildUrl(endpoint)),
      headers: headers,
      body: jsonEncode(body),
    );
  }
}
