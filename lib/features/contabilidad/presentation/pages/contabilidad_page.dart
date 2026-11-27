import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/i18n/servicio_idioma.dart';

/// Hub de Contabilidad (esqueleto inicial).
class ContabilidadPage extends ConsumerWidget {
  const ContabilidadPage({super.key});

  static const String routeName = 'contabilidad';
  static const String path = '/contabilidad';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: ServicioIdioma.t(context, 'Contabilidad'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_outlined, size: 64, color: AppColors.info),
            const SizedBox(height: 16),
            Text(
              ServicioIdioma.t(context, 'Contabilidad'),
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Módulo en construcción',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
