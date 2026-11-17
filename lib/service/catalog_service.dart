import 'dart:convert';
import '../models/catalog.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class CatalogService {
  // Obtener todas las categorías
  static Future<List<CatalogOption>> getCategories() async {
    try {
      final response = await ApiService.get(
        ApiConfig.categoriesEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CatalogOption.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todas las marcas
  static Future<List<CatalogOption>> getBrands() async {
    try {
      final response = await ApiService.get(
        ApiConfig.brandsEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CatalogOption.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener marcas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todos los proveedores
  static Future<List<CatalogOption>> getSuppliers() async {
    try {
      final response = await ApiService.get(
        ApiConfig.suppliersEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => CatalogOption.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener proveedores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
