import 'package:flutter/material.dart';
import '../../models/sale.dart';
import '../../service/sale_service.dart';
import '../../config/theme_config.dart';
import '../../widgets/common_widgets.dart';

class ClientSaleDetailPage extends StatefulWidget {
  final int saleId;

  const ClientSaleDetailPage({super.key, required this.saleId});

  @override
  State<ClientSaleDetailPage> createState() => _ClientSaleDetailPageState();
}

class _ClientSaleDetailPageState extends State<ClientSaleDetailPage> {
  Sale? _sale;
  bool _isLoading = true;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadSaleDetail();
  }

  Future<void> _loadSaleDetail() async {
    setState(() => _isLoading = true);
    try {
      final sale = await SaleService.getSaleById(widget.saleId);
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar detalle: $e');
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_sale == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: ThemeConfig.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Compra #${_sale!.saleId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(_sale!.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Fecha',
              _formatDate(_sale!.saleDate ?? DateTime.now()),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Total', 'S/ ${_sale!.total.toStringAsFixed(2)}'),
            if (_sale!.employeeName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Vendedor', _sale!.employeeName!),
            ],
            if (_sale!.paymentMethod != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Método de Pago', _sale!.paymentMethod!),
            ],
            if (_sale!.deliveryMethod != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Método de Entrega', _sale!.deliveryMethod!),
            ],
            if (_sale!.deliveryAddress != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Dirección de Entrega', _sale!.deliveryAddress!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    if (_sale == null || _sale!.details == null || _sale!.details!.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay detalles disponibles'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos Comprados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sale!.details!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final detail = _sale!.details![index];
                return _buildDetailItem(detail);
              },
            ),
            const Divider(thickness: 2),
            _buildTotalRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(SaleDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
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
                  'ID: ${detail.productId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${detail.quantity}x',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              'S/ ${detail.salePrice.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'S/ ${detail.subtotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
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
            flex: 4,
            child: Text(
              'TOTAL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              'S/ ${_sale!.total.toStringAsFixed(2)}',
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

  Widget _buildActionButtons() {
    if (_sale == null) return const SizedBox.shrink();

    List<Widget> buttons = [];

    if (_sale!.status.toLowerCase() == 'pendiente') {
      buttons.add(
        ElevatedButton.icon(
          onPressed: _isProcessingPayment ? null : _processPayment,
          icon:
              _isProcessingPayment
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.payment),
          label: Text(_isProcessingPayment ? 'Procesando...' : 'Pagar Ahora'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: buttons),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    try {
      await SaleService.updateSaleStatus(_sale!.saleId!, 'Pagado');
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Pago procesado exitosamente');
        _loadSaleDetail(); // Recargar para actualizar el estado
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al procesar pago: $e');
      }
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Compra'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSaleDetail,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _sale == null
              ? const Center(child: Text('No se pudo cargar la compra'))
              : RefreshIndicator(
                onRefresh: _loadSaleDetail,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildDetailsSection(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
    );
  }
}
