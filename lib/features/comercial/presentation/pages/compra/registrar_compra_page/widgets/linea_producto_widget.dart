import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/tipos_linea.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';

class LineaProductoWidget extends StatefulWidget {
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
  State<LineaProductoWidget> createState() => _LineaProductoWidgetState();
}

class _LineaProductoWidgetState extends State<LineaProductoWidget> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return _buildDesktop();
    }
    return _buildMobile();
  }

  InputDecoration _miniDec({String? prefix}) {
    return InputDecoration(
      prefixText: prefix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF127369)),
      ),
    );
  }

  Widget _buildDesktop() {
    final nombre = widget.ctrl.nombreProducto.text.trim().isEmpty
        ? 'Seleccionar producto…'
        : widget.ctrl.nombreProducto.text.trim();
    final tiene = widget.ctrl.nombreProducto.text.trim().isNotEmpty;

    return Column(
      children: [
        // Fila principal de la tabla (mock product-table)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Producto
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: widget.onSeleccionarProducto,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          tiene ? Icons.inventory_2_outlined : Icons.search,
                          size: 20,
                          color: const Color(0xFFA0AEC0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                tiene ? FontWeight.w600 : FontWeight.w400,
                            color: tiene
                                ? const Color(0xFF333333)
                                : const Color(0xFFA0AEC0),
                          ),
                        ),
                      ),
                      // Expandir costos (flete/seguro/aranceles/descuento)
                      IconButton(
                        tooltip: _expandido
                            ? 'Ocultar costos extra'
                            : 'Flete / seguro / aranceles / descuento',
                        icon: Icon(
                          _expandido
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                          color: const Color(0xFF666666),
                        ),
                        onPressed: () =>
                            setState(() => _expandido = !_expandido),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cantidad
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: widget.ctrl.cantidad,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,4}'),
                      ),
                    ],
                    onChanged: widget.onCantidadChanged,
                    decoration: _miniDec(),
                  ),
                ),
              ),
              // Precio unit.
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: widget.ctrl.costoUnitario,
                      style: const TextStyle(fontSize: 14),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: widget.onCostoChanged,
                      decoration: _miniDec(prefix: 'RD\$ '),
                    ),
                  ),
                ),
              ),
              // ITBIS
              Expanded(
                flex: 2,
                child: Text(
                  widget.modoSimplificado
                      ? '—'
                      : formatRdNumero(widget.linea.itbisLinea),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              // Total
              Expanded(
                flex: 2,
                child: Text(
                  formatRdNumero(widget.linea.totalLinea),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              // Acciones
              SizedBox(
                width: 40,
                child: IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE53E3E),
                    size: 20,
                  ),
                  onPressed: widget.onEliminar,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ],
          ),
        ),
        // Expandible: flete / seguro / aranceles / gastos / descuento
        if (_expandido)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Costos adicionales por unidad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.ctrl.fleteUnitario,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: widget.onFleteChanged,
                        decoration: _miniDec().copyWith(labelText: 'Flete'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.ctrl.seguroUnitario,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: widget.onSeguroChanged,
                        decoration: _miniDec().copyWith(labelText: 'Seguro'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.ctrl.arancelesUnitario,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: widget.onArancelesChanged,
                        decoration: _miniDec().copyWith(labelText: 'Aranceles'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.ctrl.gastosUnitario,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: widget.onGastosChanged,
                        decoration:
                            _miniDec().copyWith(labelText: 'Otros gastos'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.ctrl.descuento,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: widget.onDescuentoChanged,
                        decoration:
                            _miniDec().copyWith(labelText: 'Descuento %'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMobile() {
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
                Text(
                  'Línea ${widget.index + 1}',
                  style: AppTypography.labelMedium,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: widget.onEliminar,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            AppLayout.vXs,
            widget.filaResponsiva(
              child1: AppTextField(
                controller: widget.ctrl.productoId,
                label: 'ID',
                keyboardType: TextInputType.number,
                onChanged: widget.onCantidadChanged,
              ),
              child2: GestureDetector(
                onTap: widget.onSeleccionarProducto,
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: widget.ctrl.nombreProducto,
                    label: 'Seleccionar Producto',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),
            ),
            AppLayout.vS,
            const Text('Costos', style: AppTypography.labelMedium),
            AppLayout.vXs,
            widget.filaResponsiva(
              child1: AppTextField(
                controller: widget.ctrl.cantidad,
                label: 'Cantidad',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
                ],
                onChanged: widget.onCantidadChanged,
              ),
              child2: AppTextField(
                controller: widget.ctrl.costoUnitario,
                label: 'Costo Compra (RD\$)',
                prefixIcon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: widget.onCostoChanged,
              ),
            ),
            AppLayout.vS,
            widget.filaResponsiva(
              child1: AppTextField(
                controller: widget.ctrl.fleteUnitario,
                label: 'Flete por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: widget.onFleteChanged,
              ),
              child2: AppTextField(
                controller: widget.ctrl.seguroUnitario,
                label: 'Seguro por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: widget.onSeguroChanged,
              ),
            ),
            AppLayout.vS,
            widget.filaResponsiva(
              child1: AppTextField(
                controller: widget.ctrl.arancelesUnitario,
                label: 'Aranceles por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: widget.onArancelesChanged,
              ),
              child2: AppTextField(
                controller: widget.ctrl.gastosUnitario,
                label: 'Otros Gastos por unidad',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: widget.onGastosChanged,
              ),
            ),
            AppLayout.vS,
            AppTextField(
              controller: widget.ctrl.descuento,
              label: 'Descuento (%)',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: widget.onDescuentoChanged,
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
                        'Subtotal: ${formatRdNumero(widget.linea.subtotalLinea)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!widget.modoSimplificado)
                        Text(
                          '${etiquetaItbisLineas([widget.linea.tasaImpuestoLinea])}: ${formatRdNumero(widget.linea.itbisLinea)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const Divider(height: 12, color: AppColors.border),
                      Text(
                        'Total línea: ${formatRdNumero(widget.linea.totalLinea)}',
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
