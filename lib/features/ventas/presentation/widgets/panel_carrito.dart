import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_descuento.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';

class _DatosDescuento {
  const _DatosDescuento({required this.valor, required this.esPorcentaje});
  final double valor;
  final bool esPorcentaje;
}

class _CampoDescuento extends StatefulWidget {
  const _CampoDescuento({required this.montoActual, required this.onAplicar});
  final double montoActual;
  final void Function(_DatosDescuento) onAplicar;

  @override
  State<_CampoDescuento> createState() => _CampoDescuentoState();
}

class _CampoDescuentoState extends State<_CampoDescuento> {
  late final TextEditingController _controlador;
  late final FocusNode _focusNode;
  bool _esPorcentaje = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controlador = TextEditingController(
      text: widget.montoActual > 0 ? widget.montoActual.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(_CampoDescuento viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.montoActual != widget.montoActual && !_focusNode.hasFocus) {
      final nuevoTexto = widget.montoActual > 0 ? widget.montoActual.toStringAsFixed(2) : '';
      if (_controlador.text != nuevoTexto) _controlador.text = nuevoTexto;
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _alCambiarTexto(String texto) {
    final valor = double.tryParse(texto) ?? 0.0;
    widget.onAplicar(_DatosDescuento(valor: valor, esPorcentaje: _esPorcentaje));
  }

  void _cambiarTipo() {
    setState(() => _esPorcentaje = !_esPorcentaje);
    final valor = double.tryParse(_controlador.text) ?? 0.0;
    widget.onAplicar(_DatosDescuento(valor: valor, esPorcentaje: _esPorcentaje));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: AppTextField(
            controller: _controlador,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
            label: _esPorcentaje ? 'Descuento %' : 'Descuento RD\$',
            hint: '0.00',
            onChanged: _alCambiarTexto,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _cambiarTipo,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
            ),
            child: Text(_esPorcentaje ? '%' : 'RD\$', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  void _abrirSelectorDescuento(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Seleccionar Descuento',
        content: SizedBox(
          width: 500,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: const SingleChildScrollView(child: SelectorDescuento()),
          ),
        ),
        actions: [],
      ),
    );
  }

  void _aplicarDescuento(_DatosDescuento datos, WidgetRef ref) {
    final valor = datos.valor;
    final esPorcentaje = datos.esPorcentaje;
    final estado = ref.read(registrarVentaProvider);
    double baseCalculo = 0.0;

    for (final lineaRaw in estado.detalles) {
      double base = 0.0;
      double descuentoPct = 0.0;
      double descMonto = 0.0;

      base = lineaRaw.subtotalLinea ?? lineaRaw.subtotal;
      descuentoPct = lineaRaw.descuentoPorcentaje;
      descMonto = lineaRaw.montoDescuento;

      if (descuentoPct > 0) {
        base = base * (100 - descuentoPct) / 100;
      } else if (descMonto > 0) {
        base = base - descMonto;
      }
      if (base < 0) base = 0;
      baseCalculo += base;
    }

    double montoFinal;
    if (esPorcentaje) {
      montoFinal = (baseCalculo * valor / 100).clamp(0.0, baseCalculo);
    } else {
      montoFinal = valor.clamp(0.0, baseCalculo);
    }

    ref.read(registrarVentaProvider.notifier).aplicarDescuentoManual(montoFinal);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrarVentaProvider);
    final hayDescuento = estado.montoDescuento > 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Padding(
        padding: AppSpacing.allM,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text('Carrito de Venta', style: AppTypography.h4),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.l),
                  ),
                  child: Text(
                    '${estado.detalles.length} ${estado.detalles.length == 1 ? 'artículo' : 'artículos'}',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            if (estado.detalles.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.remove_shopping_cart_outlined, size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSpacing.s),
                    Text('El carrito está vacío', style: AppTypography.bodyMedium.copyWith(color: Colors.grey)),
                    const SizedBox(height: AppSpacing.xs),
                    const Text('Busca y agrega productos arriba', style: AppTypography.bodySmall),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estado.detalles.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                itemBuilder: (ctx, i) {
                  final detalle = estado.detalles[i];
                  return ItemCarrito(
                    detalle: detalle,
                    indice: i,
                    alEliminar: () => ref.read(registrarVentaProvider.notifier).quitarProducto(i),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.m),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _abrirSelectorDescuento(context),
                  icon: const Icon(Icons.local_offer_outlined, size: 16, color: Colors.grey),
                  label: const Text('Descuentos guardados', style: AppTypography.bodySmall),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: _CampoDescuento(
                    montoActual: estado.montoDescuento,
                    onAplicar: (datos) => _aplicarDescuento(datos, ref),
                  ),
                ),
              ],
            ),
            if (hayDescuento) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Descuento aplicado: - RD\$ ${estado.montoDescuento.toStringAsFixed(2)}',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: AppSpacing.allM,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildFilaTotal('Subtotal', estado.subtotal),
                  if (hayDescuento) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _buildFilaTotal('Descuento', estado.montoDescuento, esDescuento: true),
                    const SizedBox(height: AppSpacing.xs),
                    _buildFilaTotal('Base Gravable', (estado.subtotal - estado.montoDescuento).clamp(0.0, double.infinity)),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  _buildFilaTotal('ITBIS', estado.itbis),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildFilaTotal('Total', estado.total, esTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esTotal = false, bool esDescuento = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            etiqueta,
            overflow: TextOverflow.ellipsis,
            style: esTotal ? AppTypography.h4.copyWith(fontSize: 16) : AppTypography.bodyMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: 2,
          child: Text(
            '${esDescuento ? '- ' : ''}RD\$ ${monto.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: esTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: esTotal ? 18 : 14,
              color: esTotal
                  ? AppColors.primary
                  : esDescuento
                      ? AppColors.success
                      : const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}
