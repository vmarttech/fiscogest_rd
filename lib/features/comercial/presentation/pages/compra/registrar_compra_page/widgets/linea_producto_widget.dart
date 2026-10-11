import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/tipos_linea.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';

class LineaProductoWidget extends StatelessWidget {
  const LineaProductoWidget({
    super.key,
    required this.index,
    required this.linea,
    required this.ctrl,
    required this.onEliminar,
    required this.onSeleccionarProducto,
    required this.onCantidadChanged,
    required this.onCostoChanged,
    required this.onFleteChanged,
    required this.onSeguroChanged,
    required this.onArancelesChanged,
    required this.onGastosChanged,
    required this.onDescuentoChanged,
    required this.esPequena,
    required this.filaResponsiva,
    this.modoSimplificado = false,
  });

  final int index;
  final DetalleLinea linea;
  final ControladoresLinea ctrl;
  final VoidCallback onEliminar;
  final VoidCallback onSeleccionarProducto;
  final ValueChanged<String> onCantidadChanged;
  final ValueChanged<String> onCostoChanged;
  final ValueChanged<String> onFleteChanged;
  final ValueChanged<String> onSeguroChanged;
  final ValueChanged<String> onArancelesChanged;
  final ValueChanged<String> onGastosChanged;
  final ValueChanged<String> onDescuentoChanged;
  final bool esPequena;
  final Widget Function({required Widget child1, required Widget child2})
  filaResponsiva;
  final bool modoSimplificado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppCard(
        borderColor: AppColors.border,
        padding: AppSpacing.allM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Línea ${index + 1}', style: AppTypography.labelMedium),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
            AppLayout.vXs,
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.productoId,
                label: 'ID',
                keyboardType: TextInputType.number,
                onChanged: onCantidadChanged,
              ),
              child2: GestureDetector(
                onTap: onSeleccionarProducto,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: ctrl.nombreProducto,
                    label: 'Seleccionar Producto',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),
            ),
            AppLayout.vS,
            const Text('Costos', style: AppTypography.labelMedium),
            AppLayout.vXs,
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.cantidad,
                label: 'Cantidad',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                ],
                onChanged: onCantidadChanged,
              ),
              child2: AppTextField(
                controller: ctrl.costoUnitario,
                label: 'Costo Compra (RD\$)',
                prefixIcon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: onCostoChanged,
              ),
            ),
            AppLayout.vS,
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.fleteUnitario,
                label: 'Flete por unidad',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: onFleteChanged,
              ),
              child2: AppTextField(
                controller: ctrl.seguroUnitario,
                label: 'Seguro por unidad',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: onSeguroChanged,
              ),
            ),
            AppLayout.vS,
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.arancelesUnitario,
                label: 'Aranceles por unidad',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: onArancelesChanged,
              ),
              child2: AppTextField(
                controller: ctrl.gastosUnitario,
                label: 'Otros Gastos por unidad',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: onGastosChanged,
              ),
            ),
            AppLayout.vS,
            AppTextField(
              controller: ctrl.descuento,
              label: 'Descuento (%)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: onDescuentoChanged,
            ),
            AppLayout.vM,
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: AppRadius.allM,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Subtotal: ${formatRdNumero(linea.subtotalLinea)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!modoSimplificado)
                        Text(
                          '${etiquetaItbisLineas([linea.tasaImpuestoLinea])}: ${formatRdNumero(linea.itbisLinea)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const Divider(height: 12, color: AppColors.border),
                      Text(
                        'Total línea: ${formatRdNumero(linea.totalLinea)}',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
