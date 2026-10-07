import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class PlanRequeridoAlmacenes extends StatelessWidget {
  const PlanRequeridoAlmacenes({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: titulo,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Módulo de planes superiores',
                    style: AppTypography.h3,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Almacenes y transferencias entre sucursales están '
                    'disponibles en los planes Profesional y Empresa.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
