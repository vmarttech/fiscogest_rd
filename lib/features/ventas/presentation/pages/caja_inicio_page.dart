import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/caja/domain/repositories/i_caja_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobro_venta_page.dart';

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
  static final _fmtMonto = NumberFormat('#,##0.00', 'es_DO');

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
    final s = raw
        .trim()
        .replaceAll(' ', '')
        .replaceAll(',', '.');
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
      ScaffoldMessenger.of(context).showSnackBar(
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

  void _irAHistorialTurno() =>
      context.push('/ventas/cobro/historial-turno');

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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
      await ref.read(cajaRepositoryProvider).abrirSesion(fondoInicial: fondo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Caja abierta. Fondo: RD\$ ${_fmtMonto.format(fondo)}',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refrescar();
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

  Future<void> _dialogoCerrarCaja() async {
    if (_sesion == null) return;
    final teorico = _saldo ?? 0.0;
    final controller =
        TextEditingController(text: teorico.toStringAsFixed(2));
    final obsController = TextEditingController();
    final ancho = MediaQuery.of(context).size.width;

    final result = await showDialog<({double contado, String? obs})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final double contado = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                ) ??
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

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
              title: const Text('Arqueo y cierre de caja', style: AppTypography.h4),
              content: SizedBox(
                width: ancho >= AppBreakpoints.tablet ? 440 : null,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sesión #${_sesion!.id} · Fondo inicial RD\$ ${_fmtMonto.format(_sesion!.fondoInicial)}',
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
                              'RD\$ ${_fmtMonto.format(teorico)}',
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
                          border: Border.all(color: difColor.withValues(alpha: 0.4)),
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
                              'RD\$ ${_fmtMonto.format(dif)}',
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
                    Navigator.pop(
                      ctx,
                      (contado: v, obs: obs.isEmpty ? null : obs),
                    );
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

    controller.dispose();
    obsController.dispose();
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
      String msg;
      if (!ok) {
        msg = 'No se pudo cerrar la sesión';
      } else if (dif.abs() < 0.005) {
        msg = 'Caja cerrada. Cuadre exacto.';
      } else if (dif > 0) {
        msg =
            'Caja cerrada. Sobrante: RD\$ ${_fmtMonto.format(dif)}';
      } else {
        msg =
            'Caja cerrada. Faltante: RD\$ ${_fmtMonto.format(dif.abs())}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final abierta = _cajaAbierta;
    final maxW = desktop ? 1100 : (mobile ? 520 : 720);

    return AppScaffold(
      title: 'CAJA',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEstadoTurno(mobile, abierta),
                  AppLayout.vL,
                  SectionHeader(
                    title: 'Operaciones',
                    subtitle: desktop
                        ? 'Acciones de la estación de caja'
                        : null,
                  ),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _accionCobrar(abierta, mobile)),
                        AppLayout.hM,
                        Expanded(child: _accionCxc(mobile)),
                        AppLayout.hM,
                        Expanded(child: _accionHistorial(abierta, mobile)),
                      ],
                    )
                  else if (!mobile)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _accionCobrar(abierta, mobile)),
                            AppLayout.hM,
                            Expanded(child: _accionCxc(mobile)),
                          ],
                        ),
                        AppLayout.vS,
                        _accionHistorial(abierta, mobile),
                      ],
                    )
                  else ...[
                    _accionCobrar(abierta, mobile),
                    AppLayout.vS,
                    _accionCxc(mobile),
                    AppLayout.vS,
                    _accionHistorial(abierta, mobile),
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
      padding: EdgeInsets.all(mobile ? AppSpacing.m : AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: abierta ? 'ABIERTA' : 'CERRADA',
                type: abierta
                    ? StatusChipType.success
                    : StatusChipType.neutral,
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
              'RD\$ ${_fmtMonto.format(_saldo ?? 0)}',
              style: AppTypography.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: mobile ? 28 : 36,
              ),
            ),
          if (abierta && _sesion != null) ...[
            AppLayout.vS,
            Text(
              'Fondo inicial: RD\$ ${_fmtMonto.format(_sesion!.fondoInicial)}'
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
              height: mobile ? 48 : AppSizes.buttonHeightMd,
            )
          else
            SizedBox(
              width: double.infinity,
              height: mobile ? 48 : AppSizes.buttonHeightMd,
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

  Widget _accionCobrar(bool abierta, bool mobile) => _AccionCaja(
        icono: Icons.point_of_sale,
        titulo: 'Cobrar cotización',
        subtitulo: abierta
            ? 'Buscar por N° o cliente y generar factura'
            : 'Requiere caja abierta',
        color: _puedeCobrar ? AppColors.success : AppColors.grey500,
        onTap: _irACobrarCotizacion,
        habilitado: _puedeCobrar,
      );

  Widget _accionCxc(bool mobile) => _AccionCaja(
        icono: Icons.account_balance_wallet_outlined,
        titulo: 'Cuentas por cobrar',
        subtitulo: 'Saldos y abonos de clientes',
        color: AppColors.info,
        onTap: _irACuentasPorCobrar,
      );

  Widget _accionHistorial(bool abierta, bool mobile) => _AccionCaja(
        icono: Icons.receipt_long_outlined,
        titulo: 'Historial del turno',
        subtitulo: abierta
            ? 'Movimientos desde la apertura'
            : 'Movimientos desde hoy 00:00',
        color: AppColors.primary,
        onTap: _irAHistorialTurno,
      );
}

class _AccionCaja extends StatelessWidget {
  const _AccionCaja({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
    this.habilitado = true,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    return Opacity(
      opacity: habilitado ? 1 : 0.55,
      child: AppCard(
        borderColor: AppColors.border,
        onTap: onTap,
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 14 : 16,
          vertical: mobile ? 14 : 18,
        ),
        child: Row(
          children: [
            Container(
              width: mobile ? 44 : 52,
              height: mobile ? 44 : 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.allM,
              ),
              child: Icon(icono, color: color, size: mobile ? 22 : 26),
            ),
            AppLayout.hM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: mobile ? 22 : 24,
            ),
          ],
        ),
      ),
    );
  }
}
