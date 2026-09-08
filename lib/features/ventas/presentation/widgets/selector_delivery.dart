import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
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
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;
    final anchoMaximoDialog = esPantallaPequena ? anchoPantalla * 0.92 : 400.0;
    final paddingDialogo = esPantallaPequena ? 12.0 : 16.0;
    final tamanoIcono = esPantallaPequena ? 20.0 : 24.0;
    final tamanoTitulo = esPantallaPequena ? 16.0 : 18.0;
    final espaciadoIconoTitulo = esPantallaPequena ? 8.0 : 10.0;

    return AlertDialog(
      titlePadding: EdgeInsets.all(paddingDialogo),
      contentPadding: EdgeInsets.symmetric(horizontal: paddingDialogo, vertical: 8),
      actionsPadding: EdgeInsets.symmetric(horizontal: paddingDialogo, vertical: 12),
      title: Row(
        children: [
          Icon(Icons.delivery_dining, color: AppColors.primary, size: tamanoIcono),
          SizedBox(width: espaciadoIconoTitulo),
          Expanded(
            child: Text(
              'Costo de Envío / Delivery',
              style: AppTypography.labelLarge.copyWith(fontSize: tamanoTitulo),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: anchoMaximoDialog,
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Selecciona una opción o ingresa el monto manualmente:',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: 12),
            ..._opciones.map((Map<String, dynamic> opcion) {
              final String nombre = opcion['nombre'] as String;
              final double monto = opcion['monto'] as double;
              final bool seleccionada = _opcionSeleccionada == nombre ||
                  (_opcionSeleccionada == null && widget.costoActual == monto);
              return ListTile(
                dense: esPantallaPequena,
                visualDensity: VisualDensity.compact,
                title: Text(
                  nombre,
                  style: AppTypography.labelMedium.copyWith(
                    color: seleccionada ? AppColors.primary : null,
                    fontWeight: seleccionada ? FontWeight.w600 : null,
                  ),
                ),
                subtitle: Text(
                  _formatoMonto.format(monto),
                  style: AppTypography.labelSmall,
                ),
                selected: seleccionada,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                onTap: () => _seleccionarOpcion(nombre, monto),
              );
            }),
            const Divider(height: 16),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto personalizado (RD\$)',
                labelStyle: AppTypography.labelMedium,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: AppTypography.labelMedium,
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
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
