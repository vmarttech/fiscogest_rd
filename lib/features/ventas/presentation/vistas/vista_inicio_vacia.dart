import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';

class VistaInicioVacia extends ConsumerStatefulWidget {
  const VistaInicioVacia({super.key});
  @override
  ConsumerState<VistaInicioVacia> createState() => _VistaInicioVaciaState();
}

class _VistaInicioVaciaState extends ConsumerState<VistaInicioVacia> {
  static final NumberFormat _formatoMonto = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 2,
    customPattern: '¤ #,##0.00',
  );
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrarVentaProvider.notifier).establecerConsumidorFinal();
    });
  }

  Future<void> _cambiarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      ref.read(registrarVentaProvider.notifier).seleccionarCliente(cliente.id ?? 0, cliente.nombre);
    }
  }

  Future<void> _cobrar() async {
    final estado = ref.read(registrarVentaProvider);
    final valido = ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar();
    if (!valido) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Agregue productos y seleccione forma de pago')),
        );
      }
      return;
    }
    const formasPago = ['Efectivo', 'Tarjeta', 'Crédito', 'Transferencia', 'Cheque'];
    final formaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forma de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${_formatoMonto.format(estado.total)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            ...formasPago.map((forma) => ListTile(
              title: Text(forma),
              onTap: () => Navigator.pop(context, forma.toLowerCase()),
            )),
          ],
        ),
      ),
    );
    if (formaSeleccionada == null) return;
    ref.read(registrarVentaProvider.notifier).cambiarFormaPago(formaSeleccionada);
    final estadoFinal = ref.read(registrarVentaProvider);
    setState(() => _guardando = true);
    try {
      final ventaGuardada = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoFinal);
      if (ventaGuardada.id == null) {
        throw Exception('El repositorio no devolvió ID de venta');
      }
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta #${ventaGuardada.numero} registrada — ${_formatoMonto.format(ventaGuardada.total)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  double _calcularDescuentoPorLinea(RegistrarVentaState estado) {
    double totalDesc = 0.0;
    for (final linea in estado.detalles) {
      final precioConCantidad = linea.subtotalLinea ?? linea.subtotal;
      double despuesDesc = precioConCantidad;
      if (linea.descuentoPorcentaje > 0) {
        despuesDesc = precioConCantidad * (100 - linea.descuentoPorcentaje) / 100;
      } else if (linea.montoDescuento > 0) {
        despuesDesc = precioConCantidad - linea.montoDescuento;
      }
      if (despuesDesc < 0) despuesDesc = 0;
      totalDesc += (precioConCantidad - despuesDesc);
    }
    return totalDesc;
  }

  void _seleccionarProducto(DetalleVenta producto) {
    ref.read(registrarVentaProvider.notifier).agregarProductoSeleccionado(producto);
  }

  @override
  Widget build(BuildContext context) {
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));
    final estado = ref.watch(registrarVentaProvider);

    final esConsumidorFinal = estado.clienteId == 0 || estado.clienteNombre == 'Consumidor Final';

    final colorPrimario = switch (modo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.success,
      ModoOperacion.cobrar => AppColors.warning,
    };
    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';
    final tieneProductos = estado.detalles.isNotEmpty;
    final tieneResultados = estado.resultadosBusqueda.isNotEmpty;

    final montoTotal = _formatoMonto.format(estado.total);

    final tieneDescuentoGeneral = estado.montoDescuento > 0;
    final descuentoPorLinea = _calcularDescuentoPorLinea(estado);
    final subtotalConDescuentoLinea = estado.subtotal - descuentoPorLinea;
    final baseGravable = (subtotalConDescuentoLinea - estado.montoDescuento).clamp(0.0, double.infinity);
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;
    final paddingLateral = esPantallaPequena ? 16.0 : 24.0;
    final anchoMaximoContenido = esPantallaPequena ? double.infinity : 900.0;
    final espaciadoBotones = esPantallaPequena ? 4.0 : 8.0;

    Widget botonModo(ModoOperacion m, String etiqueta) {
      final activo = modo == m;
      return Expanded(
        child: FilledButton(
          onPressed: _guardando ? null : () => ref.read(ventasNavegacionProvider.notifier).establecerModoOperacion(m),
          style: FilledButton.styleFrom(
            backgroundColor: activo ? colorPrimario : Colors.transparent,
            foregroundColor: activo ? Colors.white : colorPrimario,
            side: activo ? null : BorderSide(color: colorPrimario),
            padding: EdgeInsets.symmetric(vertical: esPantallaPequena ? 8 : 12),
            minimumSize: const Size(60, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: TextStyle(fontSize: esPantallaPequena ? 11 : 13, fontWeight: FontWeight.w600),
          ),
          child: Text(etiqueta),
        ),
      );
    }

    Widget filaTotal(String etiqueta, String valor, {bool esDestacado = false, Color? colorTexto}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              etiqueta,
              style: esDestacado
                  ? AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: colorTexto)
                  : AppTypography.labelMedium.copyWith(color: colorTexto),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 160,
              child: Text(
                valor,
                textAlign: TextAlign.right,
                style: esDestacado
                    ? AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: colorTexto)
                    : AppTypography.labelMedium.copyWith(color: colorTexto),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximoContenido),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: paddingLateral, vertical: AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  botonModo(ModoOperacion.venta, 'VENTA'),
                  SizedBox(width: espaciadoBotones),
                  botonModo(ModoOperacion.cotizacion, 'COTIZACIÓN'),
                  SizedBox(width: espaciadoBotones),
                  botonModo(ModoOperacion.apartado, 'APARTADO'),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              // ✅ BARRA DE BÚSQUEDA REDUCIDA — ALINEADA A LA IZQUIERDA
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: esPantallaPequena ? anchoPantalla * 0.75 : 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        hint: 'Buscar producto, código o escanear...',
                        prefixIcon: Icons.search,
                        onChanged: (texto) => ref.read(registrarVentaProvider.notifier).buscarProducto(texto),
                      ),
                      // ✅ LISTA DE RESULTADOS DE BÚSQUEDA
                      if (tieneResultados)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.grey200),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: estado.resultadosBusqueda.length,
                            itemBuilder: (context, i) {
                              final prod = estado.resultadosBusqueda[i];
                              return ListTile(
                                dense: true,
                                title: Text(prod.nombreProducto ?? 'Producto'),
                                subtitle: Text(_formatoMonto.format(prod.precioUnitario)),
                                onTap: () {
                                  _seleccionarProducto(prod);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(nombreCliente, style: AppTypography.labelMedium),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _guardando ? null : _cambiarCliente,
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.m),
              if (!tieneProductos)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.point_of_sale_outlined, size: 56, color: AppColors.grey400),
                      SizedBox(height: AppSpacing.m),
                      Text('La venta está vacía', style: AppTypography.labelLarge),
                      SizedBox(height: AppSpacing.s),
                      Text('Busca un producto para comenzar', style: AppTypography.bodyMedium),
                    ],
                  ),
                )
              else
                const PanelCarrito(),
              const SizedBox(height: AppSpacing.xl),
              if (tieneProductos)
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!esConsumidorFinal) ...[
                        filaTotal('Subtotal:', _formatoMonto.format(estado.subtotal)),
                        if (descuentoPorLinea > 0.001)
                          filaTotal(
                            'Descuento por línea:',
                            '- ${_formatoMonto.format(descuentoPorLinea)}',
                            colorTexto: Colors.red.shade700,
                          ),
                        if (tieneDescuentoGeneral)
                          filaTotal(
                            'Descuento general:',
                            '- ${_formatoMonto.format(estado.montoDescuento)}',
                            colorTexto: Colors.red.shade700,
                          ),
                        filaTotal('Base Gravable:', _formatoMonto.format(baseGravable)),
                        filaTotal('ITBIS (18%):', _formatoMonto.format(estado.itbis)),
                      ],
                      const SizedBox(height: 8),
                      filaTotal('TOTAL:', montoTotal, esDestacado: true, colorTexto: colorPrimario),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: esPantallaPequena ? double.infinity : 260,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(0, 72),
                    ),
                    onPressed: tieneProductos && !_guardando ? _cobrar : null,
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tieneProductos ? 'COBRAR' : 'AGREGUE PRODUCTOS', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(montoTotal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
