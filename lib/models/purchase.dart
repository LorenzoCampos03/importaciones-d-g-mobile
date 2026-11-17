// models/purchase.dart
class Purchase {
  final int? purchaseId;
  final int employeeId;
  final int supplierId;
  final String? userName;
  final DateTime purchaseDate;
  final String status;
  final double totalCost;
  final List<PurchaseDetail> purchaseDetails;

  Purchase({
    this.purchaseId,
    required this.employeeId,
    required this.supplierId,
    this.userName,
    required this.purchaseDate,
    required this.status,
    required this.totalCost,
    required this.purchaseDetails,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchaseId'],
      employeeId: json['employeeId'],
      supplierId: json['supplierId'],
      userName: json['userName'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      status: json['status'],
      totalCost: json['totalCost'].toDouble(),
      purchaseDetails:
          (json['purchaseDetails'] as List)
              .map((detail) => PurchaseDetail.fromJson(detail))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'employeeId': employeeId,
      'supplierId': supplierId,
      'userName': userName,
      'purchaseDate': purchaseDate.toIso8601String().split('T')[0],
      'status': status,
      'totalCost': totalCost,
      'purchaseDetails':
          purchaseDetails.map((detail) => detail.toJson()).toList(),
    };
  }

  Purchase copyWith({
    int? purchaseId,
    int? employeeId,
    int? supplierId,
    String? userName,
    DateTime? purchaseDate,
    String? status,
    double? totalCost,
    List<PurchaseDetail>? purchaseDetails,
  }) {
    return Purchase(
      purchaseId: purchaseId ?? this.purchaseId,
      employeeId: employeeId ?? this.employeeId,
      supplierId: supplierId ?? this.supplierId,
      userName: userName ?? this.userName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
      totalCost: totalCost ?? this.totalCost,
      purchaseDetails: purchaseDetails ?? this.purchaseDetails,
    );
  }

  
}

// models/purchase_detail.dart
class PurchaseDetail {
  final int productId;
  final int quantity;
  final double unitCost;
  final double? totalCost;
  final String? productName;

  PurchaseDetail({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    this.totalCost,
    this.productName,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      productId: json['productId'],
      quantity: json['quantity'],
      unitCost: json['unitCost'].toDouble(),
      totalCost: json['totalCost']?.toDouble(),
      productName: json['productName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalCost': totalCost ?? (unitCost * quantity),
      'productName': productName,
    };
  }

  PurchaseDetail copyWith({
    int? productId,
    int? quantity,
    double? unitCost,
    double? totalCost,
    String? productName,
  }) {
    return PurchaseDetail(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      productName: productName ?? this.productName,
    );
  }

  double get calculatedTotalCost => totalCost ?? (unitCost * quantity);
}
