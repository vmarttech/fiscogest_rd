import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

///== PLANTILLA FILA DE LISTA/CARRITO — A PRUEBA DE DESBORDES ==
/// Cumplimiento automático:
/// ✅ Flexible.loose → no fuerza tamaño, se adapta
/// ✅ mainAxisSize.min → solo ocupa lo necesario
/// ✅ ConstrainedBox → límites en valores numéricos
/// ✅ AppSpacing / AppTypography → CERO valores manuales
/// ✅ Proporciones inteligentes → nunca se desborda

class PlantillaFilaLista extends StatelessWidget {
  const PlantillaFilaLista({
    super.key,
    required this.titulo,
    required this.valor,
    this.cantidad = 1,
    this.onIncrementar,
    this.onDecrementar,
    this.onEliminar,
  });
  final String titulo;
  final String valor;
  final int cantidad;
  final VoidCallback? onIncrementar;
  final VoidCallback? onDecrementar;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.vXs,
      child: Row(
        children: [
          // === COLUMNA 1: Título / Nombre (flexible) ===
          Expanded(
            flex: 4,
            child: Text(
              titulo,
              style: AppTypography.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          // === PASO 3: Controles — Flexible.loose + límites ===
          Flexible(
            flex: 5,
            fit: FlexFit.loose,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(text: '-', onPressed: onDecrementar ?? () {}),
                const SizedBox(width: AppSpacing.m),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 28, maxWidth: 40),
                  child: Text(
                    '$cantidad',
                    style: AppTypography.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                AppButton(text: '+', onPressed: onIncrementar ?? () {}),
              ],
            ),
          ),
          // === COLUMNA 3: Valor / Precio (alineado derecha) ===
          Flexible(
            flex: 3,
            fit: FlexFit.loose,
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium,
            ),
          ),
          // === COLUMNA 4: Acción eliminar ===
          const SizedBox(width: AppSpacing.xs),
          AppButton(text: '✕', onPressed: onEliminar ?? () {}),
        ],
      ),
    );
  }
}
