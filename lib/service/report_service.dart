import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// Importar HTML solo para web
import 'dart:html' as html show Blob, Url, document, AnchorElement;
import '../config/api_config.dart';
import 'api_service.dart';

class ReportService {
  /// Generar reporte PDF de una venta
  static Future<Uint8List> generateSaleReport(int saleId) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.saleReportEndpoint}/$saleId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al generar reporte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al generar reporte: $e');
    }
  }

  /// Generar reporte PDF de productos
  static Future<Uint8List> generateProductReport() async {
    try {
      final response = await ApiService.get(
        ApiConfig.productReportEndpoint,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al generar reporte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al generar reporte: $e');
    }
  }

  /// Generar reporte PDF de una compra
  static Future<Uint8List> generatePurchaseReport(int purchaseId) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.purchaseReportEndpoint}/$purchaseId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al generar reporte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al generar reporte: $e');
    }
  }

  /// Descargar archivo PDF en plataformas web
  static void downloadPdfWeb(Uint8List pdfBytes, String filename) {
    if (kIsWeb) {
      // Para web, crear un enlace de descarga
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor =
          html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = filename;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      throw UnsupportedError(
        'Esta función solo está disponible en la web. Use path_provider para guardar archivos en móviles.',
      );
    }
  }
}
