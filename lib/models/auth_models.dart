class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

class LoginResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? refreshToken;
  final int? userId;
  final String? username;
  final String? role;
  final String? email;
  final String? name;
  final String? lastName;

  LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.refreshToken,
    this.userId,
    this.username,
    this.role,
    this.email,
    this.name,
    this.lastName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      refreshToken: json['refreshToken'],
      userId: json['userId']?.toInt(),
      username: json['username'],
      role: json['role'],
      email: json['email'],
      name: json['name'],
      lastName: json['lastName'],
    );
  }
}

class RegisterRequest {
  final String username;
  final String password;
  final String email;
  final String name;
  final String lastName;
  final String? razonSocial;
  final String documentType;
  final String documentNumber;
  final String phone;
  final String? address;
  final String userType;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.name,
    required this.lastName,
    this.razonSocial,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    this.address,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'name': name,
      'lastName': lastName,
      'razonSocial': razonSocial,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'phone': phone,
      'address': address,
      'userType': userType,
    };
  }
}

class RegisterResponse {
  final String message;
  final bool success;

  RegisterResponse({required this.message, required this.success});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] ?? 'Usuario registrado exitosamente',
      success: json['success'] ?? true,
    );
  }
}
