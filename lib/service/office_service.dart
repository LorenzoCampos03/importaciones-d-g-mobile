import 'dart:convert';
import '../models/office.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class OfficeService {
  // Obtener todas las oficinas activas
  static Future<List<Office>> getAllActiveOffices() async {
    try {
      final response = await ApiService.get(
        ApiConfig.officeListEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Office.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener oficinas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todas las oficinas incluyendo inactivas
  static Future<List<Office>> getAllOffices() async {
    try {
      final response = await ApiService.get(
        ApiConfig.officeAllEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Office.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener todas las oficinas: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener oficinas por estado
  static Future<List<Office>> getOfficesByStatus(String status) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.officeBasePath}/status/$status',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Office.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener oficinas por estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener oficina por ID
  static Future<Office?> getOfficeById(int id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.officeBasePath}/$id',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Office.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener oficina: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear oficina
  static Future<Office> createOffice(Office office) async {
    try {
      final response = await ApiService.post(
        ApiConfig.officeCreateEndpoint,
        office.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Office.fromJson(data);
      } else {
        throw Exception('Error al crear oficina: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar oficina
  static Future<Office> updateOffice(Office office) async {
    try {
      if (office.officeId == null) {
        throw Exception('ID de oficina requerido para actualización');
      }

      final response = await ApiService.put(
        ApiConfig.officeUpdateEndpoint,
        office.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Office.fromJson(data);
      } else {
        throw Exception('Error al actualizar oficina: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminación lógica de oficina
  static Future<void> deleteOffice(int id) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.officeDeleteEndpoint}/$id',
        {},
        authenticated: true,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al eliminar oficina: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Restaurar oficina
  static Future<void> restoreOffice(int id) async {
    try {
      final response = await ApiService.patch(
        '${ApiConfig.officeRestoreEndpoint}/$id',
        {},
        authenticated: true,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Error al restaurar oficina: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
