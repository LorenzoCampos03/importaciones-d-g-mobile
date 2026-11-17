import 'dart:convert';
import '../models/client.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ClientService {
  // Obtener todos los clientes activos
  static Future<List<Client>> getAllActiveClients() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.clientBasePath}/active',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Client.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todos los clientes incluyendo inactivos (solo admin)
  static Future<List<Client>> getAllClients() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.clientBasePath}/all',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Client.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener todos los clientes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener clientes por estado
  static Future<List<Client>> getClientsByStatus(String status) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.clientBasePath}/status/$status',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Client.fromJson(item)).toList();
      } else {
        throw Exception(
          'Error al obtener clientes por estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener cliente por ID
  static Future<Client?> getClientById(int id) async {
    try {
      print('📡 Solicitando cliente ID: $id');
      final endpoint = '${ApiConfig.clientBasePath}/$id';
      print('🔗 Endpoint: $endpoint');

      final response = await ApiService.get(endpoint, authenticated: true);

      print('📊 Response status: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('👤 Cliente encontrado: ${data['name']} ${data['lastName']}');
        return Client.fromJson(data);
      } else if (response.statusCode == 404) {
        print('❌ Cliente no encontrado');
        return null;
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw Exception('Error al obtener cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en getClientById: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nuevo cliente
  static Future<Client> createClient(Client client) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.clientBasePath}/create',
        client.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Client.fromJson(data);
      } else {
        throw Exception('Error al crear cliente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar cliente (método admin)
  static Future<Client> updateClient(Client client) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.clientBasePath}/update',
        client.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Client.fromJson(data);
      } else {
        throw Exception('Error al actualizar cliente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar perfil del cliente por userId (para clientes)
  static Future<Client> updateClientProfile(int userId, Client client) async {
    try {
      print('📝 Actualizando perfil del cliente userId: $userId');
      final endpoint = '${ApiConfig.clientBasePath}/partialUpdate/$userId';
      print('🔗 Endpoint: $endpoint');

      final clientData = client.toJson();
      print('📤 Datos a enviar: $clientData');

      final response = await ApiService.patch(
        endpoint,
        clientData,
        authenticated: true,
      );

      print('📊 Response status: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Cliente actualizado exitosamente');
        return Client.fromJson(data);
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        throw Exception('Error al actualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception en updateClientProfile: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualización parcial de cliente
  static Future<Client> partialUpdateClient(
    int id,
    Client partialClient,
  ) async {
    try {
      final response = await ApiService.patch(
        '${ApiConfig.clientBasePath}/partialUpdate/$id',
        partialClient.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Client.fromJson(data);
      } else {
        throw Exception(
          'Error al actualizar parcialmente cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Desactivar cliente (eliminación lógica)
  static Future<void> deactivateClient(int id) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.clientBasePath}/logicalDelete/$id',
        {},
        authenticated: true,
      );

      if (response.statusCode != 204) {
        throw Exception('Error al desactivar cliente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Restaurar cliente
  static Future<void> restoreClient(int id) async {
    try {
      final response = await ApiService.patch(
        '${ApiConfig.clientBasePath}/restore/$id',
        {},
        authenticated: true,
      );

      if (response.statusCode != 204) {
        throw Exception('Error al restaurar cliente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar cliente permanentemente
  static Future<void> permanentlyDeleteClient(int id) async {
    try {
      final response = await ApiService.delete(
        '${ApiConfig.clientBasePath}/permanent/$id',
        authenticated: true,
      );

      if (response.statusCode != 204) {
        throw Exception(
          'Error al eliminar cliente permanentemente: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
