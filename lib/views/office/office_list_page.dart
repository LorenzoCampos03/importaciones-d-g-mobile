import 'package:flutter/material.dart';
import '../../models/office.dart';
import '../../service/office_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import 'office_form_page.dart';
import 'office_detail_page.dart';

class OfficeListPage extends StatefulWidget {
  const OfficeListPage({super.key});

  @override
  State<OfficeListPage> createState() => _OfficeListPageState();
}

class _OfficeListPageState extends State<OfficeListPage> {
  List<Office> _offices = [];
  List<Office> _filteredOffices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOffices() async {
    setState(() => _isLoading = true);

    try {
      final offices = await OfficeService.getAllOffices();
      setState(() {
        _offices = offices;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar oficinas: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Office> filtered = _offices;

    // Filtrar por estado
    if (_statusFilter != 'all') {
      filtered =
          filtered.where((office) {
            if (_statusFilter == 'active') {
              return office.status == 'A';
            } else if (_statusFilter == 'inactive') {
              return office.status == 'I';
            }
            return true;
          }).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((office) {
            return office.officeName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (office.address?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (office.city?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (office.phone?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);
          }).toList();
    }

    setState(() {
      _filteredOffices = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onStatusFilterChanged(String? newStatus) {
    setState(() {
      _statusFilter = newStatus ?? 'all';
    });
    _applyFilters();
  }

  Future<void> _navigateToDetail(Office office) async {
    if (office.officeId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfficeDetailPage(officeId: office.officeId!),
      ),
    );
  }

  Future<void> _navigateToForm({Office? office}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OfficeFormPage(office: office, isEdit: office != null),
      ),
    );

    if (result == true) {
      _loadOffices(); // Recargar la lista si se guardó correctamente
    }
  }

  Future<void> _deleteOffice(Office office) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
            ),
            title: Text(
              'Confirmar eliminación',
              style: ThemeConfig.headingSmall,
            ),
            content: Text(
              '¿Está seguro que desea desactivar la oficina "${office.officeName}"?',
              style: ThemeConfig.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ActionButton(
                text: 'Desactivar',
                icon: Icons.delete,
                type: ActionButtonType.danger,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await OfficeService.deleteOffice(office.officeId!);
        SnackBarHelper.showSuccess(context, 'Oficina desactivada exitosamente');
        _loadOffices(); // Recargar la lista
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Error al desactivar oficina: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador', 'Vendedor'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: 'Oficinas',
          showBackButton: false,
        ),
        body: Column(
          children: [
            // Barra de búsqueda y filtros
            _buildSearchAndFilters(),

            // Lista de oficinas
            Expanded(
              child:
                  _isLoading
                      ? const LoadingState(message: 'Cargando oficinas...')
                      : _filteredOffices.isEmpty
                      ? EmptyState(
                        icon: Icons.business,
                        title:
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron oficinas'
                                : 'No hay oficinas registradas',
                        message:
                            _searchQuery.isNotEmpty
                                ? 'Intenta con otros términos de búsqueda'
                                : 'Comienza agregando tu primera oficina',
                        actionText:
                            _searchQuery.isEmpty ? 'Agregar Oficina' : null,
                        onAction:
                            _searchQuery.isEmpty
                                ? () => _navigateToForm()
                                : null,
                      )
                      : _buildOfficesList(),
            ),
          ],
        ),
        floatingActionButton: CustomFAB(
          onPressed: () => _navigateToForm(),
          tooltip: 'Agregar oficina',
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
      decoration: const BoxDecoration(
        color: ThemeConfig.surfaceColor,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          SearchInput(
            controller: _searchController,
            hintText: 'Buscar oficinas...',
            onChanged: _onSearchChanged,
            onClear: () {
              _onSearchChanged('');
            },
          ),

          const SizedBox(height: ThemeConfig.paddingSmall),

          // Filtros
          Row(
            children: [
              Text('Filtrar por estado:', style: ThemeConfig.bodyMedium),
              const SizedBox(width: ThemeConfig.paddingSmall),
              Expanded(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  isExpanded: true,
                  onChanged: _onStatusFilterChanged,
                  style: ThemeConfig.bodyMedium,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todas')),
                    DropdownMenuItem(value: 'active', child: Text('Activas')),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactivas'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfficesList() {
    return RefreshIndicator(
      onRefresh: _loadOffices,
      color: ThemeConfig.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: ThemeConfig.paddingSmall),
        itemCount: _filteredOffices.length,
        itemBuilder: (context, index) {
          final office = _filteredOffices[index];
          return _buildOfficeItem(office);
        },
      ),
    );
  }

  Widget _buildOfficeItem(Office office) {
    return StyledListItem(
      title: office.officeName,
      subtitle: _buildOfficeSubtitle(office),
      leading: Container(
        padding: const EdgeInsets.all(ThemeConfig.paddingSmall),
        decoration: BoxDecoration(
          color: ThemeConfig.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ThemeConfig.radiusSmall),
        ),
        child: const Icon(
          Icons.business,
          color: ThemeConfig.primaryColor,
          size: 24,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemeConfig.getStatusIndicator(
            status: office.status,
            text: office.status == 'A' ? 'Activa' : 'Inactiva',
          ),
          const SizedBox(width: ThemeConfig.paddingSmall),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: ThemeConfig.textSecondaryColor,
            ),
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _navigateToDetail(office);
                  break;
                case 'edit':
                  _navigateToForm(office: office);
                  break;
                case 'delete':
                  _deleteOffice(office);
                  break;
              }
            },
            itemBuilder:
                (context) => [
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
                  if (office.status == 'A')
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                  if (office.status == 'A')
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: ThemeConfig.errorColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Desactivar',
                            style: TextStyle(color: ThemeConfig.errorColor),
                          ),
                        ],
                      ),
                    ),
                ],
          ),
        ],
      ),
      onTap: () => _navigateToDetail(office),
    );
  }

  String _buildOfficeSubtitle(Office office) {
    List<String> parts = [];

    if (office.city != null && office.city!.isNotEmpty) {
      parts.add(office.city!);
    }

    if (office.address != null && office.address!.isNotEmpty) {
      parts.add(office.address!);
    }

    if (office.phone != null && office.phone!.isNotEmpty) {
      parts.add('Tel: ${office.phone!}');
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'Sin información adicional';
  }
}
