import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/capacidad_pago_service.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/calculadora_credito_service.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/solicitudes_credito_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/expediente_solicitante_form.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/solicitud_credito_expediente.dart';
// creditoDocumentoServiceProvider está en el mismo archivo de providers
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class DetalleSolicitudCreditoPage extends ConsumerStatefulWidget {
  const DetalleSolicitudCreditoPage({super.key, required this.ventaId});

  static const String routeName = 'credito-solicitud-detalle';
  final int ventaId;

  @override
  ConsumerState<DetalleSolicitudCreditoPage> createState() =>
      _DetalleSolicitudCreditoPageState();
}

class _DetalleSolicitudCreditoPageState
    extends ConsumerState<DetalleSolicitudCreditoPage> {
  Venta? _venta;
  bool _modoFormularioCredito = false;
  RegistrarVentaState? _estadoFormularioCredito;
  bool _cargando = true;
  bool _procesando = false;
  String? _error;

  double _abono = 0;
  int _numeroCuotas = 1;
  double _tasaMensual = 0;
  DateTime? _primerVencimiento;
  CuentaPorCobrar? _cuentaBorrador;

  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final v = await ref
          .read(ventasRepositoryProvider)
          .obtenerVentaPorId(widget.ventaId);
      if (!mounted) return;
      if (v != null) {
        _abono = v.abonoInicial;
        _numeroCuotas = v.numeroCuotas < 1 ? 1 : v.numeroCuotas;
        _tasaMensual = v.tasaInteres;
        _primerVencimiento = v.vencimiento;
        // plazo en días queda en la venta; el resumen usa cuotas + tasa
      }
      setState(() {
        _venta = v;
        _cargando = false;
        if (v == null) _error = 'Documento no encontrado';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  /// Adapta Venta → estado que entiende FormularioCreditoVista.
  /// Si analyze falla aquí, alinea nombres con RegistrarVentaState (paso 1).
  RegistrarVentaState _estadoDesdeVenta(Venta v) {
    return RegistrarVentaState(
      usuarioId: v.usuarioId,
      clienteId: v.clienteId,
      clienteNombre: v.nombreCliente,
      tipoPago: 'credito',
      esCredito: true,
      abonoInicial: v.abonoInicial,
      vencimiento: v.vencimiento,
      detalles: v.detalles,
      subtotal: v.montoSubtotal,
      itbis: v.itbis,
      costoEnvio: v.costoEnvio,
      total: v.montoTotal,
      descuentoId: v.descuentoId,
      descuentoNombre: v.descuentoNombre,
      montoDescuento: v.montoDescuento,
    );
  }

  Future<void> _abrirFormularioCondiciones() async {
    final v = _venta;
    if (v == null) return;
    try {
      final estado = _estadoDesdeVenta(v);
      setState(() {
        _estadoFormularioCredito = estado;
        _modoFormularioCredito = true;
      });
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'No se pudo armar el estado del formulario: $e\n'
            'Revisa RegistrarVentaState (campos requeridos).',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cerrarFormularioCredito() {
    setState(() {
      _modoFormularioCredito = false;
      _estadoFormularioCredito = null;
    });
  }

  Future<void> _onCreditoConfirmado(
    ResultadoFormularioCredito resultado,
  ) async {
    final cuenta = resultado.cuenta;
    setState(() {
      _modoFormularioCredito = false;
      _estadoFormularioCredito = null;
      _cuentaBorrador = cuenta;
      _abono = cuenta.abonoInicial;
      _numeroCuotas = cuenta.numeroCuotas < 1 ? 1 : cuenta.numeroCuotas;
      _tasaMensual = cuenta.tasaInteres;
      _primerVencimiento = cuenta.fechaVencimiento;
      if (resultado.planPago != null && resultado.planPago!.cuotas.isNotEmpty) {
        _primerVencimiento = resultado.planPago!.cuotas.first.fechaVencimiento;
      }
    });
    await _persistirCondiciones();
  }

  Future<void> _persistirCondiciones() async {
    final v = _venta;
    if (v == null || v.id == null) return;

    setState(() => _procesando = true);
    try {
      final actualizada = v.copyWith(
        abonoInicial: _abono,
        vencimiento: _primerVencimiento,
        formaPago: 'credito',
      );
      await ref
          .read(ventasRepositoryProvider)
          .actualizarVentaBorrador(actualizada);
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Condiciones guardadas'
            '${_numeroCuotas > 1 ? ' · $_numeroCuotas cuotas' : ''}'
            '${_tasaMensual > 0 ? ' · tasa ${(_tasaMensual * 100).toStringAsFixed(2)}%' : ''}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(solicitudesCreditoProvider);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cambiarEstado(EstadoDocumento nuevo) async {
    final v = _venta;
    if (v == null || v.id == null) return;

    setState(() => _procesando = true);
    try {
      if (nuevo == EstadoDocumento.aprobado) {
        // Condiciones de crédito
        final abono = _abono > 0 ? _abono : v.abonoInicial;
        final total = v.montoTotal;
        if (_numeroCuotas < 1) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Defina al menos 1 cuota antes de aprobar'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (abono < 0 || abono > total + 0.01) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text('Abono inicial inválido respecto al total'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        // Expediente completo (usa el mismo v no-null del inicio del método)
        try {
          final exp = await ref.read(
            expedienteCreditoPorVentaProvider((
              ventaId: v.id!,
              nombre: v.nombreCliente ?? '',
              clienteId: v.clienteId,
            )).future,
          );
          final faltan = exp.camposFaltantes;
          if (faltan.isNotEmpty) {
            if (!mounted) return;
            FiscoGestNotifications.show(
              SnackBar(
                content: Text(
                  'Expediente incompleto: ${faltan.join(', ')}',
                ),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
        } catch (e) {
          if (!mounted) return;
          FiscoGestNotifications.show(
            SnackBar(
              content: Text('No se pudo validar expediente: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        // Límite de cuota: 30% ingresos (o límite aprobado en cliente)
        final clienteRepo = ref.read(clienteRepositoryProvider);
        final cliente = await clienteRepo.obtenerClientePorId(v.clienteId);
        var limite = cliente?.limiteCuotaMensual ?? 0.0;
        var ingresoCli = cliente?.ingresoMensual ?? 0.0;
        // Si el cliente no tiene límite, usar ingreso del expediente × 30%
        if (limite <= 0) {
          try {
            final exp2 = await ref.read(
              expedienteCreditoPorVentaProvider((
                ventaId: v.id!,
                nombre: v.nombreCliente ?? '',
                clienteId: v.clienteId,
              )).future,
            );
            if (exp2.ingresoMensual > 0) {
              ingresoCli = exp2.ingresoMensual;
              limite = CapacidadPagoService.limiteCuotaSugerido(
                ingresoMensual: exp2.ingresoMensual,
              );
              // Persistir sugerido en cliente si aún no tiene
              if (cliente != null && cliente.limiteCuotaMensual <= 0) {
                await clienteRepo.guardarCliente(
                  cliente.copyWith(
                    ingresoMensual: exp2.ingresoMensual,
                    limiteCuotaMensual: limite,
                  ),
                );
              }
            }
          } catch (_) {}
        }
        // Cuota del plan a aprobar
        final abonoVal = _abono > 0 ? _abono : v.abonoInicial;
        final capital = (v.montoTotal - abonoVal).clamp(0.0, double.infinity);
        final nC = _numeroCuotas < 1 ? 1 : _numeroCuotas;
        final cuotaPlan = nC <= 1
            ? capital
            : CalculadoraCreditoService.generarPlanPago(
                capital: capital,
                tasaMensual: _tasaMensual,
                numeroCuotas: nC,
                fechaPrimerVencimiento:
                    _primerVencimiento ??
                    DateTime.now().add(const Duration(days: 30)),
              ).montoPorCuota;
        if (!CapacidadPagoService.cuotaDentroDelLimite(
          montoCuota: cuotaPlan,
          limiteCuotaMensual: limite,
        )) {
          if (!mounted) return;
          FiscoGestNotifications.show(
            SnackBar(
              content: Text(
                CapacidadPagoService.mensajeExcede(
                  montoCuota: cuotaPlan,
                  limiteCuotaMensual: limite,
                  ingresoMensual: ingresoCli,
                ),
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 6),
            ),
          );
          return;
        }

        final conCond = v.copyWith(
          abonoInicial: _abono > 0 ? _abono : v.abonoInicial,
          vencimiento: _primerVencimiento ?? v.vencimiento,
          formaPago: 'credito',
        );
        await ref
            .read(ventasRepositoryProvider)
            .actualizarVentaBorrador(conCond);

        // Registrar cuenta por cobrar (DAO comercial vía repo de créditos)
        final cuenta = _cuentaBorrador;
        final nCuotas = _numeroCuotas > 0
            ? _numeroCuotas
            : (cuenta?.numeroCuotas ?? 1);
        if (cuenta != null) {
          final conVenta = cuenta.copyWith(
            ventaId: v.id,
            numeroCuotas: nCuotas,
            abonoInicial: _abono > 0 ? _abono : cuenta.abonoInicial,
            fechaVencimiento: _primerVencimiento ?? cuenta.fechaVencimiento,
          );
          await ref
              .read(cuentaPorCobrarRepositoryProvider)
              .registrarCredito(
                cuenta: conVenta,
                planPago: () {
                  final abono = _abono > 0 ? _abono : conVenta.abonoInicial;
                  final totalRef = conVenta.totalOriginal;
                  // Si totalOriginal parece el total de venta ( > abono), capital = total - abono
                  // Si totalOriginal ya es saldo financiado (~igual a total venta - abono), usar tal cual
                  final capitalFinal = totalRef > abono + 0.01
                      ? (totalRef - abono).clamp(0.0, double.infinity)
                      : totalRef;
                  final fecha = _primerVencimiento ?? conVenta.fechaVencimiento;
                  if (nCuotas <= 1) return conVenta.planPago;
                  return CalculadoraCreditoService.generarPlanPago(
                    capital: capitalFinal,
                    tasaMensual: _tasaMensual,
                    numeroCuotas: nCuotas,
                    fechaPrimerVencimiento: fecha,
                  );
                }(),
                abonoInicial: null,
              );
        } else {
          final minima = CuentaPorCobrar(
            clienteId: v.clienteId,
            clienteNombre: v.nombreCliente,
            ventaId: v.id,
            totalOriginal: v.montoTotal,
            abonoInicial: conCond.abonoInicial,
            numeroCuotas: nCuotas,
            tasaInteres: _tasaMensual,
            fechaCreacion: DateTime.now(),
            fechaVencimiento:
                conCond.vencimiento ??
                DateTime.now().add(const Duration(days: 30)),
          );
          await ref
              .read(cuentaPorCobrarRepositoryProvider)
              .registrarCredito(
                cuenta: minima,
                planPago: nCuotas > 1
                    ? CalculadoraCreditoService.generarPlanPago(
                        capital: (minima.totalOriginal - minima.abonoInicial)
                            .clamp(0.0, double.infinity),
                        tasaMensual: _tasaMensual,
                        numeroCuotas: nCuotas,
                        fechaPrimerVencimiento: minima.fechaVencimiento,
                      )
                    : null,
              );
        }
      }
      await ref
          .read(ventasRepositoryProvider)
          .cambiarEstadoDocumento(v.id!, nuevo);
      if (!mounted) return;
      ref.invalidate(solicitudesCreditoProvider);
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            nuevo == EstadoDocumento.aprobado
                ? 'Crédito aprobado. Listo para Caja.'
                : 'Solicitud rechazada.',
          ),
          backgroundColor: nuevo == EstadoDocumento.aprobado
              ? AppColors.success
              : AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  CuentaPorCobrar? get _condicionesEfectivas {
    if (_cuentaBorrador != null) return _cuentaBorrador;
    final v = _venta;
    if (v == null) return null;
    // Condiciones mínimas desde la cotización (sin pasar por el formulario)
    return CuentaPorCobrar(
      clienteId: v.clienteId,
      clienteNombre: v.nombreCliente,
      ventaId: v.id,
      totalOriginal: v.montoTotal,
      abonoInicial: _abono > 0 ? _abono : v.abonoInicial,
      numeroCuotas: _numeroCuotas,
      tasaInteres: _tasaMensual,
      fechaCreacion: DateTime.now(),
      fechaVencimiento:
          _primerVencimiento ??
          v.vencimiento ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<void> _imprimirSolicitud() async {
    final v = _venta;
    if (v == null) return;
    setState(() => _procesando = true);
    try {
      SolicitudCreditoExpediente? exp;
      if (v.id != null) {
        try {
          exp = await ref.read(
            expedienteCreditoPorVentaProvider((
              ventaId: v.id!,
              nombre: v.nombreCliente ?? '',
              clienteId: v.clienteId,
            )).future,
          );
        } catch (_) {}
      }
      await (await ref.read(
        creditoDocumentoServiceProvider.future,
      )).imprimirSolicitud(
        venta: v,
        condiciones: _condicionesEfectivas,
        expediente: exp,
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error solicitud: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }


  Future<bool> _exigirListoParaDocumento({required bool exigeCondiciones}) async {
    final v = _venta;
    if (v == null || v.id == null) return false;
    if (exigeCondiciones) {
      final abono = _abono > 0 ? _abono : v.abonoInicial;
      if (_numeroCuotas < 1) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('Defina al menos 1 cuota'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
      if (abono < 0 || abono > v.montoTotal + 0.01) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('Abono inicial inválido'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    }
    try {
      final exp = await ref.read(
        expedienteCreditoPorVentaProvider((
          ventaId: v.id!,
          nombre: v.nombreCliente ?? '',
          clienteId: v.clienteId,
        )).future,
      );
      final faltan = exp.camposFaltantes;
      if (faltan.isNotEmpty) {
        if (!mounted) return false;
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('Expediente incompleto: ${faltan.join(', ')}'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('No se pudo validar expediente: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _imprimirContrato() async {
    final v = _venta;
    final cond = _condicionesEfectivas;
    if (v == null) return;
    if (cond == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Defina condiciones (abono/cuotas) antes del contrato'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!await _exigirListoParaDocumento(exigeCondiciones: true)) return;
    setState(() => _procesando = true);
    try {
      SolicitudCreditoExpediente? expC;
      try {
        expC = await ref.read(
          expedienteCreditoPorVentaProvider((
            ventaId: v.id!,
            nombre: v.nombreCliente ?? '',
            clienteId: v.clienteId,
          )).future,
        );
      } catch (_) {}
      await (await ref.read(
        creditoDocumentoServiceProvider.future,
      )).imprimirContrato(
        venta: v,
        condiciones: cond,
        expediente: expC,
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error contrato: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _enviarSolicitud() async {
    final v = _venta;
    if (v == null) return;
    setState(() => _procesando = true);
    try {
      final svc = await ref.read(creditoDocumentoServiceProvider.future);
      await svc.enviarSolicitudPorCorreo(
        venta: v,
        condiciones: _condicionesEfectivas,
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _enviarContrato() async {
    final v = _venta;
    final cond = _condicionesEfectivas;
    if (v == null) return;
    if (cond == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Defina condiciones antes de enviar el contrato'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!await _exigirListoParaDocumento(exigeCondiciones: true)) return;
    setState(() => _procesando = true);
    try {
      final svc = await ref.read(creditoDocumentoServiceProvider.future);
      await svc.enviarContratoPorCorreo(venta: v, condiciones: cond);
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al enviar contrato: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'SOLICITUD DE CRÉDITO',
      showAppBar: !desktop,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/creditos/solicitudes');
          }
        },
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _venta == null
            ? const Center(child: Text('Sin datos'))
            : _modoFormularioCredito && _estadoFormularioCredito != null
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
            : _buildBody(_venta!),
      ),
    );
  }

  Widget _buildBody(Venta v) {
    final puedeEditar = v.estadoDocumento == EstadoDocumento.enCredito;
    final esCr = v.numeroCotizacion.startsWith('CR-');
    final puedeReabrir = esCr && v.estadoDocumento == EstadoDocumento.cotizado;
    final abonoMostrar = _abono > 0 ? _abono : v.abonoInicial;
    final saldo = (v.montoTotal - abonoMostrar).clamp(0.0, double.infinity);

    final maxW = AppBreakpoints.isDesktop(context)
        ? 1200
        : (AppBreakpoints.isTablet(context) ? 900 : 9999);

    final estadoLabel = v.estadoDocumento.name.toUpperCase();
    final cardDocumento = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'SOLICITUD DE CRÉDITO — EXPEDIENTE ÚNICO',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Text(
                  estadoLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${v.numeroCotizacion}  |  Cliente: ${v.nombreCliente ?? "#${v.clienteId}"}  |  Total: ${formatRd(v.montoTotal)}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    final bloqueExpediente = v.id == null
        ? const SizedBox.shrink()
        : Builder(
            builder: (context) {
              final asyncExp = ref.watch(
                expedienteCreditoPorVentaProvider((
                  ventaId: v.id!,
                  nombre: v.nombreCliente ?? '',
                  clienteId: v.clienteId,
                )),
              );
              return asyncExp.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Error expediente: $e',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                data: (expediente) => ExpedienteSolicitanteForm(
                  inicial: expediente,
                  editable: puedeEditar || puedeReabrir,
                  onGuardar: (exp) async {
                    try {
                      await ref
                          .read(solicitudCreditoRepositoryProvider)
                          .guardar(exp);
                      // Sync ingreso + límite de cuota al cliente (sugerido 30% si no hay override)
                      try {
                        final repo = ref.read(clienteRepositoryProvider);
                        final cli = await repo.obtenerClientePorId(v.clienteId);
                        if (cli != null && exp.ingresoMensual > 0) {
                          final pct = await ref
                              .read(parametrosCreditoProvider.future)
                              .then((p) => p.capacidadPagoPorcentaje)
                              .catchError((_) => 0.30);
                          final sugerido =
                              CapacidadPagoService.limiteCuotaSugerido(
                            ingresoMensual: exp.ingresoMensual,
                            porcentaje: pct > 0 ? pct : 0.30,
                          );
                          // Solo autocompleta límite si el depto. aún no lo fijó
                          final nuevoLimite = cli.limiteCuotaMensual > 0
                              ? cli.limiteCuotaMensual
                              : sugerido;
                          await repo.guardarCliente(
                            cli.copyWith(
                              ingresoMensual: exp.ingresoMensual,
                              limiteCuotaMensual: nuevoLimite,
                            ),
                          );
                        }
                      } catch (_) {}
                      ref.invalidate(
                        expedienteCreditoPorVentaProvider((
                          ventaId: v.id!,
                          nombre: v.nombreCliente ?? '',
                          clienteId: v.clienteId,
                        )),
                      );
                      if (!context.mounted) return;
                      FiscoGestNotifications.show(
                        const SnackBar(
                          content: Text('Expediente guardado'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (err) {
                      if (!context.mounted) return;
                      FiscoGestNotifications.show(
                        SnackBar(
                          content: Text('Error al guardar: $err'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );

    final abonoMostrarR = abonoMostrar;
    final saldoR = saldo;
    final cuotaTxt = _numeroCuotas > 1
        ? formatRd(saldoR / _numeroCuotas)
        : formatRd(saldoR);

    Widget panelCard({required String title, Widget? trailing, required Widget child}) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(height: 14, color: Color(0xFFF1F5F9)),
            child,
          ],
        ),
      );
    }

    Widget filaCond(String k, String v, {bool bold = false, Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Text(
              v,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    final bloqueCondiciones = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        panelCard(
          title: 'Resumen de Condiciones',
          trailing: const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF94A3B8)),
          child: Column(
            children: [
              filaCond('Abono inicial', formatRd(abonoMostrarR)),
              filaCond('Saldo a financiar', formatRd(saldoR), bold: true),
              filaCond('N° cuotas', '$_numeroCuotas'),
              filaCond(
                'Tasa mensual',
                _tasaMensual > 0
                    ? '${(_tasaMensual * 100).toStringAsFixed(2)}%'
                    : '—',
              ),
              filaCond('Cuota mensual', cuotaTxt, bold: true, valueColor: const Color(0xFF1D4ED8)),
              filaCond(
                'Vencimiento',
                _primerVencimiento != null
                    ? _fmtFecha.format(_primerVencimiento!)
                    : (v.vencimiento != null
                        ? _fmtFecha.format(v.vencimiento!)
                        : '—'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: puedeEditar && !_procesando
                      ? _abrirFormularioCondiciones
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'EDITAR ABONO, PLAZO Y CUOTAS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        panelCard(
          title: 'Resumen del Cliente',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: const Text(
              'Score: — (complete expediente)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ),
        panelCard(
          title: 'Acciones y Documentos',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando ? null : _imprimirSolicitud,
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFDC2626)),
                      label: const Text('SOLICITUD', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando ? null : _imprimirContrato,
                      icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
                      label: const Text('CONTRATO', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando ? null : _enviarSolicitud,
                      icon: const Icon(Icons.send_outlined, size: 16),
                      label: const Text('ENVIAR SOLICITUD', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _procesando ? null : _enviarContrato,
                      icon: const Icon(Icons.mail_outline, size: 16),
                      label: const Text('ENVIAR CONTRATO', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        panelCard(
          title: 'Decisión Final',
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: !puedeEditar || _procesando
                      ? null
                      : () => _cambiarEstado(EstadoDocumento.aprobado),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text(
                    'APROBAR CRÉDITO',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: !puedeEditar || _procesando
                      ? null
                      : () => _cambiarEstado(EstadoDocumento.anulado),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text(
                    'RECHAZAR CRÉDITO',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _procesando
                      ? null
                      : () => _cambiarEstado(EstadoDocumento.enCredito),
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text(
                    'DEVOLVER PARA REVISIÓN',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: AppLayout.pantallaPadding,
      child: AppLayout.centerConstrained(
        maxWidth: maxW,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/creditos/solicitudes');
                  }
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  'Volver',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grey700,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(height: 8),
            cardDocumento,
                AppLayout.vL,
                LayoutBuilder(
                  builder: (context, constraints) {
                    final esAncho = constraints.maxWidth >= 720;
                    if (esAncho) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: bloqueExpediente),
                          AppLayout.hL,
                          Expanded(flex: 1, child: bloqueCondiciones),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        bloqueExpediente,
                        AppLayout.vL,
                        bloqueCondiciones,
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
