import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dashboard.dart';
import '../../service/client_service.dart';
import '../../service/product_service.dart';
import '../../service/sale_service.dart';
import '../../service/purchase_service.dart';
import '../../config/theme_config.dart';
import '../client/client_list_page.dart';
import '../product/product_list_page.dart';
import 'vendor_sales_page.dart';
import '../purchase/purchase_list_page.dart';

class VendorDashboardPage extends StatefulWidget {
  const VendorDashboardPage({super.key});

  @override
  State<VendorDashboardPage> createState() => _VendorDashboardPageState();
}

class _VendorDashboardPageState extends State<VendorDashboardPage> {
  bool _isLoading = true;
  DashboardStats? _stats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userInfo?['userId'];

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Para vendedor: cargar datos generales y filtrar en frontend como workaround
      final futures = await Future.wait([
        ClientService.getAllActiveClients(),
        ProductService.getProductsByStatus('A'),
        SaleService.getAllSales(), // Usar endpoint general como workaround
        PurchaseService.getAllPurchases(),
      ]);

      final activeClients = futures[0] as List;
      final activeProducts = futures[1] as List;
      final allSales = futures[2] as List;
      final allPurchases = futures[3] as List;

      // Filtrar ventas del vendedor actual en frontend (workaround temporal)
      final mySales =
          allSales.where((sale) {
            // Verificar si existe la propiedad employeeId y coincide con el userId
            final matchesById = sale.employeeId == userId;
            final matchesByName =
                sale.employeeName == authProvider.userInfo?['name'];
            return matchesById || matchesByName;
          }).toList();

      // Calcular estadísticas del vendedor
      final totalSalesAmount = mySales.fold<double>(
        0.0,
        (sum, sale) => sum + (sale.total ?? 0.0),
      );

      final totalPurchasesAmount = allPurchases.fold<double>(
        0.0,
        (sum, purchase) => sum + (purchase.totalCost ?? 0.0),
      );

      _stats = DashboardStats(
        totalClients: 0,
        activeClients: activeClients.length,
        totalProducts: 0,
        activeProducts: activeProducts.length,
        totalSales: mySales.length,
        totalSalesAmount: totalSalesAmount,
        totalPurchases: allPurchases.length,
        totalPurchasesAmount: totalPurchasesAmount,
        totalOffices: 0,
        activeOffices: 0,
      );
    } catch (e) {
      _errorMessage = 'Error al cargar datos del dashboard: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<StatCard> _buildStatCards() {
    if (_stats == null) return [];

    return [
      StatCard(
        title: 'Mis Ventas',
        value: '${_stats!.totalSales}',
        subtitle: 'S/ ${_stats!.totalSalesAmount.toStringAsFixed(2)}',
        icon: Icons.trending_up,
        color: const Color(0xFF4CAF50), // Verde
      ),
      StatCard(
        title: 'Productos',
        value: '${_stats!.activeProducts}',
        subtitle: 'Disponibles',
        icon: Icons.inventory,
        color: const Color(0xFFFF9800), // Naranja
      ),
      StatCard(
        title: 'Clientes',
        value: '${_stats!.activeClients}',
        subtitle: 'Activos',
        icon: Icons.people,
        color: const Color(0xFF2196F3), // Azul
      ),
      StatCard(
        title: 'Compras',
        value: '${_stats!.totalPurchases}',
        subtitle: 'S/ ${_stats!.totalPurchasesAmount.toStringAsFixed(2)}',
        icon: Icons.shopping_bag,
        color: const Color(0xFFF44336), // Rojo
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Vendedor'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDashboardData,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saludo personalizado
                      Container(
                        width: double.infinity,
                        decoration: ThemeConfig.getCardDecoration(
                          withGradient: true,
                        ),
                        padding: const EdgeInsets.all(
                          ThemeConfig.paddingMedium,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.point_of_sale,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: ThemeConfig.paddingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenido, ${authProvider.userInfo?['name'] ?? 'Vendedor'}',
                                    style: ThemeConfig.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Panel de Vendedor - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                    style: ThemeConfig.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ThemeConfig.paddingLarge),

                      // Estadísticas
                      Text(
                        'Resumen de Actividad',
                        style: ThemeConfig.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.1,
                              crossAxisSpacing: ThemeConfig.paddingMedium,
                              mainAxisSpacing: ThemeConfig.paddingMedium,
                            ),
                        itemCount: _buildStatCards().length,
                        itemBuilder: (context, index) {
                          final card = _buildStatCards()[index];
                          return _buildStatCard(card);
                        },
                      ),
                      const SizedBox(height: ThemeConfig.paddingLarge),

                      // Acciones rápidas
                      Text(
                        'Acciones Rápidas',
                        style: ThemeConfig.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard(StatCard card) {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: card.color, width: 2),
            ),
            child: Icon(card.icon, size: 28, color: card.color),
          ),
          const SizedBox(height: ThemeConfig.paddingSmall),
          Text(
            card.value,
            style: ThemeConfig.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: card.color,
            ),
          ),
          Text(
            card.title,
            style: ThemeConfig.bodySmall.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            card.subtitle,
            style: ThemeConfig.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: ThemeConfig.paddingMedium,
      mainAxisSpacing: ThemeConfig.paddingMedium,
      children: [
        _buildActionCard(
          'Mis Ventas',
          Icons.trending_up,
          const Color(0xFF4CAF50), // Verde
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VendorSalesPage()),
          ),
        ),
        _buildActionCard(
          'Compras',
          Icons.shopping_bag,
          const Color(0xFFF44336), // Rojo
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PurchaseListPage()),
          ),
        ),
        _buildActionCard(
          'Productos',
          Icons.inventory,
          const Color(0xFFFF9800), // Naranja
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductListPage()),
          ),
        ),
        _buildActionCard(
          'Clientes',
          Icons.people,
          const Color(0xFF2196F3), // Azul
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientListPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: ThemeConfig.paddingSmall),
              Text(
                title,
                textAlign: TextAlign.center,
                style: ThemeConfig.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
