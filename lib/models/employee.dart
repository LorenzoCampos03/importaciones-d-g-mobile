// models/employee.dart
class Employee {
  final int userId;
  final String username;
  final String name;
  final String lastName;
  final String documentType;
  final String documentNumber;
  final String phone;
  final String email;
  final String address;
  final String? razonSocial;
  final String? hireDate;
  final int? officeId;
  final String role;
  final String status;
  final String registrationDate;
  final String? updateDate;

  Employee({
    required this.userId,
    required this.username,
    required this.name,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    required this.email,
    required this.address,
    this.razonSocial,
    this.hireDate,
    this.officeId,
    required this.role,
    required this.status,
    required this.registrationDate,
    this.updateDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      userId: json['user_id'],
      username: json['username'],
      name: json['name'],
      lastName: json['last_name'],
      documentType: json['document_type'],
      documentNumber: json['document_number'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      razonSocial: json['razon_social'],
      hireDate: json['hire_date'],
      officeId: json['office_id'],
      role: json['role'],
      status: json['status'],
      registrationDate: json['registration_date'],
      updateDate: json['update_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'name': name,
      'last_name': lastName,
      'document_type': documentType,
      'document_number': documentNumber,
      'phone': phone,
      'email': email,
      'address': address,
      'razon_social': razonSocial,
      'hire_date': hireDate,
      'office_id': officeId,
      'role': role,
      'status': status,
      'registration_date': registrationDate,
      'update_date': updateDate,
    };
  }

  String get fullName => '$name $lastName';
  
  String get displayName => '$fullName ($username)';
}