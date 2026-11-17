class ApiConfig {
  // Base URL del backend
  static const String baseUrl = 'http://localhost:8080';

  // Auth endpoints
  static const String authBasePath = '/api/v1/auth';
  static const String loginEndpoint = '$authBasePath/login';
  static const String registerEndpoint = '$authBasePath/register';
  static const String refreshTokenEndpoint = '$authBasePath/refresh';
  static const String logoutEndpoint = '$authBasePath/logout';

  // Client endpoints
  static const String clientBasePath = '/api/v1/client';
  static const String clientListEndpoint = clientBasePath;
  static const String clientCreateEndpoint = clientBasePath;
  static const String clientUpdateEndpoint = clientBasePath;
  static const String clientDeleteEndpoint = clientBasePath;

  // Employee endpoints
  static const String employeeBasePath = '/api/v1/employee';
  static const String employeeListEndpoint = employeeBasePath;
  static const String employeeCreateEndpoint = employeeBasePath;
  static const String employeeUpdateEndpoint = employeeBasePath;
  static const String employeeDeleteEndpoint = employeeBasePath;

  // Product endpoints
  static const String productBasePath = '/api/v1/products';
  static const String productListEndpoint = productBasePath;
  static const String productCreateEndpoint = productBasePath;
  static const String productUpdateEndpoint = productBasePath;
  static const String productDeleteEndpoint = '$productBasePath/delete';
  static const String productRestoreEndpoint = '$productBasePath/restore';
  static const String productByStatusEndpoint = '$productBasePath/status';

  // Purchase endpoints
  static const String purchaseBasePath = '/api/v1/purchases';
  static const String purchaseListEndpoint = purchaseBasePath;
  static const String purchaseCreateEndpoint = purchaseBasePath;
  static const String purchaseUpdateEndpoint = purchaseBasePath;
  static const String purchaseDeleteEndpoint = purchaseBasePath;
  static const String purchaseRestoreEndpoint = '$purchaseBasePath/restore';

  // Sale endpoints
  static const String saleBasePath = '/api/v1/sale';
  static const String saleListEndpoint = saleBasePath;
  static const String saleCreateEndpoint = saleBasePath;
  static const String saleUpdateEndpoint = saleBasePath;
  static const String saleDeleteEndpoint = saleBasePath;
  static const String saleRestoreEndpoint = '$saleBasePath/restore';

  // Office endpoints
  static const String officeBasePath = '/api/v1/office';
  static const String officeListEndpoint = '$officeBasePath/active';
  static const String officeAllEndpoint = '$officeBasePath/all';
  static const String officeCreateEndpoint = '$officeBasePath/create';
  static const String officeUpdateEndpoint = '$officeBasePath/update';
  static const String officeDeleteEndpoint = '$officeBasePath/logicalDelete';
  static const String officeRestoreEndpoint = '$officeBasePath/restore';

  // Catalog endpoints para dropdowns
  static const String categoriesEndpoint = '/api/v1/categories';
  static const String brandsEndpoint = '/api/v1/brands';
  static const String suppliersEndpoint = '/api/v1/suppliers';

  // Report endpoints
  static const String reportBasePath = '/api/v1/reports';
  static const String saleReportEndpoint = '$reportBasePath/sale';
  static const String productReportEndpoint = '$reportBasePath/product';
  static const String purchaseReportEndpoint = '$reportBasePath/purchase';

  // Admin endpoints
  static const String adminBasePath = '/api/v1/admin';

  // Headers por defecto
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json; charset=UTF-8',
  };

  // Construir URL completa
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
