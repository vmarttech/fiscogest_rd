import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:fiscogest_rd/features/apartados/presentation/providers/apartado_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';

class VistaInicioVacia extends ConsumerStatefulWidget {
  const VistaInicioVacia({super.key});
  @override
  ConsumerState<VistaInicioVacia> createState() => _VistaInicioVaciaState();
}

class _VistaInicioVaciaState extends ConsumerState<VistaInicioVacia> {
  static final NumberFormat _formatoNumero = NumberFormat('#,##0.00', 'es_DO');
  String _formatearMonto(double valor) => 'RD\$${_formatoNumero.format(valor)}';

  bool _guardando = false;
  bool _mostrarFormularioCredito = false;
  RegistrarVentaState? _estadoPasoCredito;
  final TextEditingController _buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrarVentaProvider.notifier).establecerConsumidorFinal();
    });
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _cambiarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      ref.read(registrarVentaProvider.notifier).seleccionarCliente(cliente.id ?? 0, cliente.nombre);
    }
  }

  void _cerrarFormularioCredito() {
    setState(() {
      _mostrarFormularioCredito = false;
      _estadoPasoCredito = null;
      _guardando = false;
    });
  }

  void _confirmarCredito(ResultadoFormularioCredito resultadoCredito) async {
    _cerrarFormularioCredito();
    if (!mounted) return;
    setState(() => _guardando = true);
    try {
      final abonoRecibido = resultadoCredito.abonoInicial?.monto ?? 0.0;
      final fechaVence = resultadoCredito.cuenta.fechaVencimiento;
      ref.read(registrarVentaProvider.notifier).establecerCondicionesCredito(abonoRecibido, fechaVence);
      final estadoConCredito = ref.read(registrarVentaProvider);
      final ventaGuardada = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoConCredito);
      if (!mounted) return;
      if (ventaGuardada.id == null) {
        throw Exception('El repositorio no devolvió ID de venta');
      }
      final saldoPendiente = estadoConCredito.total - abonoRecibido;
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Venta #${ventaGuardada.numero} registrada.\n'
              '💰 Abono inicial: ${_formatearMonto(abonoRecibido)}\n'
              '📄 Saldo pendiente: ${_formatearMonto(saldoPendiente)}\n'
              '📅 Vence: ${DateFormat('dd/MM/yyyy').format(fechaVence)}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('❌ Error crédito: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cobrar() async {
    final estado = ref.read(registrarVentaProvider);
    final modo = ref.read(ventasNavegacionProvider).modoOperacion;
    final valido = ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar();
    if (!valido) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Agregue productos y seleccione forma de pago')),
        );
      }
      return;
    }
    if (!mounted) return;
    final esPantallaPequenaDialog = MediaQuery.of(context).size.width < 600;
    const formasPago = ['Efectivo', 'Tarjeta', 'Crédito', 'Transferencia', 'Cheque'];
    final formaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(modo == ModoOperacion.apartado ? 'Forma de Reserva' : 'Forma de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${_formatearMonto(estado.total)}',
              style: TextStyle(
                fontSize: esPantallaPequenaDialog ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...formasPago.map((forma) => ListTile(
              title: Text(forma),
              onTap: () => Navigator.pop(context, forma.toLowerCase()),
            )),
          ],
        ),
      ),
    );
    if (formaSeleccionada == null || !mounted) return;
    ref.read(registrarVentaProvider.notifier).cambiarFormaPago(formaSeleccionada);
    final estadoFinal = ref.read(registrarVentaProvider);
    if (modo == ModoOperacion.apartado) {
      final idApartado = await ref.read(apartadoNotifierProvider.notifier).crearApartadoDesdeVenta(estadoFinal);
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Apartado #$idApartado registrado — Stock reservado — ${_formatearMonto(estadoFinal.total)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else if (formaSeleccionada == 'crédito') {
      setState(() {
        _mostrarFormularioCredito = true;
        _estadoPasoCredito = estadoFinal;
      });
      return;
    } else {
      final ventaGuardada = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoFinal);
      if (!mounted) return;
      if (ventaGuardada.id == null) {
        throw Exception('El repositorio no devolvió ID de venta');
      }
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Venta #${ventaGuardada.numero} registrada — ${_formatearMonto(ventaGuardada.total)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
    _buscarController.clear();
    ref.read(registrarVentaProvider.notifier)
      ..buscarProducto('')
      ..agregarProductoSeleccionado(producto);
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
    final montoTotal = _formatearMonto(estado.total);
    final tieneDescuentoGeneral = estado.montoDescuento > 0;
    final descuentoPorLinea = _calcularDescuentoPorLinea(estado);
    final subtotalConDescuentoLinea = estado.subtotal - descuentoPorLinea;
    final baseGravable = (subtotalConDescuentoLinea - estado.montoDescuento).clamp(0.0, double.infinity);
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPantallaPequena = anchoPantalla < 600;
    final paddingLateral = esPantallaPequena ? 16.0 : 24.0;
    const anchoMaximoContenido = 900.0;
    final espaciadoBotones = esPantallaPequena ? 4.0 : 8.0;
    final anchoColumnaValores = esPantallaPequena ? anchoPantalla * 0.35 : 160.0;
    final espaciadoEtiquetaValor = esPantallaPequena ? 8.0 : 16.0;
    final paddingVacioVertical = esPantallaPequena ? 24.0 : 48.0;
    final tamanoIconoVacio = esPantallaPequena ? 40.0 : 56.0;
    final fontSizeMontoBoton = esPantallaPequena ? 14.0 : 18.0;
    final espaciadoCliente = esPantallaPequena ? 6.0 : 8.0;
    final espaciadoBotonesCliente = esPantallaPequena ? 8.0 : 12.0;

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
            SizedBox(width: espaciadoEtiquetaValor),
            SizedBox(
              width: anchoColumnaValores,
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

    if (_mostrarFormularioCredito && _estadoPasoCredito != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: paddingLateral, vertical: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _cerrarFormularioCredito,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                FormularioCreditoVista(
                  estadoVenta: _estadoPasoCredito!,
                  onVolver: _cerrarFormularioCredito,
                  onConfirmado: _confirmarCredito,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
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
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: esPantallaPequena ? anchoPantalla * 0.75 : 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: _buscarController,
                        hint: 'Buscar producto, código o escanear...',
                        prefixIcon: Icons.search,
                        onChanged: (texto) => ref.read(registrarVentaProvider.notifier).buscarProducto(texto),
                      ),
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
                                subtitle: Text(_formatearMonto(prod.precioUnitario)),
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
                  SizedBox(width: espaciadoCliente),
                  Expanded(
                    child: Text(
                      nombreCliente,
                      style: AppTypography.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: espaciadoBotonesCliente),
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
                Padding(
                  padding: EdgeInsets.symmetric(vertical: paddingVacioVertical),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.point_of_sale_outlined,
                        size: tamanoIconoVacio,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        modo == ModoOperacion.apartado ? 'El apartado está vacío' : 'La venta está vacía',
                        style: esPantallaPequena
                            ? AppTypography.labelMedium
                            : AppTypography.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Busca un producto para comenzar',
                        style: esPantallaPequena
                            ? AppTypography.labelSmall
                            : AppTypography.bodyMedium,
                      ),
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
                      if (estado.costoEnvio > 0)
                        filaTotal('Envío / Delivery:', _formatearMonto(estado.costoEnvio)),
                      if (!esConsumidorFinal) ...[
                        filaTotal('Subtotal:', _formatearMonto(estado.subtotal)),
                        if (descuentoPorLinea > 0.001)
                          filaTotal(
                            'Descuento por línea:',
                            '- ${_formatearMonto(descuentoPorLinea)}',
                            colorTexto: Colors.red.shade700,
                          ),
                        if (tieneDescuentoGeneral)
                          filaTotal(
                            'Descuento general:',
                            '- ${_formatearMonto(estado.montoDescuento)}',
                            colorTexto: Colors.red.shade700,
                          ),
                        filaTotal('Base Gravable:', _formatearMonto(baseGravable)),
                        filaTotal('ITBIS (18%):', _formatearMonto(estado.itbis)),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: esPantallaPequena ? 16 : 24,
                        vertical: esPantallaPequena ? 12 : 16,
                      ),
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: Size(0, esPantallaPequena ? 60 : 72),
                    ),
                    onPressed: tieneProductos && !_guardando ? _cobrar : null,
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tieneProductos
                                    ? (modo == ModoOperacion.apartado ? 'RESERVAR' : 'COBRAR')
                                    : 'AGREGUE PRODUCTOS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: esPantallaPequena ? 12 : 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                montoTotal,
                                style: TextStyle(
                                  fontSize: fontSizeMontoBoton,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
