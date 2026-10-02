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
  CajaSesionResumen? _sesion;
  bool _cargando = true;
  String? _error;
  bool _procesando = false;

  static final _fmtFecha = DateFormat('dd/MM/yyyy HH:mm');

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
      final saldo = await repo.obtenerSaldoActual();
      final sesion = await repo.obtenerSesionAbierta();
      if (!mounted) return;
      setState(() {
        _saldo = saldo ?? 0.0;
        _sesion = sesion;
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

  /// Parsea monto (coma o punto). null si no es número.
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

  /// Política de Configuración → Caja (default: no exigir).
  bool get _exigeSesionCaja {
    final cfg = ref.read(configuracionControllerProvider).valueOrNull;
    return cfg?.cajaExigirSesion ?? false;
  }

  /// Puede entrar a cobrar: caja abierta O política no exige sesión.
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
        await ref
            .read(bitacoraOperacionesServiceProvider)
            .registrar(
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
    final teorico = _saldo ?? 0.0;
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
                (mq.size.height -
                        mq.viewInsets.bottom -
                        mq.padding.vertical -
                        160)
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
                          'Sesión #${_sesion!.id} · Fondo inicial ${formatRd(_sesion!.fondoInicial)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
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
                                'Saldo teórico',
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
    // controllers liberados con el cierre del diálogo
    if (result == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      final ok = await ref
          .read(cajaRepositoryProvider)
          .cerrarSesion(
            sesionId: _sesion!.id,
            saldoTeorico: teorico,
            montoContado: result.contado,
            observacion: result.obs,
          );
      if (!mounted) return;
      final dif = result.contado - teorico;
      if (ok) {
        try {
          await ref
              .read(bitacoraOperacionesServiceProvider)
              .registrar(
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
      // controllers del diálogo: no dispose aquí (evita _dependents.isEmpty)
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final abierta = _cajaAbierta;
    final maxW = desktop ? 1280 : (mobile ? 520 : 960);

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
            padding: AppLayout.pantallaPadding.add(
              const EdgeInsets.only(bottom: 24),
            ),
            child: AppLayout.centerConstrained(
              maxWidth: maxW,
              child: Column(
                crossAxisAlignment: mobile
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: mobile ? double.infinity : 640,
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          mobile ? 20 : 28,
                          mobile ? 22 : 28,
                          mobile ? 20 : 28,
                          mobile ? 22 : 28,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                              AppColors.primaryLight.withValues(alpha: 0.95),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: mobile ? 56 : 64,
                              height: mobile ? 56 : 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.point_of_sale_rounded,
                                color: AppColors.primary,
                                size: mobile ? 30 : 34,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estación de caja',
                                    style:
                                        (mobile
                                                ? AppTypography.h4
                                                : AppTypography.h3)
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Apertura, cobros, arqueo y movimientos del turno.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (mobile) ...[
                    _buildEstadoTurno(mobile, abierta),
                    AppLayout.vL,
                    const SectionHeader(
                      title: 'Operaciones',
                      subtitle: 'Estación de caja',
                    ),
                    const SizedBox(height: 12),
                    AppAccessGrid(
                      minTileWidth: 200,
                      maxColumns: 1,
                      spacing: 16,
                      runSpacing: 16,
                      tileHeight: 200,
                      children: [
                        AppHubCard(
                          icon: Icons.point_of_sale_outlined,
                          title: 'Cobrar cotización',
                          subtitle: _puedeCobrar
                              ? 'Buscar por N° o cliente y generar factura'
                              : 'Requiere caja abierta',
                          color: _puedeCobrar
                              ? AppColors.success
                              : AppColors.grey500,
                          onTap: _irACobrarCotizacion,
                        ),
                        AppHubCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Cuentas por cobrar',
                          subtitle:
                              'Cuotas, pagos e impresión de estados de cuenta',
                          color: AppColors.info,
                          onTap: _irACuentasPorCobrar,
                        ),
                        AppHubCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Historial del turno',
                          subtitle: abierta
                              ? 'Movimientos desde la apertura'
                              : 'Movimientos desde hoy 00:00',
                          color: AppColors.primary,
                          onTap: _irAHistorialTurno,
                        ),
                      ],
                    ),
                  ] else ...[
                    // PC: izquierda turno | derecha operaciones (aprovecha el ancho)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 520,
                          child: _buildEstadoTurno(mobile, abierta),
                        ),
                        const Spacer(),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: 520,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(
                                title: 'Operaciones',
                                subtitle: 'Accesos rápidos del turno',
                              ),
                              const SizedBox(height: 16),
                              ...[
                                _CajaOpTile(
                                  icon: Icons.point_of_sale_outlined,
                                  title: 'Cobrar cotización',
                                  subtitle: _puedeCobrar
                                      ? 'Buscar por N° o cliente y generar factura'
                                      : 'Requiere caja abierta',
                                  color: _puedeCobrar
                                      ? AppColors.success
                                      : AppColors.grey500,
                                  onTap: _irACobrarCotizacion,
                                ),
                                const SizedBox(height: 14),
                                _CajaOpTile(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: 'Cuentas por cobrar',
                                  subtitle:
                                      'Cuotas, pagos e impresión de estados de cuenta',
                                  color: AppColors.info,
                                  onTap: _irACuentasPorCobrar,
                                ),
                                const SizedBox(height: 14),
                                _CajaOpTile(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Historial del turno',
                                  subtitle: abierta
                                      ? 'Movimientos desde la apertura'
                                      : 'Movimientos desde hoy 00:00',
                                  color: AppColors.primary,
                                  onTap: _irAHistorialTurno,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  AppLayout.vXl,
                  Text(
                    'El cobro de cotizaciones asigna N° de factura e impacta '
                    'inventario y movimientos de caja.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoTurno(bool mobile, bool abierta) {
    return AppCard(
      borderColor: AppColors.border,
      padding: EdgeInsets.all(mobile ? AppSpacing.m : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: abierta ? 'ABIERTA' : 'CERRADA',
                type: abierta ? StatusChipType.success : StatusChipType.neutral,
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
          AppLayout.vM,
          Text(
            'Saldo registrado',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppLayout.vXs,
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 24,
                height: 24,
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
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: mobile ? 28 : 42,
              ),
            ),
          if (abierta && _sesion != null) ...[
            AppLayout.vS,
            Text(
              'Fondo inicial: ${formatRd(_sesion!.fondoInicial)}'
              '  ·  Apertura: ${_fmtFecha.format(_sesion!.fechaApertura)}'
              '  ·  Sesión #${_sesion!.id}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          AppLayout.vM,
          if (!abierta)
            AppButton(
              text: 'ABRIR CAJA',
              icon: Icons.lock_open,
              onPressed: _procesando ? null : _dialogoAbrirCaja,
              isDisabled: _procesando,
              width: double.infinity,
              height: mobile ? 48 : 52,
            )
          else
            SizedBox(
              width: double.infinity,
              height: mobile ? 48 : 52,
              child: OutlinedButton.icon(
                onPressed: _procesando ? null : _dialogoCerrarCaja,
                icon: const Icon(Icons.lock_outline, size: 20),
                label: Text(
                  'CERRAR CAJA',
                  style: AppTypography.button.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.grey900.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
