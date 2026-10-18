import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/domain/services/pronto_pago_service.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/pronto_pago_acuerdos_dao.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/estado_credito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart'
    as venta_providers;
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/services/bitacora_operaciones_service.dart';

class DetalleCuentaCobrarPage extends ConsumerStatefulWidget {
  const DetalleCuentaCobrarPage({super.key, required this.cuentaId});

  static const String routeName = 'credito-cuenta-detalle';
  static const String path = '/creditos/cuentas/:id';

  final int cuentaId;

  @override
  ConsumerState<DetalleCuentaCobrarPage> createState() =>
      _DetalleCuentaCobrarPageState();
}

class _DetalleCuentaCobrarPageState
    extends ConsumerState<DetalleCuentaCobrarPage> {
  CuentaPorCobrar? _cuenta;
  ProntoPagoAcuerdoData? _acuerdoActivo;
  final List<({String nombre, int cantidad, double total})> _lineas = [];
  bool _cargando = true;
  String? _error;
  bool _pagando = false;
  bool _imprimiendoCronograma = false;
  bool _imprimiendoEstadoCuenta = false;

  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _imprimirCronograma(CuentaPorCobrar c) async {
    if (c.planPago == null || c.planPago!.cuotas.isEmpty) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(content: Text('No hay cuotas para imprimir')),
      );
      return;
    }
    setState(() => _imprimiendoCronograma = true);
    try {
      final svc = await ref.read(creditoDocumentoServiceProvider.future);
      await svc.imprimirCronograma(cuenta: c);
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Error al imprimir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimiendoCronograma = false);
    }
  }

  Future<void> _imprimirEstadoCuenta(CuentaPorCobrar c) async {
    setState(() => _imprimiendoEstadoCuenta = true);
    try {
      final svc = await ref.read(creditoDocumentoServiceProvider.future);
      await svc.imprimirEstadoCuenta(cuenta: c);
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Error al imprimir estado de cuenta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _imprimiendoEstadoCuenta = false);
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _lineas.clear();
    });
    try {
      final repo = ref.read(cuentaPorCobrarRepositoryProvider);
      final CuentaPorCobrar? c = await repo.obtenerPorId(widget.cuentaId);
      if (c == null) {
        setState(() {
          _error = 'Cuenta no encontrada';
          _cargando = false;
        });
        return;
      }
      // Local no-nullable: copyWith no degrada el tipo
      CuentaPorCobrar cuenta = c;
      if (cuenta.clienteNombre == null || cuenta.clienteNombre!.isEmpty) {
        try {
          final IClienteRepository cliRepo = ref.read(
            clienteRepositoryProvider,
          );
          final cli = await cliRepo.obtenerClientePorId(cuenta.clienteId);
          if (cli != null) {
            cuenta = cuenta.copyWith(clienteNombre: cli.nombre);
          }
        } catch (_) {}
      }
      final int? ventaId = cuenta.ventaId;
      if (ventaId != null && ventaId > 0) {
        try {
          final IVentasRepository vRepo = ref.read(
            venta_providers.ventasRepositoryProvider,
          );
          final venta = await vRepo.obtenerVentaPorId(ventaId);
          if (venta != null) {
            for (final d in venta.detalles) {
              final total = d.subtotal > 0
                  ? d.subtotal
                  : (d.cantidad * d.precioUnitario);
              _lineas.add((
                nombre:
                    (d.nombreProducto != null &&
                        d.nombreProducto!.trim().isNotEmpty)
                    ? d.nombreProducto!.trim()
                    : 'Producto #${d.productoId}',
                cantidad: d.cantidad,
                total: total,
              ));
            }
          }
        } catch (_) {}
      }
      if (!mounted) return;
      ProntoPagoAcuerdoData? acuerdoDb;
        try {
          if (cuenta.id != null) {
            acuerdoDb = await ProntoPagoAcuerdosDao(ref.read(databaseProvider))
                .activoPorCuenta(cuenta.id!);
          }
        } catch (_) {
          acuerdoDb = null;
        }
        if (!mounted) return;
        setState(() {
          _cuenta = cuenta;
          _acuerdoActivo = acuerdoDb;
          _cargando = false;
        });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  Future<void> _dialogoRegistrarPago() async {
    final c = _cuenta;
    if (c == null || c.id == null) return;

    final calc0 = ProntoPagoService.calcular(c, descuentoInteresPct: 0);
    if (!calc0.elegible) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(calc0.error ?? 'No aplica pronto pago'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final acuerdo = await showDialog<_ProntoPagoResultado>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProntoPagoDialog(cuenta: c),
    );
    await Future<void>.delayed(Duration.zero);
    if (acuerdo == null || !mounted) return;

    // Solo registra el ACUERDO (no cobra). El plan de cuotas sigue vigente
    // hasta que Caja cobre la liquidación o el cliente pague cuotas normales.
    setState(() => _pagando = true);
    try {
      final calc = acuerdo.calculo;
      final dao = ProntoPagoAcuerdosDao(ref.read(databaseProvider));
      await dao.guardarAcuerdo(
        cuentaId: c.id!,
        capitalPendiente: calc.capitalPendiente,
        interesPendiente: calc.interesPendiente,
        descuentoInteresPct: calc.descuentoInteresPct,
        descuentoMonto: calc.descuentoSobreInteres,
        interesTrasDescuento: calc.interesTrasDescuento,
        montoLiquidacion: calc.montoLiquidacion,
        cuotasPendientes: calc.cuotasPendientes,
        notas: acuerdo.nota,
        usuarioId: ref.read(sesionUsuarioIdProvider),
      );
      final activo = await dao.activoPorCuenta(c.id!);
      if (mounted) {
        setState(() => _acuerdoActivo = activo);
      }
      try {
        await ref.read(bitacoraOperacionesServiceProvider).registrar(
              accion: 'pronto_pago_acordado',
              entidad: 'cuenta_por_cobrar',
              entidadId: c.id,
              usuarioId: ref.read(sesionUsuarioIdProvider),
              resumen:
                  'Pronto pago: liquidación ${formatRd(acuerdo.calculo.montoLiquidacion)} '
                  '(desc. ${acuerdo.calculo.descuentoInteresPct.toStringAsFixed(0)}% interés)',
              datos: {
                'capital': acuerdo.calculo.capitalPendiente,
                'interes': acuerdo.calculo.interesPendiente,
                'liquidacion': acuerdo.calculo.montoLiquidacion,
                'descuentoPct': acuerdo.calculo.descuentoInteresPct,
              },
            );
      } catch (_) {}

      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'Acuerdo de pronto pago registrado. '
            'Liquidación: ${formatRd(acuerdo.calculo.montoLiquidacion)}. '
            'Caja puede cobrar ese monto; si no se paga, las cuotas siguen normales.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final c = _cuenta;
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'DETALLE DE CUENTA',
      showAppBar: !desktop,
      actions: c == null
          ? null
          : [
              IconButton(
                tooltip: 'Imprimir estado de cuenta',
                onPressed: _imprimiendoEstadoCuenta
                    ? null
                    : () => _imprimirEstadoCuenta(c),
                icon: _imprimiendoEstadoCuenta
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined),
              ),
            ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/creditos/cuentas');
          }
        },
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: AppLayout.pantallaPadding,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            )
          : c == null
          ? const Center(child: Text('Cuenta no encontrada'))
          : Column(
              children: [
                Expanded(child: _buildBody(c)),
                if (!c.estaPagada)
                  SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _pagando
                                  ? null
                                  : _dialogoRegistrarPago,
                              icon: const Icon(Icons.payments_outlined),
                              label: Text(
                                _pagando
                                    ? 'Registrando…'
                                    : 'Pronto pago / liquidar',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildBody(CuentaPorCobrar c) {
    final mobile = AppBreakpoints.isMobile(context);
    final pctPagado = c.totalAPagar > 0
        ? ((c.totalAbonado / c.totalAPagar) * 100).clamp(0.0, 100.0)
        : 0.0;
    final estadoLabel = c.estado.nombre.toUpperCase();
    final esAlDia = c.estado == EstadoCredito.alDia || c.estaPagada;

    Widget cardShell({required Widget child, EdgeInsetsGeometry? padding}) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    Widget kpi({
      required String label,
      required String value,
      String? hint,
      Color? bg,
      Color? border,
      Color? valueColor,
      Color? labelColor,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg ?? const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border ?? const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: labelColor ?? const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 10,
                  color: labelColor ?? const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ── Header ──
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Row(
          children: [
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/creditos/cuentas');
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF64748B),
              ),
              child: const Text('Crédito', style: TextStyle(fontSize: 12)),
            ),
            const Text('  ›  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            TextButton(
              onPressed: () => context.go('/creditos/cuentas'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF64748B),
              ),
              child: const Text('Cuentas por Cobrar', style: TextStyle(fontSize: 12)),
            ),
            const Text('  ›  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const Text(
              'Detalle de cuenta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Detalle de cuenta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: esAlDia
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: esAlDia
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFFFCD34D),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: esAlDia
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    estadoLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: esAlDia
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Gestión integral de cuotas, saldos pendientes y registro inmediato de cobros.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        // Acciones globales
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                FiscoGestNotifications.show(
                  const SnackBar(
                    content: Text('Recordatorio: conectar WhatsApp en una próxima iteración'),
                  ),
                );
              },
              icon: const Icon(Icons.chat, size: 16, color: Color(0xFF059669)),
              label: const Text(
                'Enviar Recordatorio',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _imprimiendoEstadoCuenta
                  ? null
                  : () => _imprimirEstadoCuenta(c),
              icon: _imprimiendoEstadoCuenta
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 16),
              label: const Text(
                'Estado de Cuenta',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
              ),
            ),
            FilledButton.icon(
              onPressed: c.estaPagada || _pagando ? null : _dialogoRegistrarPago,
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: Text(
                _pagando ? 'Procesando…' : 'Pronto pago / liquidar',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );

    // ── Banner cliente + progreso + KPIs ──
    final banner = cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bannerCliente(c),
                const SizedBox(height: 12),
                _barraProgreso(c, pctPagado),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _bannerCliente(c)),
                const SizedBox(width: 16),
                SizedBox(width: 280, child: _barraProgreso(c, pctPagado)),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final items = [
                kpi(
                  label: 'Total Original',
                  value: formatRd(c.totalOriginal),
                  hint: 'Monto contratado',
                ),
                kpi(
                  label: 'Total Abonado',
                  value: formatRd(c.totalAbonado),
                  hint: '${c.abonos.length} pago${c.abonos.length == 1 ? '' : 's'} registrado${c.abonos.length == 1 ? '' : 's'}',
                  bg: const Color(0xFFECFDF5),
                  border: const Color(0xFFA7F3D0),
                  valueColor: const Color(0xFF047857),
                  labelColor: const Color(0xFF065F46),
                ),
                kpi(
                  label: 'Saldo Pendiente',
                  value: formatRd(c.saldoPendiente),
                  hint: 'Por amortizar',
                  bg: const Color(0xFFEFF6FF),
                  border: const Color(0xFFBFDBFE),
                  valueColor: const Color(0xFF1D4ED8),
                  labelColor: const Color(0xFF1E40AF),
                ),
                kpi(
                  label: 'Próximo Vencimiento',
                  value: _fmtFecha.format(c.fechaVencimiento),
                  hint: esAlDia ? 'En plazo' : 'Revisar atraso',
                ),
                kpi(
                  label: 'Frecuencia / Tasa',
                  value: c.numeroCuotas <= 1
                      ? '1 Cuota Única'
                      : '${c.numeroCuotas} Cuotas',
                  hint: c.tasaInteres > 0
                      ? 'Tasa ${(c.tasaInteres * 100).toStringAsFixed(1)}%'
                      : 'Tasa Fija 0%',
                ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: items[i]),
                    ],
                  ],
                );
              }
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: items,
              );
            },
          ),
        ],
      ),
    );

    // ── Acuerdo pronto pago activo ──
    final acuerdoActivo = _acuerdoActivo;
    final acuerdoCard = acuerdoActivo == null
        ? const SizedBox.shrink()
        : cardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Acuerdo de pronto pago activo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF047857),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Liquidación acordada: ${formatRd(acuerdoActivo.montoLiquidacion)} '
                  '(desc. ${acuerdoActivo.descuentoInteresPct.toStringAsFixed(0)}% sobre intereses). '
                  'Si el cliente no liquida en Caja, las cuotas siguen vigentes.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                ),
              ],
            ),
          );

    // ── Plan de cuotas ──
    final cuotas = c.planPago?.cuotas ?? const <Cuota>[];
    final planCard = cardShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Plan de Cuotas / Cronograma de Pagos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _imprimiendoCronograma
                      ? null
                      : () => _imprimirCronograma(c),
                  icon: _imprimiendoCronograma
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Imprimir Tabla',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (cuotas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sin plan de cuotas estructurado (pago único / sin desglose).',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            )
          else ...[
            // Cabecera tabla (desktop)
            if (!mobile)
              Container(
                color: const Color(0xFFF8FAFC),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('CUOTA #', style: _th)),
                    Expanded(flex: 2, child: Text('VENCIMIENTO', style: _th)),
                    Expanded(flex: 2, child: Text('CAPITAL', style: _th)),
                    Expanded(flex: 2, child: Text('INTERÉS', style: _th)),
                    Expanded(flex: 2, child: Text('TOTAL', style: _th)),
                    Expanded(flex: 2, child: Text('ESTADO', style: _th)),
                    SizedBox(width: 72, child: Text('ACCIÓN', style: _th, textAlign: TextAlign.right)),
                  ],
                ),
              ),
            for (final q in cuotas)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Cuota ${q.numeroCuota}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              _chipEstadoCuota(q.pagada),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vence ${_fmtFecha.format(q.fechaVencimiento)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                formatRd(q.montoTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              if (!q.pagada && !c.estaPagada)
                                TextButton(
                                  onPressed: _pagando
                                      ? null
                                      : _dialogoRegistrarPago,
                                  child: const Text('Cobrar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Cuota ${q.numeroCuota}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _fmtFecha.format(q.fechaVencimiento),
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatRd(q.montoCapital),
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatRd(q.montoInteres),
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatRd(q.montoTotal),
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                            ),
                          ),
                          Expanded(flex: 2, child: _chipEstadoCuota(q.pagada)),
                          SizedBox(
                            width: 72,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: q.pagada || c.estaPagada
                                  ? const SizedBox.shrink()
                                  : TextButton(
                                      onPressed: _pagando
                                          ? null
                                          : _dialogoRegistrarPago,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF047857),
                                        backgroundColor:
                                            const Color(0xFFECFDF5),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Cobrar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Mostrando ${cuotas.length} cuota${cuotas.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),
                  Text(
                    'Total pendiente: ${formatRd(c.saldoPendiente)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // ── Pagos realizados ──
    final pagosCard = cardShell(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.history,
                    size: 18, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pagos Realizados e Historial de Transacciones',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '${c.abonos.length} Transacción${c.abonos.length == 1 ? '' : 'es'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (c.abonos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Aún no hay abonos registrados.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            )
          else ...[
            if (!mobile)
              Container(
                color: const Color(0xFFF8FAFC),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('FECHA', style: _th)),
                    Expanded(flex: 2, child: Text('MÉTODO', style: _th)),
                    Expanded(flex: 2, child: Text('MONTO', style: _th)),
                    Expanded(flex: 2, child: Text('NOTA', style: _th)),
                    Expanded(flex: 1, child: Text('ESTADO', style: _th)),
                  ],
                ),
              ),
            for (final a in c.abonos)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
                child: mobile
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fmtFecha.format(a.fecha),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(
                                  a.metodoPago,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatRd(a.monto),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF047857),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _fmtFecha.format(a.fecha),
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              a.metodoPago,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatRd(a.monto),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              a.nota?.isNotEmpty == true ? a.nota! : '—',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'APLICADO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ],
      ),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 20,
          mobile ? 12 : 16,
          mobile ? 16 : 20,
          28,
        ),
        children: [
          AppLayout.centerConstrained(
            maxWidth: desktopMaxWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 16),
                banner,
                acuerdoCard,
                planCard,
                pagosCard,
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _th = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color(0xFF64748B),
    letterSpacing: 0.4,
  );

  int desktopMaxWidth(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) return 1100;
    if (AppBreakpoints.isTablet(context)) return 900;
    return 560;
  }

  Widget _bannerCliente(CuentaPorCobrar c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Icon(Icons.folder_open, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      c.numero ?? 'CXC-${c.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (c.ventaId != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Venta relacionada: #${c.ventaId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                c.clienteNombre ?? 'Cliente #${c.clienteId}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _barraProgreso(CuentaPorCobrar c, double pct) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Progreso de Pago',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              Text(
                '${pct.toStringAsFixed(1)}% Pagado',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Abonado: ${formatRd(c.totalAbonado)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              Text(
                'Total: ${formatRd(c.totalAPagar)}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipEstadoCuota(bool pagada) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pagada ? const Color(0xFFD1FAE5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: pagada ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
        ),
      ),
      child: Text(
        pagada ? 'PAGADA' : 'PENDIENTE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: pagada ? const Color(0xFF065F46) : const Color(0xFF92400E),
        ),
      ),
    );
  }}




class _ProntoPagoResultado {
  const _ProntoPagoResultado({required this.calculo, this.nota = ''});
  final ProntoPagoCalculo calculo;
  final String nota;
}

class _ProntoPagoDialog extends StatefulWidget {
  const _ProntoPagoDialog({required this.cuenta});
  final CuentaPorCobrar cuenta;

  @override
  State<_ProntoPagoDialog> createState() => _ProntoPagoDialogState();
}

class _ProntoPagoDialogState extends State<_ProntoPagoDialog> {
  final _pctCtrl = TextEditingController(text: '0');
  final _notaCtrl = TextEditingController();

  @override
  void dispose() {
    _pctCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  ProntoPagoCalculo get _calc {
    final pct = double.tryParse(_pctCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    return ProntoPagoService.calcular(
      widget.cuenta,
      descuentoInteresPct: pct,
    );
  }

  void _confirmar() {
    final calc = _calc;
    if (!calc.elegible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(calc.error ?? 'No elegible')),
      );
      return;
    }
    Navigator.of(context).pop(
      _ProntoPagoResultado(calculo: calc, nota: _notaCtrl.text.trim()),
    );
  }

  Widget _row(String k, String v, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calc;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Pronto pago (descuento sobre intereses)',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tabla de liquidación anticipada (estilo bancario): '
                'el descuento aplica solo a los intereses de las cuotas '
                'aún no pagadas. El capital se paga completo. '
                'Si el cliente no liquida, continúa pagando sus cuotas normales.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _row('Cuotas pendientes', '${calc.cuotasPendientes}'),
                    _row(
                      'Capital adeudado',
                      formatRd(calc.capitalPendiente),
                      bold: true,
                    ),
                    _row(
                      'Intereses adeudados',
                      formatRd(calc.interesPendiente),
                    ),
                    const Divider(height: 16),
                    _row(
                      'Descuento sobre intereses',
                      '- ${formatRd(calc.descuentoSobreInteres)}',
                      color: const Color(0xFF047857),
                    ),
                    _row(
                      'Interés a pagar',
                      formatRd(calc.interesTrasDescuento),
                    ),
                    const Divider(height: 16),
                    _row(
                      'TOTAL LIQUIDACIÓN',
                      formatRd(calc.montoLiquidacion),
                      bold: true,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pctCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '% descuento sobre intereses',
                  hintText: '0 – 100',
                  border: OutlineInputBorder(),
                  helperText: 'Ej: 50 = condona la mitad de los intereses',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notaCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nota del acuerdo (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (calc.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  calc.error!,
                  style: const TextStyle(color: Color(0xFFBE123C), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: calc.elegible ? _confirmar : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF047857)),
          child: const Text('Aprobar acuerdo'),
        ),
      ],
    );
  }
}

