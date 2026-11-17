import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../service/client_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';
import '../../utils/validation_utils.dart';

class ClientProfileEditPage extends StatefulWidget {
  final Client client;

  const ClientProfileEditPage({super.key, required this.client});

  @override
  State<ClientProfileEditPage> createState() => _ClientProfileEditPageState();
}

class _ClientProfileEditPageState extends State<ClientProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _documentNumberController;

  String _selectedDocumentType = 'DNI';
  final List<String> _documentTypes = ['DNI', 'RUC', 'Pasaporte', 'CE'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.client.name);
    _lastNameController = TextEditingController(text: widget.client.lastName);
    _phoneController = TextEditingController(text: widget.client.phone ?? '');
    _emailController = TextEditingController(text: widget.client.email);
    _addressController = TextEditingController(
      text: widget.client.address ?? '',
    );
    _documentNumberController = TextEditingController(
      text: widget.client.documentNumber,
    );
    _selectedDocumentType =
        widget.client.documentType.isNotEmpty
            ? widget.client.documentType
            : 'DNI';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Obtener el ID del usuario logueado
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final loggedUserId = authProvider.userInfo?['userId'];

      if (loggedUserId == null) {
        throw Exception('No se pudo obtener el ID del usuario logueado');
      }

      final updatedClient = Client(
        userId: loggedUserId, // Usar el ID del usuario logueado
        username: widget.client.username,
        role: widget.client.role,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.trim(),
        phone:
            _phoneController.text.isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address:
            _addressController.text.isEmpty
                ? null
                : _addressController.text.trim(),
        registrationDate: widget.client.registrationDate,
        updateDate: DateTime.now(),
        status: widget.client.status,
      );

      await ClientService.updateClientProfile(loggedUserId, updatedClient);

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Perfil actualizado exitosamente');
        Navigator.pop(context, updatedClient);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al actualizar perfil: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: ThemeConfig.getInputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: ThemeConfig.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con avatar
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: ThemeConfig.primaryColor,
                        child: Text(
                          widget.client.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Actualiza tu información de contacto',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Información personal
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos Personales',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Nombres',
                              hint: 'Ingresa tus nombres',
                              icon: Icons.person,
                              validator:
                                  (value) => ValidationUtils.validateFullName(
                                    value,
                                    'Nombres',
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              label: 'Apellidos',
                              hint: 'Ingresa tus apellidos',
                              icon: Icons.person_outline,
                              validator:
                                  (value) => ValidationUtils.validateFullName(
                                    value,
                                    'Apellidos',
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedDocumentType,
                              decoration: ThemeConfig.getInputDecoration(
                                labelText: 'Tipo Doc.',
                                prefixIcon: Icons.badge,
                              ),
                              items:
                                  _documentTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDocumentType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _documentNumberController,
                              label: 'Número de Documento',
                              hint: 'Ej: 12345678',
                              icon: Icons.numbers,
                              keyboardType: TextInputType.text,
                              enabled: true, // No se puede cambiar documento
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El documento es obligatorio';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Información de contacto
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de Contacto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'ejemplo@correo.com',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        enabled: true, // No se puede cambiar email
                        validator:
                            (value) =>
                                ValidationUtils.validateEmailImproved(value),
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        hint: 'Ej: 987654321',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator:
                            (value) =>
                                ValidationUtils.validateMobilePhone(value),
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _addressController,
                        label: 'Dirección',
                        hint: 'Ej: Av. Principal 123, Lima',
                        icon: Icons.location_on,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
