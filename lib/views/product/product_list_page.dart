import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../service/product_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'product_form_page.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _showInactive = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final products = _showInactive
          ? await ProductService.getProductsByStatus('I')
          : await ProductService.getProductsByStatus('A');

      if (mounted) {
        setState(() {
          _products = products;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar productos: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    List<Product> filtered = _products;

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.brandName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _toggleShowInactive() {
    setState(() => _showInactive = !_showInactive);
    _loadProducts();
  }

  Future<void> _navigateToForm({Product? product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(
          product: product,
        ),
      ),
    );

    if (result == true) {
      _loadProducts();
    }
  }

  Future<void> _navigateToDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product.productId!),
      ),
    );
    _loadProducts(); // Recargar por si hubo cambios
  }

  Future<void> _toggleProductStatus(Product product) async {
    final action = product.status == 'A' ? 'desactivar' : 'activar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
        title: Text(
          '${action.toUpperCase()} Producto',
          style: ThemeConfig.headingSmall,
        ),
        content: Text(
          '¿Está seguro que desea $action el producto "${product.name}"?',
          style: ThemeConfig.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ActionButton(
            text: action.toUpperCase(),
            icon: product.status == 'A' ? Icons.inventory_2_outlined : Icons.restore,
            type: product.status == 'A' ? ActionButtonType.danger : ActionButtonType.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (product.status == 'A') {
          await ProductService.deleteProduct(product.productId!);
        } else {
          // Para restaurar, necesitaríamos un método específico en el servicio
          // Por ahora solo manejamos desactivación
        }

        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Producto ${product.status == 'A' ? 'desactivado' : 'activado'} correctamente',
          );
          _loadProducts();
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Error al $action producto: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador', 'Vendedor'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Productos',
          showBackButton: false,
          actions: [
            IconButton(
              icon: Icon(
                _showInactive ? Icons.visibility : Icons.visibility_off,
                color: ThemeConfig.primaryColor,
              ),
              onPressed: _toggleShowInactive,
              tooltip: _showInactive
                  ? 'Mostrar productos activos'
                  : 'Mostrar productos inactivos',
            ),
          ],
        ),
        body: Column(
          children: [
            // Barra de búsqueda y información
            _buildSearchSection(),

            // Lista de productos
            Expanded(
              child: _isLoading
                  ? const LoadingState(message: 'Cargando productos...')
                  : _filteredProducts.isEmpty
                      ? EmptyState(
                          icon: Icons.inventory_2,
                          title: _searchQuery.isNotEmpty
                              ? 'No se encontraron productos'
                              : _showInactive
                                  ? 'No hay productos inactivos'
                                  : 'No hay productos registrados',
                          message: _searchQuery.isNotEmpty
                              ? 'Intenta con otros términos de búsqueda'
                              : _showInactive
                                  ? 'Todos los productos están activos'
                                  : 'Comienza agregando tu primer producto',
                          actionText: _searchQuery.isEmpty && !_showInactive ? 'Agregar Producto' : null,
                          onAction: _searchQuery.isEmpty && !_showInactive
                              ? () => _navigateToForm()
                              : null,
                        )
                      : _buildProductsList(),
            ),
          ],
        ),
        floatingActionButton: !_showInactive ? CustomFAB(
          onPressed: () => _navigateToForm(),
          tooltip: 'Agregar producto',
        ) : null,
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      decoration: const BoxDecoration(
        color: ThemeConfig.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          SearchInput(
            controller: _searchController,
            hintText: 'Buscar productos...',
            onChanged: _onSearchChanged,
            onClear: () => _onSearchChanged(''),
          ),

          const SizedBox(height: ThemeConfig.paddingSmall),

          // Información del filtro actual
          Row(
            children: [
              Icon(
                _showInactive ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: ThemeConfig.textSecondaryColor,
              ),
              const SizedBox(width: ThemeConfig.paddingSmall),
              Text(
                _showInactive
                    ? 'Mostrando productos inactivos'
                    : 'Mostrando productos activos',
                style: ThemeConfig.bodySmall,
              ),
              const Spacer(),
              Text(
                '${_filteredProducts.length} ${_filteredProducts.length == 1 ? 'producto' : 'productos'}',
                style: ThemeConfig.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: ThemeConfig.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: ThemeConfig.paddingSmall),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _buildProductItem(product);
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return StyledListItem(
      title: product.name,
      subtitle: _buildProductSubtitle(product),
      leading: Container(
        padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
        decoration: BoxDecoration(
          color: product.status == 'A'
              ? ThemeConfig.primaryColor.withOpacity(0.1)
              : ThemeConfig.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ThemeConfig.radiusSmall),
        ),
        child: Icon(
          Icons.inventory_2,
          color: product.status == 'A'
              ? ThemeConfig.primaryColor
              : ThemeConfig.errorColor,
          size: 24,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemeConfig.getStatusIndicator(
            status: product.status,
            text: product.status == 'A' ? 'Activo' : 'Inactivo',
          ),
          const SizedBox(width: ThemeConfig.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConfig.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: ThemeConfig.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'S/ ${product.unitPrice.toStringAsFixed(2)}',
              style: ThemeConfig.bodySmall.copyWith(
                color: ThemeConfig.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: ThemeConfig.paddingSmall),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: ThemeConfig.textSecondaryColor),
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _navigateToDetail(product);
                  break;
                case 'edit':
                  _navigateToForm(product: product);
                  break;
                case 'toggle_status':
                  _toggleProductStatus(product);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('Ver detalles'),
                  ],
                ),
              ),
              if (product.status == 'A')
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      product.status == 'A' ? Icons.inventory_2_outlined : Icons.restore,
                      size: 20,
                      color: product.status == 'A' ? ThemeConfig.errorColor : ThemeConfig.successColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.status == 'A' ? 'Desactivar' : 'Activar',
                      style: TextStyle(
                        color: product.status == 'A' ? ThemeConfig.errorColor : ThemeConfig.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _navigateToDetail(product),
    );
  }
  String _buildProductSubtitle(Product product) {
    List<String> parts = [];

    parts.add('Categoría: ${product.categoryName}');

    if (product.brandName.isNotEmpty) {
      parts.add('Marca: ${product.brandName}');
    }

    parts.add('Stock: ${product.stock}');

    return parts.join(' • ');
  }
}
