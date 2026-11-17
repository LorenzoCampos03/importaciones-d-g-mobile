import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/purchase.dart';
import '../../models/product.dart';
import '../../models/catalog.dart';
import '../../service/purchase_service.dart';
import '../../service/product_service.dart';
import '../../service/catalog_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';

class VendorPurchaseCreateEditPage extends StatefulWidget {
  final int? purchaseId;

  const VendorPurchaseCreateEditPage({super.key, this.purchaseId});

  @override
  State<VendorPurchaseCreateEditPage> createState() =>
      _VendorPurchaseCreateEditPageState();
}

class _VendorPurchaseCreateEditPageState
    extends State<VendorPurchaseCreateEditPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEditing = false;

  // Form controllers
  final TextEditingController _observationsController = TextEditingController();

  // Data
  List<Product> _products = [];
  List<CatalogOption> _suppliers = [];
  List<PurchaseDetail> _purchaseDetails = [];

  // Selected values
  String _selectedStatus = 'Pendiente';
  int? _selectedSupplierId;
  final List<String> _statusOptions = [
    'Pendiente',
    'Pagado',
    'Enviado',
    'Cancelado',
  ];

  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.purchaseId != null;
    _loadInitialData();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar productos y proveedores
      final futures = await Future.wait([
        ProductService.getProductsByStatus('A'),
        CatalogService.getSuppliers(),
      ]);

      _products = futures[0] as List<Product>;
      _suppliers = futures[1] as List<CatalogOption>;

      // Si es edición, cargar la compra existente
      if (_isEditing && widget.purchaseId != null) {
        final purchase = await PurchaseService.getPurchaseById(
          widget.purchaseId!,
        );
        if (purchase != null) {
          _populateFormWithPurchase(purchase);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar datos: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateFormWithPurchase(Purchase purchase) {
    _selectedSupplierId = purchase.supplierId;
    _selectedStatus = purchase.status;
    _purchaseDetails = purchase.purchaseDetails;
    _calculateTotal();
  }

  void _calculateTotal() {
    _totalCost = _purchaseDetails.fold(
      0.0,
      (sum, detail) => sum + (detail.totalCost ?? detail.calculatedTotalCost),
    );
    setState(() {});
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      SnackBarHelper.showError(context, 'Selecciona un proveedor');
      return;
    }
    if (_purchaseDetails.isEmpty) {
      SnackBarHelper.showError(context, 'Agrega al menos un producto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userInfo?['userId'];

      final purchase = Purchase(
        purchaseId: _isEditing ? widget.purchaseId : null,
        employeeId: userId ?? 0,
        supplierId: _selectedSupplierId!,
        purchaseDate: DateTime.now(),
        status: _selectedStatus,
        totalCost: _totalCost,
        purchaseDetails: _purchaseDetails,
      );

      Purchase savedPurchase;
      if (_isEditing && widget.purchaseId != null) {
        savedPurchase = await PurchaseService.updatePurchase(
          widget.purchaseId!,
          purchase,
        );
      } else {
        savedPurchase = await PurchaseService.createPurchase(purchase);
      }

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          _isEditing
              ? 'Compra actualizada exitosamente'
              : 'Compra creada exitosamente',
        );
        Navigator.pop(context, savedPurchase);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al guardar compra: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder:
          (context) => _ProductSelectorDialog(
            products: _products,
            onProductSelected: _addProductToPurchase,
          ),
    );
  }

  void _addProductToPurchase(Product product, int quantity, double unitCost) {
    final existing = _purchaseDetails.indexWhere(
      (detail) => detail.productId == product.id,
    );

    if (existing != -1) {
      // Actualizar cantidad si ya existe
      _purchaseDetails[existing] = _purchaseDetails[existing].copyWith(
        quantity: _purchaseDetails[existing].quantity + quantity,
        totalCost: (_purchaseDetails[existing].quantity + quantity) * unitCost,
      );
    } else {
      // Agregar nuevo producto
      _purchaseDetails.add(
        PurchaseDetail(
          productId: product.id!,
          productName: product.name,
          quantity: quantity,
          unitCost: unitCost,
          totalCost: quantity * unitCost,
        ),
      );
    }

    _calculateTotal();
  }

  void _removeProduct(int index) {
    setState(() {
      _purchaseDetails.removeAt(index);
      _calculateTotal();
    });
  }

  void _updateProductQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeProduct(index);
      return;
    }

    setState(() {
      _purchaseDetails[index] = _purchaseDetails[index].copyWith(
        quantity: newQuantity,
        totalCost: newQuantity * _purchaseDetails[index].unitCost,
      );
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const ['Vendedor'],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Compra' : 'Nueva Compra'),
          backgroundColor: const Color(0xFF2E3192),
          foregroundColor: Colors.white,
          actions: [
            if (!_isLoading)
              TextButton(
                onPressed: _savePurchase,
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información básica
                        _buildBasicInfoSection(),
                        const SizedBox(height: ThemeConfig.paddingLarge),

                        // Lista de productos
                        _buildProductsSection(),
                        const SizedBox(height: ThemeConfig.paddingLarge),

                        // Total
                        _buildTotalSection(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de la Compra',
            style: ThemeConfig.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Proveedor
          DropdownButtonFormField<int>(
            value: _selectedSupplierId,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Proveedor',
              hintText: 'Selecciona un proveedor',
              prefixIcon: Icons.business,
            ),
            items:
                _suppliers.map((supplier) {
                  return DropdownMenuItem<int>(
                    value: supplier.id,
                    child: Text(supplier.name),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSupplierId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Selecciona un proveedor';
              }
              return null;
            },
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Estado
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Estado',
              hintText: 'Selecciona el estado',
              prefixIcon: Icons.flag,
            ),
            items:
                _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value ?? 'Pendiente');
            },
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Observaciones
          TextFormField(
            controller: _observationsController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Observaciones',
              hintText: 'Observaciones adicionales (opcional)',
              prefixIcon: Icons.note,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos (${_purchaseDetails.length})',
                style: ThemeConfig.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          if (_purchaseDetails.isEmpty)
            Container(
              padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: ThemeConfig.paddingSmall),
                  Text(
                    'No hay productos agregados',
                    style: ThemeConfig.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: ThemeConfig.paddingSmall),
                  Text(
                    'Presiona "Agregar" para añadir productos',
                    style: ThemeConfig.caption,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _purchaseDetails.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final detail = _purchaseDetails[index];
                return _buildProductDetailCard(detail, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetailCard(PurchaseDetail detail, int index) {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
      child: Row(
        children: [
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.productName ?? 'Producto sin nombre',
                  style: ThemeConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Costo unitario: S/ ${detail.unitCost.toStringAsFixed(2)}',
                  style: ThemeConfig.caption,
                ),
              ],
            ),
          ),

          // Controles de cantidad
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      () => _updateProductQuantity(index, detail.quantity - 1),
                  color: ThemeConfig.errorColor,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${detail.quantity}',
                    textAlign: TextAlign.center,
                    style: ThemeConfig.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      () => _updateProductQuantity(index, detail.quantity + 1),
                  color: ThemeConfig.successColor,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // Total
          SizedBox(
            width: 80,
            child: Text(
              'S/ ${(detail.totalCost ?? detail.calculatedTotalCost).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: ThemeConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Botón eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeProduct(index),
            color: ThemeConfig.errorColor,
            tooltip: 'Eliminar producto',
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total de la Compra',
            style: ThemeConfig.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'S/ ${_totalCost.toStringAsFixed(2)}',
            style: ThemeConfig.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSelectorDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product, int, double) onProductSelected;

  const _ProductSelectorDialog({
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<_ProductSelectorDialog> {
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _filteredProducts = [];
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts =
            widget.products.where((product) {
              return product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.description.toLowerCase().contains(
                    query.toLowerCase(),
                  );
            }).toList();
      }
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _costController.text = product.unitPrice.toStringAsFixed(2);
    });
  }

  void _addProduct() {
    if (_selectedProduct == null) {
      SnackBarHelper.showError(context, 'Selecciona un producto');
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    final cost = double.tryParse(_costController.text);

    if (quantity == null || quantity <= 0) {
      SnackBarHelper.showError(context, 'Ingresa una cantidad válida');
      return;
    }

    if (cost == null || cost <= 0) {
      SnackBarHelper.showError(context, 'Ingresa un costo válido');
      return;
    }

    widget.onProductSelected(_selectedProduct!, quantity, cost);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seleccionar Producto',
                  style: ThemeConfig.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: ThemeConfig.paddingMedium),

            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: ThemeConfig.getInputDecoration(
                labelText: 'Buscar',
                hintText: 'Buscar productos...',
                prefixIcon: Icons.search,
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: ThemeConfig.paddingMedium),

            // Lista de productos
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final isSelected = _selectedProduct?.id == product.id;

                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.description}\nPrecio: S/ ${product.unitPrice.toStringAsFixed(2)}',
                      ),
                      selected: isSelected,
                      selectedTileColor: ThemeConfig.primaryColor.withOpacity(
                        0.1,
                      ),
                      onTap: () => _selectProduct(product),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: ThemeConfig.paddingMedium),

            // Configuración
            if (_selectedProduct != null) ...[
              Container(
                padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Producto seleccionado: ${_selectedProduct!.name}',
                      style: ThemeConfig.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: ThemeConfig.paddingSmall),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: ThemeConfig.getInputDecoration(
                              labelText: 'Cantidad',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: ThemeConfig.paddingMedium),
                        Expanded(
                          child: TextField(
                            controller: _costController,
                            decoration: ThemeConfig.getInputDecoration(
                              labelText: 'Costo unitario (S/)',
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ThemeConfig.paddingMedium),
            ],

            // Botón agregar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedProduct != null ? _addProduct : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar Producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
