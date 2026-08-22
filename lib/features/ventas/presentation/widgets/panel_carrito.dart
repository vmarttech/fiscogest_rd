import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_descuento.dart';

class _DatosDescuento {
  final double valor;
  final bool esPorcentaje;
  const _DatosDescuento({required this.valor, required this.esPorcentaje});
}

class _CampoDescuento extends StatefulWidget {
  final double montoActual;
  final void Function(_DatosDescuento) onAplicar;
  const _CampoDescuento({required this.montoActual, required this.onAplicar});

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
    // ✅ SOLUCIÓN CLAVE: NO actualizar el texto si el usuario ESTÁ ESCRIBIENDO
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
        SizedBox(
          width: 180,
          child: TextField(
            controller: _controlador,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
            decoration: InputDecoration(
              labelText: _esPorcentaje ? 'Descuento %' : 'Descuento RD\$',
              hintText: '0.00',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            // ✅ REGEX FLEXIBLE: permite entrada progresiva sin bloquear
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: _alCambiarTexto,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _cambiarTipo,
          child: Text(_esPorcentaje ? '%' : 'RD\$'),
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
            child: SingleChildScrollView(child: SelectorDescuento()),
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
    for (final linea in estado.detalles) {
      double base = linea.subtotalLinea;
      if (linea.descuentoPorcentaje != null && linea.descuentoPorcentaje! > 0) {
        base = base * (100 - linea.descuentoPorcentaje!) / 100;
      } else if (linea.montoDescuento != null && linea.montoDescuento! > 0) {
        base = base - linea.montoDescuento!;
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${estado.detalles.length} productos', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (estado.detalles.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('Busque y agregue productos arriba', style: TextStyle(color: Colors.grey))))
            else
              SizedBox(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: estado.detalles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final detalle = estado.detalles[i];
                    return ItemCarrito(detalle: detalle, indice: i, alEliminar: () => ref.read(registrarVentaProvider.notifier).quitarProducto(i));
                  },
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _CampoDescuento(
                montoActual: estado.montoDescuento,
                onAplicar: (datos) => _aplicarDescuento(ref, datos),
              ),
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _abrirSelectorDescuento(context), child: const Text('Seleccionar descuento de lista'))),
            if (hayDescuento) ...[
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight, child: Text('Descuento aplicado: - RD\$ ${estado.montoDescuento.toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold))),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildFilaTotal('Subtotal', estado.subtotal),
            if (hayDescuento) ...[
              const SizedBox(height: 4),
              _buildFilaTotal('Descuento', estado.montoDescuento, esDescuento: true),
              _buildFilaTotal('Base Gravable', (estado.subtotal - estado.montoDescuento).clamp(0.0, double.infinity)),
            ],
            const SizedBox(height: 4),
            _buildFilaTotal('ITBIS', estado.itbis),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1.2),
            const SizedBox(height: 8),
            _buildFilaTotal('TOTAL A PAGAR', estado.total, esTotal: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esTotal = false, bool esDescuento = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 16 : 14, color: esTotal ? Colors.green.shade800 : const Color(0xFF424242))),
          Text('${esDescuento ? '- ' : ''}RD\$ ${monto.toStringAsFixed(2)}', style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 18 : 14, color: esTotal ? Colors.green.shade700 : esDescuento ? Colors.green.shade700 : const Color(0xFF212121))),
        ],
      ),
    );
  }
}
