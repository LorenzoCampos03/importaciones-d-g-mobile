import 'package:flutter/material.dart';
import '../../models/sale.dart';
import '../../service/sale_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'sale_detail_page.dart';

class SaleListPage extends StatefulWidget {
  const SaleListPage({super.key});

  @override
  State<SaleListPage> createState() => _SaleListPageState();
}

class _SaleListPageState extends State<SaleListPage> {
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Filtros
  String _selectedStatus = 'Todos';
  String _selectedDateFilter = 'Todos';
  final List<String> _statusOptions = [
    'Todos',
    'Pagado',
    'Pendiente',
    'Enviado',
    'Cancelado',
  ];
  final List<String> _dateFilterOptions = [
    'Todos',
    'Hoy',
    'Esta semana',
    'Este mes',
  ];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await SaleService.getAllSales();
      // Ordenar por saleId descendente (más recientes primero)
      sales.sort((a, b) => (b.saleId ?? 0).compareTo(a.saleId ?? 0));
      setState(() {
        _sales = sales;
        _filteredSales = sales;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar ventas: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterSales(String query) {
    setState(() {
      _filteredSales =
          _sales.where((sale) {
            // Filtro por texto de búsqueda
            bool matchesSearch = true;
            if (query.isNotEmpty) {
              matchesSearch =
                  (sale.clientName?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false) ||
                  (sale.employeeName?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false) ||
                  (sale.saleId?.toString().contains(query) ?? false);
            }

            // Filtro por estado
            bool matchesStatus =
                _selectedStatus == 'Todos' || sale.status == _selectedStatus;

            // Filtro por fecha
            bool matchesDate = true;
            if (_selectedDateFilter != 'Todos' && sale.saleDate != null) {
              final saleDate = sale.saleDate!;
              final now = DateTime.now();

              switch (_selectedDateFilter) {
                case 'Hoy':
                  matchesDate =
                      saleDate.year == now.year &&
                      saleDate.month == now.month &&
                      saleDate.day == now.day;
                  break;
                case 'Esta semana':
                  final startOfWeek = now.subtract(
                    Duration(days: now.weekday - 1),
                  );
                  final endOfWeek = startOfWeek.add(const Duration(days: 6));
                  matchesDate =
                      saleDate.isAfter(
                        startOfWeek.subtract(const Duration(days: 1)),
                      ) &&
                      saleDate.isBefore(endOfWeek.add(const Duration(days: 1)));
                  break;
                case 'Este mes':
                  matchesDate =
                      saleDate.year == now.year && saleDate.month == now.month;
                  break;
              }
            }

            return matchesSearch && matchesStatus && matchesDate;
          }).toList();
    });
  }

  void _applyFilters() {
    _filterSales(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const ['Administrador', 'Vendedor'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Ventas'),
          actions: [
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list : Icons.filter_list_off,
              ),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSales,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body:
            _isLoading
                ? const LoadingState(message: 'Cargando ventas...')
                : _filteredSales.isEmpty
                ? _buildEmptyStateWithHeader()
                : CustomScrollView(
                  slivers: [
                    // Header con barra de búsqueda, filtros y estadísticas
                    SliverToBoxAdapter(
                      child: Container(
                        color: ThemeConfig.backgroundColor,
                        child: Column(
                          children: [
                            // Barra de búsqueda
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                ThemeConfig.paddingMedium,
                                ThemeConfig.paddingMedium,
                                ThemeConfig.paddingMedium,
                                ThemeConfig.paddingSmall,
                              ),
                              child: SearchInput(
                                controller: _searchController,
                                hintText:
                                    'Buscar por cliente, vendedor o ID...',
                                onChanged: _filterSales,
                              ),
                            ),

                            // Panel de filtros (compacto)
                            if (_showFilters)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  ThemeConfig.paddingMedium,
                                  0,
                                  ThemeConfig.paddingMedium,
                                  ThemeConfig.paddingSmall,
                                ),
                                child: _buildCompactFiltersPanel(),
                              ),

                            // Estadísticas compactas
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                ThemeConfig.paddingMedium,
                                0,
                                ThemeConfig.paddingMedium,
                                ThemeConfig.paddingMedium,
                              ),
                              child: _buildCompactStatsCard(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lista de ventas scrollable
                    SliverPadding(
                      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final sale = _filteredSales[index];
                          return _buildSaleCard(sale);
                        }, childCount: _filteredSales.length),
                      ),
                    ),
                  ],
                ),
        floatingActionButton: CustomFAB(
          onPressed: () => _navigateToReport(),
          icon: Icons.analytics,
          tooltip: 'Ver Reportes',
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithHeader() {
    return CustomScrollView(
      slivers: [
        // Header con barra de búsqueda, filtros y estadísticas
        SliverToBoxAdapter(
          child: Container(
            color: ThemeConfig.backgroundColor,
            child: Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ThemeConfig.paddingMedium,
                    ThemeConfig.paddingMedium,
                    ThemeConfig.paddingMedium,
                    ThemeConfig.paddingSmall,
                  ),
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Buscar por cliente, vendedor o ID...',
                    onChanged: _filterSales,
                  ),
                ),

                // Panel de filtros (compacto)
                if (_showFilters)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ThemeConfig.paddingMedium,
                      0,
                      ThemeConfig.paddingMedium,
                      ThemeConfig.paddingSmall,
                    ),
                    child: _buildCompactFiltersPanel(),
                  ),

                // Estadísticas compactas
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ThemeConfig.paddingMedium,
                    0,
                    ThemeConfig.paddingMedium,
                    ThemeConfig.paddingMedium,
                  ),
                  child: _buildCompactStatsCard(),
                ),
              ],
            ),
          ),
        ),

        // Empty State
        SliverFillRemaining(
          child: EmptyState(
            icon: Icons.receipt_long,
            title:
                _sales.isEmpty
                    ? 'No hay ventas registradas'
                    : 'No se encontraron ventas',
            message:
                _sales.isEmpty
                    ? 'Las ventas aparecerán aquí una vez que se registren.'
                    : 'Intenta ajustar los términos de búsqueda.',
            actionText: _sales.isEmpty ? null : 'Limpiar búsqueda',
            onAction:
                _sales.isEmpty
                    ? null
                    : () {
                      _searchController.clear();
                      _filterSales('');
                    },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatsCard() {
    final totalSales = _sales.length;
    final totalAmount = _sales.fold(0.0, (sum, sale) => sum + sale.total);
    final paidSales = _sales.where((sale) => sale.status == 'Pagado').length;
    final pendingSales =
        _sales.where((sale) => sale.status == 'Pendiente').length;

    return Container(
      decoration: ThemeConfig.getCardDecoration(withGradient: true),
      padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Ventas',
            style: ThemeConfig.bodyMedium.copyWith(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ThemeConfig.paddingSmall),

          // Grid de 2x2 súper compacto
          Row(
            children: [
              Expanded(
                child: _buildCompactStatItem(
                  icon: Icons.receipt_long,
                  label: 'Total',
                  value: totalSales.toString(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCompactStatItem(
                  icon: Icons.attach_money,
                  label: 'Monto',
                  value: 'S/ ${totalAmount.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatItem(
                  icon: Icons.check_circle,
                  label: 'Pagadas',
                  value: paidSales.toString(),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildCompactStatItem(
                  icon: Icons.pending,
                  label: 'Pendientes',
                  value: pendingSales.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 78, 78, 78), size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color.fromARGB(179, 57, 56, 56),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color.fromARGB(179, 57, 56, 56),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFiltersPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConfig.paddingSmall),
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: ThemeConfig.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Filtros',
                style: ThemeConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatus = 'Todos';
                    _selectedDateFilter = 'Todos';
                    _searchController.clear();
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.clear_all, size: 14),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: ThemeConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.paddingSmall),

          // Filtros en una sola fila
          Row(
            children: [
              // Filtro por estado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado:', style: ThemeConfig.caption),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: ThemeConfig.bodySmall,
                        items:
                            _statusOptions
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: ThemeConfig.bodySmall,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: ThemeConfig.paddingSmall),

              // Filtro por fecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha:', style: ThemeConfig.caption),
                    const SizedBox(height: 4),
                    Container(
                      height: 36,
                      child: DropdownButtonFormField<String>(
                        value: _selectedDateFilter,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: ThemeConfig.bodySmall,
                        items:
                            _dateFilterOptions
                                .map(
                                  (dateFilter) => DropdownMenuItem(
                                    value: dateFilter,
                                    child: Text(
                                      dateFilter,
                                      style: ThemeConfig.bodySmall,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDateFilter = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConfig.paddingMedium),
      decoration: ThemeConfig.getCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: InkWell(
          onTap: () => _navigateToSaleDetail(sale),
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
          child: Column(
            children: [
              Row(
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
                      Icons.receipt_long,
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
                          'Venta #${sale.saleId}',
                          style: ThemeConfig.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        if (sale.clientName != null)
                          Text(
                            'Cliente: ${sale.clientName}',
                            style: ThemeConfig.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (sale.employeeName != null)
                          Text(
                            'Vendedor: ${sale.employeeName}',
                            style: ThemeConfig.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (sale.saleDate != null)
                          Text(
                            _formatDate(sale.saleDate!),
                            style: ThemeConfig.caption,
                          ),

                        // Mostrar productos si existen
                        if (sale.details != null &&
                            sale.details!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _buildProductsSummary(sale.details!),
                            style: ThemeConfig.caption.copyWith(
                              color: ThemeConfig.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

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
                                  sale.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(sale.status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                sale.status,
                                style: TextStyle(
                                  color: _getStatusColor(sale.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'S/ ${sale.total.toStringAsFixed(2)}',
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
                        onPressed: () => _navigateToSaleDetail(sale),
                        tooltip: 'Ver detalles',
                      ),
                      if (sale.status == 'Pagado' || sale.status == 'Enviado')
                        IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          color: ThemeConfig.successColor,
                          onPressed: () => _downloadReport(sale),
                          tooltip: 'Descargar reporte',
                        ),
                    ],
                  ),
                ],
              ),

              // Mostrar productos si están disponibles
              if (sale.details != null && sale.details!.isNotEmpty) ...[
                const SizedBox(height: ThemeConfig.paddingMedium),
                Container(
                  padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
                  decoration: BoxDecoration(
                    color: ThemeConfig.backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(
                      ThemeConfig.radiusSmall,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            size: 16,
                            color: ThemeConfig.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Productos (${sale.details!.length})',
                            style: ThemeConfig.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ThemeConfig.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...sale.details!
                          .take(3)
                          .map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Text(
                                    '• ${detail.productName ?? 'Producto'}',
                                    style: ThemeConfig.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'x${detail.quantity}',
                                    style: ThemeConfig.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (sale.details!.length > 3)
                        Text(
                          '... y ${sale.details!.length - 3} productos más',
                          style: ThemeConfig.caption.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pagado':
        return ThemeConfig.successColor;
      case 'Pendiente':
        return ThemeConfig.warningColor;
      case 'Enviado':
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

  String _buildProductsSummary(List<dynamic> details) {
    if (details.isEmpty) return '';

    final int productCount = details.length;
    final int totalQuantity = details.fold(0, (sum, detail) {
      if (detail is Map<String, dynamic>) {
        return sum + (detail['quantity'] as int? ?? 0);
      }
      return sum;
    });

    if (productCount == 1) {
      final detail = details.first;
      if (detail is Map<String, dynamic>) {
        final productName = detail['productName'] ?? 'Producto';
        final quantity = detail['quantity'] ?? 1;
        return '$quantity x $productName';
      }
    }

    return '$productCount productos ($totalQuantity items)';
  }

  void _navigateToSaleDetail(Sale sale) {
    if (sale.saleId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SaleDetailPage(saleId: sale.saleId!),
        ),
      );
    }
  }

  Future<void> _downloadReport(Sale sale) async {
    if (sale.saleId == null) return;

    if (sale.status != 'Pagado' && sale.status != 'Enviado') {
      SnackBarHelper.showWarning(
        context,
        'Solo se pueden descargar reportes de ventas pagadas o enviadas',
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
    SnackBarHelper.showInfo(context, 'Funcionalidad de reportes en desarrollo');
  }
}
