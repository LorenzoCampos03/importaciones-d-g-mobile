import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../service/sale_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import '../sale/sale_detail_page.dart';
import 'vendor_sale_create_edit_page.dart';

class VendorSalesPage extends StatefulWidget {
  const VendorSalesPage({super.key});

  @override
  State<VendorSalesPage> createState() => _VendorSalesPageState();
}

class _VendorSalesPageState extends State<VendorSalesPage> {
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
    'Cancelado', // Agregado para mostrar ventas eliminadas
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
    _loadMySales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMySales() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userInfo?['userId'];

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener todas las ventas y filtrar por vendedor en frontend (workaround temporal)
      final allSales = await SaleService.getAllSales();
      final sales =
          allSales.where((sale) {
            // Verificar si existe la propiedad employeeId y coincide con el userId
            return sale.employeeId == userId ||
                sale.employeeName == authProvider.userInfo?['name'];
          }).toList();
      // Ordenar por saleId descendente (más recientes primero)
      sales.sort((a, b) => (b.saleId ?? 0).compareTo(a.saleId ?? 0));
      setState(() {
        _sales = sales;
        _filteredSales = sales;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar mis ventas: $e');
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
    final authProvider = Provider.of<AuthProvider>(context);

    return RoleGuard(
      allowedRoles: const ['Vendedor'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Ventas'),
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
              onPressed: _loadMySales,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSales.isEmpty
                ? _buildEmptyStateWithHeader()
                : CustomScrollView(
                  slivers: [
                    // Header con información del vendedor
                    SliverToBoxAdapter(
                      child: Container(
                        color: ThemeConfig.backgroundColor,
                        child: Column(
                          children: [
                            // Info del vendedor
                            Container(
                              margin: const EdgeInsets.all(
                                ThemeConfig.paddingMedium,
                              ),
                              decoration: ThemeConfig.getCardDecoration(
                                withGradient: true,
                              ),
                              padding: const EdgeInsets.all(
                                ThemeConfig.paddingMedium,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      0,
                                      0,
                                      0,
                                    ).withOpacity(0.2),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: ThemeConfig.paddingMedium,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Vendedor: ${authProvider.userInfo?['name'] ?? 'Usuario'}',
                                          style: ThemeConfig.bodyLarge.copyWith(
                                            color: const Color.fromARGB(
                                              255,
                                              0,
                                              0,
                                              0,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Total de ventas: ${_sales.length}',
                                          style: ThemeConfig.bodyMedium
                                              .copyWith(
                                                color: const Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ).withOpacity(0.9),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Barra de búsqueda
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                ThemeConfig.paddingMedium,
                                0,
                                ThemeConfig.paddingMedium,
                                ThemeConfig.paddingSmall,
                              ),
                              child: SearchInput(
                                controller: _searchController,
                                hintText: 'Buscar por cliente o ID...',
                                onChanged: _filterSales,
                              ),
                            ),

                            // Panel de filtros
                            if (_showFilters)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  ThemeConfig.paddingMedium,
                                  0,
                                  ThemeConfig.paddingMedium,
                                  ThemeConfig.paddingSmall,
                                ),
                                child: _buildFiltersPanel(),
                              ),

                            // Estadísticas de ventas
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                ThemeConfig.paddingMedium,
                                0,
                                ThemeConfig.paddingMedium,
                                ThemeConfig.paddingMedium,
                              ),
                              child: _buildStatsCard(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lista de ventas
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToCreateSale(),
          backgroundColor: const Color(0xFF4CAF50),
          child: const Icon(Icons.add, color: Colors.white),
          tooltip: 'Nueva Venta',
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithHeader() {
    final authProvider = Provider.of<AuthProvider>(context);

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            color: const Color.fromARGB(255, 0, 82, 163),
            child: Column(
              children: [
                // Info del vendedor
                Container(
                  margin: const EdgeInsets.all(ThemeConfig.paddingMedium),
                  decoration: ThemeConfig.getCardDecoration(withGradient: true),
                  padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ).withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: ThemeConfig.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vendedor: ${authProvider.userInfo?['name'] ?? 'Usuario'}',
                              style: ThemeConfig.bodyLarge.copyWith(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total de ventas: ${_sales.length}',
                              style: ThemeConfig.bodyMedium.copyWith(
                                color: const Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ).withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ThemeConfig.paddingMedium,
                    0,
                    ThemeConfig.paddingMedium,
                    ThemeConfig.paddingSmall,
                  ),
                  child: SearchInput(
                    controller: _searchController,
                    hintText: 'Buscar por cliente o ID...',
                    onChanged: _filterSales,
                  ),
                ),

                // Panel de filtros
                if (_showFilters)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ThemeConfig.paddingMedium,
                      0,
                      ThemeConfig.paddingMedium,
                      ThemeConfig.paddingSmall,
                    ),
                    child: _buildFiltersPanel(),
                  ),

                // Estadísticas
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ThemeConfig.paddingMedium,
                    0,
                    ThemeConfig.paddingMedium,
                    ThemeConfig.paddingMedium,
                  ),
                  child: _buildStatsCard(),
                ),
              ],
            ),
          ),
        ),

        // Empty State
        SliverFillRemaining(
          child: EmptyState(
            icon: Icons.trending_up,
            title:
                _sales.isEmpty
                    ? 'No tienes ventas registradas'
                    : 'No se encontraron ventas',
            message:
                _sales.isEmpty
                    ? 'Tus ventas aparecerán aquí una vez que las registres.'
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

  Widget _buildStatsCard() {
    final totalSales = _sales.length;
    final totalAmount = _sales.fold(0.0, (sum, sale) => sum + sale.total);
    final paidSales = _sales.where((sale) => sale.status == 'Pagado').length;
    final pendingSales =
        _sales.where((sale) => sale.status == 'Pendiente').length;

    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: ThemeConfig.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mis Estadísticas',
                style: ThemeConfig.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Grid de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.receipt_long,
                  label: 'Total Ventas',
                  value: totalSales.toString(),
                  color: ThemeConfig.primaryColor,
                ),
              ),
              const SizedBox(width: ThemeConfig.paddingSmall),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'Monto Total',
                  value: 'S/ ${totalAmount.toStringAsFixed(0)}',
                  color: ThemeConfig.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.paddingSmall),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Pagadas',
                  value: paidSales.toString(),
                  color: ThemeConfig.successColor,
                ),
              ),
              const SizedBox(width: ThemeConfig.paddingSmall),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.pending,
                  label: 'Pendientes',
                  value: pendingSales.toString(),
                  color: ThemeConfig.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ThemeConfig.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: ThemeConfig.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: ThemeConfig.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
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
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: ThemeConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Filtros
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado:', style: ThemeConfig.caption),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                  ],
                ),
              ),
              const SizedBox(width: ThemeConfig.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fecha:', style: ThemeConfig.caption),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedDateFilter,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                      Icons.trending_up,
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
                          style: ThemeConfig.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (sale.clientName != null)
                          Text(
                            'Cliente: ${sale.clientName}',
                            style: ThemeConfig.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (sale.saleDate != null)
                          Text(
                            _formatDate(sale.saleDate!),
                            style: ThemeConfig.caption,
                          ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
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
                                  fontSize: 12,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: ThemeConfig.warningColor,
                        onPressed: () => _navigateToEditSale(sale),
                        tooltip: 'Editar venta',
                      ),
                      if (sale.status !=
                          'Cancelado') // Solo mostrar eliminar si no está cancelada
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: ThemeConfig.errorColor,
                          onPressed: () => _deleteSale(sale),
                          tooltip: 'Eliminar venta',
                        ),
                      if (sale.status ==
                          'Cancelado') // Mostrar restaurar si está cancelada
                        IconButton(
                          icon: const Icon(Icons.restore, size: 20),
                          color: ThemeConfig.successColor,
                          onPressed: () => _restoreSale(sale),
                          tooltip: 'Restaurar venta',
                        ),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        color: ThemeConfig.primaryColor,
                        onPressed: () => _navigateToSaleDetail(sale),
                        tooltip: 'Ver detalles',
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
                          .take(2)
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
                      if (sale.details!.length > 2)
                        Text(
                          '... y ${sale.details!.length - 2} productos más',
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

  Future<void> _navigateToCreateSale() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VendorSaleCreateEditPage()),
    );

    if (result != null) {
      _loadMySales(); // Recargar las ventas
    }
  }

  Future<void> _navigateToEditSale(Sale sale) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorSaleCreateEditPage(saleId: sale.saleId),
      ),
    );

    if (result != null) {
      _loadMySales(); // Recargar las ventas
    }
  }

  Future<void> _deleteSale(Sale sale) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar la venta #${sale.saleId}?\n'
              'Esta acción marcará la venta como cancelada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true && sale.saleId != null) {
      try {
        await SaleService.deleteSale(sale.saleId!);
        SnackBarHelper.showSuccess(context, 'Venta eliminada exitosamente');
        _loadMySales(); // Recargar las ventas
      } catch (e) {
        SnackBarHelper.showError(context, 'Error al eliminar venta: $e');
      }
    }
  }

  Future<void> _restoreSale(Sale sale) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar restauración'),
            content: Text(
              '¿Estás seguro de que deseas restaurar la venta #${sale.saleId}?\n'
              'Esta acción cambiará el estado a Pendiente.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Restaurar'),
              ),
            ],
          ),
    );

    if (confirmed == true && sale.saleId != null) {
      try {
        await SaleService.restoreSale(sale.saleId!);
        SnackBarHelper.showSuccess(context, 'Venta restaurada exitosamente');
        _loadMySales(); // Recargar las ventas
      } catch (e) {
        SnackBarHelper.showError(context, 'Error al restaurar venta: $e');
      }
    }
  }
}
