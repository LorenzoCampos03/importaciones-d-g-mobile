import 'dart:convert';
import '../models/employee.dart';
import 'api_service.dart';

class EmployeeService {
  // Obtener empleado por ID
  static Future<Employee?> getEmployeeById(int id) async {
    try {
      final response = await ApiService.get(
        '/api/v1/employee/$id',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Employee.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener empleado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todos los empleados activos
  static Future<List<Employee>> getAllActiveEmployees() async {
    try {
      final response = await ApiService.get(
        '/api/v1/employee/listEmployee',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Employee.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener empleados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
