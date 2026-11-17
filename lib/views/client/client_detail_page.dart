import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../service/client_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';

class ClientDetailPage extends StatefulWidget {
  final int? clientId;
  final Client? client;

  const ClientDetailPage({super.key, this.clientId, this.client})
    : assert(
        clientId != null || client != null,
        'Either clientId or client must be provided',
      );

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  Client? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    setState(() => _isLoading = true);

    try {
      if (widget.client != null) {
        // Si ya tenemos el cliente, lo usamos
        setState(() => _client = widget.client);
      } else if (widget.clientId != null) {
        // Si solo tenemos el ID, lo cargamos
        final client = await ClientService.getClientById(widget.clientId!);
        setState(() => _client = client);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar información del cliente: $e',
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleClientStatus() async {
    if (_client == null) return;

    final action = _client!.isActive ? 'desactivar' : 'activar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
        title: Text(
          '${action.toUpperCase()} Cliente',
          style: ThemeConfig.headingSmall,
        ),
        content: Text(
          '¿Está seguro que desea $action a ${_client!.fullName}?',
          style: ThemeConfig.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ActionButton(
            text: action.toUpperCase(),
            icon: _client!.isActive ? Icons.person_off : Icons.restore,
            type: _client!.isActive ? ActionButtonType.danger : ActionButtonType.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_client!.isActive) {
          await ClientService.deactivateClient(_client!.userId!);
        } else {
          await ClientService.restoreClient(_client!.userId!);
        }

        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Cliente ${_client!.isActive ? 'desactivado' : 'activado'} correctamente',
          );
          _loadClient(); // Recargar datos
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Error al $action cliente: $e',
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'No disponible';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador', 'Vendedor'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Detalle del Cliente',
        ),
        body: _isLoading
            ? const LoadingState(message: 'Cargando información del cliente...')
            : _client == null
                ? ErrorState(
                    title: 'Error',
                    message: 'No se pudo cargar la información del cliente',
                    actionText: 'Volver',
                    onAction: () => Navigator.pop(context),
                  )
                : _buildClientDetails(),
      ),
    );
  }

  Widget _buildClientDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información personal
          InfoCard(
            title: 'Información Personal',
            withGradient: true,
            items: [
              InfoItem(
                label: 'Nombre Completo',
                value: _client!.fullName,
                icon: Icons.person,
              ),
              InfoItem(
                label: 'Email',
                value: _client!.email,
                icon: Icons.email,
              ),
              InfoItem(
                label: 'Documento',
                value: '${_client!.documentType}: ${_client!.documentNumber}',
                icon: Icons.badge,
              ),
              if (_client!.phone != null && _client!.phone!.isNotEmpty)
                InfoItem(
                  label: 'Teléfono',
                  value: _client!.phone!,
                  icon: Icons.phone,
                ),
              InfoItem(
                label: 'Estado',
                icon: Icons.info,
                widget: ThemeConfig.getStatusIndicator(
                  status: _client!.isActive ? 'A' : 'I',
                  text: _client!.isActive ? 'Activo' : 'Inactivo',
                ),
              ),
            ],
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Información del sistema
          InfoCard(
            title: 'Información del Sistema',
            items: [
              InfoItem(
                label: 'ID de Usuario',
                value: '#${_client!.userId}',
                icon: Icons.tag,
              ),
              InfoItem(
                label: 'Fecha de Registro',
                value: _formatDateTime(_client!.registrationDate),
                icon: Icons.calendar_today,
              ),
              if (_client!.updateDate != null)
                InfoItem(
                  label: 'Última Actualización',
                  value: _formatDateTime(_client!.updateDate),
                  icon: Icons.update,
                ),
            ],
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Acciones disponibles
          InfoCard(
            title: 'Acciones',
            items: [],
            actions: [
              ActionButton(
                text: _client!.isActive ? 'Desactivar Cliente' : 'Activar Cliente',
                icon: _client!.isActive ? Icons.person_off : Icons.restore,
                type: _client!.isActive ? ActionButtonType.danger : ActionButtonType.primary,
                onPressed: _toggleClientStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
