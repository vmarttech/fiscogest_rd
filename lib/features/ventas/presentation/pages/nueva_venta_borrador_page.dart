import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
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
import 'package:fiscogest_rd/features/creditos/presentation/pages/solicitudes_credito_page.dart'
    show solicitudesCreditoProvider;
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/selector_delivery.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/sheet_contado_fiao.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/sheet_anotar_fiao.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart'
    show cajaRepositoryProvider;
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';

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
  final FocusNode _posRootFocus = FocusNode(debugLabel: 'pos-desktop-root');
  DateTime? _ultimoAtajoPos;
  LogicalKeyboardKey? _ultimaTeclaAtajo;

  /// Atajos globales del POS (desktop). Funciona aunque el foco esté en un TextField.
  bool _atajoPosAbierto = false;

  bool _posOnKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    // Flutter a veces marca mal repeat; filtramos por bandera + tiempo
    if (!mounted) return false;
    if (!AppBreakpoints.isDesktop(context)) return false;

    final key = event.logicalKey;
    final esAtajo =
        key == LogicalKeyboardKey.f3 ||
        key == LogicalKeyboardKey.f4 ||
        key == LogicalKeyboardKey.f5 ||
        key == LogicalKeyboardKey.f7 ||
        key == LogicalKeyboardKey.f8 ||
        key == LogicalKeyboardKey.f9 ||
        key == LogicalKeyboardKey.f10 ||
        key == LogicalKeyboardKey.f11;
    if (!esAtajo) return false;

    if (_atajoPosAbierto) return true;

    final ahora = DateTime.now();
    if (_ultimoAtajoPos != null &&
        _ultimaTeclaAtajo == key &&
        ahora.difference(_ultimoAtajoPos!) <
            const Duration(milliseconds: 900)) {
      return true;
    }
    _ultimoAtajoPos = ahora;
    _ultimaTeclaAtajo = key;
    _atajoPosAbierto = true;

    final st = ref.read(ventaBorradorProvider);
    final puede = st.detalles.isNotEmpty && st.montoTotal > 0 && !_guardando;

    try {
      if (key == LogicalKeyboardKey.f3) {
        _abrirDescuentoGeneralCotizacion(context, ref).whenComplete(() {
          _atajoPosAbierto = false;
        });
        return true;
      }
      if (key == LogicalKeyboardKey.f4) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ConsultaStockLecturaSheet(),
        ).whenComplete(() {
          _atajoPosAbierto = false;
        });
        return true;
      }
      if (key == LogicalKeyboardKey.f5 || key == LogicalKeyboardKey.f10) {
        if (puede) {
          setState(() => _esCredito = false);
          _guardarCotizacion(esCredito: false);
        }
        _atajoPosAbierto = false;
        return true;
      }
      if (key == LogicalKeyboardKey.f7) {
        context.push('/ventas/cotizaciones/historial');
        _atajoPosAbierto = false;
        return true;
      }
      if (key == LogicalKeyboardKey.f8) {
        context.push('/ventas/historial');
        _atajoPosAbierto = false;
        return true;
      }
      if (key == LogicalKeyboardKey.f9) {
        if (puede) {
          setState(() => _esCredito = true);
          _guardarCotizacion(esCredito: true);
        }
        _atajoPosAbierto = false;
        return true;
      }
      if (key == LogicalKeyboardKey.f11) {
        if (puede) {
          final simplificado = ref.read(modoColmadoProvider);
          if (simplificado) {
            _onGenerarVentaSimplificada();
          } else {
            _guardarCotizacion(esCredito: _esCredito);
          }
        }
        _atajoPosAbierto = false;
        return true;
      }
    } catch (_) {
      _atajoPosAbierto = false;
      rethrow;
    }
    _atajoPosAbierto = false;
    return false;
  }

  /// Etiqueta del vendedor según sesión (sin palabras repetidas).
  String _etiquetaVendedorSesion(UsuarioSesion? s) {
    if (s == null) return '—';
    var nombre = s.nombre.trim();
    if (nombre.isEmpty) nombre = s.username.trim();
    final parts = <String>[];
    for (final w in nombre.split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      if (parts.isEmpty || parts.last.toLowerCase() != w.toLowerCase()) {
        parts.add(w);
      }
    }
    nombre = parts.join(' ');
    if (nombre.length > 28) {
      nombre = '${nombre.substring(0, 26)}…';
    }
    final rol = s.rolNorm;
    final low = nombre.toLowerCase();
    if (low.contains('admin') || low.contains(rol.toLowerCase())) {
      return nombre;
    }
    return '$nombre · $rol';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sesion = ref.read(sesionProvider);
      if (sesion != null) {
        ref.read(ventaBorradorProvider.notifier).establecerUsuarioId(sesion.id);
      }
    });
    HardwareKeyboard.instance.addHandler(_posOnKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _posRootFocus.requestFocus();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ventaBorradorProvider.notifier).establecerConsumidorFinal();
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    HardwareKeyboard.instance.removeHandler(_posOnKey);
    _posRootFocus.dispose();
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
        final formaPago = await SheetContadoFiao.showMetodoPago(context);
        if (!mounted || formaPago == null) return;
        await _guardarCotizacion(
          esCredito: false,
          abrirCobro: true,
          formaPago: formaPago,
        );
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
    String formaPago = 'efectivo',
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

      // Modo simplificado Contado: cobra e imprime AQUÍ (sin Caja fiscal).
      if (abrirCobro && !esCredito) {
        final estadoFinal = ref.read(ventaBorradorProvider);
        final ventaId = estadoFinal.id;
        final montoTotal = estadoFinal.montoTotal;
        if (ventaId == null) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('No se pudo obtener el id de la venta'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        final repositorio = ref.read(ventasRepositoryProvider);
        final venta = await repositorio.confirmarVentaBorrador(
          ventaId,
          formaPago: formaPago,
        );
        final ventaConDetalle = await repositorio.obtenerVentaPorId(
          venta.id ?? ventaId,
        );
        if (ventaConDetalle == null) {
          throw Exception('No se pudo recargar la venta facturada');
        }
        if (ventaConDetalle.detalles.isEmpty) {
          throw Exception(
            'La venta no tiene productos en base de datos. '
            'Genere de nuevo con productos.',
          );
        }
        final inv = ref.read(ventaInventarioServiceProvider);
        await inv.aplicarSalidaInventario(ventaConDetalle);
        try {
          ref.invalidate(productoControllerProvider);
        } catch (_) {}
        if (montoTotal > 0) {
          final cajaRepo = ref.read(cajaRepositoryProvider);
          final nFactura = venta.numeroFactura ?? venta.numeroCotizacion;
          await cajaRepo.registrarMovimiento(
            referencia: nFactura,
            monto: montoTotal,
            tipo: 'ingreso',
            descripcion: 'Cobro venta $nFactura (modo simple)',
            formaPago: formaPago,
          );
        }
        ref.invalidate(listaCotizacionesProvider);
        ref.invalidate(listaVentasProvider);
        if (!mounted) return;
        _limpiarFormulario();
        final nFactura = venta.numeroFactura ?? venta.numeroCotizacion;
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Venta $nFactura cobrada · ${formatRd(montoTotal)}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        final desea = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Cobro completado'),
            content: Text('N° $nFactura · ${formatRd(montoTotal)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Más tarde'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Imprimir / enviar'),
              ),
            ],
          ),
        );
        if (desea == true && mounted) {
          final emp = ref.read(configuracionControllerProvider).valueOrNull;
          final accion = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Comprobante'),
              content: const Text('Elija imprimir o enviar.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'imprimir'),
                  child: const Text('Imprimir'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'enviar'),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Enviar'),
                ),
              ],
            ),
          );
          if (accion != null && mounted) {
            try {
              await ComprobantePdf.imprimirFactura(
                ventaConDetalle,
                compartir: accion == 'enviar',
                empresa: emp,
              );
            } catch (e) {
              if (mounted) {
                FiscoGestNotifications.show(
                  SnackBar(
                    content: Text('PDF: $e'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }
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
      ref.invalidate(solicitudesCreditoProvider);
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
      ref.invalidate(solicitudesCreditoProvider);
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
    final esPantallaPequena = AppBreakpoints.isMobile(context);
    final esPantallaAncha =
        !AppBreakpoints.isMobile(context) &&
        MediaQuery.sizeOf(context).width >= 720;

    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'NUEVA COTIZACIÓN',
      showAppBar:
          !desktop ||
          (_modoFormularioCredito && _estadoFormularioCredito != null),
      // En desktop la entrada es directa: atrás → Dashboard
      leading: (_modoFormularioCredito && _estadoFormularioCredito != null)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver al POS',
              onPressed: _cerrarFormularioCredito,
            )
          : (desktop
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Atrás',
                    onPressed: () => safeBack(context, fallback: '/inicio'),
                  )),
      // En crédito desktop también mostrar AppBar para poder volver
      // (showAppBar se ajusta abajo si hace falta)
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
            : _buildCuerpoPos(
                estado: estado,
                puedeGenerar: puedeGenerar,
                esPantallaPequena: esPantallaPequena,
                esPantallaAncha: esPantallaAncha,
                desktop: desktop,
              ),
      ),
    );
  }

  /// Cuerpo POS: atajos solo en desktop; móvil idéntico a antes.
  Widget _buildCuerpoPos({
    required VentaBorradorState estado,
    required bool puedeGenerar,
    required bool esPantallaPequena,
    required bool esPantallaAncha,
    required bool desktop,
  }) {
    final cuerpo = Column(
      children: [
        Expanded(
          child: esPantallaAncha
              ? _buildDosColumnas(estado, puedeGenerar, esPantallaPequena)
              : _buildUnaColumna(estado, puedeGenerar, esPantallaPequena),
        ),
        _buildBarraFijaPos(estado, puedeGenerar, esPantallaPequena),
        if (desktop) _buildDockAccionesRapidas(estado, puedeGenerar),
      ],
    );
    if (!desktop) return cuerpo;

    // Atajos solo vía HardwareKeyboard (_posOnKey) para no abrir 2 diálogos.
    return Focus(focusNode: _posRootFocus, autofocus: true, child: cuerpo);
  }

  Widget _buildDockAccionesRapidas(
    VentaBorradorState estado,
    bool puedeGenerar,
  ) {
    Widget chip(String label, String key, IconData icon, VoidCallback onTap) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  key,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'ACCIONES RÁPIDAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          chip('Descuento', 'F3', Icons.percent, () {
            _abrirDescuentoGeneralCotizacion(context, ref);
          }),
          chip('Stock', 'F4', Icons.inventory_2_outlined, () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ConsultaStockLecturaSheet(),
            );
          }),
          chip('Cotizar', 'F5', Icons.request_quote_outlined, () {
            if (!puedeGenerar || _guardando) return;
            setState(() => _esCredito = false);
            _guardarCotizacion(esCredito: false);
          }),
          chip('Simulador', '', Icons.calculate_outlined, () {
            context.push('/ventas/simulador-credito');
          }),
          const Spacer(),
          TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Atajos de teclado'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('F3  Descuento general'),
                      Text('F4  Stock'),
                      Text('F5 / F10  Cotización'),
                      Text('F7  Historial cotizaciones'),
                      Text('F8  Historial ventas'),
                      Text('F9  Crédito'),
                      Text('F11 Finalizar'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Atajos de teclado',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'F9 Crédito · F10 Cotización · F11 Finalizar',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
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
          _buildSeccionProductos(esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildListaItemsCarrito(estado, esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildSeccionDelivery(estado, esPantallaPequena),
          SizedBox(height: esPantallaPequena ? 12 : 16),
          _buildSeccionResumen(estado, esPantallaPequena),
          const SizedBox(height: 8),
          _buildEnlaceHistorial(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Desktop POS — layout 1:1 con mock HTML nuevopo.html
  /// (Config drawer | Carrito centrado | Cierre). NO usar en móvil.
  Widget _buildDosColumnas(
    VentaBorradorState estado,
    bool puedeGenerar,
    bool esPantallaPequena,
  ) {
    final simp = ref.watch(modoColmadoProvider);
    final carritoVacio = estado.detalles.isEmpty;
    final showSub = carritoVacio ? 0.0 : estado.subtotal;
    final showDesc = carritoVacio ? 0.0 : estado.montoDescuento;
    final showItbis = carritoVacio ? 0.0 : estado.itbis;
    final showTotal = carritoVacio ? 0.0 : estado.montoTotal;
    final nombreCliente = (estado.clienteNombre ?? '').trim().isEmpty
        ? 'Consumidor Final'
        : estado.clienteNombre!.trim();
    final direccion = (estado.clienteDireccion ?? '').trim().isEmpty
        ? 'Sucursal Principal'
        : estado.clienteDireccion!.trim();
    final tipoVenta = _esCredito ? 'Crédito' : 'Venta normal';
    final disabled = !puedeGenerar || _guardando;

    Widget configRow({
      required IconData icon,
      required String label,
      required String value,
      VoidCallback? onTap,
      Color accent = const Color(0xFF0F172A),
    }) {
      final canTap = onTap != null;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: accent.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canTap)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: accent.withValues(alpha: 0.45),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget outlineAction({
      required IconData icon,
      required String label,
      required String shortcut,
      required VoidCallback? onPressed,
    }) {
      return SizedBox(
        height: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF334155),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                shortcut,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // —— Carrito: vacío (mock) o tabla con ítems ——
    final Widget cartBody;
    if (estado.detalles.isEmpty) {
      cartBody = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.95),
                  shadows: const [
                    Shadow(color: Color(0x590EA5E9), blurRadius: 16),
                  ],
                ),
                const SizedBox(height: 12),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                    children: [
                      TextSpan(text: 'Carrito vacío — '),
                      TextSpan(
                        text: 'busca un producto',
                        style: TextStyle(color: Color(0xFF0EA5E9)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Agrega productos para comenzar una nueva operación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                // Buscador centrado (mismo motor que PanelProductos)
                PanelProductos(alAgregar: _agregarProductoACotizacion),
              ],
            ),
          ),
        ),
      );
    } else {
      cartBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Carrito de compra',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: estado.detalles.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (context, i) {
                final item = estado.detalles[i];
                final nombre =
                    (item['productoNombre'] as String?)?.trim().isNotEmpty ==
                        true
                    ? (item['productoNombre'] as String).trim()
                    : 'Producto';
                final cant = (item['cantidad'] as num?)?.toDouble() ?? 0.0;
                final precio =
                    (item['precioUnitario'] as num?)?.toDouble() ?? 0.0;
                final sub =
                    (item['subtotal'] as num?)?.toDouble() ?? (cant * precio);
                final tasa = (item['tasaImpuesto'] as num?)?.toDouble() ?? 0.0;
                final itbisLinea = simp
                    ? 0.0
                    : sub * (tasa > 1 ? tasa / 100.0 : tasa);
                final productoId = item['productoId'] is int
                    ? item['productoId'] as int
                    : int.tryParse('${item['productoId'] ?? ''}');
                final cantLabel = cant % 1 == 0
                    ? cant.toInt().toString()
                    : cant.toStringAsFixed(2);
                final descP =
                    (item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0;
                final descM =
                    (item['montoDescuento'] as num?)?.toDouble() ?? 0.0;
                final tieneDesc = descP > 0 || descM > 0;
                return ListTile(
                  dense: true,
                  title: Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    simp
                        ? '$cantLabel × ${formatRd(precio)}${tieneDesc ? ' · desc.' : ''}'
                        : '$cantLabel × ${formatRd(precio)} · ITBIS ${formatRd(itbisLinea)}${tieneDesc ? ' · desc.' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (productoId != null) ...[
                        IconButton(
                          tooltip: 'Menos',
                          icon: const Icon(
                            Icons.remove,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () {
                            final n = cant <= 1
                                ? (cant > 0.001 ? cant - 0.5 : 0.0)
                                : cant - 1;
                            ref
                                .read(ventaBorradorProvider.notifier)
                                .cambiarCantidad(
                                  productoId,
                                  n < 0.001 ? 0.0 : n,
                                );
                          },
                        ),
                        IconButton(
                          tooltip: 'Más',
                          icon: const Icon(
                            Icons.add,
                            size: 16,
                            color: Color(0xFF0EA5E9),
                          ),
                          onPressed: () {
                            ref
                                .read(ventaBorradorProvider.notifier)
                                .cambiarCantidad(productoId, cant + 1);
                          },
                        ),
                        IconButton(
                          tooltip: 'Descuento línea',
                          icon: Icon(
                            Icons.percent,
                            size: 16,
                            color: tieneDesc
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                          ),
                          onPressed: () => _abrirDescuentoLineaCotizacion(
                            context,
                            ref,
                            productoId,
                            item,
                          ),
                        ),
                      ],
                      Text(
                        formatRd(sub + (simp ? 0 : itbisLinea)),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (productoId != null)
                        IconButton(
                          tooltip: 'Quitar',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          onPressed: () {
                            ref
                                .read(ventaBorradorProvider.notifier)
                                .quitarProducto(productoId);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: PanelProductos(alAgregar: _agregarProductoACotizacion),
          ),
        ],
      );
    }

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══ CONFIG DRAWER (w-72 ≈ 288) ═══
          SizedBox(
            width: 288,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune, size: 16, color: Color(0xFF94A3B8)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Configuración de operación',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        configRow(
                          icon: Icons.person_outline,
                          label: 'Cliente',
                          value: nombreCliente,
                          onTap: _seleccionarCliente,
                        ),
                        // Vendedor = solo quien tiene la sesión abierta
                        configRow(
                          icon: Icons.badge_outlined,
                          label: 'Vendedor',
                          value: _etiquetaVendedorSesion(
                            ref.watch(sesionProvider),
                          ),
                          onTap: null,
                          accent: const Color(0xFF2563EB),
                        ),
                        configRow(
                          icon: Icons.location_on_outlined,
                          label: 'Dirección',
                          value: direccion,
                          onTap: () {},
                        ),
                        configRow(
                          icon: Icons.sell_outlined,
                          label: 'Tipo de venta',
                          value: tipoVenta,
                          onTap: () {
                            setState(() => _esCredito = !_esCredito);
                          },
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'CONSULTAS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        configRow(
                          icon: Icons.request_quote_outlined,
                          label: 'Historial cotizaciones',
                          value: 'F7 · Ver listado',
                          accent: const Color(0xFF0F766E),
                          onTap: () =>
                              context.push('/ventas/cotizaciones/historial'),
                        ),
                        configRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'Historial ventas',
                          value: 'F8 · Ver listado',
                          accent: const Color(0xFF1D4ED8),
                          onTap: () => context.push('/ventas/historial'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          // ═══ CENTRO: CARRITO ═══
          Expanded(child: cartBody),

          const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

          // ═══ CIERRE (w-80 ≈ 320) ═══
          SizedBox(
            width: 320,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cierre de operación',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _htmlTotRow('Subtotal', formatRd(showSub)),
                          const SizedBox(height: 12),
                          _htmlTotRow(
                            'Descuento',
                            showDesc > 0
                                ? '- ${formatRd(showDesc)}'
                                : formatRd(0),
                          ),
                          if (!simp) ...[
                            const SizedBox(height: 12),
                            _htmlTotRow('ITBIS (18%)', formatRd(showItbis)),
                          ],
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formatRd(showTotal),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Contado (primario sky)
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: disabled
                                  ? null
                                  : () {
                                      setState(() => _esCredito = false);
                                      if (simp) {
                                        _onGenerarVentaSimplificada();
                                      } else {
                                        _guardarCotizacion(esCredito: false);
                                      }
                                    },
                              icon: const Icon(Icons.credit_card, size: 18),
                              label: const Text(
                                'Contado',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0EA5E9),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF94A3B8,
                                ),
                                elevation: 0,
                                shadowColor: const Color(0x4D0EA5E9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (!simp) ...[
                            const SizedBox(height: 10),
                            outlineAction(
                              icon: Icons.credit_card,
                              label: 'Crédito',
                              shortcut: 'F9',
                              onPressed: disabled
                                  ? null
                                  : () {
                                      setState(() => _esCredito = true);
                                      _guardarCotizacion(esCredito: true);
                                    },
                            ),
                            const SizedBox(height: 10),
                            outlineAction(
                              icon: Icons.description_outlined,
                              label: 'Crear Cotización',
                              shortcut: 'F10',
                              onPressed: disabled
                                  ? null
                                  : () {
                                      setState(() => _esCredito = false);
                                      _guardarCotizacion(esCredito: false);
                                    },
                            ),
                          ],
                          const SizedBox(height: 10),
                          outlineAction(
                            icon: Icons.check,
                            label: 'Finalizar operación',
                            shortcut: 'F11',
                            onPressed: disabled
                                ? null
                                : () {
                                    if (simp) {
                                      _onGenerarVentaSimplificada();
                                    } else {
                                      _guardarCotizacion(esCredito: _esCredito);
                                    }
                                  },
                          ),
                        ],
                      ),
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

  Widget _htmlTotRow(String k, String v) {
    return Row(
      children: [
        Text(k, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
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
          maxLines: 2,
          softWrap: true,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: esPantallaPequena ? 11.5 : 12.5,
            height: 1.25,
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
                child: SizedBox(
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
