import 'package:flutter/material.dart';

class DashboardStats {
  final int totalClients;
  final int activeClients;
  final int totalProducts;
  final int activeProducts;
  final int totalSales;
  final double totalSalesAmount;
  final int totalPurchases;
  final double totalPurchasesAmount;
  final int totalOffices;
  final int activeOffices;

  DashboardStats({
    required this.totalClients,
    required this.activeClients,
    required this.totalProducts,
    required this.activeProducts,
    required this.totalSales,
    required this.totalSalesAmount,
    required this.totalPurchases,
    required this.totalPurchasesAmount,
    required this.totalOffices,
    required this.activeOffices,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalClients: json['totalClients'] ?? 0,
      activeClients: json['activeClients'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      totalSales: json['totalSales'] ?? 0,
      totalSalesAmount: (json['totalSalesAmount'] ?? 0.0).toDouble(),
      totalPurchases: json['totalPurchases'] ?? 0,
      totalPurchasesAmount: (json['totalPurchasesAmount'] ?? 0.0).toDouble(),
      totalOffices: json['totalOffices'] ?? 0,
      activeOffices: json['activeOffices'] ?? 0,
    );
  }
}

class StatCard {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class RecentActivity {
  final String title;
  final String description;
  final DateTime date;
  final String type;

  RecentActivity({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}
