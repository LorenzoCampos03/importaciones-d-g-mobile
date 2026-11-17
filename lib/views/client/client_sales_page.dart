import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../service/sale_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'client_sale_detail_page.dart';
import 'client_sale_edit_page.dart';

class ClientSalesPage extends StatefulWidget {
  const ClientSalesPage({super.key});

  @override
  State<ClientSalesPage> createState() => _ClientSalesPageState();
}

class _ClientSalesPageState extends State<ClientSalesPage> {
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';

  final List<String> _statusFilters = [
    'Todos',
    'Pendiente',
    'Pagado',
    'Enviado',
    'Cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clientId = authProvider.userInfo?['userId'];

      if (clientId != null) {
        final sales = await SaleService.getSalesByClient(clientId);
        setState(() {
          _sales = sales;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar compras: $e');
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSales =
          _sales.where((sale) {
            bool matchesSearch =
                _searchQuery.isEmpty ||
                sale.saleId.toString().contains(_searchQuery) ||
                (sale.employeeName?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);

            bool matchesStatus =
                _selectedStatusFilter == 'Todos' ||
                sale.status == _selectedStatusFilter;

            return matchesSearch && matchesStatus;
          }).toList();

      // Ordenar por fecha descendente
      _filteredSales.sort(
        (a, b) => (b.saleDate ?? DateTime.now()).compareTo(
          a.saleDate ?? DateTime.now(),
        ),
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'pagado':
        return Colors.blue;
      case 'enviado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Barra de búsqueda
        TextField(
          decoration: ThemeConfig.getInputDecoration(
            labelText: 'Buscar compras',
            hintText: 'ID, vendedor...',
            prefixIcon: Icons.search,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _applyFilters();
            });
          },
        ),
        const SizedBox(height: 12),

        // Filtro por estado
        Row(
          children: [
            const Text(
              'Estado: ',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      _statusFilters.map((status) {
                        final isSelected = status == _selectedStatusFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter = status;
                                _applyFilters();
                              });
                            },
                            selectedColor: ThemeConfig.primaryColor.withOpacity(
                              0.2,
                            ),
                            checkmarkColor: ThemeConfig.primaryColor,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(sale.saleId!),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: ThemeConfig.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Compra #${sale.saleId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(sale.status),
                ],
              ),
              const SizedBox(height: 12),

              // Información
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Fecha',
                          _formatDate(sale.saleDate ?? DateTime.now()),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Total',
                          'S/ ${sale.total.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.inventory,
                          'Productos',
                          '${sale.details?.length ?? 0} items',
                        ),
                        if (sale.employeeName != null) ...[
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.person,
                            'Vendedor',
                            sale.employeeName!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Acciones
                  Column(
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) => _handleSaleAction(action, sale),
                        itemBuilder: (context) => _buildActionMenu(sale),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildActionMenu(Sale sale) {
    List<PopupMenuEntry<String>> items = [];

    // Ver detalles - siempre disponible
    items.add(
      const PopupMenuItem(
        value: 'view',
        child: ListTile(
          leading: Icon(Icons.visibility),
          title: Text('Ver detalles'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    // Según el estado, mostrar diferentes acciones
    switch (sale.status.toLowerCase()) {
      case 'pendiente':
        items.addAll([
          const PopupMenuItem(
            value: 'pay',
            child: ListTile(
              leading: Icon(Icons.payment, color: Colors.blue),
              title: Text('Pagar', style: TextStyle(color: Colors.blue)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit, color: Colors.orange),
              title: Text('Editar', style: TextStyle(color: Colors.orange)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.cancel, color: Colors.red),
              title: Text('Cancelar', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ]);
        break;

      case 'pagado':
      case 'enviado':
        // Solo ver detalles para estados finales exitosos
        break;

      case 'cancelado':
        items.add(
          const PopupMenuItem(
            value: 'restore',
            child: ListTile(
              leading: Icon(Icons.restore, color: Colors.green),
              title: Text('Restaurar', style: TextStyle(color: Colors.green)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
        break;
    }

    return items;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _handleSaleAction(String action, Sale sale) async {
    switch (action) {
      case 'view':
        _navigateToDetail(sale.saleId!);
        break;
      case 'pay':
        _showPaymentDialog(sale);
        break;
      case 'edit':
        _navigateToEdit(sale.saleId!);
        break;
      case 'cancel':
        _showCancelConfirmation(sale);
        break;
      case 'restore':
        _showRestoreConfirmation(sale);
        break;
    }
  }

  void _navigateToDetail(int saleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientSaleDetailPage(saleId: saleId),
      ),
    );
  }

  void _navigateToEdit(int saleId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientSaleEditPage(saleId: saleId),
      ),
    );

    if (result != null) {
      _loadSales(); // Recargar lista
    }
  }

  void _showPaymentDialog(Sale sale) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Confirmar Pago'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Confirmas el pago de la compra #${sale.saleId}?'),
                const SizedBox(height: 8),
                Text(
                  'Total: S/ ${sale.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processPayment(sale);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar Pago'),
              ),
            ],
          ),
    );
  }

  void _showCancelConfirmation(Sale sale) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Confirmar Cancelación'),
              ],
            ),
            content: Text(
              '¿Estás seguro de que quieres cancelar la compra #${sale.saleId}? Esta acción se puede revertir.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelSale(sale.saleId!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancelar Compra'),
              ),
            ],
          ),
    );
  }

  void _showRestoreConfirmation(Sale sale) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.restore, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Confirmar Restauración'),
              ],
            ),
            content: Text(
              '¿Estás seguro de que quieres restaurar la compra #${sale.saleId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _restoreSale(sale.saleId!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Restaurar'),
              ),
            ],
          ),
    );
  }

  Future<void> _processPayment(Sale sale) async {
    try {
      await SaleService.updateSaleStatus(sale.saleId!, 'Pagado');
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Pago procesado exitosamente');
        _loadSales();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al procesar pago: $e');
      }
    }
  }

  Future<void> _cancelSale(int saleId) async {
    try {
      await SaleService.deleteSale(saleId);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Compra cancelada exitosamente');
        _loadSales();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cancelar compra: $e');
      }
    }
  }

  Future<void> _restoreSale(int saleId) async {
    try {
      await SaleService.restoreSale(saleId);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Compra restaurada exitosamente');
        _loadSales();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al restaurar compra: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const ['Cliente'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Compras'),
          backgroundColor: const Color.fromARGB(255, 49, 197, 0),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadSales,
                  child: Column(
                    children: [
                      // Filtros y búsqueda
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: _buildSearchAndFilters(),
                      ),

                      // Lista de compras
                      Expanded(
                        child:
                            _filteredSales.isEmpty
                                ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No tienes compras disponibles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: _filteredSales.length,
                                  itemBuilder: (context, index) {
                                    return _buildSaleCard(
                                      _filteredSales[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
