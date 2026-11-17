import 'package:flutter/material.dart';
import '../../service/client_service.dart';
import '../../models/client.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'client_detail_page.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;
  bool _showInactiveClients = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);

    try {
      final allClients = await ClientService.getAllClients();
      if (_showInactiveClients) {
        // Mostrar solo clientes inactivos
        _clients = allClients.where((client) => !client.isActive).toList();
      } else {
        // Mostrar solo clientes activos
        _clients = allClients.where((client) => client.isActive).toList();
      }
      _filterClients();
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al cargar clientes: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterClients() {
    setState(() {
      _filteredClients = _clients.where((client) {
        return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.lastName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.documentNumber.contains(_searchQuery);
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterClients();
  }

  void _toggleShowInactive() {
    setState(() => _showInactiveClients = !_showInactiveClients);
    _loadClients();
  }

  Future<void> _deactivateClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
        title: Text(
          'Desactivar Cliente',
          style: ThemeConfig.headingSmall,
        ),
        content: Text(
          '¿Está seguro que desea desactivar a ${client.fullName}?',
          style: ThemeConfig.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ActionButton(
            text: 'Desactivar',
            icon: Icons.person_off,
            type: ActionButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ClientService.deactivateClient(client.userId!);
        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Cliente desactivado correctamente',
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Error al desactivar cliente: $e',
          );
        }
      }
    }
  }

  Future<void> _restoreClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
        title: Text(
          'Restaurar Cliente',
          style: ThemeConfig.headingSmall,
        ),
        content: Text(
          '¿Está seguro que desea restaurar a ${client.fullName}?',
          style: ThemeConfig.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ActionButton(
            text: 'Restaurar',
            icon: Icons.restore,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ClientService.restoreClient(client.userId!);
        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Cliente restaurado correctamente',
          );
          _loadClients();
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Error al restaurar cliente: $e',
          );
        }
      }
    }
  }

  Future<void> _navigateToDetail(Client client) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailPage(clientId: client.userId!),
      ),
    );
    _loadClients(); // Recargar por si hubo cambios
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador', 'Vendedor'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Clientes',
          showBackButton: false,
          actions: [
            IconButton(
              icon: Icon(
                _showInactiveClients ? Icons.visibility : Icons.visibility_off,
                color: ThemeConfig.primaryColor,
              ),
              onPressed: _toggleShowInactive,
              tooltip: _showInactiveClients
                  ? 'Mostrar clientes activos'
                  : 'Mostrar clientes inactivos',
            ),
          ],
        ),
        body: Column(
          children: [
            // Barra de búsqueda y información
            _buildSearchSection(),

            // Lista de clientes
            Expanded(
              child: _isLoading
                  ? const LoadingState(message: 'Cargando clientes...')
                  : _filteredClients.isEmpty
                      ? EmptyState(
                          icon: Icons.people,
                          title: _searchQuery.isNotEmpty
                              ? 'No se encontraron clientes'
                              : _showInactiveClients
                                  ? 'No hay clientes inactivos'
                                  : 'No hay clientes registrados',
                          message: _searchQuery.isNotEmpty
                              ? 'Intenta con otros términos de búsqueda'
                              : _showInactiveClients
                                  ? 'Todos los clientes están activos'
                                  : 'Los clientes aparecerán aquí cuando se registren',
                        )
                      : _buildClientsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      decoration: const BoxDecoration(
        color: ThemeConfig.surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          SearchInput(
            controller: _searchController,
            hintText: 'Buscar por nombre, email o documento...',
            onChanged: _onSearchChanged,
            onClear: () => _onSearchChanged(''),
          ),

          const SizedBox(height: ThemeConfig.paddingSmall),

          // Información del filtro actual
          Row(
            children: [
              Icon(
                _showInactiveClients ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: ThemeConfig.textSecondaryColor,
              ),
              const SizedBox(width: ThemeConfig.paddingSmall),
              Text(
                _showInactiveClients
                    ? 'Mostrando clientes inactivos'
                    : 'Mostrando clientes activos',
                style: ThemeConfig.bodySmall,
              ),
              const Spacer(),
              Text(
                '${_filteredClients.length} ${_filteredClients.length == 1 ? 'cliente' : 'clientes'}',
                style: ThemeConfig.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    return RefreshIndicator(
      onRefresh: _loadClients,
      color: ThemeConfig.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: ThemeConfig.paddingSmall),
        itemCount: _filteredClients.length,
        itemBuilder: (context, index) {
          final client = _filteredClients[index];
          return _buildClientItem(client);
        },
      ),
    );
  }

  Widget _buildClientItem(Client client) {
    return StyledListItem(
      title: client.fullName,
      subtitle: _buildClientSubtitle(client),
      leading: Container(
        padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
        decoration: BoxDecoration(
          color: client.isActive
              ? ThemeConfig.primaryColor.withOpacity(0.1)
              : ThemeConfig.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ThemeConfig.radiusSmall),
        ),
        child: Icon(
          Icons.person,
          color: client.isActive
              ? ThemeConfig.primaryColor
              : ThemeConfig.errorColor,
          size: 24,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemeConfig.getStatusIndicator(
            status: client.isActive ? 'A' : 'I',
            text: client.isActive ? 'Activo' : 'Inactivo',
          ),
          const SizedBox(width: ThemeConfig.paddingSmall),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: ThemeConfig.textSecondaryColor),
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _navigateToDetail(client);
                  break;
                case 'deactivate':
                  _deactivateClient(client);
                  break;
                case 'restore':
                  _restoreClient(client);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('Ver detalles'),
                  ],
                ),
              ),
              if (client.isActive)
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.person_off, size: 20, color: ThemeConfig.errorColor),
                      SizedBox(width: 8),
                      Text('Desactivar', style: TextStyle(color: ThemeConfig.errorColor)),
                    ],
                  ),
                ),
              if (!client.isActive)
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore, size: 20, color: ThemeConfig.successColor),
                      SizedBox(width: 8),
                      Text('Restaurar', style: TextStyle(color: ThemeConfig.successColor)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () => _navigateToDetail(client),
    );
  }

  String _buildClientSubtitle(Client client) {
    List<String> parts = [];

    if (client.email.isNotEmpty) {
      parts.add(client.email);
    }

    if (client.documentNumber.isNotEmpty) {
      parts.add('Doc: ${client.documentNumber}');
    }

    if (client.phone != null && client.phone!.isNotEmpty) {
      parts.add('Tel: ${client.phone!}');
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'Sin información adicional';
  }
}
