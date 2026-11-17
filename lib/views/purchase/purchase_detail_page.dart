import 'package:flutter/material.dart';
import '../../models/purchase.dart';
import '../../service/purchase_service.dart';
import '../../service/auth_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';

class PurchaseDetailPage extends StatefulWidget {
  final int purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  Purchase? _purchase;
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  bool _isUpdatingStatus = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _loadPurchaseDetail();
  }

  Future<void> _getCurrentUserRole() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUserRole = user?['role'];
    });
  }

  Future<void> _loadPurchaseDetail() async {
    setState(() => _isLoading = true);
    try {
      final purchase = await PurchaseService.getPurchaseById(widget.purchaseId);
      setState(() {
        _purchase = purchase;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar detalle de compra: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Detalle de Compra #${widget.purchaseId}',
          actions: [
            if (_purchase != null && _purchase!.status == 'Recibido')
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _isGeneratingReport ? null : _downloadReport,
                tooltip: 'Descargar reporte',
              ),
          ],
        ),
        body:
            _isLoading
                ? const LoadingState(message: 'Cargando detalle de compra...')
                : _purchase == null
                ? const ErrorState(
                  title: 'Compra no encontrada',
                  message: 'No se pudo cargar la información de la compra.',
                  actionText: 'Volver',
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información principal
                      _buildMainInfoCard(),

                      const SizedBox(height: ThemeConfig.paddingMedium),

                      // Información del proveedor
                      _buildSupplierInfoCard(),

                      const SizedBox(height: ThemeConfig.paddingMedium),

                      // Información de la compra
                      _buildPurchaseInfoCard(),

                      const SizedBox(height: ThemeConfig.paddingMedium),

                      // Detalles de productos
                      if (_purchase!.purchaseDetails.isNotEmpty)
                        _buildProductsCard(),

                      if (_purchase!.purchaseDetails.isNotEmpty)
                        const SizedBox(height: ThemeConfig.paddingMedium),

                      // Acciones
                      _buildActionsCard(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return InfoCard(
      title: 'Información Principal',
      withGradient: true,
      items: [
        InfoItem(
          label: 'ID de Compra',
          value: '#${_purchase!.purchaseId}',
          icon: Icons.shopping_bag,
        ),
        InfoItem(
          label: 'Estado',
          icon: Icons.info,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(_purchase!.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(_purchase!.status),
                width: 1.5,
              ),
            ),
            child: Text(
              _purchase!.status,
              style: TextStyle(
                color: _getStatusColor(_purchase!.status),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        InfoItem(
          label: 'Total',
          value: 'S/ ${_purchase!.totalCost.toStringAsFixed(2)}',
          icon: Icons.attach_money,
        ),
        InfoItem(
          label: 'Fecha de Compra',
          value: _formatDate(_purchase!.purchaseDate),
          icon: Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildSupplierInfoCard() {
    return InfoCard(
      title: 'Información del Proveedor',
      items: [
        InfoItem(
          label: 'ID Proveedor',
          value: _purchase!.supplierId.toString(),
          icon: Icons.business,
        ),
      ],
    );
  }

  Widget _buildPurchaseInfoCard() {
    return InfoCard(
      title: 'Información de la Compra',
      items: [
        InfoItem(
          label: 'ID Empleado',
          value: _purchase!.employeeId.toString(),
          icon: Icons.person,
        ),
        if (_purchase!.userName != null)
          InfoItem(
            label: 'Usuario',
            value: _purchase!.userName!,
            icon: Icons.account_circle,
          ),
      ],
    );
  }

  Widget _buildProductsCard() {
    return InfoCard(
      title: 'Productos Comprados (${_purchase!.purchaseDetails.length})',
      items: [
        InfoItem(
          label: 'Lista de Productos',
          icon: Icons.inventory,
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _purchase!.purchaseDetails.map((detail) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeConfig.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ThemeConfig.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.productName ??
                                    'Producto #${detail.productId}',
                                style: ThemeConfig.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'ID Producto: ${detail.productId}',
                                style: ThemeConfig.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Cantidad: ${detail.quantity}',
                              style: ThemeConfig.caption,
                            ),
                            Text(
                              'Costo Unit: S/ ${detail.unitCost.toStringAsFixed(2)}',
                              style: ThemeConfig.bodySmall,
                            ),
                            Text(
                              'Total: S/ ${detail.calculatedTotalCost.toStringAsFixed(2)}',
                              style: ThemeConfig.bodySmall.copyWith(
                                color: ThemeConfig.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return InfoCard(
      title: 'Acciones',
      items: [],
      actions: [
        if (_canDownloadReport())
          ActionButton(
            text: 'Descargar Reporte',
            icon: Icons.download,
            onPressed: _downloadReport,
            isLoading: _isGeneratingReport,
          ),
        if (_canUpdateStatus())
          ActionButton(
            text: _getNextStatusText(),
            icon: _getNextStatusIcon(),
            onPressed: _updateStatus,
            isLoading: _isUpdatingStatus,
            type: ActionButtonType.secondary,
          ),
        ActionButton(
          text: 'Volver',
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          type: ActionButtonType.secondary,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Recibido':
        return ThemeConfig.successColor;
      case 'Pendiente':
        return ThemeConfig.warningColor;
      case 'En Tránsito':
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

  bool _canDownloadReport() {
    return _purchase!.status == 'Recibido';
  }

  bool _canUpdateStatus() {
    return _currentUserRole == 'Administrador' &&
        _purchase!.status != 'Cancelado';
  }

  String _getNextStatusText() {
    switch (_purchase!.status) {
      case 'Pendiente':
        return 'Marcar en Tránsito';
      case 'En Tránsito':
        return 'Marcar como Recibido';
      default:
        return 'Actualizar Estado';
    }
  }

  IconData _getNextStatusIcon() {
    switch (_purchase!.status) {
      case 'Pendiente':
        return Icons.local_shipping;
      case 'En Tránsito':
        return Icons.check_circle;
      default:
        return Icons.update;
    }
  }

  Future<void> _downloadReport() async {
    setState(() => _isGeneratingReport = true);

    try {
      // await ReportService.downloadPurchaseReport(_purchase!.purchaseId!);
      // Simulación ya que el método no existe aún
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Reporte descargado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al descargar reporte: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
      }
    }
  }

  Future<void> _updateStatus() async {
    String newStatus;
    switch (_purchase!.status) {
      case 'Pendiente':
        newStatus = 'En Tránsito';
        break;
      case 'En Tránsito':
        newStatus = 'Recibido';
        break;
      default:
        return;
    }

    // Confirmar acción
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Acción'),
            content: Text(
              '¿Estás seguro de marcar esta compra como "$newStatus"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdatingStatus = true);

    try {
      // await PurchaseService.updatePurchaseStatus(_purchase!.purchaseId!, newStatus);
      // Simulación ya que el método no existe aún
      await Future.delayed(const Duration(seconds: 1));

      // Recargar los datos
      await _loadPurchaseDetail();

      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Estado actualizado a "$newStatus" exitosamente',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al actualizar estado: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }
}
