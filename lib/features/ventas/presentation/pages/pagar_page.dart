import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class PagarPage extends ConsumerStatefulWidget {
  const PagarPage({super.key});
  static const routeName = 'pagar';

  @override
  ConsumerState<PagarPage> createState() => _PagarPageState();
}

class _PagarPageState extends ConsumerState<PagarPage> {
  @override
  Widget build(BuildContext context) {
    
    return const AppScaffold(
      backgroundColor: AppColors.pageBackground,
      // design system

      title: 'Cuentas por Pagar',
      body: SingleChildScrollView(
        padding: AppLayout.pantallaPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión de Pagos y Compromisos', style: AppTypography.h4),
            SizedBox(height: 16),
            Text(
              'Pantalla en desarrollo. Aquí se mostrarán las cuentas por pagar a proveedores.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
