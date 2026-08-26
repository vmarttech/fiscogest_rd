import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_descuento.dart';

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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          child: TextField(
            controller: _controlador,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              labelText: _esPorcentaje ? 'Descuento %' : 'Descuento RD\$',
              hintText: '0.00',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: _alCambiarTexto,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: _cambiarTipo,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Descuento'),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: SizedBox(
          width: 500,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 450),
            child: const SingleChildScrollView(child: SelectorDescuento()),
          ),
        ),
      ),
    );
  }

  void _aplicarDescuento(WidgetRef ref, _DatosDescuento datos) {
    final valor = datos.valor;
    final esPorcentaje = datos.esPorcentaje;
    final estado = ref.read(registrarVentaProvider);
    double baseCalculo = 0.0;
    for (final lineaRaw in estado.detalles) {
      final dynamic linea = lineaRaw;
      double base = 0.0;
      double descuentoPct = 0.0;
      double descMonto = 0.0;
      if (linea is DetalleVenta) {
        base = linea.subtotalLinea ?? linea.subtotal;
        descuentoPct = linea.descuentoPorcentaje;
        descMonto = linea.montoDescuento;
      } else {
        final mapa = linea as Map;
        base = (mapa['subtotalLinea'] as double?) ?? 0.0;
        descuentoPct = (mapa['descuentoPorcentaje'] as double?) ?? 0.0;
        descMonto = (mapa['montoDescuento'] as double?) ?? 0.0;
      }
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
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Carrito de Venta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${estado.detalles.length} ${estado.detalles.length == 1 ? 'artículo' : 'artículos'}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (estado.detalles.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.remove_shopping_cart_outlined, size: 40, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('El carrito está vacío', style: TextStyle(color: theme.colorScheme.outline, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    const Text('Busca y agrega productos arriba', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: estado.detalles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final detalleRaw = estado.detalles[i];
                  final DetalleVenta detalle = detalleRaw;
                  return ItemCarrito(
                    detalle: detalle,
                    indice: i,
                    alEliminar: () => ref.read(registrarVentaProvider.notifier).quitarProducto(i),
                  );
                },
              ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _abrirSelectorDescuento(context),
                  icon: const Icon(Icons.local_offer_outlined, size: 16),
                  label: const Text('Descuentos guardados', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
                _CampoDescuento(
                  montoActual: estado.montoDescuento,
                  onAplicar: (datos) => _aplicarDescuento(ref, datos),
                ),
              ],
            ),
            if (hayDescuento) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Descuento aplicado: - RD\$ ${estado.montoDescuento.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildFilaTotal('Subtotal', estado.subtotal, context),
                  if (hayDescuento) ...[
                    const SizedBox(height: 6),
                    _buildFilaTotal('Descuento', estado.montoDescuento, context, esDescuento: true),
                    const SizedBox(height: 6),
                    _buildFilaTotal('Base Gravable', (estado.subtotal - estado.montoDescuento).clamp(0.0, double.infinity), context),
                  ],
                  const SizedBox(height: 6),
                  _buildFilaTotal('ITBIS', estado.itbis, context),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildFilaTotal('TOTAL A PAGAR', estado.total, context, esTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, BuildContext context, {bool esTotal = false, bool esDescuento = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontWeight: esTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: esTotal ? 15 : 13,
            color: esTotal ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${esDescuento ? '- ' : ''}RD\$ ${monto.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: esTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: esTotal ? 18 : 13,
            color: esTotal
                ? theme.colorScheme.primary
                : esDescuento
                    ? Colors.green.shade700
                    : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
