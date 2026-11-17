import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/dashboard.dart';
import '../../service/client_service.dart';
import '../../service/product_service.dart';
import '../../service/sale_service.dart';
import '../../service/purchase_service.dart';
import '../../service/office_service.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import '../client/client_list_page.dart';
import '../product/product_list_page.dart';
import '../sale/sale_list_page.dart';
import '../purchase/purchase_list_page.dart';
import '../office/office_list_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar datos de forma paralela
      final futures = await Future.wait([
        ClientService.getAllClients(),
        ClientService.getAllActiveClients(),
        ProductService.getAllProducts(),
        ProductService.getProductsByStatus('A'),
        SaleService.getAllSales(),
        PurchaseService.getAllPurchases(),
        OfficeService.getAllOffices(),
        OfficeService.getAllActiveOffices(),
      ]);

      final allClients = futures[0] as List;
      final activeClients = futures[1] as List;
      final allProducts = futures[2] as List;
      final activeProducts = futures[3] as List;
      final allSales = futures[4] as List;
      final allPurchases = futures[5] as List;
      final allOffices = futures[6] as List;
      final activeOffices = futures[7] as List;

      // Calcular totales de ventas y compras
      final totalSalesAmount = allSales.fold<double>(
        0.0,
        (sum, sale) => sum + (sale.total ?? 0.0),
      );
      final totalPurchasesAmount = allPurchases.fold<double>(
        0.0,
        (sum, purchase) => sum + (purchase.totalCost ?? 0.0),
      );

      _stats = DashboardStats(
        totalClients: allClients.length,
        activeClients: activeClients.length,
        totalProducts: allProducts.length,
        activeProducts: activeProducts.length,
        totalSales: allSales.length,
        totalSalesAmount: totalSalesAmount,
        totalPurchases: allPurchases.length,
        totalPurchasesAmount: totalPurchasesAmount,
        totalOffices: allOffices.length,
        activeOffices: activeOffices.length,
      );
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar datos del dashboard: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userInfo = authProvider.userInfo;

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: ThemeConfig.primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Panel de Administración',
                  style: ThemeConfig.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: ThemeConfig.primaryGradient,
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'logout':
                        _logout();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userInfo?['name'] ?? 'Usuario',
                                style: ThemeConfig.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userInfo?['email'] ?? '',
                                style: ThemeConfig.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text('Cerrar Sesión'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ];
        },
        body:
            _isLoading
                ? const LoadingState(message: 'Cargando dashboard...')
                : _stats == null
                ? ErrorState(
                  title: 'Error',
                  message: 'No se pudieron cargar los datos del dashboard',
                  actionText: 'Reintentar',
                  onAction: _loadDashboardData,
                )
                : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: ThemeConfig.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas principales
            _buildStatsSection(),

            const SizedBox(height: ThemeConfig.paddingLarge),

            // Accesos rápidos
            _buildQuickAccessSection(),

            const SizedBox(height: ThemeConfig.paddingLarge),

            // Resumen financiero
            _buildFinancialSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estadísticas Generales', style: ThemeConfig.headingSmall),

        const SizedBox(height: ThemeConfig.paddingMedium),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          crossAxisSpacing: ThemeConfig.paddingMedium,
          mainAxisSpacing: ThemeConfig.paddingMedium,
          children: [
            _buildStatCard(
              title: 'Clientes',
              value: '${_stats!.activeClients}',
              subtitle: 'de ${_stats!.totalClients} totales',
              icon: Icons.people,
              color: ThemeConfig.primaryColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientListPage(),
                    ),
                  ),
            ),
            _buildStatCard(
              title: 'Productos',
              value: '${_stats!.activeProducts}',
              subtitle: 'de ${_stats!.totalProducts} totales',
              icon: Icons.inventory_2,
              color: ThemeConfig.accentColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListPage(),
                    ),
                  ),
            ),
            _buildStatCard(
              title: 'Oficinas',
              value: '${_stats!.activeOffices}',
              subtitle: 'de ${_stats!.totalOffices} totales',
              icon: Icons.business,
              color: ThemeConfig.successColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfficeListPage(),
                    ),
                  ),
            ),
            _buildStatCard(
              title: 'Ventas',
              value: '${_stats!.totalSales}',
              subtitle: 'transacciones',
              icon: Icons.shopping_cart,
              color: ThemeConfig.warningColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SaleListPage(),
                    ),
                  ),
            ),
          ],
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ThemeConfig.getCardDecoration(withGradient: true),
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ThemeConfig.radiusSmall,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: ThemeConfig.textSecondaryColor,
                ),
              ],
            ),

            const Spacer(),

            Text(
              value,
              style: ThemeConfig.headingLarge.copyWith(
                color: color,
                fontSize: 32,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: ThemeConfig.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            Text(subtitle, style: ThemeConfig.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accesos Rápidos', style: ThemeConfig.headingSmall),

        const SizedBox(height: ThemeConfig.paddingMedium),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          crossAxisSpacing: ThemeConfig.paddingMedium,
          mainAxisSpacing: ThemeConfig.paddingMedium,
          children: [
            _buildQuickAccessCard(
              title: 'Nueva Venta',
              icon: Icons.add_shopping_cart,
              color: ThemeConfig.successColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SaleListPage(),
                    ),
                  ),
            ),
            _buildQuickAccessCard(
              title: 'Nueva Compra',
              icon: Icons.shopping_bag,
              color: ThemeConfig.warningColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseListPage(),
                    ),
                  ),
            ),
            _buildQuickAccessCard(
              title: 'Gestionar Clientes',
              icon: Icons.people_alt,
              color: ThemeConfig.primaryColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientListPage(),
                    ),
                  ),
            ),
            _buildQuickAccessCard(
              title: 'Gestionar Productos',
              icon: Icons.inventory,
              color: ThemeConfig.accentColor,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListPage(),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: ThemeConfig.getCardDecoration(),
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ThemeConfig.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: ThemeConfig.paddingSmall),

            Expanded(
              child: Text(
                title,
                style: ThemeConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: ThemeConfig.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return InfoCard(
      title: 'Resumen Financiero',
      withGradient: true,
      items: [
        InfoItem(
          label: 'Total en Ventas',
          value: 'S/ ${_stats!.totalSalesAmount.toStringAsFixed(2)}',
          icon: Icons.trending_up,
        ),
        InfoItem(
          label: 'Total en Compras',
          value: 'S/ ${_stats!.totalPurchasesAmount.toStringAsFixed(2)}',
          icon: Icons.trending_down,
        ),
        InfoItem(
          label: 'Balance',
          value:
              'S/ ${(_stats!.totalSalesAmount - _stats!.totalPurchasesAmount).toStringAsFixed(2)}',
          icon: Icons.account_balance,
          widget: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConfig.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  (_stats!.totalSalesAmount - _stats!.totalPurchasesAmount) >= 0
                      ? ThemeConfig.successColor.withOpacity(0.1)
                      : ThemeConfig.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'S/ ${(_stats!.totalSalesAmount - _stats!.totalPurchasesAmount).toStringAsFixed(2)}',
              style: ThemeConfig.bodyLarge.copyWith(
                color:
                    (_stats!.totalSalesAmount - _stats!.totalPurchasesAmount) >=
                            0
                        ? ThemeConfig.successColor
                        : ThemeConfig.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
