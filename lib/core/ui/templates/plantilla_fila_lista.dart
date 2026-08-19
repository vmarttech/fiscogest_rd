import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// PLANTILLA FILA DE LISTA — A prueba de desbordes
/// Usa Flexible.loose + ConstrainedBox → nunca se rompe
class PlantillaFilaLista extends StatelessWidget {

  const PlantillaFilaLista({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.cantidad = 1,
    this.alSumar,
    this.alRestar,
    this.alEliminar,
  });
  final String etiqueta;
  final String valor;
  final int cantidad;
  final VoidCallback? alSumar;
  final VoidCallback? alRestar;
  final VoidCallback? alEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.vXs,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              etiqueta,
              style: AppTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Flexible(
            flex: 5,
            fit: FlexFit.loose,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: alRestar,
                  icon: const Text('-', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: AppSpacing.m),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 32, maxWidth: 48),
                  child: Text(
                    '$cantidad',
                    style: AppTypography.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                IconButton(
                  onPressed: alSumar,
                  icon: const Text('+', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Flexible(
            flex: 3,
            fit: FlexFit.loose,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: alEliminar,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
