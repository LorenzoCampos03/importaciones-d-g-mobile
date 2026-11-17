import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../models/product.dart';
import '../../models/client.dart';
import '../../models/employee.dart';
import '../../service/sale_service.dart';
import '../../service/product_service.dart';
import '../../service/client_service.dart';
import '../../service/employee_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';

class VendorSaleCreateEditPage extends StatefulWidget {
  final int? saleId;

  const VendorSaleCreateEditPage({super.key, this.saleId});

  @override
  State<VendorSaleCreateEditPage> createState() =>
      _VendorSaleCreateEditPageState();
}

class _VendorSaleCreateEditPageState extends State<VendorSaleCreateEditPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEditing = false;

  // Form controllers
  final TextEditingController _observationsController = TextEditingController();

  // Data
  Sale? _currentSale;
  Employee? _currentEmployee;
  List<Client> _clients = [];
  List<Product> _products = [];
  List<SaleDetail> _saleDetails = [];

  // Selected values
  Client? _selectedClient;
  String _selectedPaymentMethod = 'Efectivo';
  String _selectedDeliveryMethod = 'Recojo en tienda';
  final List<String> _paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];
  final List<String> _deliveryMethods = [
    'Recojo en tienda',
    'Delivery',
    'Envío a domicilio',
  ];

  final TextEditingController _deliveryAddressController =
      TextEditingController();

  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.saleId != null;
    _loadInitialData();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userInfo?['userId'];

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Cargar datos del empleado, clientes y productos en paralelo
      final futures = await Future.wait([
        EmployeeService.getEmployeeById(userId),
        ClientService.getAllActiveClients(),
        ProductService.getProductsByStatus('A'),
      ]);

      _currentEmployee = futures[0] as Employee?;
      _clients = futures[1] as List<Client>;
      _products = futures[2] as List<Product>;

      // Si es edición, cargar la venta existente
      if (_isEditing && widget.saleId != null) {
        _currentSale = await SaleService.getSaleById(widget.saleId!);
        if (_currentSale != null) {
          _populateFormWithSale(_currentSale!);
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

  void _populateFormWithSale(Sale sale) {
    _selectedClient = _clients.firstWhere(
      (client) => client.id == sale.clientId,
      orElse: () => _clients.first,
    );
    _selectedPaymentMethod = sale.paymentMethod ?? 'Efectivo';
    _selectedDeliveryMethod = sale.deliveryMethod ?? 'Recojo en tienda';
    _deliveryAddressController.text = sale.deliveryAddress ?? '';
    _observationsController.text = sale.observations ?? '';
    _saleDetails = sale.details ?? [];
    _calculateTotal();
  }

  void _calculateTotal() {
    _total = _saleDetails.fold(0.0, (sum, detail) => sum + detail.totalPrice);
    setState(() {});
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      SnackBarHelper.showError(context, 'Selecciona un cliente');
      return;
    }
    if (_saleDetails.isEmpty) {
      SnackBarHelper.showError(context, 'Agrega al menos un producto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final employeeId = authProvider.userInfo?['userId'];

      // Usar el officeId del empleado cargado, no del token
      final officeId = _currentEmployee?.officeId;

      // Usar exactamente el mismo formato que Angular
      final saleData = {
        'client_id': _selectedClient!.id!,
        'employee_id': employeeId!,
        'office_id': officeId,
        'payment_method': _selectedPaymentMethod,
        'delivery_method': _selectedDeliveryMethod,
        'delivery_address':
            _selectedDeliveryMethod == 'Recojo en tienda'
                ? null
                : _deliveryAddressController.text.trim().isEmpty
                ? null
                : _deliveryAddressController.text.trim(),
        'saleDetails':
            _saleDetails
                .map(
                  (detail) => {
                    'productId': detail.productId!,
                    'quantity': detail.quantity,
                  },
                )
                .toList(),
      };

      print('Enviando datos de venta: $saleData'); // Debug

      Sale savedSale;
      if (_isEditing && widget.saleId != null) {
        // TODO: Implementar actualización
        savedSale = await SaleService.createSaleFromData(saleData); // Temporal
      } else {
        savedSale = await SaleService.createSaleFromData(saleData);
      }

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          _isEditing
              ? 'Venta actualizada exitosamente'
              : 'Venta creada exitosamente',
        );
        Navigator.pop(context, savedSale);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al guardar venta: $e');
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
            onProductSelected: _addProductToSale,
          ),
    );
  }

  void _addProductToSale(Product product, int quantity) {
    final existing = _saleDetails.indexWhere(
      (detail) => detail.productId == product.id,
    );

    if (existing != -1) {
      // Actualizar cantidad si ya existe
      _saleDetails[existing] = _saleDetails[existing].copyWith(
        quantity: _saleDetails[existing].quantity + quantity,
        totalPrice:
            (_saleDetails[existing].quantity + quantity) *
            _saleDetails[existing].unitPrice,
      );
    } else {
      // Agregar nuevo producto
      _saleDetails.add(
        SaleDetail(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          unitPrice: product.salePrice,
          totalPrice: quantity * product.salePrice,
        ),
      );
    }

    _calculateTotal();
  }

  void _removeProduct(int index) {
    setState(() {
      _saleDetails.removeAt(index);
      _calculateTotal();
    });
  }

  void _updateProductQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeProduct(index);
      return;
    }

    setState(() {
      _saleDetails[index] = _saleDetails[index].copyWith(
        quantity: newQuantity,
        totalPrice: newQuantity * _saleDetails[index].unitPrice,
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
          title: Text(_isEditing ? 'Editar Venta' : 'Nueva Venta'),
          backgroundColor: const Color(0xFF2E3192),
          foregroundColor: Colors.white,
          actions: [
            if (!_isLoading)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSale,
                tooltip: 'Guardar',
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
                        _buildBasicInfoCard(),
                        const SizedBox(height: ThemeConfig.paddingMedium),

                        // Productos
                        _buildProductsCard(),
                        const SizedBox(height: ThemeConfig.paddingMedium),

                        // Total
                        _buildTotalCard(),
                        const SizedBox(height: ThemeConfig.paddingLarge),

                        // Botón guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSale,
                            child: Text(
                              _isEditing ? 'Actualizar Venta' : 'Crear Venta',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Básica',
            style: ThemeConfig.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Cliente
          DropdownButtonFormField<Client>(
            value: _selectedClient,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              border: OutlineInputBorder(),
            ),
            items:
                _clients
                    .map(
                      (client) => DropdownMenuItem(
                        value: client,
                        child: Text('${client.name} ${client.lastName}'),
                      ),
                    )
                    .toList(),
            onChanged: (client) => setState(() => _selectedClient = client),
            validator:
                (value) => value == null ? 'Selecciona un cliente' : null,
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Método de pago
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(
              labelText: 'Método de Pago',
              border: OutlineInputBorder(),
            ),
            items:
                _paymentMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
            onChanged:
                (method) => setState(() => _selectedPaymentMethod = method!),
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Método de entrega
          DropdownButtonFormField<String>(
            value: _selectedDeliveryMethod,
            decoration: const InputDecoration(
              labelText: 'Método de Entrega',
              border: OutlineInputBorder(),
            ),
            items:
                _deliveryMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
            onChanged:
                (method) => setState(() => _selectedDeliveryMethod = method!),
          ),

          // Dirección de entrega (solo si no es recojo en tienda)
          if (_selectedDeliveryMethod != 'Recojo en tienda') ...[
            const SizedBox(height: ThemeConfig.paddingMedium),
            TextFormField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de Entrega',
                border: OutlineInputBorder(),
                hintText: 'Ingresa la dirección de entrega',
              ),
              validator: (value) {
                if (_selectedDeliveryMethod != 'Recojo en tienda' &&
                    (value == null || value.trim().isEmpty)) {
                  return 'La dirección es requerida para este método de entrega';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: ThemeConfig.paddingMedium),

          // Observaciones
          TextFormField(
            controller: _observationsController,
            decoration: const InputDecoration(
              labelText: 'Observaciones (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard() {
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
                'Productos (${_saleDetails.length})',
                style: ThemeConfig.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: ThemeConfig.paddingMedium),

          if (_saleDetails.isEmpty)
            Container(
              padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
              child: const Center(child: Text('No hay productos agregados')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _saleDetails.length,
              itemBuilder: (context, index) => _buildProductItem(index),
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(int index) {
    final detail = _saleDetails[index];

    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConfig.paddingSmall),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(ThemeConfig.radiusSmall),
      ),
      padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.productName ?? 'Producto',
                  style: ThemeConfig.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'S/ ${detail.unitPrice.toStringAsFixed(2)} c/u',
                  style: ThemeConfig.bodySmall,
                ),
              ],
            ),
          ),

          // Cantidad
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed:
                    () => _updateProductQuantity(index, detail.quantity - 1),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red,
              ),
              Container(
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
                onPressed:
                    () => _updateProductQuantity(index, detail.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green,
              ),
            ],
          ),

          // Subtotal
          SizedBox(
            width: 80,
            child: Text(
              'S/ ${detail.totalPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: ThemeConfig.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Eliminar
          IconButton(
            onPressed: () => _removeProduct(index),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(withGradient: true),
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total de la Venta:',
            style: ThemeConfig.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'S/ ${_total.toStringAsFixed(2)}',
            style: ThemeConfig.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSelectorDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product, int) onProductSelected;

  const _ProductSelectorDialog({
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectorDialog> createState() => _ProductSelectorDialogState();
}

class _ProductSelectorDialogState extends State<_ProductSelectorDialog> {
  Product? _selectedProduct;
  int _quantity = 1;
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts =
          widget.products
              .where(
                (product) =>
                    product.name.toLowerCase().contains(query.toLowerCase()) ||
                    product.description.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
        child: Column(
          children: [
            Text(
              'Seleccionar Producto',
              style: ThemeConfig.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ThemeConfig.paddingMedium),

            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterProducts,
            ),
            const SizedBox(height: ThemeConfig.paddingMedium),

            // Lista de productos
            Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      'S/ ${product.salePrice.toStringAsFixed(2)} - Stock: ${product.stock}',
                    ),
                    selected: _selectedProduct?.id == product.id,
                    onTap: () => setState(() => _selectedProduct = product),
                  );
                },
              ),
            ),

            if (_selectedProduct != null) ...[
              const Divider(),
              Row(
                children: [
                  const Text('Cantidad: '),
                  IconButton(
                    onPressed:
                        _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_quantity'),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: ThemeConfig.paddingMedium),
            ],

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: ThemeConfig.paddingSmall),
                ElevatedButton(
                  onPressed:
                      _selectedProduct != null
                          ? () {
                            widget.onProductSelected(
                              _selectedProduct!,
                              _quantity,
                            );
                            Navigator.pop(context);
                          }
                          : null,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
