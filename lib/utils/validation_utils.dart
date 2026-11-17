class ValidationUtils {
  // Validación de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un email válido';
    }

    return null;
  }

  // Validación de contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'La contraseña debe tener al menos una mayúscula, una minúscula y un número';
    }

    return null;
  }

  // Validación de confirmación de contraseña
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirme su contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // Validación de username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El usuario es requerido';
    }

    if (value.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números y guiones bajos';
    }

    return null;
  }

  // Validación de nombres (solo letras)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'Solo se permiten letras en $fieldName';
    }

    if (value.length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }

    return null;
  }

  // Validación de teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }

    if (!RegExp(r'^9[0-9]{8}$').hasMatch(value)) {
      return 'El teléfono debe tener 9 dígitos y empezar con 9';
    }

    return null;
  }

  // Validación de DNI
  static String? validateDNI(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI es requerido';
    }

    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'El DNI debe tener 8 dígitos';
    }

    return null;
  }

  // Validación de RUC
  static String? validateRUC(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RUC es requerido';
    }

    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      return 'El RUC debe tener 11 dígitos';
    }

    return null;
  }

  // Validación de pasaporte
  static String? validatePassport(String? value) {
    if (value == null || value.isEmpty) {
      return 'El pasaporte es requerido';
    }

    if (value.length < 6 || value.length > 12) {
      return 'El pasaporte debe tener entre 6 y 12 caracteres';
    }

    return null;
  }

  // Validación de documento según tipo
  static String? validateDocument(String? value, String documentType) {
    switch (documentType) {
      case 'DNI':
        return validateDNI(value);
      case 'RUC':
        return validateRUC(value);
      case 'PASAPORTE':
        return validatePassport(value);
      default:
        return value == null || value.isEmpty
            ? 'El documento es requerido'
            : null;
    }
  }

  // Validación de razón social
  static String? validateRazonSocial(String? value) {
    if (value == null || value.isEmpty) {
      return 'La razón social es requerida';
    }

    if (value.length < 3) {
      return 'La razón social debe tener al menos 3 caracteres';
    }

    return null;
  }

  // Obtener fortaleza de contraseña
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(score: 0, level: 'Sin contraseña', color: 'weak');
    }

    int score = 0;

    // Longitud
    if (password.length >= 8) score += 25;
    if (password.length >= 12) score += 25;

    // Minúsculas
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10;

    // Mayúsculas
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 10;

    // Números
    if (RegExp(r'\d').hasMatch(password)) score += 10;

    // Caracteres especiales
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 20;

    String level;
    String color;

    if (score < 30) {
      level = 'Débil';
      color = 'weak';
    } else if (score < 60) {
      level = 'Regular';
      color = 'medium';
    } else if (score < 90) {
      level = 'Fuerte';
      color = 'strong';
    } else {
      level = 'Muy fuerte';
      color = 'very-strong';
    }

    return PasswordStrength(score: score, level: level, color: color);
  }

  // Obtener requerimientos faltantes de contraseña
  static List<String> getPasswordRequirements(String password) {
    List<String> requirements = [];

    if (password.length < 8) {
      requirements.add('Al menos 8 caracteres');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      requirements.add('Al menos una letra minúscula');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      requirements.add('Al menos una letra mayúscula');
    }

    if (!RegExp(r'\d').hasMatch(password)) {
      requirements.add('Al menos un número');
    }

    return requirements;
  }

  // Validación de nombres y apellidos (solo letras y espacios)
  static String? validateFullName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    // Solo letras, espacios y caracteres acentuados
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ\s]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName solo debe contener letras y espacios';
    }

    if (value.trim().length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 50) {
      return '$fieldName no puede tener más de 50 caracteres';
    }

    return null;
  }

  // Validación de teléfono móvil peruano (9 dígitos, comienza con 9)
  static String? validateMobilePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }

    final phone = value.trim();

    // Debe tener exactamente 9 dígitos
    if (phone.length != 9) {
      return 'El teléfono debe tener exactamente 9 dígitos';
    }

    // Solo números
    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'El teléfono solo debe contener números';
    }

    // Debe comenzar con 9 (móvil peruano)
    if (!phone.startsWith('9')) {
      return 'El teléfono móvil debe comenzar con 9';
    }

    return null;
  }

  // Validación de email mejorada
  static String? validateEmailImproved(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }

    final email = value.trim();

    // Regex para email válido
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Ingrese un email válido';
    }

    if (email.length > 254) {
      return 'El email es demasiado largo';
    }

    return null;
  }
}

class PasswordStrength {
  final int score;
  final String level;
  final String color;

  PasswordStrength({
    required this.score,
    required this.level,
    required this.color,
  });
}
