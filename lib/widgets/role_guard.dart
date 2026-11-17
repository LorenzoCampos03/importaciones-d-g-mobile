import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userRole = authProvider.userRole;

        if (userRole != null && allowedRoles.contains(userRole)) {
          return child;
        }

        return fallback ?? const UnauthorizedWidget();
      },
    );
  }
}

class UnauthorizedWidget extends StatelessWidget {
  const UnauthorizedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Denegado'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'No tienes permisos para acceder a esta sección',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Contacta al administrador si crees que esto es un error',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Enum para los roles disponibles según Constants.java
class AppRoles {
  static const String administrador = 'Administrador';
  static const String vendedor = 'Vendedor';
  static const String cliente = 'Cliente';

  static const List<String> all = [administrador, vendedor, cliente];
  static const List<String> adminOnly = [administrador];
  static const List<String> adminAndVendedor = [administrador, vendedor];
  static const List<String> clienteOnly = [cliente];
}
