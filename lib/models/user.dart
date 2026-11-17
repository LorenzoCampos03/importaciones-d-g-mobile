class User {
  final int? id;
  final String username;
  final String email;
  final String name;
  final String lastName;
  final String? razonSocial;
  final String documentType;
  final String documentNumber;
  final String phone;
  final String? address;
  final String userType;
  final String role;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.lastName,
    this.razonSocial,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    this.address,
    required this.userType,
    required this.role,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      name: json['name'],
      lastName: json['lastName'],
      razonSocial: json['razonSocial'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      phone: json['phone'],
      address: json['address'],
      userType: json['userType'],
      role: json['role'],
      active: json['active'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'lastName': lastName,
      'razonSocial': razonSocial,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'phone': phone,
      'address': address,
      'userType': userType,
      'role': role,
      'active': active,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '$name $lastName';
}
