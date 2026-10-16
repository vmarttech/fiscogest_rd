import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_dao.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
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
  List<CajaMovimientoResumen> _movimientos = [];
  String? _nombreCajeroCache;
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
      List<CajaMovimientoResumen> movs = [];
      if (sesion != null) {
        try {
          movs = await repo.listarMovimientosPorSesion(sesion.id);
        } catch (_) {}
      }

      // Nombre real del cajero (usuarios.nombre / username)
      String? nombreCajero;
      final uid = sesion?.usuarioId;
      if (uid != null) {
        try {
          final auth = ref.read(sesionProvider);
          if (auth != null && auth.id == uid) {
            final n = auth.nombre.trim();
            final u = auth.username.trim();
            if (n.isNotEmpty) {
              nombreCajero = n;
            } else if (u.isNotEmpty) {
              nombreCajero = u;
            }
          }
          if (nombreCajero == null || nombreCajero!.isEmpty) {
            final db = ref.read(appDatabaseProvider);
            final row = await UsuariosDao(db).obtenerPorId(uid);
            if (row != null) {
              final n = row.nombre.trim();
              final u = row.username.trim();
              if (n.isNotEmpty) {
                nombreCajero = n;
              } else if (u.isNotEmpty) {
                nombreCajero = u;
              }
            }
          }
        } catch (_) {}
        nombreCajero ??= 'Cajero #$uid';
      }

      if (!mounted) return;
      setState(() {
        _sesion = sesion;
        _resumen = resumen;
        _saldo = saldo;
        _movimientos = movs;
        _nombreCajeroCache = nombreCajero;
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

  UsuarioSesion? get _usuarioActual => ref.read(sesionProvider);

  /// Solo rol Cajero opera el turno. Admin supervisa / crea usuarios.
  bool get _esCajero {
    final u = _usuarioActual;
    if (u == null) return false;
    return u.rolNorm == 'Cajero';
  }

  bool get _esAdmin {
    final u = _usuarioActual;
    return u?.esAdmin == true;
  }

  /// ¿La sesión abierta pertenece al usuario logueado?
  bool get _sesionEsMia {
    final s = _sesion;
    final u = _usuarioActual;
    if (s == null || u == null) return false;
    return s.usuarioId == u.id;
  }


  /// Usuario de la sesión de caja (cajero del turno).
  String get _nombreUsuarioCaja {
    final c = _nombreCajeroCache?.trim();
    if (c != null && c.isNotEmpty) return c;
    final sid = _sesion?.usuarioId;
    if (sid == null) return '—';
    final auth = ref.read(sesionProvider);
    if (auth != null && auth.id == sid) {
      final n = auth.nombre.trim();
      if (n.isNotEmpty) return n;
      final u = auth.username.trim();
      if (u.isNotEmpty) return u;
    }
    return 'Cajero #$sid';
  }


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
    // Regla: el turno de caja lo abre el CAJERO logueado (no Admin).
    if (!_esCajero) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            _esAdmin
                ? 'El administrador no opera caja. Use un usuario con rol Cajero para abrir el turno.'
                : 'Solo un usuario con rol Cajero puede abrir caja.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final uid = _usuarioActual?.id;
    if (uid == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('No hay sesión de usuario. Vuelva a iniciar sesión.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
          .abrirSesion(
            fondoInicial: fondo,
            usuarioId: _usuarioActual!.id,
          );
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
    // El cajero del turno cierra su caja. Admin puede cerrar en supervisión.
    if (!_esAdmin && !_sesionEsMia) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text(
            'Esta caja pertenece a otro cajero. Solo él o un administrador pueden cerrarla.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
      showAppBar: !desktop, // PC: solo shell (sin barra teal CAJA)
      showBackButton: false,
      leading: desktop
          ? null
          : IconButton(
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
    // 3 | 6 | 3 — mockup HTML / captura
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildFondoSesionCard(abierta: abierta),
              const SizedBox(height: 14),
              _buildEstadoCajaCard(abierta: abierta),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(flex: 6, child: _buildUltimosMovimientos()),
        const SizedBox(width: 14),
        Expanded(flex: 3, child: _buildOperacionesRapidas(abierta)),
      ],
    );
  }

  Widget _buildMobile(bool abierta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFondoSesionCard(abierta: abierta),
        const SizedBox(height: 12),
        _buildEstadoCajaCard(abierta: abierta),
        const SizedBox(height: 12),
        _buildOperacionesRapidas(abierta),
        const SizedBox(height: 12),
        _buildUltimosMovimientos(),
      ],
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String s) => Text(
        s,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      );

  Widget _kvLine(String k, String v, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metodoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFondoSesionCard({required bool abierta}) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('FONDO Y SESIÓN'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                const Text(
                  'Efectivo en cajón',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                if (_cargando)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else if (_error != null)
                  Text(
                    'Error: $_error',
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    formatRd(_saldo ?? 0),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.8,
                    ),
                  ),
              ],
            ),
          ),
          if (abierta && _sesion != null) ...[
            const SizedBox(height: 14),
            _kvLine('Fondo inicial', formatRd(_sesion!.fondoInicial)),
            _kvLine('Apertura', _fmtFecha.format(_sesion!.fechaApertura)),
            _kvLine(
              'Sesión #',
              '${_sesion!.id}',
              valueColor: const Color(0xFF10B981),
            ),
          ],
          if (!abierta) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _dialogoAbrirCaja,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text(
                  'Abrir Caja',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoCajaCard({required bool abierta}) {
    final tarjeta = _resumen?.ingresosTarjeta ?? 0.0;
    final transfer = _resumen?.ingresosTransferencia ?? 0.0;
    final cheque = _resumen?.ingresosCheque ?? 0.0;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _sectionLabel('ESTADO DE CAJA')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: abierta
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: abierta
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      abierta ? 'ABIERTA' : 'CERRADA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: abierta
                            ? const Color(0xFF047857)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metodoPill('Tarjeta', formatRd(tarjeta)),
          const SizedBox(height: 8),
          _metodoPill('Transfer', formatRd(transfer)),
          const SizedBox(height: 8),
          _metodoPill('Cheque', formatRd(cheque)),
          if (abierta) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _procesando ? null : _dialogoCerrarCaja,
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text(
                  'Cerrar Caja',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totLine(String k, String v, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: emphasize ? 13 : 12,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
                color: emphasize
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              v,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 15 : 12.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperacionesRapidas(bool abierta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'OPERACIONES RÁPIDAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _CajaOpTile(
            icon: Icons.point_of_sale_outlined,
            title: 'Cobrar cotización',
            subtitle: _puedeCobrar
                ? 'Pago + cotizaciones activas'
                : 'Requiere caja abierta',
            color: _puedeCobrar ? AppColors.primary : AppColors.grey500,
            onTap: _irACobrarCotizacion,
          ),
          const SizedBox(height: 10),
          _CajaOpTile(
            icon: Icons.description_outlined,
            title: 'Cuentas por cobrar',
            subtitle: 'Facturas pendientes',
            color: const Color(0xFF6366F1),
            onTap: _irACuentasPorCobrar,
          ),
          const SizedBox(height: 10),
          _CajaOpTile(
            icon: Icons.history_rounded,
            title: 'Historial del turno',
            subtitle:
                abierta ? 'Actividad de esta sesión' : 'Desde hoy 00:00',
            color: const Color(0xFF64748B),
            onTap: _irAHistorialTurno,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          _totLine('Subtotal', formatRd(0)),
          _totLine('ITBIS', formatRd(0)),
          _totLine('Descuentos', formatRd(0)),
          const SizedBox(height: 4),
          _totLine('Total', formatRd(0), emphasize: true),
          const SizedBox(height: 14),
          // Botones apilados: no se cortan en columna estrecha
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: abierta ? _irACobrarCotizacion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'F12 · Procesar cobro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: abierta
                  ? () {
                      // Cancelar cobro en curso / limpiar selección futura
                      FiscoGestNotifications.show(
                        const SnackBar(
                          content: Text('Sin cobro en curso'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'F5 · Cancelar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelTipoMov(String tipo) {
    final u = tipo.toUpperCase();
    if (u.contains('APERTURA')) return 'Apertura de caja';
    if (u.contains('CIERRE')) return 'Cierre de caja';
    if (u.contains('INGRESO') || u.contains('VENTA') || u.contains('COBRO')) {
      return 'Ingreso';
    }
    if (u.contains('EGRESO') || u.contains('RETIRO')) return 'Egreso';
    return tipo.isEmpty ? 'Movimiento' : tipo;
  }

  Widget _buildUltimosMovimientos() {
    final items = _movimientos.length > 8
        ? _movimientos.sublist(0, 8)
        : _movimientos;

    Widget h(String text, {int flex = 1, TextAlign a = TextAlign.left}) =>
        Expanded(
          flex: flex,
          child: Text(
            text,
            textAlign: a,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
        );

    Widget dataRow({
      required String fecha,
      required String usuario,
      required String accion,
      required String referencia,
      required String detalle,
      required String monto,
      bool muted = false,
    }) {
      final c = muted ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: muted ? Colors.white : const Color(0xFFF8FAFC),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                fecha,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted ? c : const Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                usuario,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c),
              ),
            ),
            Expanded(
              flex: 3,
              child: muted
                  ? Text(accion, style: TextStyle(fontSize: 11, color: c))
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          accion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                referencia,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                monto,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: muted ? c : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    if (items.isEmpty) {
      if (_cajaAbierta && _sesion != null) {
        rows.add(dataRow(
          fecha: _fmtHora.format(_sesion!.fechaApertura),
          usuario: _nombreUsuarioCaja,
          accion: 'Apertura de caja',
          referencia: 'Sesión #${_sesion!.id}',
          detalle: 'Fondo inicial',
          monto: formatRd(_sesion!.fondoInicial),
        ));
      }
      rows.add(dataRow(
        fecha: '--:--',
        usuario: '--',
        accion: '--',
        referencia: '—',
        detalle: 'Sin movimientos adicionales',
        monto: 'RD\$0.00',
        muted: true,
      ));
    } else {
      for (final m in items) {
        final ref = m.referenciaTipo.isNotEmpty
            ? '${m.referenciaTipo} #${m.referenciaId}'
            : (_sesion != null ? 'Sesión #${_sesion!.id}' : '—');
        final det = m.formaPago.isNotEmpty ? m.formaPago : m.tipo;
        rows.add(dataRow(
          fecha: _fmtHora.format(m.fecha),
          usuario: _nombreUsuarioCaja,
          accion: _labelTipoMov(m.tipo),
          referencia: ref,
          detalle: det,
          monto: formatRd(m.monto),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ÚLTIMOS MOVIMIENTOS (DETALLADO)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: _irAHistorialTurno,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver todos →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF1F5F9),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      h('Fecha', flex: 2),
                      h('Usuario', flex: 2),
                      h('Acción/Tipo', flex: 3),
                      h('Referencia', flex: 2),
                      h('Comentario/Detalle', flex: 3),
                      h('Monto', flex: 2, a: TextAlign.right),
                    ],
                  ),
                ),
                ...rows,
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar ticket/movimiento...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _irAHistorialTurno(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'F2',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Escanear',
                onPressed: _irAHistorialTurno,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
              ),
            ],
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
