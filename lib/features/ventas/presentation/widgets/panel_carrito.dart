import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';

class _DatosDescuento {
  const _DatosDescuento({required this.valor, required this.esPorcentaje});
  final double valor;
  final bool esPorcentaje;
}

const double _maximoPorcentaje = 35.0;

class _CampoDescuento extends StatefulWidget {
  const _CampoDescuento({
    required this.montoActual,
    required this.onAplicar,
    required this.anchoCampo,
  });
  final double montoActual;
  final void Function(_DatosDescuento) onAplicar;
  final double anchoCampo;

  @override
  State<_CampoDescuento> createState() => _CampoDescuentoState();
}

class _CampoDescuentoState extends State<_CampoDescuento> {
  late final TextEditingController _controlador;
  bool _esPorcentaje = false;
  double? _valorUltimoEnviado;
  bool _advertenciaMostrada = false;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController(text: _formatear(widget.montoActual));
    _valorUltimoEnviado = widget.montoActual;
  }

  @override
  void didUpdateWidget(_CampoDescuento viejo) {
    super.didUpdateWidget(viejo);
    if (widget.montoActual != _valorUltimoEnviado) {
      final nuevoTexto = _formatear(widget.montoActual);
      if (_controlador.text != nuevoTexto) {
        _controlador.text = nuevoTexto;
      }
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  static String _formatear(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _validarYLimitarValor(double valor) {
    if (_esPorcentaje && valor > _maximoPorcentaje) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_advertenciaMostrada) {
          _advertenciaMostrada = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ El descuento máximo permitido es 35%. Requiere autorización para más.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
      return _maximoPorcentaje;
    }
    if (valor <= 0) {
      if (_advertenciaMostrada) {
        _advertenciaMostrada = false;
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      return 0;
    }
    if (_advertenciaMostrada && valor <= _maximoPorcentaje) {
      _advertenciaMostrada = false;
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    return valor;
  }

  void _aplicarSegunTexto(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    var valor = double.tryParse(limpio) ?? 0.0;
    valor = _validarYLimitarValor(valor);
    if (_valorUltimoEnviado != valor) {
      _valorUltimoEnviado = valor;
      widget.onAplicar(
        _DatosDescuento(valor: valor, esPorcentaje: _esPorcentaje),
      );
    }
  }

  void _cambiarTipo(bool nuevoTipo) {
    setState(() {
      _esPorcentaje = nuevoTipo;
      _advertenciaMostrada = false;
    });
    final valorActual = _valorUltimoEnviado ?? 0.0;
    widget.onAplicar(
      _DatosDescuento(valor: valorActual, esPorcentaje: nuevoTipo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.anchoCampo,
      child: TextField(
        controller: _controlador,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: _esPorcentaje ? 'Desc %' : 'Desc RD\$',
          labelStyle: const TextStyle(fontSize: 13),
          hintText: '0,00',
          hintStyle: const TextStyle(fontSize: 15),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          suffixIcon: PopupMenuButton<bool>(
            onSelected: _cambiarTipo,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 50, maxWidth: 56),
            position: PopupMenuPosition.under,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: false,
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money, size: 16),
                    SizedBox(width: 4),
                    Text('RD\$', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: true,
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.percent, size: 16),
                    SizedBox(width: 4),
                    Text('%', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            child: Container(
              alignment: Alignment.center,
              width: 36,
              child: Text(
                _esPorcentaje ? '%' : 'RD\$',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        onChanged: _aplicarSegunTexto,
      ),
    );
  }
}

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  (double, double) _calcularBaseYDatos(RegistrarVentaState estado) {
    double baseConDescLinea = 0.0;
    double totalDescLinea = 0.0;
    for (final linea in estado.detalles) {
      final precioConCantidad = linea.subtotalLinea ?? linea.subtotal;
      double despuesDescLinea = precioConCantidad;
      if (linea.descuentoPorcentaje > 0) {
        despuesDescLinea = precioConCantidad * (100 - linea.descuentoPorcentaje) / 100;
      } else if (linea.montoDescuento > 0) {
        despuesDescLinea = precioConCantidad - linea.montoDescuento;
      }
      if (despuesDescLinea < 0) despuesDescLinea = 0;
      baseConDescLinea += despuesDescLinea;
      totalDescLinea += (precioConCantidad - despuesDescLinea);
    }
    return (baseConDescLinea, totalDescLinea);
  }

  void _aplicarDescuento(_DatosDescuento datos, WidgetRef ref, BuildContext context) {
    final estado = ref.read(registrarVentaProvider);
    final notifier = ref.read(registrarVentaProvider.notifier);
    final error = notifier.puedeAplicarDescuentoGeneral();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    final (baseCalculo, _) = _calcularBaseYDatos(estado);
    final montoFinal = datos.esPorcentaje
        ? (baseCalculo * datos.valor / 100).clamp(0.0, baseCalculo)
        : datos.valor.clamp(0.0, baseCalculo);
    notifier.aplicarDescuentoManual(montoFinal);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;
    final paddingHorizontal = esPantallaPequena ? AppSpacing.s : AppSpacing.m;
    final paddingVerticalVacio = esPantallaPequena ? 24.0 : 48.0;
    final tamanoIconoVacio = esPantallaPequena ? 36.0 : 48.0;
    final anchoCampoDescuento = esPantallaPequena ? anchoPantalla * 0.38 : 130.0;
    final fontSizeDescuento = esPantallaPequena ? 10.0 : 12.0;
    final paddingCantidadArticulos = esPantallaPequena
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 2);

    final estado = ref.read(registrarVentaProvider);
    final hayDescuentoGeneral = estado.montoDescuento > 0;

    return AppCard(
      padding: EdgeInsets.symmetric(
        vertical: esPantallaPequena ? AppSpacing.xs : AppSpacing.s,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: esPantallaPequena ? AppSpacing.xs : AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: esPantallaPequena ? 18 : 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: esPantallaPequena ? 6 : 8),
                    Text(
                      'Carrito de Venta',
                      style: esPantallaPequena
                          ? AppTypography.labelMedium
                          : AppTypography.labelLarge,
                    ),
                  ],
                ),
                Container(
                  padding: paddingCantidadArticulos,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${estado.detalles.length} art.',
                    style: AppTypography.labelSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: esPantallaPequena ? AppSpacing.xs : AppSpacing.s),
            if (estado.detalles.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: paddingVerticalVacio),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: tamanoIconoVacio,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: esPantallaPequena ? 6 : 8),
                    Text(
                      'La venta está vacía',
                      style: esPantallaPequena
                          ? AppTypography.labelMedium
                          : AppTypography.bodyMedium,
                    ),
                    SizedBox(height: esPantallaPequena ? 2 : 4),
                    const Text(
                      'Busca un producto para comenzar',
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: estado.detalles.asMap().entries.map((entrada) {
                  final indice = entrada.key;
                  final detalle = entrada.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: ItemCarrito(
                      detalle: detalle,
                      indice: indice,
                      alEliminar: () =>
                          ref.read(registrarVentaProvider.notifier).quitarProducto(indice),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: esPantallaPequena ? AppSpacing.xs : AppSpacing.s),
            const Divider(height: 1, thickness: 0.5),
            SizedBox(height: esPantallaPequena ? AppSpacing.xs : AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CampoDescuento(
                  montoActual: estado.montoDescuento,
                  onAplicar: (datos) => _aplicarDescuento(datos, ref, context),
                  anchoCampo: anchoCampoDescuento,
                ),
              ],
            ),
            if (hayDescuentoGeneral)
              Padding(
                padding: EdgeInsets.only(
                  top: esPantallaPequena ? 2 : 4,
                  right: esPantallaPequena ? 2 : 4,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '- RD\$ ${estado.montoDescuento.toStringAsFixed(2).replaceAll('.', ',')} (general)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSizeDescuento,
                    ),
                  ),
                ),
              ),
            SizedBox(height: esPantallaPequena ? AppSpacing.xs : AppSpacing.s),
          ],
        ),
      ),
    );
  }
}
