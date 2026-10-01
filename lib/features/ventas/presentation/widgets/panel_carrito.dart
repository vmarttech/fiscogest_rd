import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

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
    return formatRdNumero(valor);
  }

  double _validarYLimitarValor(double valor) {
    if (_esPorcentaje && valor > _maximoPorcentaje) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_advertenciaMostrada) {
          _advertenciaMostrada = true;
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text(
                'El descuento máximo permitido es 35%. Requiere autorización para más.',
              ),
              backgroundColor: AppColors.warning,
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
        style: AppTypography.bodyMedium.copyWith(fontSize: 14),
        decoration: InputDecoration(
          labelText: _esPorcentaje ? 'Desc %' : 'Desc RD\$',
          labelStyle: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
          hintText: '0,00',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          suffixIcon: PopupMenuButton<bool>(
            onSelected: _cambiarTipo,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, maxWidth: 52),
            position: PopupMenuPosition.under,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: false,
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text('RD\$', style: AppTypography.labelMedium),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: true,
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.percent, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('%', style: AppTypography.labelMedium),
                  ],
                ),
              ),
            ],
            child: Container(
              alignment: Alignment.center,
              width: 36,
              child: Text(
                _esPorcentaje ? '%' : 'RD\$',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
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
        despuesDescLinea =
            precioConCantidad * (100 - linea.descuentoPorcentaje) / 100;
      } else if (linea.montoDescuento > 0) {
        despuesDescLinea = precioConCantidad - linea.montoDescuento;
      }
      if (despuesDescLinea < 0) despuesDescLinea = 0;
      baseConDescLinea += despuesDescLinea;
      totalDescLinea += (precioConCantidad - despuesDescLinea);
    }
    return (baseConDescLinea, totalDescLinea);
  }

  void _aplicarDescuento(
    _DatosDescuento datos,
    WidgetRef ref,
    BuildContext context,
  ) {
    final estado = ref.read(registrarVentaProvider);
    final notifier = ref.read(registrarVentaProvider.notifier);
    final error = notifier.puedeAplicarDescuentoGeneral();
    if (error != null) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
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
    final errGen = notifier.aplicarDescuentoGeneral(
      montoFinal,
      esPorcentaje: false,
    );
    if (errGen != null && context.mounted) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(errGen),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppBreakpoints.isMobile(context);
    final estado = ref.watch(registrarVentaProvider);
    final hayDescuentoGeneral = estado.montoDescuento > 0;
    final anchoCampoDescuento = isMobile
        ? MediaQuery.of(context).size.width * 0.38
        : 130.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Carrito de Venta',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${estado.detalles.length} art.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contenido
            if (estado.detalles.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 28 : 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: isMobile ? 40 : 48,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'La venta está vacía',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Busca un producto para comenzar',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ItemCarrito(
                      detalle: detalle,
                      indice: indice,
                      alEliminar: () => ref
                          .read(registrarVentaProvider.notifier)
                          .quitarProducto(indice),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Descuento general
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '- ${formatRd(estado.montoDescuento)} (general)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
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
