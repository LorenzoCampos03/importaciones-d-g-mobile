import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../models/client.dart';
import '../../service/sale_service.dart';
import '../../service/client_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'client_profile_edit_page.dart';
import 'client_sales_page.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  bool _isLoading = true;
  Client? _clientInfo;
  List<Sale> _clientSales = [];

  // Estadísticas
  int _totalPurchases = 0;
  int _pendingPurchases = 0;
  int _completedPurchases = 0;
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clientId = authProvider.userInfo?['userId'];

      print('🔍 Client ID: $clientId');
      print('🔍 User Info: ${authProvider.userInfo}');

      if (clientId != null) {
        print('📡 Cargando información del cliente...');

        // Cargar información del cliente
        try {
          final clientInfo = await ClientService.getClientById(clientId);
          print(
            '👤 Cliente cargado: ${clientInfo?.name} ${clientInfo?.lastName}',
          );
          print('📧 Email: ${clientInfo?.email}');
          setState(() {
            _clientInfo = clientInfo;
          });
        } catch (e) {
          print('❌ Error al cargar cliente: $e');
          if (mounted) {
            SnackBarHelper.showError(
              context,
              'Error al cargar información del cliente: $e',
            );
          }
        }

        // Cargar ventas del cliente
        try {
          print('🛒 Cargando ventas del cliente ID: $clientId...');
          final clientSales = await SaleService.getSalesByClient(clientId);
          print('✅ Ventas cargadas: ${clientSales.length}');
          clientSales.forEach((sale) {
            print(
              '  - Venta #${sale.saleId}: ${sale.status} - S/ ${sale.total}',
            );
          });

          setState(() {
            _clientSales = clientSales;
          });

          _calculateStats();
        } catch (e) {
          print('❌ Error al cargar ventas: $e');
          if (mounted) {
            SnackBarHelper.showError(context, 'Error al cargar compras: $e');
          }
        }
      } else {
        print('❌ No se pudo obtener el ID del cliente');
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'No se pudo obtener información del usuario',
          );
        }
      }
    } catch (e) {
      print('❌ Error general: $e');
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar datos: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _totalPurchases = _clientSales.length;
    _pendingPurchases =
        _clientSales.where((sale) => sale.status == 'Pendiente').length;
    _completedPurchases =
        _clientSales.where((sale) => sale.status == 'Enviado').length;
    _totalSpent = _clientSales.fold(0.0, (sum, sale) => sum + sale.total);
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (mounted) {
          // Navegar a la pantalla de login y limpiar el stack de navegación
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Error al cerrar sesión: $e');
        }
      }
    }
  }

  Widget _buildProfileSection() {
    if (_clientInfo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No se pudo cargar la información del perfil'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: ThemeConfig.primaryColor,
                  child: Text(
                    _clientInfo!.name.isNotEmpty
                        ? _clientInfo!.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_clientInfo!.name} ${_clientInfo!.lastName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clientInfo!.email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente desde ${_formatDate(_clientInfo!.registrationDate ?? DateTime.now())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit),
                  label: const Text('Actualizar Información'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.phone,
                    label: 'Teléfono',
                    value: _clientInfo!.phone ?? 'No registrado',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: _clientInfo!.address ?? 'No registrada',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.person,
                    label: 'Rol',
                    value: 'Cliente',
                    valueColor: ThemeConfig.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: ThemeConfig.primaryColor, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'TOTAL DE COMPRAS',
            value: _totalPurchases.toString(),
            subtitle: 'Pedidos realizados',
            icon: Icons.shopping_bag,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'PENDIENTES',
            value: _pendingPurchases.toString(),
            subtitle: 'En proceso',
            icon: Icons.access_time,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'COMPLETADOS',
            value: _completedPurchases.toString(),
            subtitle: 'Entregados',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'TOTAL GASTADO',
            value: 'S/ ${_totalSpent.toStringAsFixed(2)}',
            subtitle: 'En compras',
            icon: Icons.attach_money,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPurchases() {
    final recentSales = _clientSales.take(3).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Compras Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _navigateToAllPurchases,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ver todas'),
                ),
              ],
            ),
            const Text(
              'Últimas transacciones realizadas',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (recentSales.isEmpty) ...[
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No has realizado compras aún',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...recentSales.map((sale) => _buildRecentPurchaseItem(sale)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPurchaseItem(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeConfig.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag,
              color: ThemeConfig.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compra #${sale.saleId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sale.details?.length ?? 0} productos',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  _formatDate(sale.saleDate ?? DateTime.now()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusChip(sale.status),
              const SizedBox(height: 4),
              Text(
                'S/ ${sale.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        break;
      case 'pagado':
        color = Colors.blue;
        break;
      case 'enviado':
        color = Colors.green;
        break;
      case 'cancelado':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientProfileEditPage(client: _clientInfo!),
      ),
    );

    if (result != null) {
      _loadDashboardData(); // Recargar datos
    }
  }

  void _navigateToAllPurchases() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientSalesPage()),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const ['Cliente'],
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Panel Principal'),
          backgroundColor: ThemeConfig.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Perfil del cliente
                        _buildProfileSection(),
                        const SizedBox(height: 20),

                        // Estadísticas
                        _buildStatsCards(),
                        const SizedBox(height: 20),

                        // Compras recientes
                        _buildRecentPurchases(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
