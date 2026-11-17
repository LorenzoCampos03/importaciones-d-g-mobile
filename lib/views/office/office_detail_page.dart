import 'package:flutter/material.dart';
import '../../models/office.dart';
import '../../service/office_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'office_form_page.dart';

class OfficeDetailPage extends StatefulWidget {
  final int officeId;

  const OfficeDetailPage({super.key, required this.officeId});

  @override
  State<OfficeDetailPage> createState() => _OfficeDetailPageState();
}

class _OfficeDetailPageState extends State<OfficeDetailPage> {
  Office? _office;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadOfficeDetail();
  }

  Future<void> _loadOfficeDetail() async {
    setState(() => _isLoading = true);
    try {
      final office = await OfficeService.getOfficeById(widget.officeId);
      setState(() {
        _office = office;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar detalle de oficina: $e',
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editOffice() async {
    if (_office == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OfficeFormPage(office: _office, isEdit: true),
      ),
    );

    if (result == true) {
      // Recargar los datos si se guardó exitosamente
      _loadOfficeDetail();
    }
  }

  String _getStatusText(String status) {
    return status == 'A' ? 'Activa' : 'Inactiva';
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador', 'Vendedor'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Detalle de Oficina',
          actions: [
            if (_office != null && _office!.status == 'A')
              IconButton(
                icon: const Icon(Icons.edit, color: ThemeConfig.primaryColor),
                onPressed: _editOffice,
                tooltip: 'Editar oficina',
              ),
          ],
        ),
        body:
            _isLoading
                ? const LoadingState(message: 'Cargando detalle de oficina...')
                : _office == null
                ? ErrorState(
                  title: 'Error',
                  message: 'No se pudo cargar la oficina',
                  actionText: 'Volver',
                  onAction: () => Navigator.pop(context),
                )
                : _buildOfficeDetails(),
      ),
    );
  }

  Widget _buildOfficeDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica
          InfoCard(
            title: 'Información de la Oficina',
            withGradient: true,
            items: [
              InfoItem(
                label: 'Nombre de la Oficina',
                value: _office!.officeName,
                icon: Icons.business,
              ),
              InfoItem(
                label: 'Estado',
                icon: Icons.info,
                widget: ThemeConfig.getStatusIndicator(
                  status: _office!.status,
                  text: _getStatusText(_office!.status),
                ),
              ),
              if (_office!.address != null)
                InfoItem(
                  label: 'Dirección',
                  value: _office!.address!,
                  icon: Icons.location_on,
                ),
              if (_office!.city != null)
                InfoItem(
                  label: 'Ciudad',
                  value: _office!.city!,
                  icon: Icons.location_city,
                ),
              if (_office!.phone != null)
                InfoItem(
                  label: 'Teléfono',
                  value: _office!.phone!,
                  icon: Icons.phone,
                ),
              InfoItem(
                label: 'ID de Oficina',
                value: '#${_office!.officeId}',
                icon: Icons.tag,
              ),
            ],
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Acciones disponibles
          if (_office!.status == 'A')
            InfoCard(
              title: 'Acciones',
              items: [],
              actions: [
                ActionButton(
                  text: 'Editar Oficina',
                  icon: Icons.edit,
                  onPressed: _editOffice,
                  isLoading: _isUpdatingStatus,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
