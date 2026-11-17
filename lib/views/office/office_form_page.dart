import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/office.dart';
import '../../service/office_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';

class OfficeFormPage extends StatefulWidget {
  final Office? office;
  final bool isEdit;

  const OfficeFormPage({super.key, this.office, this.isEdit = false});

  @override
  State<OfficeFormPage> createState() => _OfficeFormPageState();
}

class _OfficeFormPageState extends State<OfficeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _officeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.office != null) {
      // Verificar si la oficina está inactiva
      if (widget.office!.status == 'I') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarHelper.showWarning(
            context,
            'No se pueden editar oficinas inactivas',
          );
          Navigator.pop(context);
        });
        return;
      }
      _loadOfficeData();
    }
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadOfficeData() {
    final office = widget.office!;
    _officeNameController.text = office.officeName;
    _addressController.text = office.address ?? '';
    _cityController.text = office.city ?? '';
    _phoneController.text = office.phone ?? '';
  }

  Future<void> _saveOffice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final office = Office(
        officeId: widget.isEdit ? widget.office!.officeId : null,
        officeName: _officeNameController.text.trim(),
        address:
            _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
        city:
            _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
        phone:
            _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
        status: widget.isEdit ? widget.office!.status : 'A',
      );

      if (widget.isEdit) {
        await OfficeService.updateOffice(office);
        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Oficina actualizada exitosamente',
          );
        }
      } else {
        await OfficeService.createOffice(office);
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Oficina creada exitosamente');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al ${widget.isEdit ? 'actualizar' : 'crear'} oficina: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateOfficeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la oficina es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 5) {
      return 'La dirección debe tener al menos 5 caracteres';
    }
    if (value != null && value.trim().length > 200) {
      return 'La dirección no puede exceder 200 caracteres';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
      return 'La ciudad debe tener al menos 2 caracteres';
    }
    if (value != null && value.trim().length > 50) {
      return 'La ciudad no puede exceder 50 caracteres';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final phone = value.trim();

      // Debe tener exactamente 9 dígitos
      if (phone.length != 9) {
        return 'El teléfono debe tener exactamente 9 dígitos';
      }

      // Validar usando la expresión regular de la base de datos
      // CHECK (REGEXP_LIKE(phone, '^(9[0-9]{8}|01[0-9]{7})$'))
      // Móvil: comienza con 9 (9[0-9]{8})
      // Fijo: comienza con 01 (01[0-9]{7})
      if (!RegExp(r'^(9[0-9]{8}|01[0-9]{7})$').hasMatch(phone)) {
        return 'Formato inválido:\n• Móvil: 9 dígitos comenzando con 9\n• Fijo: 9 dígitos comenzando con 01';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: widget.isEdit ? 'Editar Oficina' : 'Nueva Oficina',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica
                InfoCard(
                  title: 'Información de la Oficina',
                  withGradient: true,
                  items: [],
                ),

                const SizedBox(height: ThemeConfig.paddingMedium),

                // Campos del formulario
                _buildFormFields(),

                const SizedBox(height: ThemeConfig.paddingLarge),

                // Botones de acción
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos Requeridos', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Nombre de la oficina (requerido)
          TextFormField(
            controller: _officeNameController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Nombre de la Oficina *',
              prefixIcon: Icons.business,
              hintText: 'Ej: Oficina Central',
            ),
            validator: _validateOfficeName,
            textInputAction: TextInputAction.next,
            maxLength: 100,
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          Text(
            'Datos Opcionales',
            style: ThemeConfig.headingSmall.copyWith(
              color: ThemeConfig.textSecondaryColor,
            ),
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Dirección (opcional)
          TextFormField(
            controller: _addressController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icons.location_on,
              hintText: 'Ej: Av. Principal 123',
            ),
            validator: _validateAddress,
            textInputAction: TextInputAction.next,
            maxLength: 200,
            maxLines: 2,
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Ciudad (opcional)
          TextFormField(
            controller: _cityController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Ciudad',
              prefixIcon: Icons.location_city,
              hintText: 'Ej: Lima',
            ),
            validator: _validateCity,
            textInputAction: TextInputAction.next,
            maxLength: 50,
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Teléfono (opcional)
          TextFormField(
            controller: _phoneController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icons.phone,
              hintText: '999999999 o 017654321',
            ),
            validator: _validatePhone,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            maxLength: 9,
          ),

          const SizedBox(height: ThemeConfig.paddingSmall),

          Text('* Campos requeridos', style: ThemeConfig.caption),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acciones', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          Row(
            children: [
              Expanded(
                child: ActionButton(
                  text: 'Cancelar',
                  icon: Icons.cancel,
                  type: ActionButtonType.secondary,
                  onPressed: _isLoading ? () {} : () => Navigator.pop(context),
                ),
              ),

              const SizedBox(width: ThemeConfig.paddingMedium),

              Expanded(
                child: ActionButton(
                  text: widget.isEdit ? 'Actualizar' : 'Crear Oficina',
                  icon: widget.isEdit ? Icons.update : Icons.save,
                  onPressed: _saveOffice,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
