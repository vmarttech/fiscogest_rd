import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});
  static const String routeName = 'facturacion';
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Text(
          'Módulo de Facturación y NC',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
