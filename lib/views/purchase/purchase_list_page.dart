import 'package:flutter/material.dart';
import '../../models/purchase.dart';
import '../../service/purchase_service.dart';
import '../../service/auth_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'purchase_detail_page.dart';
import '../vendor/vendor_purchase_create_edit_page.dart';
import '../vendor/vendor_purchase_list_page.dart';

class PurchaseListPage extends StatefulWidget {
  const PurchaseListPage({super.key});

  @override
  State<PurchaseListPage> createState() => _PurchaseListPageState();
}

class _PurchaseListPageState extends State<PurchaseListPage> {
  List<Purchase> _purchases = [];
  List<Purchase> _filteredPurchases = [];
  bool _isLoading = true;
  String? _currentUserRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _loadPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserRole() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUserRole = user?['role'];
    });
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final purchases = await PurchaseService.getAllPurchases();
      // Ordenar por purchaseId descendente (más recientes primero)
      purchases.sort(
        (a, b) => (b.purchaseId ?? 0).compareTo(a.purchaseId ?? 0),
      );
      setState(() {
        _purchases = purchases;
        _filteredPurchases = purchases;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar compras: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterPurchases(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPurchases = _purchases;
      } else {
        _filteredPurchases =
            _purchases
                .where(
                  (purchase) =>
                      (purchase.userName?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false) ||
                      (purchase.purchaseId?.toString().contains(query) ??
                          false) ||
                      (purchase.supplierId.toString().contains(query)),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si es vendedor, redirigir a su página específica
    if (_currentUserRole == 'Vendedor') {
      return const VendorPurchaseListPage();
    }

    return RoleGuard(
      allowedRoles: const ['Administrador'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Gestión de Compras',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPurchases,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body:
            _isLoading
                ? const LoadingState(message: 'Cargando compras...')
                : Column(
                  children: [
                    // Barra de búsqueda y estadísticas
                    Container(
                      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                      child: Column(
                        children: [
                          SearchInput(
                            controller: _searchController,
                            hintText:
                                'Buscar por usuario, ID de compra o proveedor...',
                            onChanged: _filterPurchases,
                          ),
                          const SizedBox(height: ThemeConfig.paddingMedium),
                          _buildStatsCard(),
                        ],
                      ),
                    ),

                    // Lista de compras
                    Expanded(
                      child:
                          _filteredPurchases.isEmpty
                              ? EmptyState(
                                icon: Icons.shopping_bag,
                                title:
                                    _purchases.isEmpty
                                        ? 'No hay compras registradas'
                                        : 'No se encontraron compras',
                                message:
                                    _purchases.isEmpty
                                        ? 'Las compras aparecerán aquí una vez que se registren.'
                                        : 'Intenta ajustar los términos de búsqueda.',
                                actionText:
                                    _purchases.isEmpty
                                        ? null
                                        : 'Limpiar búsqueda',
                                onAction:
                                    _purchases.isEmpty
                                        ? null
                                        : () {
                                          _searchController.clear();
                                          _filterPurchases('');
                                        },
                              )
                              : RefreshIndicator(
                                onRefresh: _loadPurchases,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(
                                    ThemeConfig.paddingMedium,
                                  ),
                                  itemCount: _filteredPurchases.length,
                                  itemBuilder: (context, index) {
                                    final purchase = _filteredPurchases[index];
                                    return _buildPurchaseCard(purchase);
                                  },
                                ),
                              ),
                    ),
                  ],
                ),
        floatingActionButton:
            _currentUserRole == 'Vendedor'
                ? FloatingActionButton(
                  onPressed: () => _navigateToCreatePurchase(),
                  backgroundColor: const Color(0xFFF44336),
                  child: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Nueva Compra',
                )
                : CustomFAB(
                  onPressed: () => _navigateToReport(),
                  icon: Icons.analytics,
                  tooltip: 'Ver Reportes',
                ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalPurchases = _purchases.length;
    final totalAmount = _purchases.fold(
      0.0,
      (sum, purchase) => sum + purchase.totalCost,
    );
    final receivedPurchases =
        _purchases.where((purchase) => purchase.status == 'Recibido').length;
    final pendingPurchases =
        _purchases.where((purchase) => purchase.status == 'Pendiente').length;

    return InfoCard(
      title: 'Resumen de Compras',
      withGradient: true,
      items: [
        InfoItem(
          label: 'Total de Compras',
          value: totalPurchases.toString(),
          icon: Icons.shopping_bag,
        ),
        InfoItem(
          label: 'Monto Total',
          value: 'S/ ${totalAmount.toStringAsFixed(2)}',
          icon: Icons.attach_money,
        ),
        InfoItem(
          label: 'Compras Recibidas',
          value: receivedPurchases.toString(),
          icon: Icons.check_circle,
        ),
        InfoItem(
          label: 'Compras Pendientes',
          value: pendingPurchases.toString(),
          icon: Icons.pending,
        ),
      ],
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConfig.paddingMedium),
      decoration: ThemeConfig.getCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: InkWell(
          onTap: () => _navigateToPurchaseDetail(purchase),
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: ThemeConfig.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: ThemeConfig.paddingMedium),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compra #${purchase.purchaseId}',
                      style: ThemeConfig.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Proveedor ID: ${purchase.supplierId}',
                      style: ThemeConfig.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (purchase.userName != null)
                      Text(
                        'Usuario: ${purchase.userName}',
                        style: ThemeConfig.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      _formatDate(purchase.purchaseDate),
                      style: ThemeConfig.caption,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              purchase.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(purchase.status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            purchase.status,
                            style: TextStyle(
                              color: _getStatusColor(purchase.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'S/ ${purchase.totalCost.toStringAsFixed(2)}',
                          style: ThemeConfig.bodyMedium.copyWith(
                            color: ThemeConfig.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    color: ThemeConfig.primaryColor,
                    onPressed: () => _navigateToPurchaseDetail(purchase),
                    tooltip: 'Ver detalles',
                  ),
                  if (purchase.status == 'Recibido')
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      color: ThemeConfig.successColor,
                      onPressed: () => _downloadReport(purchase),
                      tooltip: 'Descargar reporte',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Recibido':
        return ThemeConfig.successColor;
      case 'Pendiente':
        return ThemeConfig.warningColor;
      case 'En Tránsito':
        return ThemeConfig.primaryColor;
      case 'Cancelado':
        return ThemeConfig.errorColor;
      default:
        return ThemeConfig.textSecondaryColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _navigateToPurchaseDetail(Purchase purchase) {
    if (purchase.purchaseId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PurchaseDetailPage(purchaseId: purchase.purchaseId!),
        ),
      );
    }
  }

  Future<void> _downloadReport(Purchase purchase) async {
    if (purchase.purchaseId == null) return;

    if (purchase.status != 'Recibido') {
      SnackBarHelper.showWarning(
        context,
        'Solo se pueden descargar reportes de compras recibidas',
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const LoadingState(message: 'Generando reporte...'),
      );

      // Simulación de descarga de reporte
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        SnackBarHelper.showSuccess(context, 'Reporte descargado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        SnackBarHelper.showError(context, 'Error al descargar reporte: $e');
      }
    }
  }

  void _navigateToReport() {
    // Navegar a la página de reportes
    // Esta funcionalidad se implementará según las necesidades específicas
    SnackBarHelper.showInfo(context, 'Funcionalidad de reportes en desarrollo');
  }

  Future<void> _navigateToCreatePurchase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VendorPurchaseCreateEditPage(),
      ),
    );

    if (result != null) {
      _loadPurchases(); // Recargar las compras
    }
  }
}
