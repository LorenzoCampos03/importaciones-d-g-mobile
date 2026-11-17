import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'product_form_page.dart';
import '../../models/product.dart';
import '../../service/product_service.dart';

class ProductDetailPage extends StatefulWidget {
  final int? productId;
  final Product? product;

  const ProductDetailPage({super.key, this.productId, this.product})
    : assert(
        productId != null || product != null,
        'Either productId or product must be provided',
      );

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.product != null) {
        // Si ya tenemos el producto, lo usamos
        setState(() {
          _product = widget.product;
        });
      } else if (widget.productId != null) {
        // Si solo tenemos el ID, lo cargamos
        final product = await ProductService.getProductById(widget.productId!);
        setState(() {
          _product = product;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el producto: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleProductStatus() async {
    if (_product == null) return;

    try {
      final updatedProduct = _product!.copyWith(
        status: _product!.status == 'A' ? 'I' : 'A',
      );
      await ProductService.updateProduct(updatedProduct);
      await _loadProduct();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _product!.status == 'A'
                  ? 'Producto desactivado correctamente'
                  : 'Producto activado correctamente',
            ),
            backgroundColor: const Color(0xFF2E3192),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        backgroundColor: const Color(0xFF2E3192),
        foregroundColor: Colors.white,
        actions: [
          if (_product != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) => ProductFormPage(product: _product),
                      ),
                    )
                    .then((_) => _loadProduct());
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle_status') {
                  _showToggleStatusDialog();
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            _product!.status == 'A'
                                ? Icons.block
                                : Icons.check_circle,
                            color:
                                _product!.status == 'A'
                                    ? Colors.red
                                    : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _product!.status == 'A' ? 'Desactivar' : 'Activar',
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProduct,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
              : _product == null
              ? const Center(child: Text('Producto no encontrado'))
              : RefreshIndicator(
                onRefresh: _loadProduct,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductHeader(),
                      const SizedBox(height: 24),
                      _buildProductDetails(),
                      const SizedBox(height: 24),
                      _buildProductStats(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProductHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3192).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    size: 40,
                    color: Color(0xFF2E3192),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3192),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusChip(_product!.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(_product!.description, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Producto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID', _product!.productId.toString()),
            _buildDetailRow(
              'Categoría',
              _product!.categoryName ?? 'Sin categoría',
            ),
            _buildDetailRow('Marca', _product!.brandName ?? 'Sin marca'),
            _buildDetailRow(
              'Proveedor',
              _product!.supplierName ?? 'Sin proveedor',
            ),
            _buildDetailRow(
              'Precio Unitario',
              'S/ ${_product!.unitPrice.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Stock', _product!.stock.toString()),
            _buildDetailRow(
              'Estado',
              _product!.status == 'A' ? 'Activo' : 'Inactivo',
            ),
            if (_product!.registrationDate != null)
              _buildDetailRow(
                'Fecha de Registro',
                _product!.registrationDate != null
                    ? _formatDate(_product!.registrationDate!)
                    : 'No disponible',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Precio Unitario',
                    'S/ ${_product!.unitPrice.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Stock',
                    _product!.stock.toString(),
                    Icons.inventory,
                    _product!.stock > 10 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isActive = status == 'A';
    final color = isActive ? Colors.green : Colors.red;
    final text = isActive ? 'ACTIVO' : 'INACTIVO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showToggleStatusDialog() {
    final isActive = _product!.status == 'A';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isActive ? 'Desactivar Producto' : 'Activar Producto'),
          content: Text(
            isActive
                ? '¿Está seguro de que desea desactivar el producto "${_product!.name}"?'
                : '¿Está seguro de que desea activar el producto "${_product!.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleProductStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isActive ? 'Desactivar' : 'Activar'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }
}
