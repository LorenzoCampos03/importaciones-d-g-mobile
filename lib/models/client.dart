// lib/models/client.dart
class Client {
  final int? userId;
  final String? username;
  final String? password;
  final String? role;
  final String name;
  final String lastName;
  final String documentType;
  final String documentNumber;
  final String? phone;
  final String email;
  final String? address;
  final DateTime? registrationDate;
  final DateTime? updateDate;
  final String? razonSocial;
  final DateTime? hireDate;
  final int? officeId;
  final String status;

  Client({
    this.userId,
    this.username,
    this.password,
    this.role,
    required this.name,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    this.phone,
    required this.email,
    this.address,
    this.registrationDate,
    this.updateDate,
    this.razonSocial,
    this.hireDate,
    this.officeId,
    this.status = 'A',
  });

  String get fullName => '$name $lastName';

  String get initials =>
      '${name.isNotEmpty ? name[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

  bool get isActive => status == 'A';

  // Getter para compatibilidad
  int? get id => userId;

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      userId: json['user_id'],
      username: json['username'],
      password: json['password'],
      role: json['role'],
      name: json['name'] ?? '',
      lastName: json['last_name'] ?? '',
      documentType: json['document_type'] ?? '',
      documentNumber: json['document_number'] ?? '',
      phone: json['phone'],
      email: json['email'] ?? '',
      address: json['address'],
      registrationDate:
          json['registration_date'] != null
              ? DateTime.parse(json['registration_date'])
              : null,
      updateDate:
          json['update_date'] != null
              ? DateTime.parse(json['update_date'])
              : null,
      razonSocial: json['razon_social'],
      hireDate:
          json['hire_date'] != null ? DateTime.parse(json['hire_date']) : null,
      officeId: json['office_id'],
      status: json['status'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'password': password,
      'role': role,
      'name': name,
      'last_name': lastName,
      'document_type': documentType,
      'document_number': documentNumber,
      'phone': phone,
      'email': email,
      'address': address,
      'registration_date': registrationDate?.toIso8601String().split('T')[0],
      'update_date': updateDate?.toIso8601String().split('T')[0],
      'razon_social': razonSocial,
      'hire_date': hireDate?.toIso8601String().split('T')[0],
      'office_id': officeId,
      'status': status,
    };
  }

  Client copyWith({
    int? userId,
    String? username,
    String? password,
    String? role,
    String? name,
    String? lastName,
    String? documentType,
    String? documentNumber,
    String? phone,
    String? email,
    String? address,
    DateTime? registrationDate,
    DateTime? updateDate,
    String? razonSocial,
    DateTime? hireDate,
    int? officeId,
    String? status,
  }) {
    return Client(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      registrationDate: registrationDate ?? this.registrationDate,
      updateDate: updateDate ?? this.updateDate,
      razonSocial: razonSocial ?? this.razonSocial,
      hireDate: hireDate ?? this.hireDate,
      officeId: officeId ?? this.officeId,
      status: status ?? this.status,
    );
  }
}
