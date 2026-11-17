import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validation_utils.dart';
import '../../models/auth_models.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Controladores de texto
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Variables de estado
  String _userType = 'NATURAL';
  String _documentType = 'DNI';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _usernameError;
  bool _checkingUsername = false;

  // Opciones
  final List<Map<String, String>> _userTypes = [
    {'value': 'NATURAL', 'label': 'Persona Natural'},
    {'value': 'EMPRESA', 'label': 'Empresa'},
  ];

  final List<Map<String, String>> _documentTypes = [
    {'value': 'DNI', 'label': 'DNI'},
    {'value': 'RUC', 'label': 'RUC'},
    {'value': 'PASAPORTE', 'label': 'Pasaporte'},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _razonSocialController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability() async {
    if (_usernameController.text.isEmpty) return;

    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAvailable = await authProvider.checkUsernameAvailability(
      _usernameController.text,
    );

    setState(() {
      _checkingUsername = false;
      _usernameError = isAvailable ? null : 'Este usuario ya está en uso';
    });
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validar primera página
      if (_validateFirstPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateFirstPage() {
    return _nameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _documentNumberController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        ValidationUtils.validateName(_nameController.text, 'El nombre') ==
            null &&
        ValidationUtils.validateName(_lastNameController.text, 'El apellido') ==
            null &&
        ValidationUtils.validateEmail(_emailController.text) == null &&
        ValidationUtils.validateDocument(
              _documentNumberController.text,
              _documentType,
            ) ==
            null &&
        ValidationUtils.validatePhone(_phoneController.text) == null &&
        (_userType != 'EMPRESA' || _razonSocialController.text.isNotEmpty);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _usernameError != null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final registerRequest = RegisterRequest(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      razonSocial:
          _userType == 'EMPRESA' ? _razonSocialController.text.trim() : null,
      documentType: _documentType,
      documentNumber: _documentNumberController.text.trim(),
      phone: _phoneController.text.trim(),
      address:
          _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
      userType: _userType,
    );

    final success = await authProvider.register(registerRequest);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada exitosamente. Ya puedes iniciar sesión.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Error en el registro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Sistema de Importaciones D&G',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    // Indicador de progreso
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  _currentPage >= 0
                                      ? Colors.white
                                      : Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color:
                                  _currentPage >= 1
                                      ? Colors.white
                                      : Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        // Página 1: Información personal
                        _buildPersonalInfoPage(),
                        // Página 2: Información de cuenta
                        _buildAccountInfoPage(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3192),
            ),
          ),
          const SizedBox(height: 24),

          // Tipo de usuario
          const Text(
            'Tipo de Usuario',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                _userTypes.map((type) {
                  return Expanded(
                    child: RadioListTile<String>(
                      title: Text(type['label']!),
                      value: type['value']!,
                      groupValue: _userType,
                      onChanged: (value) {
                        setState(() {
                          _userType = value!;
                        });
                      },
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Nombre
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            validator:
                (value) => ValidationUtils.validateName(value, 'El nombre'),
          ),
          const SizedBox(height: 16),

          // Apellido
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Apellido *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            validator:
                (value) => ValidationUtils.validateName(value, 'El apellido'),
          ),
          const SizedBox(height: 16),

          // Razón social (solo para empresas)
          if (_userType == 'EMPRESA') ...[
            TextFormField(
              controller: _razonSocialController,
              decoration: InputDecoration(
                labelText: 'Razón Social *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E3192),
                    width: 2,
                  ),
                ),
              ),
              validator: ValidationUtils.validateRazonSocial,
            ),
            const SizedBox(height: 16),
          ],

          // Tipo de documento
          DropdownButtonFormField<String>(
            value: _documentType,
            decoration: InputDecoration(
              labelText: 'Tipo de Documento *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            items:
                _documentTypes.map((doc) {
                  return DropdownMenuItem(
                    value: doc['value'],
                    child: Text(doc['label']!),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _documentType = value!;
                _documentNumberController.clear();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Seleccione un tipo de documento';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Número de documento
          TextFormField(
            controller: _documentNumberController,
            decoration: InputDecoration(
              labelText: '$_documentType *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
            validator:
                (value) =>
                    ValidationUtils.validateDocument(value, _documentType),
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email *',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: ValidationUtils.validateEmail,
          ),
          const SizedBox(height: 16),

          // Teléfono
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Teléfono *',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: ValidationUtils.validatePhone,
          ),
          const SizedBox(height: 16),

          // Dirección
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Dirección',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Botón siguiente
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3192),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Siguiente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Enlace a login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta? '),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Inicia sesión aquí',
                  style: TextStyle(
                    color: Color(0xFF2E3192),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Cuenta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3192),
            ),
          ),
          const SizedBox(height: 24),

          // Usuario
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Usuario *',
              prefixIcon: const Icon(Icons.person),
              suffixIcon:
                  _checkingUsername
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : (_usernameError == null &&
                          _usernameController.text.isNotEmpty)
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
              errorText: _usernameError,
            ),
            validator: ValidationUtils.validateUsername,
            onChanged: (_) {
              if (_usernameController.text.length >= 3) {
                _checkUsernameAvailability();
              }
            },
          ),
          const SizedBox(height: 16),

          // Contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            validator: ValidationUtils.validatePassword,
            onChanged: (_) => setState(() {}),
          ),

          // Indicador de fortaleza de contraseña
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],

          const SizedBox(height: 16),

          // Confirmar contraseña
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E3192),
                  width: 2,
                ),
              ),
            ),
            validator:
                (value) => ValidationUtils.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
          ),
          const SizedBox(height: 32),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E3192),
                    side: const BorderSide(color: Color(0xFF2E3192)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed:
                          authProvider.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E3192),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          authProvider.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = ValidationUtils.getPasswordStrength(
      _passwordController.text,
    );
    final requirements = ValidationUtils.getPasswordRequirements(
      _passwordController.text,
    );

    Color strengthColor;
    switch (strength.color) {
      case 'weak':
        strengthColor = Colors.red;
        break;
      case 'medium':
        strengthColor = Colors.orange;
        break;
      case 'strong':
        strengthColor = Colors.green;
        break;
      case 'very-strong':
        strengthColor = Colors.green.shade700;
        break;
      default:
        strengthColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength.score / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strength.level,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (requirements.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'La contraseña debe tener:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          ...requirements.map(
            (req) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                '• $req',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
