import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/item_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_descuento.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
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
  double? _valorUltimoEnviado;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controlador = TextEditingController(text: _formatear(widget.montoActual));
    _valorUltimoEnviado = widget.montoActual;
    _focusNode.addListener(_alPerderFoco);
  }

  @override
  void didUpdateWidget(_CampoDescuento viejo) {
    super.didUpdateWidget(viejo);
    if (_focusNode.hasFocus) return;
    if (widget.montoActual != _valorUltimoEnviado) {
      final nuevoTexto = _formatear(widget.montoActual);
      if (_controlador.text != nuevoTexto) {
        _controlador.text = nuevoTexto;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_alPerderFoco);
    _controlador.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatear(double valor) {
    return valor > 0 ? valor.toStringAsFixed(2) : '';
  }

  void _alPerderFoco() {
    if (!_focusNode.hasFocus) {
      final valor =
          double.tryParse(_controlador.text.replaceAll(',', '.')) ?? 0.0;
      _valorUltimoEnviado = valor;
      _controlador.text = _formatear(valor);
    }
  }

  void _alCambiarTexto(String texto) {
    final limpio = texto
        .replaceAll(RegExp(r'[^0-9.,]'), '')
        .replaceAll(',', '.');
    final valor = double.tryParse(limpio) ?? 0.0;
    if (_valorUltimoEnviado != valor) {
      _valorUltimoEnviado = valor;
      widget.onAplicar(
        _DatosDescuento(valor: valor, esPorcentaje: _esPorcentaje),
      );
    }
  }

  void _cambiarTipo() {
    setState(() => _esPorcentaje = !_esPorcentaje);
    final valor =
        double.tryParse(_controlador.text.replaceAll(',', '.')) ?? 0.0;
    _valorUltimoEnviado = valor;
    widget.onAplicar(
      _DatosDescuento(valor: valor, esPorcentaje: _esPorcentaje),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Listener(
            onPointerUp: (_) {
              if (!_focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_focusNode);
              }
            },
            child: Focus(
              focusNode: _focusNode,
              child: AppTextField(
                controller: _controlador,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                label: _esPorcentaje ? 'Descuento %' : 'Descuento RD\$',
                hint: '0.00',
                onChanged: _alCambiarTexto,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _cambiarTipo,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
            ),
            child: Text(
              _esPorcentaje ? '%' : 'RD\$',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  (double baseConDescuentoLinea, double totalDescuentoLinea)
  _calcularBaseYDatos(RegistrarVentaState estado) {
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
    final estado = ref.watch(registrarVentaProvider);
    final hayDescuentoGeneral = estado.montoDescuento > 0;
    final (baseConDescuentoLinea, totalDescuentoLinea) = _calcularBaseYDatos(estado);
    final hayDescuentoLinea = totalDescuentoLinea.abs() > 0.001;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Padding(
        padding: AppSpacing.allM,
        child: LayoutBuilder(
          builder: (context, restricciones) {
            if (restricciones.maxWidth < 800) {
              return _construirModoMovil(
                estado,
                hayDescuentoGeneral,
                hayDescuentoLinea,
                baseConDescuentoLinea,
                totalDescuentoLinea,
                context,
                ref,
              );
            }
            return _construirModoEscritorio(
              estado,
              hayDescuentoGeneral,
              hayDescuentoLinea,
              baseConDescuentoLinea,
              totalDescuentoLinea,
              context,
              ref,
            );
          },
        ),
      ),
    );
  }

  Widget _construirModoMovil(
    RegistrarVentaState estado,
    bool hayDescuentoGeneral,
    bool hayDescuentoLinea,
    double baseConDescuentoLinea,
    double totalDescuentoLinea,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _construirEncabezado(estado),
        const SizedBox(height: AppSpacing.s),
        if (estado.detalles.isEmpty)
          _construirCarritoVacio()
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _construirListaProductos(estado, ref),
            ),
          ),
        const SizedBox(height: AppSpacing.s),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: AppSpacing.s),
        _construirFilaDescuentos(
          estado, hayDescuentoGeneral, hayDescuentoLinea, baseConDescuentoLinea, totalDescuentoLinea, context, ref,
        ),
        if (hayDescuentoGeneral) ...[
          const SizedBox(height: AppSpacing.xs),
          _construirDescuentoGeneral(estado),
        ],
        const SizedBox(height: AppSpacing.s),
      ],
    );
  }

  Widget _construirModoEscritorio(
    RegistrarVentaState estado,
    bool hayDescuentoGeneral,
    bool hayDescuentoLinea,
    double baseConDescuentoLinea,
    double totalDescuentoLinea,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _construirEncabezado(estado),
        const SizedBox(height: AppSpacing.s),
        if (estado.detalles.isEmpty)
          const SizedBox.shrink()
        else
          SizedBox(
            height: 280,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _construirListaProductos(estado, ref),
            ),
          ),
        const SizedBox(height: AppSpacing.s),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: AppSpacing.s),
        _construirFilaDescuentos(
          estado, hayDescuentoGeneral, hayDescuentoLinea, baseConDescuentoLinea, totalDescuentoLinea, context, ref,
        ),
        if (hayDescuentoGeneral) ...[
          const SizedBox(height: AppSpacing.xs),
          _construirDescuentoGeneral(estado),
        ],
        const SizedBox(height: AppSpacing.s),
      ],
    );
  }

  Widget _construirEncabezado(RegistrarVentaState estado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text('Carrito de Venta', style: AppTypography.h4),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
          child: Text(
            '${estado.detalles.length} art.',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirCarritoVacio() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.remove_shopping_cart_outlined,
            size: 36,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'El carrito está vacío',
            style: AppTypography.bodyMedium.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _construirListaProductos(RegistrarVentaState estado, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: estado.detalles.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (ctx, i) {
        final detalle = estado.detalles[i];
        return ItemCarrito(
          detalle: detalle,
          indice: i,
          alEliminar: () =>
              ref.read(registrarVentaProvider.notifier).quitarProducto(i),
        );
      },
    );
  }

  Widget _construirFilaDescuentos(
    RegistrarVentaState estado,
    bool hayDescuentoGeneral,
    bool hayDescuentoLinea,
    double baseConDescuentoLinea,
    double totalDescuentoLinea,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => const SelectorDescuentoDialog(),
            );
          },
          icon: const Icon(
            Icons.local_offer_outlined,
            size: 16,
            color: Colors.grey,
          ),
          label: const Text('Descuentos', style: AppTypography.bodySmall),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(40, 36),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: _CampoDescuento(
            montoActual: estado.montoDescuento,
            onAplicar: (datos) => _aplicarDescuento(datos, ref, context),
          ),
        ),
      ],
    );
  }

  Widget _construirDescuentoGeneral(RegistrarVentaState estado) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '- RD\$ ${estado.montoDescuento.toStringAsFixed(2)} (general)',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
