class Office {
  final int? officeId;
  final String officeName;
  final String? address;
  final String? city;
  final String? phone;
  final String status;

  Office({
    this.officeId,
    required this.officeName,
    this.address,
    this.city,
    this.phone,
    this.status = 'A',
  });

  bool get isActive => status == 'A';

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      officeId: json['office_id'],
      officeName: json['office_name'] ?? '',
      address: json['address'],
      city: json['city'],
      phone: json['phone'],
      status: json['status'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'office_id': officeId,
      'office_name': officeName,
      'address': address,
      'city': city,
      'phone': phone,
      'status': status,
    };
  }

  Office copyWith({
    int? officeId,
    String? officeName,
    String? address,
    String? city,
    String? phone,
    String? status,
  }) {
    return Office(
      officeId: officeId ?? this.officeId,
      officeName: officeName ?? this.officeName,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }
}
