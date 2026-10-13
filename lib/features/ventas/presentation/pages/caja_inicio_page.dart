import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/presentation/widgets/shell_drawer_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobro_venta_page.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/services/bitacora_operaciones_service.dart';

/// Hub de la estación de Caja — responsive PC / tablet / móvil.
class CajaInicioPage extends ConsumerStatefulWidget {
  const CajaInicioPage({super.key});

  static const String routeName = 'caja-inicio';
  static const String path = '/ventas/cobro';

  @override
  ConsumerState<CajaInicioPage> createState() => _CajaInicioPageState();
}

class _CajaInicioPageState extends ConsumerState<CajaInicioPage> {
  double? _saldo;
  ResumenSesionCaja? _resumen;
  CajaSesionResumen? _sesion;
  bool _cargando = true;
  String? _error;
  bool _procesando = false;

  static final _fmtFecha = DateFormat('dd/MM/yyyy HH:mm');
  static final _fmtHora = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _refrescar();
  }

  Future<void> _refrescar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(cajaRepositoryProvider);
      final sesion = await repo.obtenerSesionAbierta();
      ResumenSesionCaja? resumen;
      double saldo = 0.0;
      if (sesion != null) {
        resumen = await repo.obtenerResumenSesion(sesion.id);
        saldo = resumen.efectivoEsperado;
      }
      if (!mounted) return;
      setState(() {
        _sesion = sesion;
        _resumen = resumen;
        _saldo = saldo;
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

  bool get _cajaAbierta => _sesion != null && _sesion!.estaAbierta;

  double? _parseMonto(String raw) {
    final s = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  String? _validarMontoNoNegativo(String raw, {String label = 'Monto'}) {
    final v = _parseMonto(raw);
    if (v == null) {
      return '$label inválido. Use números (ej. 1500.50)';
    }
    if (v < 0) return '$label no puede ser negativo';
    if (v > 999999999) return '$label fuera de rango';
    return null;
  }

  bool get _exigeSesionCaja {
    final cfg = ref.read(configuracionControllerProvider).valueOrNull;
    return cfg?.cajaExigirSesion ?? false;
  }

  bool get _puedeCobrar => _cajaAbierta || !_exigeSesionCaja;

  void _irACobrarCotizacion() {
    if (!_puedeCobrar) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Debe abrir la caja antes de cobrar'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.push(CobroVentaPage.pathOperacion);
  }

  void _irACuentasPorCobrar() => context.push('/ventas/cobrar');

  void _irAHistorialTurno() => context.push('/ventas/cobro/historial-turno');

  Future<void> _dialogoAbrirCaja() async {
    final controller = TextEditingController(text: '0');
    final ancho = MediaQuery.of(context).size.width;
    final fondo = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
          title: const Text('Abrir caja', style: AppTypography.h4),
          content: SizedBox(
            width: ancho >= AppBreakpoints.tablet ? 420 : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Indique el fondo inicial (efectivo en cajón).',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppLayout.vM,
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fondo inicial',
                    prefixText: 'RD\$ ',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final err = _validarMontoNoNegativo(
                  controller.text,
                  label: 'Fondo inicial',
                );
                if (err != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, _parseMonto(controller.text));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Abrir'),
            ),
          ],
        );
      },
    );
    if (fondo == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      final sesionId = await ref
          .read(cajaRepositoryProvider)
          .abrirSesion(fondoInicial: fondo);
      try {
        await ref.read(bitacoraOperacionesServiceProvider).registrar(
              accion: 'caja_abierta',
              entidad: 'sesion_caja',
              entidadId: sesionId,
              usuarioId: ref.read(sesionUsuarioIdProvider),
              resumen: 'Caja abierta con fondo de ${formatRd(fondo)}',
              datos: {'fondoInicial': fondo},
            );
      } catch (_) {}
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Caja abierta. Fondo: ${formatRd(fondo)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refrescar();
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

  Future<void> _dialogoCerrarCaja() async {
    if (_sesion == null) return;
    final resumenCierre = await ref
        .read(cajaRepositoryProvider)
        .obtenerResumenSesion(_sesion!.id);
    final teorico = resumenCierre.efectivoEsperado;
    final controller = TextEditingController(text: teorico.toStringAsFixed(2));
    final obsController = TextEditingController();
    final ancho = MediaQuery.of(context).size.width;
    final result = await showDialog<({double contado, String? obs})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final double contado =
                double.tryParse(controller.text.trim().replaceAll(',', '.')) ??
                    teorico;
            final dif = contado - teorico;
            final Color difColor;
            final String difLabel;
            if (dif.abs() < 0.005) {
              difColor = AppColors.success;
              difLabel = 'Cuadre exacto';
            } else if (dif > 0) {
              difColor = AppColors.primary;
              difLabel = 'Sobrante';
            } else {
              difColor = AppColors.error;
              difLabel = 'Faltante';
            }
            final mq = MediaQuery.of(ctx);
            final maxH =
                (mq.size.height - mq.viewInsets.bottom - mq.padding.vertical - 160)
                    .clamp(200.0, 480.0);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: const Text(
                'Arqueo y cierre de caja',
                style: AppTypography.h4,
              ),
              content: SizedBox(
                width: ancho >= AppBreakpoints.tablet ? 440 : double.maxFinite,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sesión #${_sesion!.id} · Fondo ${formatRd(resumenCierre.fondoInicial)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppLayout.vS,
                        Text(
                          '+ Ingresos efectivo ${formatRd(resumenCierre.ingresosEfectivo)}'
                          '  − Egresos ${formatRd(resumenCierre.egresosEfectivo)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Tarjeta ${formatRd(resumenCierre.ingresosTarjeta)} · '
                          'Transfer ${formatRd(resumenCierre.ingresosTransferencia)} · '
                          'Cheque ${formatRd(resumenCierre.ingresosCheque)}'
                          ' (no se cuentan en el cajón)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        AppLayout.vM,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Efectivo esperado',
                                style: AppTypography.labelMedium,
                              ),
                              Text(
                                formatRd(teorico),
                                style: AppTypography.h4.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppLayout.vM,
                        TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Efectivo contado en cajón',
                            prefixText: 'RD\$ ',
                            border: OutlineInputBorder(),
                            helperText: 'Cuente billetes y monedas del cajón',
                          ),
                          autofocus: true,
                          onChanged: (_) => setLocal(() {}),
                        ),
                        AppLayout.vM,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: difColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: difColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                difLabel,
                                style: AppTypography.labelMedium.copyWith(
                                  color: difColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatRd(dif),
                                style: AppTypography.h4.copyWith(
                                  color: difColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppLayout.vM,
                        TextField(
                          controller: obsController,
                          decoration: const InputDecoration(
                            labelText: 'Observación (opcional)',
                            border: OutlineInputBorder(),
                            hintText: 'Ej. faltante por cambio, billete roto…',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final err = _validarMontoNoNegativo(
                      controller.text,
                      label: 'Efectivo contado',
                    );
                    if (err != null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    final v = _parseMonto(controller.text)!;
                    final obs = obsController.text.trim();
                    if ((v - teorico).abs() >= 0.005 && obs.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Explique el faltante o sobrante antes de cerrar.',
                          ),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, (
                      contado: v,
                      obs: obs.isEmpty ? null : obs,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Confirmar cierre'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      final ok = await ref.read(cajaRepositoryProvider).cerrarSesion(
            sesionId: _sesion!.id,
            saldoTeorico: teorico,
            montoContado: result.contado,
            observacion: result.obs,
          );
      if (!mounted) return;
      final dif = result.contado - teorico;
      if (ok) {
        try {
          await ref.read(bitacoraOperacionesServiceProvider).registrar(
                accion: 'caja_cerrada',
                entidad: 'sesion_caja',
                entidadId: _sesion!.id,
                usuarioId: ref.read(sesionUsuarioIdProvider),
                resumen: 'Cierre de caja con diferencia ${formatRd(dif)}',
                datos: {
                  'saldoTeorico': teorico,
                  'montoContado': result.contado,
                  'diferencia': dif,
                  'observacion': result.obs,
                },
              );
        } catch (_) {}
      }
      if (!mounted) return;
      String msg;
      if (!ok) {
        msg = 'No se pudo cerrar la sesión';
      } else if (dif.abs() < 0.005) {
        msg = 'Caja cerrada. Cuadre exacto.';
      } else if (dif > 0) {
        msg = 'Caja cerrada. Sobrante: ${formatRd(dif)}';
      } else {
        msg = 'Caja cerrada. Faltante: ${formatRd(dif.abs())}';
      }
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(msg),
          backgroundColor: ok
              ? (dif.abs() < 0.005 ? AppColors.success : AppColors.warning)
              : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refrescar();
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

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final abierta = _cajaAbierta;
    final maxW = desktop ? 1200 : (mobile ? 520 : 960);

    return AppScaffold(
      title: 'CAJA',
      showBackButton: false,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menú',
        onPressed: () => ShellDrawerScope.open(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refrescar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 28,
              mobile ? 12 : 24,
              mobile ? 16 : 28,
              32,
            ),
            child: AppLayout.centerConstrained(
              maxWidth: maxW,
              child: mobile
                  ? _buildMobile(abierta)
                  : _buildDesktop(abierta),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DESKTOP — layout de la imagen
  // ─────────────────────────────────────────────
  Widget _buildDesktop(bool abierta) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Izquierda: card de saldo (más vertical / estrecha) ──
        Expanded(
          flex: 4,
          child: _buildSaldoCard(mobile: false, abierta: abierta),
        ),
        const SizedBox(width: 28),
        // ── Derecha: operaciones + movimientos ──
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Operaciones',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Accesos rápidos del turno',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _CajaOpTile(
                icon: Icons.point_of_sale_outlined,
                title: 'Cobrar cotización',
                subtitle: _puedeCobrar
                    ? 'Registra un pago y aplica cotizaciones activas.'
                    : 'Requiere caja abierta',
                color: _puedeCobrar ? AppColors.primary : AppColors.grey500,
                onTap: _irACobrarCotizacion,
              ),
              const SizedBox(height: 10),
              _CajaOpTile(
                icon: Icons.description_outlined,
                title: 'Cuentas por cobrar',
                subtitle: 'Gestiona facturas pendientes y pagos de clientes.',
                color: const Color(0xFF6366F1),
                onTap: _irACuentasPorCobrar,
              ),
              const SizedBox(height: 10),
              _CajaOpTile(
                icon: Icons.history_rounded,
                title: 'Historial del turno',
                subtitle: abierta
                    ? 'Revisa la actividad completa de esta sesión.'
                    : 'Movimientos desde hoy 00:00',
                color: const Color(0xFF64748B),
                onTap: _irAHistorialTurno,
              ),
              const SizedBox(height: 24),
              _buildUltimosMovimientos(),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MÓVIL
  // ─────────────────────────────────────────────
  Widget _buildMobile(bool abierta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSaldoCard(mobile: true, abierta: abierta),
        const SizedBox(height: 20),
        Text(
          'Operaciones',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Accesos rápidos del turno',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _CajaOpTile(
          icon: Icons.point_of_sale_outlined,
          title: 'Cobrar cotización',
          subtitle: _puedeCobrar
              ? 'Registra un pago y aplica cotizaciones activas.'
              : 'Requiere caja abierta',
          color: _puedeCobrar ? AppColors.primary : AppColors.grey500,
          onTap: _irACobrarCotizacion,
        ),
        const SizedBox(height: 10),
        _CajaOpTile(
          icon: Icons.description_outlined,
          title: 'Cuentas por cobrar',
          subtitle: 'Gestiona facturas pendientes y pagos de clientes.',
          color: const Color(0xFF6366F1),
          onTap: _irACuentasPorCobrar,
        ),
        const SizedBox(height: 10),
        _CajaOpTile(
          icon: Icons.history_rounded,
          title: 'Historial del turno',
          subtitle: abierta
              ? 'Revisa la actividad completa de esta sesión.'
              : 'Movimientos desde hoy 00:00',
          color: const Color(0xFF64748B),
          onTap: _irAHistorialTurno,
        ),
        const SizedBox(height: 20),
        _buildUltimosMovimientos(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // CARD SALDO (hero)
  // ─────────────────────────────────────────────
  Widget _buildSaldoCard({required bool mobile, required bool abierta}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        mobile ? 20 : 28,
        mobile ? 20 : 36,
        mobile ? 20 : 28,
        mobile ? 20 : 32,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge estado
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: abierta
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.grey200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: abierta ? AppColors.success : AppColors.grey500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      abierta ? 'ABIERTA' : 'CERRADA',
                      style: AppTypography.labelSmall.copyWith(
                        color:
                            abierta ? AppColors.success : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_procesando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Efectivo en cajón',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (_error != null)
            Text(
              'Error: $_error',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            )
          else
            Text(
              formatRd(_saldo ?? 0),
              style: AppTypography.h1.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F3D3A),
                fontSize: mobile ? 32 : 42,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
          if (abierta && _resumen != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tarjeta ${formatRd(_resumen!.ingresosTarjeta)} · '
              'Transfer ${formatRd(_resumen!.ingresosTransferencia)} · '
              'Cheque ${formatRd(_resumen!.ingresosCheque)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_resumen!.egresosEfectivo > 0.001)
              Text(
                'Egresos efectivo ${formatRd(_resumen!.egresosEfectivo)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
          ],
          if (abierta && _sesion != null) ...[
            const SizedBox(height: 20),
            // 3 chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Fondo inicial',
                  value: formatRd(_sesion!.fondoInicial),
                ),
                _MetricChip(
                  icon: Icons.schedule_outlined,
                  label: 'Apertura',
                  value: _fmtFecha.format(_sesion!.fechaApertura),
                ),
                _MetricChip(
                  icon: Icons.work_outline_rounded,
                  label: 'Sesión',
                  value: '#${_sesion!.id}',
                ),
              ],
            ),
          ],
          SizedBox(height: mobile ? 24 : 48),
          if (!abierta)
            SizedBox(
              width: double.infinity,
              height: mobile ? 48 : 56,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _dialogoAbrirCaja,
                icon: const Icon(Icons.lock_open_rounded, size: 20),
                label: const Text(
                  'Abrir Caja',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: mobile ? 48 : 56,
              child: OutlinedButton.icon(
                onPressed: _procesando ? null : _dialogoCerrarCaja,
                icon: const Icon(Icons.lock_outline_rounded, size: 20),
                label: const Text(
                  'Cerrar Caja',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(
                    color: Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                  backgroundColor: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ÚLTIMOS MOVIMIENTOS (UI; datos reales vía historial)
  // ─────────────────────────────────────────────
  Widget _buildUltimosMovimientos() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Últimos movimientos',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _irAHistorialTurno,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ver todos →',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Placeholder visual; el detalle real está en Historial del turno
          _MovimientoRow(
            hora: _cajaAbierta && _sesion != null
                ? _fmtHora.format(_sesion!.fechaApertura)
                : '--:--',
            icon: Icons.lock_open_rounded,
            iconColor: AppColors.info,
            titulo: _cajaAbierta && _sesion != null
                ? 'Apertura de caja · Sesión #${_sesion!.id}'
                : 'Sin sesión abierta',
            subtitulo: _cajaAbierta && _sesion != null
                ? 'Fondo inicial'
                : 'Abre la caja para registrar movimientos',
            monto: _cajaAbierta && _sesion != null
                ? formatRd(_sesion!.fondoInicial)
                : '—',
            montoColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            'Consulta el historial del turno para ver cobros, retiros y ajustes.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHIPS DE MÉTRICAS
// ─────────────────────────────────────────────
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TILE DE OPERACIÓN
// ─────────────────────────────────────────────
class _CajaOpTile extends StatelessWidget {
  const _CajaOpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILA DE MOVIMIENTO
// ─────────────────────────────────────────────
class _MovimientoRow extends StatelessWidget {
  const _MovimientoRow({
    required this.hora,
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.subtitulo,
    required this.monto,
    required this.montoColor,
  });

  final String hora;
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String subtitulo;
  final String monto;
  final Color montoColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              hora,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitulo,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            monto,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: montoColor,
            ),
          ),
        ],
      ),
    );
  }
}
