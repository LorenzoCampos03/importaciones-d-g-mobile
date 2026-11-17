import 'package:flutter/material.dart';
import '../../models/sale.dart';
import '../../service/sale_service.dart';
import '../../service/report_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import '../../service/auth_service.dart';

class SaleDetailPage extends StatefulWidget {
  final int saleId;

  const SaleDetailPage({super.key, required this.saleId});

  @override
  State<SaleDetailPage> createState() => _SaleDetailPageState();
}

class _SaleDetailPageState extends State<SaleDetailPage> {
  Sale? _sale;
  bool _isLoading = true;
  bool _isGeneratingReport = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _loadSaleDetail();
  }

  Future<void> _getCurrentUserRole() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUserRole = user?['role'];
      });
    } catch (e) {
      // Error al obtener rol del usuario
    }
  }

  Future<void> _loadSaleDetail() async {
    setState(() => _isLoading = true);
    try {
      final sale = await SaleService.getSaleById(widget.saleId);
      setState(() {
        _sale = sale;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar detalle de venta: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador', 'Vendedor'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Detalle de Venta #${widget.saleId}',
          actions: [
            if (_sale?.status == 'Pagado' || _sale?.status == 'Enviado')
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _downloadReport,
                tooltip: 'Descargar reporte',
              ),
          ],
        ),
        body:
            _isLoading
                ? const LoadingState(message: 'Cargando detalle de venta...')
                : _sale == null
                ? const ErrorState(
                  title: 'Venta no encontrada',
                  message: 'No se pudo cargar la información de la venta.',
                  actionText: 'Volver',
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                  child: Column(
                    children: [
                      _buildSaleInfoCard(),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      _buildClientInfoCard(),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      _buildEmployeeInfoCard(),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      _buildPaymentInfoCard(),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      if (_sale!.details != null && _sale!.details!.isNotEmpty)
                        _buildProductsCard(),
                      const SizedBox(height: ThemeConfig.paddingMedium),
                      _buildActionsCard(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSaleInfoCard() {
    return InfoCard(
      title: 'Información de la Venta',
      withGradient: true,
      items: [
        InfoItem(
          label: 'ID de Venta',
          value: '#${_sale!.saleId}',
          icon: Icons.receipt_long,
        ),
        InfoItem(
          label: 'Fecha de Venta',
          value:
              _sale!.saleDate != null
                  ? _formatDate(_sale!.saleDate!)
                  : 'No especificada',
          icon: Icons.calendar_today,
        ),
        InfoItem(
          label: 'Estado',
          icon: Icons.info,
          widget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_sale!.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(_sale!.status)),
            ),
            child: Text(
              _sale!.status,
              style: TextStyle(
                color: _getStatusColor(_sale!.status),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        InfoItem(
          label: 'Total',
          icon: Icons.attach_money,
          widget: Text(
            'S/ ${_sale!.total.toStringAsFixed(2)}',
            style: ThemeConfig.headingMedium.copyWith(
              color: ThemeConfig.successColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfoCard() {
    return InfoCard(
      title: 'Información del Cliente',
      items: [
        InfoItem(
          label: 'Cliente',
          value: _sale!.clientName ?? 'No especificado',
          icon: Icons.person,
        ),
      ],
    );
  }

  Widget _buildEmployeeInfoCard() {
    return InfoCard(
      title: 'Información del Vendedor',
      items: [
        InfoItem(
          label: 'Vendedor',
          value: _sale!.employeeName ?? 'No especificado',
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildPaymentInfoCard() {
    return InfoCard(
      title: 'Información de Pago',
      items: [
        InfoItem(
          label: 'Método de Pago',
          value: _sale!.paymentMethod ?? 'No especificado',
          icon: Icons.payment,
        ),
      ],
    );
  }

  Widget _buildProductsCard() {
    return InfoCard(
      title: 'Productos de la Venta',
      items: [
        InfoItem(
          label: 'Cantidad de productos',
          value: '${_sale!.details!.length} productos',
          icon: Icons.inventory_2,
        ),
        InfoItem(
          label: 'Lista de productos',
          icon: Icons.list,
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _sale!.details!
                    .map(
                      (detail) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeConfig.backgroundColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ThemeConfig.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.productName ?? 'Producto',
                                    style: ThemeConfig.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (detail.productDescription != null)
                                    Text(
                                      detail.productDescription!,
                                      style: ThemeConfig.caption,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Precio unitario: S/ ${detail.unitPrice.toStringAsFixed(2)}',
                                    style: ThemeConfig.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ThemeConfig.primaryColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x${detail.quantity}',
                                    style: ThemeConfig.bodySmall.copyWith(
                                      color: ThemeConfig.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'S/ ${detail.totalPrice.toStringAsFixed(2)}',
                                  style: ThemeConfig.bodyMedium.copyWith(
                                    color: ThemeConfig.successColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
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
        if (_sale!.status == 'Pagado' || _sale!.status == 'Enviado')
          ActionButton(
            text: 'Descargar Reporte',
            icon: Icons.download,
            onPressed: _downloadReport,
            isLoading: _isGeneratingReport,
          ),
        ActionButton(
          text: 'Volver',
          icon: Icons.arrow_back,
          type: ActionButtonType.secondary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pagado':
        return ThemeConfig.successColor;
      case 'Pendiente':
        return ThemeConfig.warningColor;
      case 'Enviado':
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

  Future<void> _downloadReport() async {
    setState(() => _isGeneratingReport = true);
    try {
      // Simular descarga de reporte
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Reporte descargado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al descargar reporte: $e');
      }
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }
}
