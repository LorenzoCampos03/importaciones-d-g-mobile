import 'package:flutter/material.dart';
import '../../models/purchase.dart';
import '../../service/purchase_service.dart';
import '../../config/theme_config.dart';
import '../../widgets/common_widgets.dart';

class VendorPurchaseDetailPage extends StatefulWidget {
  final int purchaseId;

  const VendorPurchaseDetailPage({super.key, required this.purchaseId});

  @override
  State<VendorPurchaseDetailPage> createState() =>
      _VendorPurchaseDetailPageState();
}

class _VendorPurchaseDetailPageState extends State<VendorPurchaseDetailPage> {
  Purchase? _purchase;
  bool _isLoading = true;
  bool _isChangingStatus = false;

  final List<String> _purchaseStatuses = [
    'Pendiente',
    'Pagado',
    'Enviado',
    'Cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _loadPurchaseDetail();
  }

  Future<void> _loadPurchaseDetail() async {
    setState(() => _isLoading = true);
    try {
      final purchase = await PurchaseService.getPurchaseById(widget.purchaseId);
      setState(() {
        _purchase = purchase;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar detalle: $e');
      }
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_purchase == null || newStatus == _purchase!.status) return;

    setState(() => _isChangingStatus = true);
    try {
      final updatedPurchase = await PurchaseService.changeStatus(
        widget.purchaseId,
        newStatus,
      );
      setState(() {
        _purchase = updatedPurchase;
        _isChangingStatus = false;
      });
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Estado cambiado a: $newStatus');
      }
    } catch (e) {
      setState(() => _isChangingStatus = false);
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cambiar estado: $e');
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
    if (_purchase == null) return const SizedBox.shrink();

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
                  Icons.shopping_bag,
                  color: ThemeConfig.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Compra #${_purchase!.purchaseId}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(_purchase!.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Fecha', _formatDate(_purchase!.purchaseDate)),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Total',
              '\$${_purchase!.totalCost.toStringAsFixed(2)}',
            ),
            if (_purchase!.userName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Empleado', _purchase!.userName!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatusSelector() {
    if (_purchase == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambiar Estado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _purchaseStatuses.map((status) {
                    final isSelected = status == _purchase!.status;
                    final isDisabled = _isChangingStatus;

                    return GestureDetector(
                      onTap:
                          isDisabled || isSelected
                              ? null
                              : () => _changeStatus(status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _getStatusColor(status)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : _getStatusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            if (_isChangingStatus) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    if (_purchase == null || _purchase!.purchaseDetails.isEmpty) {
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
              'Detalles de la Compra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _purchase!.purchaseDetails.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final detail = _purchase!.purchaseDetails[index];
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

  Widget _buildDetailItem(PurchaseDetail detail) {
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
              '\$${detail.unitCost.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '\$${detail.calculatedTotalCost.toStringAsFixed(2)}',
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
              '\$${_purchase!.totalCost.toStringAsFixed(2)}',
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
            onPressed: _loadPurchaseDetail,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _purchase == null
              ? const Center(child: Text('No se pudo cargar la compra'))
              : RefreshIndicator(
                onRefresh: _loadPurchaseDetail,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildStatusSelector(),
                      const SizedBox(height: 16),
                      _buildDetailsSection(),
                    ],
                  ),
                ),
              ),
    );
  }
}
