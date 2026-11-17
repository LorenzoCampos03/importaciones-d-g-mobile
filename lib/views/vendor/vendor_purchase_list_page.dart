import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/purchase.dart';
import '../../service/purchase_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'vendor_purchase_create_edit_page.dart';
import 'vendor_purchase_detail_page.dart';

class VendorPurchaseListPage extends StatefulWidget {
  const VendorPurchaseListPage({super.key});

  @override
  State<VendorPurchaseListPage> createState() => _VendorPurchaseListPageState();
}

class _VendorPurchaseListPageState extends State<VendorPurchaseListPage> {
  List<Purchase> _purchases = [];
  List<Purchase> _filteredPurchases = [];
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
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userInfo?['userId'];

      if (userId != null) {
        final purchases = await PurchaseService.getPurchasesByEmployee(userId);
        setState(() {
          _purchases = purchases;
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
      _filteredPurchases =
          _purchases.where((purchase) {
            bool matchesSearch =
                _searchQuery.isEmpty ||
                purchase.purchaseId.toString().contains(_searchQuery) ||
                (purchase.userName?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);

            bool matchesStatus =
                _selectedStatusFilter == 'Todos' ||
                purchase.status == _selectedStatusFilter;

            return matchesSearch && matchesStatus;
          }).toList();

      // Ordenar por fecha descendente
      _filteredPurchases.sort(
        (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
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
            hintText: 'ID, empleado...',
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

  Widget _buildPurchaseCard(Purchase purchase) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(purchase.purchaseId!),
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
                    Icons.shopping_bag,
                    color: ThemeConfig.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Compra #${purchase.purchaseId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(purchase.status),
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
                          _formatDate(purchase.purchaseDate),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Total',
                          '\$${purchase.totalCost.toStringAsFixed(2)}',
                        ),
                        if (purchase.userName != null) ...[
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.person,
                            'Empleado',
                            purchase.userName!,
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
                        onSelected:
                            (action) => _handlePurchaseAction(action, purchase),
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: ListTile(
                                  leading: Icon(Icons.visibility),
                                  title: Text('Ver detalles'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Editar'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (purchase.status != 'Cancelado') ...[
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ] else ...[
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.restore,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      'Restaurar',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ],
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

  Future<void> _handlePurchaseAction(String action, Purchase purchase) async {
    switch (action) {
      case 'view':
        _navigateToDetail(purchase.purchaseId!);
        break;
      case 'edit':
        _navigateToEdit(purchase.purchaseId!);
        break;
      case 'delete':
        _showDeleteConfirmation(purchase);
        break;
      case 'restore':
        _showRestoreConfirmation(purchase);
        break;
    }
  }

  void _navigateToDetail(int purchaseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorPurchaseDetailPage(purchaseId: purchaseId),
      ),
    );
  }

  void _navigateToEdit(int purchaseId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VendorPurchaseCreateEditPage(purchaseId: purchaseId),
      ),
    );

    if (result != null) {
      _loadPurchases(); // Recargar lista
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VendorPurchaseCreateEditPage(),
      ),
    );

    if (result != null) {
      _loadPurchases(); // Recargar lista
    }
  }

  void _showDeleteConfirmation(Purchase purchase) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Confirmar Eliminación'),
              ],
            ),
            content: Text(
              '¿Estás seguro de que quieres eliminar la compra #${purchase.purchaseId}? Esta acción se puede revertir.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePurchase(purchase.purchaseId!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  void _showRestoreConfirmation(Purchase purchase) {
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
              '¿Estás seguro de que quieres restaurar la compra #${purchase.purchaseId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _restorePurchase(purchase.purchaseId!);
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

  Future<void> _deletePurchase(int purchaseId) async {
    try {
      await PurchaseService.deletePurchase(purchaseId);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Compra eliminada exitosamente');
        _loadPurchases();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al eliminar compra: $e');
      }
    }
  }

  Future<void> _restorePurchase(int purchaseId) async {
    try {
      await PurchaseService.restorePurchase(purchaseId);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Compra restaurada exitosamente');
        _loadPurchases();
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
      allowedRoles: const ['Vendedor'],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Compras'),
          backgroundColor: ThemeConfig.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPurchases,
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadPurchases,
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
                            _filteredPurchases.isEmpty
                                ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No hay compras disponibles',
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
                                  itemCount: _filteredPurchases.length,
                                  itemBuilder: (context, index) {
                                    return _buildPurchaseCard(
                                      _filteredPurchases[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreate,
          backgroundColor: ThemeConfig.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
