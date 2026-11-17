import 'dart:convert';
import '../models/product.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ProductService {
  // Obtener todos los productos
  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await ApiService.get(
        ApiConfig.productListEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener productos por estado
  static Future<List<Product>> getProductsByStatus(String status) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.productByStatusEndpoint}/$status',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener productos por estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener producto por ID
  static Future<Product?> getProductById(int id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.productListEndpoint}/$id',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear producto
  static Future<Product> createProduct(Product product) async {
    try {
      final response = await ApiService.post(
        ApiConfig.productCreateEndpoint,
        product.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Error al crear producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar producto
  static Future<Product> updateProduct(Product product) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.productUpdateEndpoint}/${product.productId}',
        product.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Error al actualizar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminación lógica de producto
  static Future<void> deleteProduct(int id) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.productDeleteEndpoint}/$id',
        {},
        authenticated: true,
      );

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Restaurar producto
  static Future<void> restoreProduct(int id) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.productRestoreEndpoint}/$id',
        {},
        authenticated: true,
      );

      if (response.statusCode != 204) {
        throw Exception('Error al restaurar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener productos disponibles para clientes
  static Future<List<Product>> getAvailableProducts() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.productBasePath}/available',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener productos disponibles: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
