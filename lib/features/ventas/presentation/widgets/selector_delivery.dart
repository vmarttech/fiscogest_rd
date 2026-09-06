import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';

class SelectorDeliveryDialog extends ConsumerStatefulWidget {

  const SelectorDeliveryDialog({
    super.key,
    required this.costoActual,
  });
  final double costoActual;

  @override
  ConsumerState<SelectorDeliveryDialog> createState() => _SelectorDeliveryDialogState();
}

class _SelectorDeliveryDialogState extends ConsumerState<SelectorDeliveryDialog> {
  late final TextEditingController _montoController;
  String? _opcionSeleccionada;
  static final NumberFormat _formatoMonto = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );

  static const List<Map<String, dynamic>> _opciones = [
    {'nombre': 'Santo Domingo', 'monto': 50.0},
    {'nombre': 'Nacional', 'monto': 150.0},
    {'nombre': 'Urgente', 'monto': 250.0},
    {'nombre': 'Retiro en tienda', 'monto': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: widget.costoActual > 0 ? widget.costoActual.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  void _seleccionarOpcion(String nombre, double monto) {
    setState(() {
      _opcionSeleccionada = nombre;
      _montoController.text = monto.toStringAsFixed(2);
    });
  }

  void _confirmar() {
    final montoTexto = _montoController.text.trim();
    final monto = double.tryParse(montoTexto) ?? 0.0;
    ref.read(registrarVentaProvider.notifier).asignarCostoEnvio(monto);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.delivery_dining, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('Costo de Envío / Delivery'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Selecciona una opción o ingresa el monto manualmente:'),
            const SizedBox(height: 16),
            ..._opciones.map((Map<String, dynamic> opcion) {
              final String nombre = opcion['nombre'] as String;
              final double monto = opcion['monto'] as double;
              final bool seleccionada = _opcionSeleccionada == nombre ||
                  (_opcionSeleccionada == null && widget.costoActual == monto);
              return ListTile(
                title: Text(nombre),
                subtitle: Text(_formatoMonto.format(monto)),
                selected: seleccionada,
                onTap: () => _seleccionarOpcion(nombre, monto),
              );
            }),
            const Divider(height: 24),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto personalizado (RD\$)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) {
                setState(() => _opcionSeleccionada = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
