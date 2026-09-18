import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/tipos_linea.dart';

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
  final Widget Function({required Widget child1, required Widget child2}) filaResponsiva;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Padding(
        padding: AppSpacing.allM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Línea ${index + 1}',
                  style: AppTypography.labelMedium,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
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
            const SizedBox(height: 4),
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
            const SizedBox(height: 8),
            const Text(
              'Costos',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: 4),
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.cantidad,
                label: 'Cantidad',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,4}'),
                  ),
                ],
                onChanged: onCantidadChanged,
              ),
              child2: AppTextField(
                controller: ctrl.costoUnitario,
                label: 'Costo Compra (RD\$)',
                prefixIcon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                onChanged: onCostoChanged,
              ),
            ),
            const SizedBox(height: 8),
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.fleteUnitario,
                label: 'Flete por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                onChanged: onFleteChanged,
              ),
              child2: AppTextField(
                controller: ctrl.seguroUnitario,
                label: 'Seguro por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                onChanged: onSeguroChanged,
              ),
            ),
            const SizedBox(height: 8),
            filaResponsiva(
              child1: AppTextField(
                controller: ctrl.arancelesUnitario,
                label: 'Aranceles por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                onChanged: onArancelesChanged,
              ),
              child2: AppTextField(
                controller: ctrl.gastosUnitario,
                label: 'Otros Gastos por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                onChanged: onGastosChanged,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: ctrl.descuento,
              label: 'Descuento (%)',
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              onChanged: onDescuentoChanged,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal: RD\$ ${linea.subtotalLinea.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium,
                  ),
                  Text(
                    'ITBIS (18%): RD\$ ${linea.itbisLinea.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium,
                  ),
                  const Divider(height: 8),
                  Text(
                    'Total Línea: RD\$ ${linea.totalLinea.toStringAsFixed(2)}',
                    style: AppTypography.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
