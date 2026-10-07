import 'package:fiscogest_rd/features/impuestos/presentation/providers/impuesto_providers.dart';
import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/consulta_stock_lectura_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_access_grid.dart';
import 'package:fiscogest_rd/core/ui/app_hub_card.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
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
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';

class VistaInicioVacia extends ConsumerStatefulWidget {
  const VistaInicioVacia({super.key});

  @override
  ConsumerState<VistaInicioVacia> createState() => _VistaInicioVaciaState();
}

class _VistaInicioVaciaState extends ConsumerState<VistaInicioVacia> {
  String _formatearMonto(double valor) => formatRd(valor);

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
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(
      context,
    );
    if (cliente != null && mounted) {
      ref
          .read(registrarVentaProvider.notifier)
          .seleccionarCliente(cliente.id ?? 0, cliente.nombre);
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
      ref
          .read(registrarVentaProvider.notifier)
          .establecerCondicionesCredito(abonoRecibido, fechaVence);
      final estadoConCredito = ref.read(registrarVentaProvider);
      final modo = ref.read(ventasNavegacionProvider).modoOperacion;

      if (modo == ModoOperacion.apartado) {
        await ref
            .read(apartadoNotifierProvider.notifier)
            .crearApartadoDesdeVenta(estadoConCredito);
      } else {
        final ventaGuardada = await ref
            .read(registrarVentaUseCaseProvider)
            .ejecutar(estadoConCredito);
        if (!mounted) return;
        if (ventaGuardada.id == null) {
          throw Exception('El repositorio no devolvió ID de venta');
        }
      }

      final saldoPendiente = estadoConCredito.total - abonoRecibido;
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(
              modo == ModoOperacion.apartado
                  ? 'Apartado registrado — Crédito vinculado.\nAbono inicial: ${_formatearMonto(abonoRecibido)}\nSaldo pendiente: ${_formatearMonto(saldoPendiente)}\nVence: ${DateFormat('dd/MM/yyyy').format(fechaVence)}'
                  : 'Venta registrada.\nAbono inicial: ${_formatearMonto(abonoRecibido)}\nSaldo pendiente: ${_formatearMonto(saldoPendiente)}\nVence: ${DateFormat('dd/MM/yyyy').format(fechaVence)}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('Error crédito: $e\n$stackTrace');
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _reservarApartado() async {
    final estado = ref.read(registrarVentaProvider);
    final valido = ref
        .read(registrarVentaProvider.notifier)
        .validarAntesDeGuardar();

    if (!valido) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('Agregue productos y seleccione forma de pago'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    const formasPago = [
      'Efectivo',
      'Tarjeta',
      'Crédito',
      'Transferencia',
      'Cheque',
    ];
    final formaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Forma de Reserva',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${_formatearMonto(estado.total)}',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 16),
            ...formasPago.map(
              (forma) => ListTile(
                title: Text(forma),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () => Navigator.pop(context, forma.toLowerCase()),
              ),
            ),
          ],
        ),
      ),
    );

    if (formaSeleccionada == null || !mounted) return;

    ref
        .read(registrarVentaProvider.notifier)
        .cambiarFormaPago(formaSeleccionada);
    final estadoFinal = ref.read(registrarVentaProvider);

    if (formaSeleccionada == 'crédito') {
      setState(() {
        _mostrarFormularioCredito = true;
        _estadoPasoCredito = estadoFinal;
      });
      return;
    }

    final idApartado = await ref
        .read(apartadoNotifierProvider.notifier)
        .crearApartadoDesdeVenta(estadoFinal);
    if (mounted) {
      ref.read(registrarVentaProvider.notifier).vaciarVenta();
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Apartado #$idApartado registrado — Stock reservado — ${_formatearMonto(estadoFinal.total)}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double _calcularDescuentoPorLinea(RegistrarVentaState estado) {
    double totalDesc = 0.0;
    for (final linea in estado.detalles) {
      final precioConCantidad = linea.subtotalLinea ?? linea.subtotal;
      double despuesDesc = precioConCantidad;
      if (linea.descuentoPorcentaje > 0) {
        despuesDesc =
            precioConCantidad * (100 - linea.descuentoPorcentaje) / 100;
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
    final modo = ref.watch(
      ventasNavegacionProvider.select((e) => e.modoOperacion),
    );
    final estado = ref.watch(registrarVentaProvider);
    final esConsumidorFinal =
        estado.clienteId == 0 || estado.clienteNombre == 'Consumidor Final';
    final isMobile = AppBreakpoints.isMobile(context);
    final esApartado = modo == ModoOperacion.apartado;

    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';
    final tieneProductos = estado.detalles.isNotEmpty;
    final tieneResultados = estado.resultadosBusqueda.isNotEmpty;
    final montoTotal = _formatearMonto(estado.total);
    final tieneDescuentoGeneral = estado.montoDescuento > 0;
    final descuentoPorLinea = _calcularDescuentoPorLinea(estado);
    final subtotalConDescuentoLinea = estado.subtotal - descuentoPorLinea;
    final baseGravable = (subtotalConDescuentoLinea - estado.montoDescuento)
        .clamp(0.0, double.infinity);

    if (_mostrarFormularioCredito && _estadoPasoCredito != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 16,
            ),
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
                const SizedBox(height: 12),
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
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── SI NO ES APARTADO → entrada a Cotización (único POS) ───
              if (!esApartado) ...[
                _buildEntradaCotizacion(isMobile),
              ] else ...[
                // ─── FLUJO APARTADO (sin cambios de lógica) ───
                AppTextField(
                  controller: _buscarController,
                  hint: 'Buscar producto, código o escanear...',
                  prefixIcon: Icons.search,
                  onChanged: (texto) => ref
                      .read(registrarVentaProvider.notifier)
                      .buscarProducto(texto),
                ),

                if (tieneResultados)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppRadius.allM,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: estado.resultadosBusqueda.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) {
                        final prod = estado.resultadosBusqueda[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            prod.nombreProducto ?? 'Producto',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            _formatearMonto(prod.precioUnitario),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          onTap: () => _seleccionarProducto(prod),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.allM,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 20,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nombreCliente,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _guardando ? null : _cambiarCliente,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (!tieneProductos)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 56),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.allL,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: isMobile ? 48 : 56,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'El apartado está vacío',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Busca un producto para comenzar',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const PanelCarrito(),

                const SizedBox(height: 24),

                if (tieneProductos)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (estado.costoEnvio > 0)
                          _FilaResumen(
                            label: 'Envío / Delivery',
                            value: _formatearMonto(estado.costoEnvio),
                          ),
                        if (!esConsumidorFinal) ...[
                          _FilaResumen(
                            label: 'Subtotal',
                            value: _formatearMonto(estado.subtotal),
                          ),
                          if (descuentoPorLinea > 0.001)
                            _FilaResumen(
                              label: 'Descuento por línea',
                              value: '- ${_formatearMonto(descuentoPorLinea)}',
                              color: AppColors.error,
                            ),
                          if (tieneDescuentoGeneral)
                            _FilaResumen(
                              label: 'Descuento general',
                              value:
                                  '- ${_formatearMonto(estado.montoDescuento)}',
                              color: AppColors.error,
                            ),
                          _FilaResumen(
                            label: 'Base Gravable',
                            value: _formatearMonto(baseGravable),
                          ),
                          if (!(ref
                                  .watch(configuracionControllerProvider)
                                  .valueOrNull
                                  ?.modoSimplificado ??
                              false))
                            _FilaResumen(
                              label: etiquetaItbis(ref.watch(tasaItbisVigenteProvider)),
                              value: _formatearMonto(estado.itbis),
                            ),
                        ],
                        const SizedBox(height: 8),
                        _FilaResumen(
                          label: 'TOTAL',
                          value: montoTotal,
                          destacado: true,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: isMobile ? double.infinity : 280,
                    height: isMobile ? 56 : 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppColors.grey300,
                      ),
                      onPressed: tieneProductos && !_guardando
                          ? _reservarApartado
                          : null,
                      child: _guardando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tieneProductos
                                      ? 'RESERVAR'
                                      : 'AGREGUE PRODUCTOS',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                if (tieneProductos) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    montoTotal,
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hub POS: modo normal (cotizar / crédito) o colmado (vender / fiao).
  Widget _buildEntradaCotizacion(bool isMobile) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = !isMobile && width >= 900;
    final simplificado = ref.watch(modoColmadoProvider);

    void irNuevaCotizacion() => context.push('/ventas/cotizaciones/nueva');
    void irHistorial() {
      ref
          .read(ventasNavegacionProvider.notifier)
          .cambiarVista(VistaActual.historial);
    }

    void irSimuladorCredito() {
      context.push('/ventas/simulador-credito');
    }

    void consultarStock() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const ConsultaStockLecturaSheet(),
      );
    }

    final cta = _PosCtaCard(
      isMobile: isMobile,
      simplificado: simplificado,
      onTap: irNuevaCotizacion,
    );

    final atajos = AppAccessGrid(
      minTileWidth: isMobile ? 150 : 180,
      maxColumns: 2,
      mobileColumns: 2,
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      tileHeight: isMobile ? 72 : 168,
      children: [
        if (isMobile)
          AppHubCard(
            icon: Icons.history_rounded,
            title: 'Historial',
            subtitle: simplificado ? 'Ventas del día' : 'Cotizaciones y ventas',
            color: AppColors.info,
            onTap: irHistorial,
          ),
        AppHubCard(
          icon: Icons.inventory_2_outlined,
          title: 'Consultar stock',
          subtitle: isMobile ? 'Solo lectura' : 'Solo lectura, sin salir',
          color: AppColors.primary,
          onTap: consultarStock,
        ),
        if (!simplificado)
          AppHubCard(
            icon: Icons.calculate_outlined,
            title: 'Simular crédito',
            subtitle: isMobile
                ? 'Montos y cuotas'
                : 'Montos y cuotas oficiales',
            color: AppColors.warning,
            onTap: irSimuladorCredito,
          ),
        if (simplificado)
          AppHubCard(
            icon: Icons.edit_note_rounded,
            title: 'Fiao',
            subtitle: isMobile ? 'Lo que me deben' : 'Pendientes y abonos',
            color: AppColors.warning,
            onTap: () => context.push('/ventas/fios'),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: cta),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _PosContextoCard(
                    onHistorial: irHistorial,
                    isMobile: false,
                    simplificado: simplificado,
                  ),
                ),
              ],
            )
          else ...[
            cta,
            if (!isMobile) ...[
              const SizedBox(height: 14),
              _PosContextoCard(
                onHistorial: irHistorial,
                simplificado: simplificado,
              ),
            ],
          ],
          SizedBox(height: isMobile ? 14 : 22),
          Text(
            simplificado ? 'Accesos rápidos' : 'Accesos del vendedor',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 15 : null,
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(height: 4),
            Text(
              simplificado
                  ? 'Venda al contado o fiao. Consulte stock sin salir. Historial arriba.'
                  : 'Stock en solo lectura y simulación de crédito. Historial en la tarjeta superior.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: isMobile ? 8 : 14),
          atajos,
          SizedBox(height: isMobile ? 14 : 22),
          if (!simplificado) ...[
            Text(
              'Flujo del vendedor',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 15 : null,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 10),
            _PosFlujoBanner(isMobile: isMobile),
            SizedBox(height: isMobile ? 8 : 12),
          ],
        ],
      ),
    );
  }
}

/// CTA principal del POS — máxima jerarquía visual.
class _PosCtaCard extends StatelessWidget {
  const _PosCtaCard({
    required this.isMobile,
    required this.onTap,
    this.simplificado = false,
  });
  final bool isMobile;
  final bool simplificado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.primaryLight.withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: isMobile ? 10 : 20,
                offset: Offset(0, isMobile ? 4 : 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 28,
              vertical: isMobile ? 22 : 28,
            ),
            child: Row(
              children: [
                Container(
                  width: isMobile ? 56 : 64,
                  height: isMobile ? 56 : 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                  ),
                  child: Icon(
                    simplificado
                        ? Icons.point_of_sale_rounded
                        : Icons.request_quote_rounded,
                    color: Colors.white,
                    size: isMobile ? 30 : 34,
                  ),
                ),
                SizedBox(width: isMobile ? 16 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        simplificado ? 'Vender' : 'Nueva cotización',
                        style: (isMobile ? AppTypography.h4 : AppTypography.h3)
                            .copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isMobile ? 18 : null,
                            ),
                      ),
                      SizedBox(height: isMobile ? 4 : 4),
                      Text(
                        simplificado
                            ? (isMobile
                                ? 'Productos → Contado o Fiao'
                                : 'Arme el pedido y cobre: contado o fiao')
                            : (isMobile
                                ? 'Arme el pedido y envíe a Caja'
                                : 'Arme el pedido, aplique crédito si aplica y envíe a Caja'),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.3,
                          fontSize: isMobile ? 13 : null,
                        ),
                        maxLines: isMobile ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: isMobile ? 26 : 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contexto / recordatorio de estación (sin depender aún de KPIs live).
class _PosContextoCard extends StatelessWidget {
  const _PosContextoCard({
    required this.onHistorial,
    this.isMobile = false,
    this.simplificado = false,
  });
  final VoidCallback onHistorial;
  final bool isMobile;
  final bool simplificado;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onHistorial,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 18,
            vertical: isMobile ? 10 : 18,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: isMobile ? 6 : 12,
                offset: Offset(0, isMobile ? 2 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: AppColors.info,
                  size: isMobile ? 18 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: isMobile ? 14 : null,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 4),
                      Text(
                        simplificado
                            ? 'Ventas y pedidos recientes.'
                            : 'Cotizaciones y ventas del vendedor.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.75),
                          height: 1.35,
                        ),
                      ),
                    ] else ...[
                      Text(
                        simplificado
                            ? 'Ventas recientes'
                            : 'Cotizaciones y ventas',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                size: isMobile ? 18 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosFlujoBanner extends StatelessWidget {
  const _PosFlujoBanner({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final pasos = <(IconData, String)>[
      (Icons.edit_note_rounded, 'Cotizar'),
      (Icons.inventory_2_outlined, 'Ver stock'),
      (Icons.calculate_outlined, 'Simular cuotas'),
      (Icons.outgoing_mail, 'Enviar a cobro'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 18,
        vertical: isMobile ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: isMobile
          ? Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < pasos.length; i++) ...[
                  _paso(pasos[i].$1, pasos[i].$2, compact: true),
                  if (i < pasos.length - 1)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                ],
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < pasos.length; i++) ...[
                  Expanded(child: _paso(pasos[i].$1, pasos[i].$2)),
                  if (i < pasos.length - 1)
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _paso(IconData icon, String label, {bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: compact ? 16 : 20, color: AppColors.primary),
        SizedBox(width: compact ? 4 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.label,
    required this.value,
    this.destacado = false,
    this.color,
  });
  final String label;
  final String value;
  final bool destacado;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textSecondary,
              fontSize: destacado ? 15 : 13.5,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 130,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.textPrimary,
                fontSize: destacado ? 16 : 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
