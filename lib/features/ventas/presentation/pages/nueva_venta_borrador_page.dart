import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_dao.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/consulta_stock_lectura_sheet.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_delivery.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/sheet_contado_fiao.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/sheet_anotar_fiao.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';


/// Usuarios activos para el dropdown Vendedor del POS.
final posUsuariosVentaProvider =
    FutureProvider.autoDispose<List<UsuarioData>>((ref) async {
  final db = ref.watch(databaseProvider);
  final todos = await UsuariosDao(db).obtenerTodos();
  return todos
      .where((u) => u.estado.toLowerCase() != 'inactivo')
      .toList();
});

class NuevaVentaBorradorPage extends ConsumerStatefulWidget {
  const NuevaVentaBorradorPage({super.key});
  static const String routeName = '/ventas/cotizaciones/nueva';

  @override
  ConsumerState<NuevaVentaBorradorPage> createState() =>
      _NuevaVentaBorradorPageState();
}

class _NuevaVentaBorradorPageState
    extends ConsumerState<NuevaVentaBorradorPage> {
  final TextEditingController _buscadorController = TextEditingController();
  DateTime? _fechaVencimientoSeleccionada;
  bool _esCredito = false;
  bool _modoFormularioCredito = false;
  RegistrarVentaState? _estadoFormularioCredito;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ventaBorradorProvider.notifier).establecerConsumidorFinal();
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _agregarProductoACotizacion(
    Producto producto,
    double cantidad,
  ) async {
    ref
        .read(ventaBorradorProvider.notifier)
        .agregarProducto(producto, cantidad);
    if (mounted) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('${producto.nombre} agregado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _seleccionarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(
      context,
    );
    if (cliente != null && mounted) {
      ref
          .read(ventaBorradorProvider.notifier)
          .seleccionarCliente(
            cliente.id ?? 0,
            cliente.nombre,
            telefono: cliente.telefono,
            direccion: cliente.direccion,
          );
    }
  }

  Future<void> _seleccionarVencimiento() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 30)),
      firstDate: hoy.add(const Duration(days: 1)),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() => _fechaVencimientoSeleccionada = fecha);
      ref.read(ventaBorradorProvider.notifier).establecerVencimiento(fecha);
    }
  }

  Future<void> _abrirDelivery() async {
    final costoActual = ref.read(ventaBorradorProvider).costoEnvio;
    await showDialog<void>(
      context: context,
      builder: (ctx) => SelectorDeliveryDialog(
        costoActual: costoActual,
        onAsignarCosto: (monto) {
          ref.read(ventaBorradorProvider.notifier).asignarCostoEnvio(monto);
        },
      ),
    );
  }

  void _limpiarFormulario() {
    ref.read(ventaBorradorProvider.notifier).vaciar();
    ref.read(ventaBorradorProvider.notifier).establecerConsumidorFinal();
    _buscadorController.clear();
    if (mounted) {
      setState(() {
        _fechaVencimientoSeleccionada = null;
        _esCredito = false;
        _guardando = false;
      });
    }
  }

  void _cambiarEsCredito(bool valor) {
    setState(() => _esCredito = valor);
    ref
        .read(ventaBorradorProvider.notifier)
        .establecerFormaPago(esCredito: valor);
  }

  RegistrarVentaState _mapearBorradorARegistrarVenta(
    VentaBorradorState estado,
  ) {
    final detalles = estado.detalles.map((m) {
      final cant = (m['cantidad'] as num?)?.toDouble() ?? 0.0;
      final precio = (m['precioUnitario'] as num?)?.toDouble() ?? 0.0;
      final sub = (m['subtotal'] as num?)?.toDouble() ?? (cant * precio);
      final pid = m['productoId'];
      final productoId = pid is int ? pid : int.tryParse('$pid') ?? 0;
      return DetalleVenta(
        productoId: productoId,
        cantidad: cant.round().clamp(1, 999999),
        precioUnitario: precio,
        subtotal: sub,
        nombreProducto: m['productoNombre'] as String?,
        subtotalLinea: sub,
      );
    }).toList();
    return RegistrarVentaState(
      clienteId: estado.clienteId,
      clienteNombre: estado.clienteNombre,
      tipoPago: estado.esCredito ? 'Crédito' : estado.tipoPago,
      esCredito: estado.esCredito,
      detalles: detalles,
      subtotal: estado.subtotal,
      itbis: estado.itbis,
      costoEnvio: estado.costoEnvio,
      total: estado.montoTotal,
      montoDescuento: estado.montoDescuento,
      descuentoId: estado.descuentoId,
      descuentoNombre: estado.descuentoNombre,
      vencimiento: estado.vencimiento,
    );
  }

  Future<void> _onGenerarVentaSimplificada() async {
    final estado = ref.read(ventaBorradorProvider);
    if (estado.detalles.isEmpty || estado.montoTotal <= 0) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Agregue productos antes de generar la venta'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final totalTexto = formatRd(estado.montoTotal);
    final nombre = (estado.clienteNombre ?? '').trim();

    final resultado = await SheetContadoFiao.show(
      context,
      totalTexto: totalTexto,
      nombreCliente: nombre.isEmpty ? null : nombre,
    );

    if (!mounted || resultado == null) return;

    switch (resultado) {
      case ResultadoCobro.contado:
        await _guardarCotizacion(esCredito: false, abrirCobro: true);
        break;
      case ResultadoCobro.fiao:
        final ok = await SheetAnotarFiao.show(
          context,
          total: estado.montoTotal,
          nombreInicial: nombre.isEmpty ? null : nombre,
        );
        if (!mounted) return;
        if (ok == true) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text('Fiao anotado: ${formatRd(estado.montoTotal)}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _limpiarFormulario();
        }
        break;
    }
  }

  Future<void> _guardarCotizacion({
    required bool esCredito,
    bool abrirCobro = false,
  }) async {
    setState(() => _guardando = true);
    try {
      final notificador = ref.read(ventaBorradorProvider.notifier);
      final repositorio = ref.read(ventasRepositoryProvider);
      notificador.establecerFormaPago(esCredito: esCredito);
      setState(() => _esCredito = esCredito);

      const double abonoDesdeFormulario = 0.0;

      // Crédito → mismo formulario que Apartado (antes de guardar)
      if (esCredito) {
        final estadoBorrador = ref.read(ventaBorradorProvider);
        if (estadoBorrador.detalles.isEmpty || estadoBorrador.montoTotal <= 0) {
          if (mounted) {
            FiscoGestNotifications.show(
              const SnackBar(
                content: Text(
                  'Agregue productos antes de generar la cotización',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        final estadoParaCredito = _mapearBorradorARegistrarVenta(
          estadoBorrador,
        );
        if (!mounted) return;
        // Embebido (mismo patrón que Apartado / depto. Crédito)
        setState(() {
          _estadoFormularioCredito = estadoParaCredito;
          _modoFormularioCredito = true;
          _guardando = false;
        });
        return;
      }

      final cfgNum = ref.read(configuracionControllerProvider).valueOrNull;
      final numeroCotizacion = await repositorio.siguienteNumeroCotizacion(
        esCredito: esCredito,
        prefijoContado: cfgNum?.prefijoContado ?? 'C',
        prefijoCredito: cfgNum?.prefijoCredito ?? 'CR',
      );
      notificador.establecerNumeroCotizacion(numeroCotizacion);
      // Contado → cotizado (listo para Caja)
      // Crédito → enCredito (pendiente de aprobación)
      notificador.establecerEstadoDocumento(
        esCredito ? EstadoDocumento.enCredito : EstadoDocumento.cotizado,
      );
      final numeroGuardado = await notificador.guardar();
      if (numeroGuardado == null) {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Agregue productos antes de generar la cotización'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Si hay id y abono de crédito, actualizar abonoInicial en BD
      final idGuardado = ref.read(ventaBorradorProvider).id;
      if (_esCredito && idGuardado != null && abonoDesdeFormulario > 0) {
        await repositorio.registrarVentaConAbono(
          idGuardado,
          abonoDesdeFormulario,
          'Abono inicial cotización crédito',
          formaPago: 'Credito',
        );
        // registrarVentaConAbono facturaba: solo queremos abono en cotización.
        // Revertimos a enCredito sin factura si el método facturó.
        await repositorio.cambiarEstadoDocumento(
          idGuardado,
          EstadoDocumento.enCredito,
        );
      }

      if (!mounted) return;

      // Modo simplificado Contado: abrir cobro en la misma secuencia
      if (abrirCobro && !esCredito) {
        final estadoFinal = ref.read(ventaBorradorProvider);
        final ventaId = estadoFinal.id;
        final montoTotal = estadoFinal.montoTotal;
        final numeroCot = estadoFinal.numero.trim().isNotEmpty
            ? estadoFinal.numero
            : numeroGuardado;
        final nombreCli = estadoFinal.clienteNombre;
        ref.invalidate(listaCotizacionesProvider);
      ref.invalidate(listaVentasProvider);
        _limpiarFormulario();
        if (ventaId != null && mounted) {
          // Caja unificada (no CobroVentaPage)
          context.go(
            '/ventas/cobro',
            extra: <String, dynamic>{
              'ventaId': ventaId,
              'montoTotal': montoTotal,
              'esCredito': false,
              'numeroCotizacion': numeroCot,
              'nombreCliente': nombreCli,
            },
          );
        }
        return;
      }

      final mensaje = _esCredito
          ? 'Cotización N° $numeroGuardado en crédito.\n'
                'Abono: ${formatRd(abonoDesdeFormulario)}\n'
                'Pendiente de aprobación → luego Caja.'
          : 'Cotización N° $numeroGuardado generada.\n'
                'Lista para cobrar en Caja.';
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      ref.invalidate(listaCotizacionesProvider);
      ref.invalidate(listaVentasProvider);
      _limpiarFormulario();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al generar cotización: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _cerrarFormularioCredito() {
    setState(() {
      _modoFormularioCredito = false;
      _estadoFormularioCredito = null;
    });
  }

  /// Tras CONFIRMAR en FormularioCreditoVista: guarda cotización crédito.
  Future<void> _onCreditoConfirmado(
    ResultadoFormularioCredito resultado,
  ) async {
    setState(() {
      _modoFormularioCredito = false;
      _estadoFormularioCredito = null;
      _guardando = true;
    });
    final abonoDesdeFormulario = resultado.abonoInicial?.monto ?? 0.0;
    final vencimientoCredito = resultado.cuenta.fechaVencimiento;
    try {
      final notificador = ref.read(ventaBorradorProvider.notifier);
      final repositorio = ref.read(ventasRepositoryProvider);
      notificador.establecerFormaPago(esCredito: true);
      notificador.establecerVencimiento(vencimientoCredito);

      final cfgNum = ref.read(configuracionControllerProvider).valueOrNull;
      final numeroCotizacion = await repositorio.siguienteNumeroCotizacion(
        esCredito: true,
        prefijoContado: cfgNum?.prefijoContado ?? 'C',
        prefijoCredito: cfgNum?.prefijoCredito ?? 'CR',
      );
      notificador.establecerNumeroCotizacion(numeroCotizacion);
      notificador.establecerEstadoDocumento(EstadoDocumento.enCredito);

      final numeroGuardado = await notificador.guardar();
      if (numeroGuardado == null) {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Agregue productos antes de generar la cotización'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final idGuardado = ref.read(ventaBorradorProvider).id;
      if (idGuardado != null) {
        final c = resultado.cuenta;
        await repositorio.actualizarCondicionesCredito(
          ventaId: idGuardado,
          abonoInicial: c.abonoInicial,
          numeroCuotas: c.numeroCuotas,
          plazoDias: c.plazoDias,
          tasaInteres: c.tasaInteres,
          montoInteres: c.montoInteres,
        );
        await repositorio.cambiarEstadoDocumento(
          idGuardado,
          EstadoDocumento.enCredito,
        );
      }

      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Cotización N° $numeroGuardado en crédito.\n'
            'Abono: ${formatRd(abonoDesdeFormulario)}\n'
            'Pendiente de aprobación → luego Caja.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      ref.invalidate(listaCotizacionesProvider);
      ref.invalidate(listaVentasProvider);
      _limpiarFormulario();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al generar cotización: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(ventaBorradorProvider);
    final puedeGenerar = estado.detalles.isNotEmpty && estado.montoTotal > 0;
    final esPantallaPequena = MediaQuery.of(context).size.width < 600;
    final esPantallaAncha = MediaQuery.of(context).size.width >= 720;

    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'NUEVA COTIZACIÓN',
      showAppBar: !desktop,
      // En desktop la entrada es directa: atrás → Dashboard
      leading: desktop
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Atrás',
              onPressed: () => safeBack(context, fallback: '/inicio'),
            ),
      body: SafeArea(
        bottom: true,
        maintainBottomViewPadding: true,
        child: _modoFormularioCredito && _estadoFormularioCredito != null
            ? Container(
                padding: AppSpacing.allM,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.allL,
                  border: Border.all(color: AppColors.border),
                ),
                child: FormularioCreditoVista(
                  estadoVenta: _estadoFormularioCredito!,
                  onVolver: _cerrarFormularioCredito,
                  onConfirmado: _onCreditoConfirmado,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: esPantallaAncha
                        ? _buildDosColumnas(
                            estado,
                            puedeGenerar,
                            esPantallaPequena,
                          )
                        : _buildUnaColumna(
                            estado,
                            puedeGenerar,
                            esPantallaPequena,
                          ),
                  ),
                  _buildBarraFijaPos(estado, puedeGenerar, esPantallaPequena),
                ],
              ),
      ),
    );
  }

  Widget _buildUnaColumna(
    VentaBorradorState estado,
    bool puedeGenerar,
    bool esPantallaPequena,
  ) {
    final padding = esPantallaPequena ? 12.0 : 16.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esPantallaPequena) ...[
            _buildAccesosSecundarios(),
            const SizedBox(height: 12),
          ],
          _buildSeccionTipoYVencimiento(esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildSeccionCliente(estado, esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildSeccionDelivery(estado, esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildSeccionProductos(esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildListaItemsCarrito(estado, esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildSeccionResumen(estado, esPantallaPequena),
          const SizedBox(height: 8),
          _buildEnlaceHistorial(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDosColumnas(
    VentaBorradorState estado,
    bool puedeGenerar,
    bool esPantallaPequena,
  ) {
    // Layout enterprise 3 columnas (guía POS):
    // Izq: configuración · Centro: carrito tabla · Der: cierre
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── IZQUIERDA: Configuración de venta (estilo guía) ──
          SizedBox(
            width: 250,
            child: _posCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Configuración de venta',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Contado / Crédito
                  _buildPosTipoPagoYVence(),
                  const SizedBox(height: 14),
                  // Cliente (recuadro)
                  const Text(
                    'Cliente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Material(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: _seleccionarCliente,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              (estado.clienteNombre ?? '').trim().isEmpty
                                  ? 'Consumidor Final (default)'
                                  : estado.clienteNombre!.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if ((estado.clienteId ?? 0) > 0)
                              FutureBuilder(
                                future: ref
                                    .read(clienteRepositoryProvider)
                                    .obtenerClientePorId(estado.clienteId!),
                                builder: (context, snap) {
                                  final c = snap.data;
                                  if (c == null || c.limiteCuotaMensual <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Límite cuota RD\$ ${c.limiteCuotaMensual.toStringAsFixed(0)}'
                                      '${c.saldoPendiente > 0 ? ' · Saldo RD\$ ${c.saldoPendiente.toStringAsFixed(0)}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      (estado.clienteTelefono ?? '')
                                              .trim()
                                              .isNotEmpty
                                          ? estado.clienteTelefono!.trim()
                                          : 'Cédula / RNC',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: (estado.clienteTelefono ?? '')
                                                .trim()
                                                .isNotEmpty
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _seleccionarCliente,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F766E),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Cambiar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Vendedor (conectado a usuarios del sistema)
                  const Text(
                    'Vendedor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildPosVendedorDropdown(estado),
                  const SizedBox(height: 14),
                  // Dirección
                  const Text(
                    'Dirección',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 72),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      (estado.clienteDireccion ?? '').trim().isEmpty
                          ? 'Sin dirección registrada'
                          : estado.clienteDireccion!.trim(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (estado.clienteDireccion ?? '').trim().isEmpty
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _posMiniChip(
                        Icons.request_quote_outlined,
                        'Cotiz.',
                        () => context.push('/ventas/cotizaciones/historial'),
                      ),
                      _posMiniChip(
                        Icons.receipt_long_outlined,
                        'Ventas',
                        () => context.push('/ventas/historial'),
                      ),
                      _posMiniChip(
                        Icons.inventory_2_outlined,
                        'Stock',
                        () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ConsultaStockLecturaSheet(),
                          );
                        },
                      ),
                      _posMiniChip(
                        Icons.calculate_outlined,
                        'Simular',
                        () => context.push('/ventas/simulador-credito'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── CENTRO: Carrito de compra (tabla) ──
          Expanded(
            child: _posCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Carrito de compra',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${estado.detalles.length} ítem(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tabla: ancho mínimo + scroll horizontal → todas las columnas visibles
                  // Tabla alineada: header y filas con los MISMOS anchos (Table)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Anchos compartidos (header = filas)
                        // Producto flex | Cant 64 | P.Unit 80 | Desc 48 | ITBIS 76 | Total 84 | Acc 28
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FixedColumnWidth(64),
                              2: FixedColumnWidth(80),
                              3: FixedColumnWidth(48),
                              4: FixedColumnWidth(76),
                              5: FixedColumnWidth(84),
                              6: FixedColumnWidth(28),
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: const [
                              TableRow(
                                children: [
                                  Text('Producto', maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('Cant.', textAlign: TextAlign.center, maxLines: 1,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('P.Unit.', textAlign: TextAlign.center, maxLines: 1,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('Desc.%', textAlign: TextAlign.center, maxLines: 1,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('ITBIS', textAlign: TextAlign.center, maxLines: 1,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                  Text('Total', textAlign: TextAlign.center, maxLines: 1,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                                  SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: estado.detalles.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Carrito vacío — busque un producto abajo',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: estado.detalles.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  itemBuilder: (context, i) {
                                    final item = estado.detalles[i];
                                    final nombre =
                                        (item['productoNombre'] as String?)?.trim().isNotEmpty == true
                                            ? (item['productoNombre'] as String).trim()
                                            : 'Producto';
                                    final cant = (item['cantidad'] as num?)?.toDouble() ?? 0.0;
                                    final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                                    final descM = (item['montoDescuento'] as num?)?.toDouble() ?? 0.0;
                                    final descP = (item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0;
                                    final sub = (item['subtotal'] as num?)?.toDouble() ?? (cant * precio);
                                    final tasa = (item['tasaImpuesto'] as num?)?.toDouble() ?? 0.0;
                                    final itbisLinea = sub * (tasa > 1 ? tasa / 100.0 : tasa);
                                    final productoId = item['productoId'] is int
                                        ? item['productoId'] as int
                                        : int.tryParse('${item['productoId'] ?? ''}');
                                    final tieneDesc = descP > 0 || descM > 0;
                                    final cantLabel = cant % 1 == 0
                                        ? cant.toInt().toString()
                                        : cant.toStringAsFixed(2);
                                    final String descLabel;
                                    if (descP > 0) {
                                      descLabel = '${descP.toStringAsFixed(0)}%';
                                    } else if (descM > 0 && (cant * precio) > 0) {
                                      descLabel = '${((descM / (cant * precio)) * 100).toStringAsFixed(0)}%';
                                    } else {
                                      descLabel = '0%';
                                    }
                                    final bg = i.isEven ? Colors.white : const Color(0xFFF8FAFC);

                                    return Container(
                                      color: bg,
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      child: Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(3),
                                          1: FixedColumnWidth(64),
                                          2: FixedColumnWidth(80),
                                          3: FixedColumnWidth(48),
                                          4: FixedColumnWidth(76),
                                          5: FixedColumnWidth(84),
                                          6: FixedColumnWidth(28),
                                        },
                                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                        children: [
                                          TableRow(
                                            children: [
                                              Text(
                                                nombre,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0F172A),
                                                  height: 1.2,
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (productoId != null)
                                                    InkWell(
                                                      onTap: () {
                                                        final n = cant <= 1
                                                            ? (cant > 0.001 ? cant - 0.5 : 0.0)
                                                            : cant - 1;
                                                        ref.read(ventaBorradorProvider.notifier).cambiarCantidad(
                                                              productoId,
                                                              n < 0.001 ? 0.0 : n,
                                                            );
                                                      },
                                                      child: const Icon(Icons.remove, size: 13, color: Color(0xFF64748B)),
                                                    ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                                    child: Text(
                                                      cantLabel,
                                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                                                    ),
                                                  ),
                                                  if (productoId != null)
                                                    InkWell(
                                                      onTap: () {
                                                        ref.read(ventaBorradorProvider.notifier).cambiarCantidad(
                                                              productoId,
                                                              cant + 1,
                                                            );
                                                      },
                                                      child: const Icon(Icons.add, size: 13, color: Color(0xFF0F766E)),
                                                    ),
                                                ],
                                              ),
                                              Text(
                                                formatRd(precio),
                                                textAlign: TextAlign.right,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                              ),
                                              InkWell(
                                                onTap: productoId == null
                                                    ? null
                                                    : () => _abrirDescuentoLineaCotizacion(
                                                          context,
                                                          ref,
                                                          productoId,
                                                          item,
                                                        ),
                                                child: Text(
                                                  descLabel,
                                                  textAlign: TextAlign.right,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: tieneDesc
                                                        ? const Color(0xFF059669)
                                                        : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                formatRd(itbisLinea),
                                                textAlign: TextAlign.right,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                              Text(
                                                formatRd(sub),
                                                textAlign: TextAlign.right,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              productoId == null
                                                  ? const SizedBox.shrink()
                                                  : InkWell(
                                                      onTap: () {
                                                        ref.read(ventaBorradorProvider.notifier).quitarProducto(productoId);
                                                      },
                                                      child: const Icon(
                                                        Icons.delete_outline,
                                                        size: 17,
                                                        color: Color(0xFFDC2626),
                                                      ),
                                                    ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
// Total línea carrito
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF475569))),
                        const Spacer(),
                        Text(formatRd(estado.montoTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Buscador de productos (abajo, como la guía)
                  PanelProductos(alAgregar: _agregarProductoACotizacion),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── DERECHA: Cierre de operación ──
          SizedBox(
            width: 230,
            child: _posCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cierre de operación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _posCierreField('Subtotal (RD\$)', formatRd(estado.subtotal)),
                  const SizedBox(height: 8),
                  _posCierreField(
                    'Descuento',
                    estado.montoDescuento > 0 ? '- ${formatRd(estado.montoDescuento)}' : formatRd(0),
                  ),
                  const SizedBox(height: 8),
                  _posCierreField('ITBIS', formatRd(estado.itbis)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatRd(estado.montoTotal),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _abrirDescuentoGeneralCotizacion(context, ref),
                    icon: const Icon(Icons.discount_outlined, size: 18),
                    label: Text(
                      estado.montoDescuento > 0 ? 'Editar descuento' : 'Aplicar descuento',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: Builder(
                      builder: (context) {
                        final simplificado = ref.watch(modoColmadoProvider);
                        final onTap = !puedeGenerar || _guardando
                            ? null
                            : simplificado
                                ? _onGenerarVentaSimplificada
                                : () => _guardarCotizacion(esCredito: _esCredito);
                        final label = simplificado
                            ? 'PROCESAR COBRO'
                            : (_esCredito ? 'CREAR COTIZACIÓN (CR)' : 'CREAR COTIZACIÓN (C)');
                        final bg = !puedeGenerar || _guardando
                            ? const Color(0xFF94A3B8)
                            : (_esCredito ? const Color(0xFFD97706) : const Color(0xFF0F766E));
                        return ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bg,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _guardando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _posCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _posMiniChip(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF0F766E)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posCierreField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildAccesosSecundarios() {
    Widget chip({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF0F766E)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (AppBreakpoints.isDesktop(context)) ...[
          const Text(
            'Punto de venta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Capture la venta: cliente · productos · delivery · contado o crédito',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(
              icon: Icons.request_quote_outlined,
              label: 'Historial cotizaciones',
              onTap: () => context.push('/ventas/cotizaciones/historial'),
            ),
            chip(
              icon: Icons.receipt_long_outlined,
              label: 'Historial ventas',
              onTap: () => context.push('/ventas/historial'),
            ),
            chip(
              icon: Icons.inventory_2_outlined,
              label: 'Consultar stock',
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ConsultaStockLecturaSheet(),
                );
              },
            ),
            chip(
              icon: Icons.calculate_outlined,
              label: 'Simular crédito',
              onTap: () => context.push('/ventas/simulador-credito'),
            ),
          ],
        ),
      ],
    );
  }


  /// Contado / Crédito + Vence — pensado para columna izquierda del POS (ancho completo, sin truncar).

  Widget _buildPosVendedorDropdown(VentaBorradorState estado) {
    final asyncUsers = ref.watch(posUsuariosVentaProvider);
    final sesion = ref.watch(sesionProvider);
    final currentId = estado.usuarioId;

    return asyncUsers.when(
      loading: () => Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Cargando…', style: TextStyle(color: Color(0xFF94A3B8))),
      ),
      error: (_, __) => Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          sesion?.nombre ?? 'Usuario actual',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      data: (users) {
        // Solo usuarios con rol Vendedor (los crea el admin en Usuarios)
        final lista = users
            .where((u) {
              final r = u.rol.toLowerCase().trim();
              return r == 'vendedor' || r.contains('vend');
            })
            .toList();

        final ids = lista.map((u) => u.id).toSet();
        // Solo un id que exista en la lista de vendedores
        final int? value = ids.contains(currentId)
            ? currentId
            : (lista.isNotEmpty ? lista.first.id : null);
        // Si el borrador tenía un admin, alinear al primer vendedor
        if (value != null && value != currentId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(ventaBorradorProvider.notifier).establecerUsuarioId(value);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: value,
              hint: const Text(
                'Seleccionar…',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              items: lista
                  .map(
                    (u) => DropdownMenuItem<int>(
                      value: u.id,
                      child: Text(
                        '${u.nombre}${u.apellido != null && u.apellido!.isNotEmpty ? ' ${u.apellido}' : ''} · ${u.rol}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                ref.read(ventaBorradorProvider.notifier).establecerUsuarioId(id);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPosTipoPagoYVence() {
    Widget chip({
      required bool credito,
      required String label,
      required IconData icon,
    }) {
      final sel = _esCredito == credito;
      final color = credito ? const Color(0xFFD97706) : const Color(0xFF0F766E);
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _esCredito = credito);
              ref.read(ventaBorradorProvider.notifier).establecerFormaPago(esCredito: credito);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? color : const Color(0xFFE2E8F0),
                  width: sel ? 1.8 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: sel ? color : const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: sel ? color : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            chip(
              credito: false,
              label: 'Contado',
              icon: Icons.payments_outlined,
            ),
            const SizedBox(width: 8),
            chip(
              credito: true,
              label: 'Crédito',
              icon: Icons.schedule,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: _seleccionarVencimiento,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF0F766E)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vencimiento',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fechaVencimientoSeleccionada != null
                              ? '${_fechaVencimientoSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaVencimientoSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaVencimientoSeleccionada!.year}'
                              : 'Opcional',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionTipoYVencimiento(bool esPantallaPequena) {
    Widget opcionPago({required bool credito}) {
      final seleccionada = _esCredito == credito;
      final color = credito ? AppColors.warning : AppColors.primary;
      return Expanded(
        child: Material(
          color: seleccionada ? color.withValues(alpha: 0.10) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _cambiarEsCredito(credito),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: EdgeInsets.symmetric(
                horizontal: esPantallaPequena ? 6 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: seleccionada ? color : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    credito ? Icons.schedule : Icons.payments_outlined,
                    size: 16,
                    color: seleccionada ? color : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      credito ? 'Crédito' : 'Contado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: esPantallaPequena ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: seleccionada
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                opcionPago(credito: false),
                const SizedBox(width: 4),
                opcionPago(credito: true),
              ],
            ),
          ),
        ),
        SizedBox(width: esPantallaPequena ? 6 : 10),
        Expanded(
          flex: 4,
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _seleccionarVencimiento,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: EdgeInsets.symmetric(
                  horizontal: esPantallaPequena ? 8 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: esPantallaPequena ? 6 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Vence',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: esPantallaPequena ? 12 : 13,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            _fechaVencimientoSeleccionada != null
                                ? '${_fechaVencimientoSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaVencimientoSeleccionada!.month.toString().padLeft(2, '0')}/${(_fechaVencimientoSeleccionada!.year % 100).toString().padLeft(2, '0')}'
                                : 'Opcional',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: esPantallaPequena ? 10 : 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionCliente(
    VentaBorradorState estado,
    bool esPantallaPequena,
  ) {
    final clienteSeleccionado =
        (estado.clienteId ?? 0) > 0 &&
        (estado.clienteNombre?.trim().isNotEmpty ?? false);
    final nombreCliente = clienteSeleccionado
        ? estado.clienteNombre!.trim()
        : 'Agregar cliente';
    final tamanoCuerpo = esPantallaPequena ? 14.0 : 15.0;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _seleccionarCliente,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: esPantallaPequena ? 14 : 16,
            vertical: esPantallaPequena ? 12 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: clienteSeleccionado
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  clienteSeleccionado ? Icons.person : Icons.person_add_alt_1,
                  size: 22,
                  color: clienteSeleccionado
                      ? Colors.white
                      : const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: esPantallaPequena ? 11 : 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nombreCliente,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: tamanoCuerpo,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clienteSeleccionado)
                      FutureBuilder(
                        future: ref
                            .read(clienteRepositoryProvider)
                            .obtenerClientePorId(estado.clienteId!),
                        builder: (context, snap) {
                          final c = snap.data;
                          if (c == null) return const SizedBox.shrink();
                          final lim = c.limiteCuotaMensual;
                          final saldo = c.saldoPendiente;
                          if (lim <= 0 && saldo <= 0) {
                            return Text(
                              'Sin límite de cuota',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            );
                          }
                          final partes = <String>[];
                          if (lim > 0) {
                            partes.add(
                              'Límite cuota RD\$ ${lim.toStringAsFixed(0)}',
                            );
                          }
                          if (saldo > 0) {
                            partes.add(
                              'Saldo RD\$ ${saldo.toStringAsFixed(0)}',
                            );
                          }
                          return Text(
                            partes.join(' · '),
                            style: AppTypography.bodySmall.copyWith(
                              color: saldo > 0
                                  ? AppColors.warning
                                  : AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                  ],
                ),
              ),
              Text(
                'Cambiar',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: esPantallaPequena ? 12 : 13,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionDelivery(
    VentaBorradorState estado,
    bool esPantallaPequena,
  ) {
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tieneEnvio = estado.costoEnvio > 0;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _abrirDelivery,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: esPantallaPequena ? 14 : 16,
            vertical: esPantallaPequena ? 12 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tieneEnvio
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delivery_dining,
                size: 22,
                color: tieneEnvio ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envío / Delivery',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: tamanoCuerpo,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      tieneEnvio
                          ? formatRd(estado.costoEnvio)
                          : 'Sin envío (tocar para elegir)',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: esPantallaPequena ? 11 : 12,
                        color: tieneEnvio
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionProductos(bool esPantallaPequena) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: esPantallaPequena ? 14 : 15,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Busque por nombre, código o código de barras',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: esPantallaPequena ? 11.5 : 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        PanelProductos(alAgregar: _agregarProductoACotizacion),
      ],
    );
  }

  Widget _buildListaItemsCarrito(
    VentaBorradorState estado,
    bool esPantallaPequena,
  ) {
    if (estado.detalles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: esPantallaPequena ? 28 : 36,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: esPantallaPequena ? 40 : 48,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 10),
            Text(
              'Carrito vacío',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: esPantallaPequena ? 14 : 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Busca y agrega productos arriba',
              style: AppTypography.bodySmall.copyWith(
                fontSize: esPantallaPequena ? 12 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;
    final tamanoEtiqueta = esPantallaPequena ? 11.0 : 12.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              esPantallaPequena ? 12 : 14,
              esPantallaPequena ? 10 : 12,
              esPantallaPequena ? 12 : 14,
              8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Carrito',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: tamanoCuerpo,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${estado.detalles.length} art.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: tamanoEtiqueta,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...estado.detalles.asMap().entries.map((entrada) {
            final item = entrada.value;
            final nombre = (item['productoNombre'] as String?) ?? 'Producto';
            final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 0.0;
            final precioUnitario =
                (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
            final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
            final productoId = item['productoId'] as int?;
            final descPct =
                (item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0;
            final descMonto =
                (item['montoDescuento'] as num?)?.toDouble() ?? 0.0;
            final tieneDescLinea = descPct > 0 || descMonto > 0;
            final cantLabel = cantidad % 1 == 0
                ? cantidad.toInt().toString()
                : cantidad.toStringAsFixed(2);
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: esPantallaPequena ? 12 : 14,
                    vertical: esPantallaPequena ? 10 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: tamanoCuerpo,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$cantLabel  ×  ${formatRd(precioUnitario)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: tamanoEtiqueta,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (tieneDescLinea)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      descPct > 0
                                          ? 'Desc. línea: ${descPct.toStringAsFixed(1)}%'
                                          : 'Desc. línea: ${formatRd(descMonto)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRd(subtotal),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: tamanoCuerpo,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (productoId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _QtyChip(
                              icon: Icons.remove,
                              onTap: () {
                                final n = cantidad <= 1
                                    ? (cantidad > 0.001 ? cantidad - 0.5 : 0)
                                    : cantidad - 1;
                                ref
                                    .read(ventaBorradorProvider.notifier)
                                    .cambiarCantidad(
                                      productoId,
                                      (n < 0.001 ? 0 : n).toDouble(),
                                    );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                cantLabel,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _QtyChip(
                              icon: Icons.add,
                              onTap: () {
                                ref
                                    .read(ventaBorradorProvider.notifier)
                                    .cambiarCantidad(productoId, cantidad + 1);
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Descuento de línea',
                              icon: Icon(
                                Icons.percent,
                                size: 20,
                                color: tieneDescLinea
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _abrirDescuentoLineaCotizacion(
                                context,
                                ref,
                                productoId,
                                item,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.error,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () {
                                ref
                                    .read(ventaBorradorProvider.notifier)
                                    .quitarProducto(productoId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (entrada.key < estado.detalles.length - 1)
                  const Divider(height: 1, indent: 12, endIndent: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeccionResumen(
    VentaBorradorState estado,
    bool esPantallaPequena,
  ) {
    final tamanoCuerpo = esPantallaPequena ? 13.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esPantallaPequena ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de la operación',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: esPantallaPequena ? 13.5 : 14.5,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _filaResumen('Subtotal', formatRd(estado.subtotal), tamanoCuerpo),
          if (!(ref.watch(modoColmadoProvider)))
            _filaResumen(
              etiquetaItbisLineas(
                estado.detalles.map(
                  (d) => ((d['tasaImpuesto'] as num?) ?? 0).toDouble(),
                ),
              ),
              formatRd(estado.itbis),
              tamanoCuerpo,
            ),
          if (estado.costoEnvio > 0)
            _filaResumen(
              'Envío / Delivery',
              formatRd(estado.costoEnvio),
              tamanoCuerpo,
            ),
          if (estado.montoDescuento > 0)
            _filaResumen(
              'Descuento general',
              '- ${formatRd(estado.montoDescuento)}',
              tamanoCuerpo,
              colorValor: AppColors.error,
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _abrirDescuentoGeneralCotizacion(context, ref),
              icon: Icon(
                estado.montoDescuento > 0
                    ? Icons.discount
                    : Icons.discount_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                estado.montoDescuento > 0
                    ? 'Editar / quitar descuento general'
                    : 'Aplicar descuento general',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: esPantallaPequena ? 14 : 15,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                formatRd(estado.montoTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: esPantallaPequena ? 20.0 : 24.0,
                  color: const Color(0xFF0F766E),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filaResumen(
    String etiqueta,
    String valor,
    double fontSize, {
    Color? colorValor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: fontSize,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valor,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: colorValor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnlaceHistorial() {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.history, size: 18),
        label: const Text('Ver historial de ventas'),
        onPressed: () => context.push('/ventas/historial'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  Widget _buildBarraFijaPos(
    VentaBorradorState estado,
    bool puedeGenerar,
    bool esPantallaPequena,
  ) {
    // Desktop: CTA en panel "Cierre de operación" (3 columnas)
    if (!esPantallaPequena) {
      return const SizedBox.shrink();
    }

    // Móvil: barra inferior
    final simplificado = ref.watch(modoColmadoProvider);
    final onTap = !puedeGenerar || _guardando
        ? null
        : simplificado
            ? _onGenerarVentaSimplificada
            : () => _guardarCotizacion(esCredito: _esCredito);
    final label = simplificado
        ? 'GENERAR VENTA'
        : (_esCredito ? 'Crear cotización (CR)' : 'Crear cotización (C)');
    final bg = simplificado
        ? AppColors.primary
        : (_esCredito ? AppColors.warning : AppColors.primary);

    return Material(
      elevation: 8,
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatRd(estado.montoTotal),
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.grey300,
                    disabledForegroundColor: AppColors.grey500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _abrirDescuentoLineaCotizacion(
    BuildContext context,
    WidgetRef ref,
    int productoId,
    Map<String, dynamic> item,
  ) async {
    final notifier = ref.read(ventaBorradorProvider.notifier);
    final bloqueo = notifier.puedeAplicarDescuentoLinea(item);
    final yaTiene =
        ((item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0) > 0 ||
        ((item['montoDescuento'] as num?)?.toDouble() ?? 0) > 0;
    if (bloqueo != null && !yaTiene) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(bloqueo),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tienePorcentaje =
        ((item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0) > 0;
    final controller = TextEditingController(
      text: tienePorcentaje
          ? ((item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0)
                .toStringAsFixed(2)
          : ((item['montoDescuento'] as num?)?.toDouble() ?? 0) > 0
          ? ((item['montoDescuento'] as num?)?.toDouble() ?? 0).toStringAsFixed(
              2,
            )
          : '',
    );
    var esPorcentaje = tienePorcentaje;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Descuento de línea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('RD\$'),
                      selected: !esPorcentaje,
                      onSelected: (_) => setLocal(() => esPorcentaje = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('%'),
                      selected: esPorcentaje,
                      onSelected: (_) => setLocal(() => esPorcentaje = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: esPorcentaje ? '%' : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                notifier.aplicarDescuentoLinea(productoId, 0);
                Navigator.pop(ctx);
              },
              child: const Text('Sin descuento'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final valor =
                    double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                final err = notifier.aplicarDescuentoLinea(
                  productoId,
                  valor,
                  esPorcentaje: esPorcentaje,
                );
                if (err != null && context.mounted) {
                  FiscoGestNotifications.show(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDescuentoGeneralCotizacion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(ventaBorradorProvider.notifier);
    final estado = ref.read(ventaBorradorProvider);
    final bloqueo = notifier.puedeAplicarDescuentoGeneral();
    if (bloqueo != null && estado.montoDescuento <= 0) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(bloqueo),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = TextEditingController(
      text: estado.montoDescuento > 0
          ? estado.montoDescuento.toStringAsFixed(2)
          : '',
    );
    var esPorcentaje = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Descuento general'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('RD\$'),
                      selected: !esPorcentaje,
                      onSelected: (_) => setLocal(() => esPorcentaje = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('%'),
                      selected: esPorcentaje,
                      onSelected: (_) => setLocal(() => esPorcentaje = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  suffixText: esPorcentaje ? '%' : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                notifier.aplicarDescuento(0);
                Navigator.pop(ctx);
              },
              child: const Text('Sin descuento'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final raw =
                    double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                double monto = raw;
                if (esPorcentaje) {
                  monto = estado.subtotal * (raw / 100);
                }
                final err = notifier.aplicarDescuento(monto);
                if (err != null && context.mounted) {
                  FiscoGestNotifications.show(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyChip extends StatelessWidget {
  const _QtyChip({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
