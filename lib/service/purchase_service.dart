import 'dart:convert';
import '../models/purchase.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PurchaseService {
  // Obtener todas las compras
  static Future<List<Purchase>> getAllPurchases() async {
    try {
      final response = await ApiService.get(
        ApiConfig.purchaseListEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Purchase.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener compras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener compra por ID
  static Future<Purchase?> getPurchaseById(int id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.purchaseListEndpoint}/$id',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Purchase.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener compra: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva compra
  static Future<Purchase> createPurchase(Purchase purchase) async {
    try {
      final response = await ApiService.post(
        ApiConfig.purchaseCreateEndpoint,
        purchase.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Purchase.fromJson(data);
      } else {
        throw Exception('Error al crear compra: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar compra
  static Future<Purchase> updatePurchase(int id, Purchase purchase) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.purchaseUpdateEndpoint}/$id',
        purchase.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Purchase.fromJson(data);
      } else {
        throw Exception('Error al actualizar compra: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar compra (cancelar)
  static Future<void> deletePurchase(int id) async {
    try {
      final response = await ApiService.delete(
        '${ApiConfig.purchaseDeleteEndpoint}/$id',
        authenticated: true,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar compra: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al eliminar compra: $e');
    }
  }

  // Restaurar compra (cambiar de Cancelado a Pendiente)
  static Future<void> restorePurchase(int id) async {
    try {
      // Cambiar estado de Cancelado a Pendiente
      await changeStatus(id, 'Pendiente');
    } catch (e) {
      throw Exception('Error al restaurar compra: $e');
    }
  }

  // Cambiar estado de compra
  static Future<Purchase> changeStatus(int id, String newStatus) async {
    try {
      // Primero obtener la compra actual
      final currentPurchase = await getPurchaseById(id);
      if (currentPurchase == null) {
        throw Exception('Compra no encontrada');
      }

      // Crear copia con el nuevo estado
      final updatedPurchase = currentPurchase.copyWith(status: newStatus);

      // Actualizar usando el endpoint de actualización
      final response = await ApiService.put(
        '${ApiConfig.purchaseUpdateEndpoint}/$id',
        updatedPurchase.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Purchase.fromJson(data);
      } else {
        throw Exception('Error al cambiar estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  // Obtener compras por empleado
  static Future<List<Purchase>> getPurchasesByEmployee(int employeeId) async {
    try {
      final allPurchases = await getAllPurchases();
      return allPurchases
          .where((purchase) => purchase.employeeId == employeeId)
          .toList();
    } catch (e) {
      throw Exception('Error al obtener compras del empleado: $e');
    }
  }
}
