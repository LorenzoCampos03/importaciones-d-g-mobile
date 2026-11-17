class Product {
  final int? productId;
  final String name;
  final String description;
  final double unitPrice;
  final int stock;
  final String status; // 'A' = Active, 'I' = Inactive
  final String? registrationDate;

  // Campos para mostrar los nombres
  final String categoryName;
  final String supplierName;
  final String brandName;

  // Campos para los IDs de las relaciones
  final int? categoryId;
  final int? supplierId;
  final int? brandId;

  Product({
    this.productId,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.stock,
    this.status = 'A',
    this.registrationDate,
    required this.categoryName,
    required this.supplierName,
    required this.brandName,
    this.categoryId,
    this.supplierId,
    this.brandId,
  });

  bool get isActive => status == 'A';
  bool get isAvailable => isActive && stock > 0;

  // Getters para compatibilidad
  int? get id => productId;
  double get salePrice => unitPrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      status: json['status'] ?? 'A',
      registrationDate: json['registrationDate'],
      categoryName: json['categoryName'] ?? '',
      supplierName: json['supplierName'] ?? '',
      brandName: json['brandName'] ?? '',
      categoryId: json['categoryId'],
      supplierId: json['supplierId'],
      brandId: json['brandId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'unitPrice': unitPrice,
      'stock': stock,
      'status': status,
      'categoryName': categoryName,
      'supplierName': supplierName,
      'brandName': brandName,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'brandId': brandId,
    };
  }

  Product copyWith({
    int? productId,
    String? name,
    String? description,
    double? unitPrice,
    int? stock,
    String? status,
    String? registrationDate,
    String? categoryName,
    String? supplierName,
    String? brandName,
    int? categoryId,
    int? supplierId,
    int? brandId,
  }) {
    return Product(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      registrationDate: registrationDate ?? this.registrationDate,
      categoryName: categoryName ?? this.categoryName,
      supplierName: supplierName ?? this.supplierName,
      brandName: brandName ?? this.brandName,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      brandId: brandId ?? this.brandId,
    );
  }
}
