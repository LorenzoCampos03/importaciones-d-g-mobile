class CatalogOption {
  final int id;
  final String name;
  final String? description;

  CatalogOption({required this.id, required this.name, this.description});

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    // Extraer ID según el tipo de entidad
    int id = 0;
    String name = '';

    if (json.containsKey('categoryId')) {
      id = json['categoryId'] ?? 0;
      name = json['categoryName'] ?? '';
    } else if (json.containsKey('brandId')) {
      id = json['brandId'] ?? 0;
      name = json['brandName'] ?? '';
    } else if (json.containsKey('supplierId')) {
      id = json['supplierId'] ?? 0;
      name = json['supplierName'] ?? '';
    } else {
      // Fallback genérico
      id = json['id'] ?? 0;
      name = json['name'] ?? '';
    }

    return CatalogOption(id: id, name: name, description: json['description']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
