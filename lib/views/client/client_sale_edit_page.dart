import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sale.dart';
import '../../models/product.dart';
import '../../service/sale_service.dart';
import '../../service/product_service.dart';
import '../../config/theme_config.dart';
import '../../widgets/common_widgets.dart';

class ClientSaleEditPage extends StatefulWidget {
  final int saleId;

  const ClientSaleEditPage({super.key, required this.saleId});

  @override
  State<ClientSaleEditPage> createState() => _ClientSaleEditPageState();
}

class _ClientSaleEditPageState extends State<ClientSaleEditPage> {
  final _formKey = GlobalKey<FormState>();

  Sale? _originalSale;
  List<Product> _availableProducts = [];
  List<SaleDetail> _saleDetails = [];

  bool _isLoading = true;
  bool _isSaving = false;

  // Controladores para campos de texto
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _deliveryMethodController =
      TextEditingController();
  final TextEditingController _deliveryAddressController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _paymentMethodController.dispose();
    _deliveryMethodController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        SaleService.getSaleById(widget.saleId),
        ProductService.getAvailableProducts(), // Usar endpoint para clientes
      ]);

      final sale = futures[0] as Sale?;
      final products = futures[1] as List<Product>;

      if (sale != null) {
        setState(() {
          _originalSale = sale;
          _availableProducts = products;
          _saleDetails = List.from(sale.details ?? []);

          // Llenar controladores
          _paymentMethodController.text = sale.paymentMethod ?? '';
          _deliveryMethodController.text = sale.deliveryMethod ?? '';
          _deliveryAddressController.text = sale.deliveryAddress ?? '';

          _isLoading = false;
        });
      } else {
        throw Exception('Venta no encontrada');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar datos: $e');
        Navigator.pop(context);
      }
    }
  }

  bool _canEdit() {
    return _originalSale?.status.toLowerCase() == 'pendiente';
  }

  void _updateQuantity(int index, int newQuantity) {
    // Validación: no permitir cantidades <= 0
    if (newQuantity <= 0) {
      SnackBarHelper.showError(
        context,
        'La cantidad debe ser mayor a 0. Use "Eliminar" para quitar el producto.',
      );
      return;
    }

    setState(() {
      final detail = _saleDetails[index];
      _saleDetails[index] = detail.copyWith(
        quantity: newQuantity,
        totalPrice: detail.unitPrice * newQuantity,
      );
    });
  }

  void _removeProduct(int index) {
    if (_saleDetails.length <= 1) {
      SnackBarHelper.showError(
        context,
        'No puedes eliminar todos los productos. Debe quedar al menos uno.',
      );
      return;
    }

    setState(() {
      _saleDetails.removeAt(index);
    });
  }

  void _addProduct() {
    if (!_canEdit()) {
      SnackBarHelper.showError(
        context,
        'Solo puedes editar compras en estado Pendiente',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildProductSelectionDialog(),
    );
  }

  Widget _buildProductSelectionDialog() {
    // Filtrar productos que no están ya en la venta
    final availableProducts =
        _availableProducts.where((product) {
          return !_saleDetails.any((detail) => detail.productId == product.id);
        }).toList();

    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child:
            availableProducts.isEmpty
                ? const Center(
                  child: Text('No hay productos disponibles para agregar'),
                )
                : ListView.builder(
                  itemCount: availableProducts.length,
                  itemBuilder: (context, index) {
                    final product = availableProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio: S/ ${product.salePrice.toStringAsFixed(2)}',
                          ),
                          Text('Stock: ${product.stock}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _addProductToSale(product);
                        },
                        child: const Text('Agregar'),
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  void _addProductToSale(Product product) {
    setState(() {
      _saleDetails.add(
        SaleDetail(
          productId: product.id!,
          productName: product.name,
          quantity: 1,
          unitPrice: product.salePrice,
          totalPrice: product.salePrice,
        ),
      );
    });
  }

  double _calculateTotal() {
    return _saleDetails.fold(
      0.0,
      (sum, detail) => sum + (detail.unitPrice * detail.quantity),
    );
  }

  Widget _buildProductsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_canEdit())
                  ElevatedButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _saleDetails.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return _buildProductItem(_saleDetails[index], index);
              },
            ),

            const Divider(thickness: 2),
            _buildTotalRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(SaleDetail detail, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Información del producto
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.productName ?? 'Producto ID: ${detail.productId}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'S/ ${detail.unitPrice.toStringAsFixed(2)} c/u',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Cantidad
          Expanded(
            child:
                _canEdit()
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:
                              detail.quantity > 1
                                  ? () => _updateQuantity(
                                    index,
                                    detail.quantity - 1,
                                  )
                                  : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 20,
                        ),
                        SizedBox(
                          width: 40,
                          child: TextFormField(
                            initialValue: detail.quantity.toString(),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              final quantity = int.tryParse(value ?? '');
                              if (quantity == null || quantity <= 0) {
                                return 'Mín: 1';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final quantity = int.tryParse(value);
                              if (quantity != null &&
                                  quantity > 0 &&
                                  quantity != detail.quantity) {
                                _updateQuantity(index, quantity);
                              }
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => _updateQuantity(index, detail.quantity + 1),
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 20,
                        ),
                      ],
                    )
                    : Text(
                      '${detail.quantity}x',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
          ),

          // Subtotal
          Expanded(
            child: Text(
              'S/ ${(detail.unitPrice * detail.quantity).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Botón eliminar
          if (_canEdit() && _saleDetails.length > 1)
            IconButton(
              onPressed: () => _removeProduct(index),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'TOTAL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              'S/ ${_calculateTotal().toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Entrega',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _paymentMethodController,
              enabled: _canEdit(),
              decoration: ThemeConfig.getInputDecoration(
                labelText: 'Método de Pago',
                hintText: 'Efectivo, Tarjeta, Transferencia...',
                prefixIcon: Icons.payment,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _deliveryMethodController,
              enabled: _canEdit(),
              decoration: ThemeConfig.getInputDecoration(
                labelText: 'Método de Entrega',
                hintText: 'Delivery, Recojo en tienda...',
                prefixIcon: Icons.local_shipping,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _deliveryAddressController,
              enabled: _canEdit(),
              maxLines: 2,
              decoration: ThemeConfig.getInputDecoration(
                labelText: 'Dirección de Entrega',
                hintText: 'Ingresa la dirección completa...',
                prefixIcon: Icons.location_on,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSale() async {
    if (!_canEdit()) {
      SnackBarHelper.showError(
        context,
        'Solo puedes editar compras en estado Pendiente',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_saleDetails.isEmpty) {
      SnackBarHelper.showError(context, 'Debe haber al menos un producto');
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Usar los métodos específicos del backend para manejar cambios en detalles
      await _updateSaleDetails();

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Compra actualizada exitosamente');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al actualizar compra: $e');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateSaleDetails() async {
    final originalDetails = _originalSale!.details ?? [];

    // Manejar cambios en cantidades de productos existentes
    for (int i = 0; i < _saleDetails.length; i++) {
      final currentDetail = _saleDetails[i];
      final originalDetail = originalDetails.firstWhere(
        (detail) => detail.productId == currentDetail.productId,
        orElse:
            () => SaleDetail(
              productId: -1,
              quantity: 0,
              unitPrice: 0,
              totalPrice: 0,
            ),
      );

      if (originalDetail.productId != -1) {
        // Producto existente - verificar si cambió la cantidad
        if (originalDetail.quantity != currentDetail.quantity) {
          await SaleService.updateSaleDetailQuantity(
            _originalSale!.saleId!,
            originalDetail.id!, // Usar el ID del detalle original
            currentDetail.quantity,
          );
        }
      } else {
        // Producto nuevo - agregar
        await SaleService.addSaleDetail(_originalSale!.saleId!, {
          'productId': currentDetail.productId,
          'quantity': currentDetail.quantity,
        });
      }
    }

    // Eliminar productos que ya no están en la lista
    for (final originalDetail in originalDetails) {
      final stillExists = _saleDetails.any(
        (detail) => detail.productId == originalDetail.productId,
      );

      if (!stillExists) {
        await SaleService.removeSaleDetail(
          _originalSale!.saleId!,
          originalDetail.id!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_canEdit() ? 'Editar Compra' : 'Ver Compra'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_canEdit())
            IconButton(
              onPressed: _isSaving ? null : _saveSale,
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!_canEdit())
                        Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Solo puedes editar compras en estado Pendiente',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      _buildProductsList(),
                      const SizedBox(height: 16),

                      _buildDeliveryInfo(),
                      const SizedBox(height: 16),

                      if (_canEdit())
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveSale,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeConfig.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child:
                                _isSaving
                                    ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Guardando...'),
                                      ],
                                    )
                                    : const Text(
                                      'Guardar Cambios',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
