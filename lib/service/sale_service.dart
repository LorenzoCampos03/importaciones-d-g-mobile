import 'dart:convert';
import '../models/sale.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class SaleService {
  // Obtener todas las ventas
  static Future<List<Sale>> getAllSales() async {
    try {
      final response = await ApiService.get(
        ApiConfig.saleListEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Sale.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener ventas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener venta por ID
  static Future<Sale?> getSaleById(int id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.saleListEndpoint}/$id',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener venta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva venta
  static Future<Sale> createSale(SaleRequest saleRequest) async {
    try {
      final response = await ApiService.post(
        ApiConfig.saleCreateEndpoint,
        saleRequest.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al crear venta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nueva venta con datos directos (compatible con Angular)
  static Future<Sale> createSaleFromData(Map<String, dynamic> saleData) async {
    try {
      final response = await ApiService.post(
        ApiConfig.saleCreateEndpoint,
        saleData,
        authenticated: true,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al crear venta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar venta lógicamente
  static Future<Sale> deleteSale(int saleId) async {
    try {
      final response = await ApiService.delete(
        '${ApiConfig.saleListEndpoint}/$saleId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al eliminar venta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Restaurar venta eliminada (cambiar estado a "Pagado")
  static Future<Sale> restoreSale(int saleId) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.saleBasePath}/$saleId/status?status=Pagado',
        {},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al restaurar venta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al restaurar venta: $e');
    }
  }

  // Obtener ventas por cliente
  static Future<List<Sale>> getSalesByClient(int clientId) async {
    try {
      print('📡 Solicitando ventas para cliente ID: $clientId');
      final endpoint = '${ApiConfig.saleBasePath}/client/$clientId';
      print('🔗 Endpoint: $endpoint');

      final response = await ApiService.get(endpoint, authenticated: true);

      print('📊 Response status: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('📦 Datos recibidos: ${data.length} ventas');

        final sales =
            data.map((item) {
              print('🔄 Procesando venta: ${item['saleId']}');
              return Sale.fromJson(item);
            }).toList();

        print('✅ Ventas procesadas exitosamente: ${sales.length}');
        return sales;
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        throw Exception(
          'Error al obtener ventas del cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Exception en getSalesByClient: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener ventas por empleado
  static Future<List<Sale>> getSalesByEmployee(int employeeId) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.saleBasePath}/employee/$employeeId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Sale.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener ventas del empleado: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar estado de una venta
  static Future<Sale> updateSaleStatus(int saleId, String status) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.saleListEndpoint}/$saleId/status?status=$status',
        {},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al actualizar estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar cantidad de un detalle de venta
  static Future<Sale> updateSaleDetailQuantity(
    int saleId,
    int detailId,
    int quantity,
  ) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.saleBasePath}/$saleId/details/$detailId?quantity=$quantity',
        {},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al actualizar cantidad: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar un detalle de venta
  static Future<Sale> removeSaleDetail(int saleId, int detailId) async {
    try {
      final response = await ApiService.delete(
        '${ApiConfig.saleBasePath}/$saleId/details/$detailId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al eliminar detalle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Agregar un detalle a una venta existente
  static Future<Sale> addSaleDetail(
    int saleId,
    Map<String, dynamic> detailData,
  ) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.saleBasePath}/$saleId/details',
        detailData,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sale.fromJson(data);
      } else {
        throw Exception('Error al agregar detalle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar venta completa - ELIMINAR ESTE MÉTODO YA QUE NO EXISTE EN EL BACKEND
  // static Future<Sale> updateSale(int saleId, Sale sale) async {
  //   El backend no tiene este endpoint, use los métodos específicos de detalles
  // }
}
