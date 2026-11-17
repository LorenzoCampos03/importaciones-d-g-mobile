class Sale {
  final int? saleId;
  final int? clientId;
  final int? employeeId;
  final String? clientName;
  final String? employeeName;
  final DateTime? saleDate;
  final double total; // Cambiado de totalAmount a total
  final String? paymentMethod;
  final String? deliveryMethod;
  final String? deliveryAddress;
  final String status;
  final String? observations;
  final List<SaleDetail>? details;

  Sale({
    this.saleId,
    this.clientId,
    this.employeeId,
    this.clientName,
    this.employeeName,
    this.saleDate,
    this.total = 0.0,
    this.paymentMethod,
    this.deliveryMethod,
    this.deliveryAddress,
    this.status = 'Pendiente',
    this.observations,
    this.details,
  });

  bool get isActive => ['Pagado', 'Pendiente', 'Enviado'].contains(status);
  bool get isPaid => status == 'Pagado';
  bool get isPending => status == 'Pendiente';
  bool get isCancelled => status == 'Cancelado';

  // Getter para compatibilidad
  int? get id => saleId;

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      saleId: json['saleId'],
      clientId: json['clientId'],
      employeeId: json['employeeId'],
      clientName: json['clientName'],
      employeeName: json['employeeName'],
      saleDate:
          json['saleDate'] != null ? DateTime.parse(json['saleDate']) : null,
      total: (json['total'] ?? json['totalAmount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'],
      deliveryMethod: json['deliveryMethod'],
      deliveryAddress: json['deliveryAddress'],
      status: json['status'] ?? 'Pendiente',
      observations: json['observations'],
      details:
          json['details'] != null
              ? (json['details'] as List)
                  .map((detail) => SaleDetail.fromJson(detail))
                  .toList()
              : json['saleDetails'] != null
              ? (json['saleDetails'] as List)
                  .map((detail) => SaleDetail.fromJson(detail))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'clientId': clientId,
      'employeeId': employeeId,
      'clientName': clientName,
      'employeeName': employeeName,
      'saleDate': saleDate?.toIso8601String(),
      'total': total,
      'paymentMethod': paymentMethod,
      'deliveryMethod': deliveryMethod,
      'deliveryAddress': deliveryAddress,
      'status': status,
      'observations': observations,
      'details': details?.map((detail) => detail.toJson()).toList(),
    };
  }

  Sale copyWith({
    int? saleId,
    int? clientId,
    int? employeeId,
    String? clientName,
    String? employeeName,
    DateTime? saleDate,
    double? total,
    String? paymentMethod,
    String? deliveryMethod,
    String? deliveryAddress,
    String? status,
    String? observations,
    List<SaleDetail>? details,
  }) {
    return Sale(
      saleId: saleId ?? this.saleId,
      clientId: clientId ?? this.clientId,
      employeeId: employeeId ?? this.employeeId,
      clientName: clientName ?? this.clientName,
      employeeName: employeeName ?? this.employeeName,
      saleDate: saleDate ?? this.saleDate,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      details: details ?? this.details,
    );
  }
}

class SaleDetail {
  final int? detailId;
  final int? saleId;
  final int? productId;
  final String? productName;
  final String? productDescription;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SaleDetail({
    this.detailId,
    this.saleId,
    this.productId,
    this.productName,
    this.productDescription,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  // Getters para compatibilidad
  int? get id => detailId;
  double get subtotal => totalPrice;
  double get salePrice => unitPrice;

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    return SaleDetail(
      detailId: json['detailId'] ?? json['saleDetailId'],
      saleId: json['saleId'],
      productId: json['productId'],
      productName: json['productName'],
      productDescription: json['productDescription'],
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? json['subtotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detailId': detailId,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'productDescription': productDescription,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  SaleDetail copyWith({
    int? detailId,
    int? saleId,
    int? productId,
    String? productName,
    String? productDescription,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return SaleDetail(
      detailId: detailId ?? this.detailId,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

// DTOs para requests
class SaleRequest {
  final int clientId;
  final int employeeId;
  final String paymentMethod;
  final List<SaleDetailRequest> details;

  SaleRequest({
    required this.clientId,
    required this.employeeId,
    required this.paymentMethod,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'employeeId': employeeId,
      'paymentMethod': paymentMethod,
      'details': details.map((detail) => detail.toJson()).toList(),
    };
  }
}

class SaleDetailRequest {
  final int productId;
  final int quantity;
  final double unitPrice;

  SaleDetailRequest({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
