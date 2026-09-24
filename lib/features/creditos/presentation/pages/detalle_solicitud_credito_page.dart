import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/solicitudes_credito_page.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/expediente_solicitante_form.dart';
// creditoDocumentoServiceProvider está en el mismo archivo de providers
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

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

  static final _fmt = NumberFormat('#,##0.00', 'es_DO');
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
        _primerVencimiento = v.vencimiento;
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
      ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _onCreditoConfirmado(ResultadoFormularioCredito resultado) async {
    final cuenta = resultado.cuenta;
    setState(() {
      _modoFormularioCredito = false;
      _estadoFormularioCredito = null;
      _cuentaBorrador = cuenta;
      _abono = cuenta.abonoInicial;
      _numeroCuotas = cuenta.numeroCuotas < 1 ? 1 : cuenta.numeroCuotas;
      _tasaMensual = cuenta.tasaInteres;
      _primerVencimiento = cuenta.fechaVencimiento;
      if (resultado.planPago != null &&
          resultado.planPago!.cuotas.isNotEmpty) {
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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
        if (cuenta != null) {
          final conVenta = cuenta.copyWith(ventaId: v.id);
          await ref.read(cuentaPorCobrarRepositoryProvider).registrarCredito(
                cuenta: conVenta,
                planPago: conVenta.planPago,
                abonoInicial: null,
              );
        } else {
          // Sin formulario previo: cuenta mínima desde la cotización
          final minima = CuentaPorCobrar(
            clienteId: v.clienteId,
            clienteNombre: v.nombreCliente,
            ventaId: v.id,
            totalOriginal: v.montoTotal,
            abonoInicial: conCond.abonoInicial,
            fechaCreacion: DateTime.now(),
            fechaVencimiento:
                conCond.vencimiento ?? DateTime.now().add(const Duration(days: 30)),
          );
          await ref.read(cuentaPorCobrarRepositoryProvider).registrarCredito(
                cuenta: minima,
              );
        }
      }
      await ref
          .read(ventasRepositoryProvider)
          .cambiarEstadoDocumento(v.id!, nuevo);
      if (!mounted) return;
      ref.invalidate(solicitudesCreditoProvider);
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      fechaVencimiento: _primerVencimiento ??
          v.vencimiento ??
          DateTime.now().add(const Duration(days: 30)),
    );
  }

  Future<void> _imprimirSolicitud() async {
    final v = _venta;
    if (v == null) return;
    setState(() => _procesando = true);
    try {
      await (await ref.read(creditoDocumentoServiceProvider.future)).imprimirSolicitud(
            venta: v,
            condiciones: _condicionesEfectivas,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _imprimirContrato() async {
    final v = _venta;
    final cond = _condicionesEfectivas;
    if (v == null) return;
    if (cond == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Defina condiciones (abono/cuotas) antes del contrato'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _procesando = true);
    try {
      await (await ref.read(creditoDocumentoServiceProvider.future)).imprimirContrato(
            venta: v,
            condiciones: cond,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Defina condiciones antes de enviar el contrato'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _procesando = true);
    try {
      final svc = await ref.read(creditoDocumentoServiceProvider.future);
      await svc.enviarContratoPorCorreo(venta: v, condiciones: cond);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
    return AppScaffold(
      title: 'SOLICITUD DE CRÉDITO',
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
                    : _modoFormularioCredito &&
                            _estadoFormularioCredito != null
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
    final puedeReabrir =
        esCr && v.estadoDocumento == EstadoDocumento.cotizado;
    final abonoMostrar = _abono > 0 ? _abono : v.abonoInicial;
    final saldo =
        (v.montoTotal - abonoMostrar).clamp(0.0, double.infinity);

    final maxW = AppBreakpoints.isDesktop(context)
        ? 1100
        : (AppBreakpoints.isTablet(context) ? 900 : 720);

    final cardDocumento = AppCard(
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.numeroCotizacion,
            style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          AppLayout.vS,
          Text(
            'Cliente: ${v.nombreCliente ?? "#${v.clienteId}"}',
            style: AppTypography.bodyMedium,
          ),
          Text(
            'Total: RD\$ ${_fmt.format(v.montoTotal)}',
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w600),
          ),
          AppLayout.vS,
          StatusChip(
            label: v.estadoDocumento.name.toUpperCase(),
            type: v.estadoDocumento == EstadoDocumento.aprobado
                ? StatusChipType.success
                : v.estadoDocumento == EstadoDocumento.enCredito
                    ? StatusChipType.warning
                    : StatusChipType.neutral,
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
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.error),
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
                      ref.invalidate(
                        expedienteCreditoPorVentaProvider((
                          ventaId: v.id!,
                          nombre: v.nombreCliente ?? '',
                          clienteId: v.clienteId,
                        )),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expediente guardado'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (err) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
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

    final bloqueCondiciones = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Condiciones de crédito',
          subtitle: 'Usa el mismo formulario de abono, tasa y cuotas',
          actionLabel: puedeEditar ? 'Editar' : null,
          onAction: puedeEditar && !_procesando
              ? _abrirFormularioCondiciones
              : null,
        ),
        AppCard(
          borderColor: AppColors.border,
          child: Column(
            children: [
              AppLayout.filaDato(
                etiqueta: 'Abono inicial',
                valor: 'RD\$ ${_fmt.format(abonoMostrar)}',
              ),
              AppLayout.filaDato(
                etiqueta: 'Saldo a financiar',
                valor: 'RD\$ ${_fmt.format(saldo)}',
              ),
              AppLayout.filaDato(
                etiqueta: 'N° cuotas',
                valor: '$_numeroCuotas',
              ),
              AppLayout.filaDato(
                etiqueta: 'Tasa mensual',
                valor: _tasaMensual > 0
                    ? '${(_tasaMensual * 100).toStringAsFixed(2)}%'
                    : (_cuentaBorrador != null ? '0%' : '—'),
              ),
              AppLayout.filaDato(
                etiqueta: 'Vencimiento',
                valor: (_primerVencimiento ?? v.vencimiento) != null
                    ? _fmtFecha.format(_primerVencimiento ?? v.vencimiento!)
                    : '—',
              ),
            ],
          ),
        ),
        if (puedeEditar) ...[
          AppLayout.vM,
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _procesando ? null : _abrirFormularioCondiciones,
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('EDITAR ABONO, PLAZO Y CUOTAS'),
            ),
          ),
          AppLayout.vS,
          ResponsiveRow(
            breakpoint: 600,
            child1: OutlinedButton.icon(
              onPressed: _procesando ? null : _imprimirSolicitud,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('SOLICITUD'),
            ),
            child2: OutlinedButton.icon(
              onPressed: _procesando ? null : _imprimirContrato,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('CONTRATO'),
            ),
          ),
          AppLayout.vS,
          ResponsiveRow(
            breakpoint: 600,
            child1: OutlinedButton.icon(
              onPressed: _procesando ? null : _enviarSolicitud,
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('ENVIAR SOLICITUD'),
            ),
            child2: OutlinedButton.icon(
              onPressed: _procesando ? null : _enviarContrato,
              icon: const Icon(Icons.attach_email_outlined, size: 18),
              label: const Text('ENVIAR CONTRATO'),
            ),
          ),
          AppLayout.vL,
          AppButton(
            text: 'APROBAR CRÉDITO',
            icon: Icons.check_circle_outline,
            onPressed: _procesando
                ? null
                : () => _cambiarEstado(EstadoDocumento.aprobado),
            isDisabled: _procesando,
            width: double.infinity,
          ),
          AppLayout.vS,
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _procesando
                  ? null
                  : () => _cambiarEstado(EstadoDocumento.anulado),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('RECHAZAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
        if (puedeReabrir) ...[
          AppLayout.vM,
          AppButton(
            text: 'PASAR A ANÁLISIS DE CRÉDITO',
            icon: Icons.assignment_turned_in_outlined,
            onPressed: _procesando
                ? null
                : () => _cambiarEstado(EstadoDocumento.enCredito),
            isDisabled: _procesando,
            width: double.infinity,
          ),
          AppLayout.vS,
          Text(
            'Este CR- está en estado cotizado. Pásalo a análisis para editar condiciones y aprobar.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        if (!puedeEditar && !puedeReabrir) ...[
          AppLayout.vL,
          Text(
            v.estadoDocumento == EstadoDocumento.aprobado
                ? 'Aprobado. El cajero puede facturar en Caja.'
                : 'Esta solicitud ya no está en análisis.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );

    return SingleChildScrollView(
      padding: AppLayout.pantallaPadding,
      child: AppLayout.centerConstrained(
        maxWidth: maxW,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancha = constraints.maxWidth >= 720;
            if (!ancha) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cardDocumento,
                  AppLayout.vL,
                  bloqueExpediente,
                  AppLayout.vL,
                  bloqueCondiciones,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cardDocumento,
                AppLayout.vL,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: bloqueExpediente),
                    AppLayout.hM,
                    Expanded(flex: 2, child: bloqueCondiciones),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}
