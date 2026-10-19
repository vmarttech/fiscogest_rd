// ignore_for_file: unused_element, unused_field, unused_import, unused_element_parameter
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/notificaciones_provider.dart';
import 'package:fiscogest_rd/features/caja/presentation/pdf/informe_z_pdf.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/ambiente_dgii.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/caja_inicio_page.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart' as venta_providers;
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pdf/comprobante_abono_cuota_pdf.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/pronto_pago_acuerdos_table.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/pronto_pago_acuerdos_dao.dart';
import 'package:fiscogest_rd/core/services/dgii_rnc_consulta_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:flutter/services.dart';
import 'package:fiscogest_rd/core/presentation/pages/dashboard_desktop_proto.dart' show dashCajaProvider;
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_dao.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
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
  bool _extraCajaAplicado = false;
  final _buscaProductoCtrl = TextEditingController();
  final _recibidoCtrl = TextEditingController(text: '0');
  final _focusBuscaProducto = FocusNode();
  String _modoUi = 'venta';
  String _tipoNcf = 'B02';
  String _formaPagoUi = 'Efectivo';
  final _rncFiscalController = TextEditingController();
  bool _buscandoRnc = false;
  String? _rncNombreEncontrado;

  Venta? _ticketSeleccionado;
  List<Venta> _pendientes = [];
  CuentaPorCobrar? _cxcActiva;
  ProntoPagoAcuerdoData? _cxcProntoPago;
  final _cxcMontoCtrl = TextEditingController();

  List<Venta> _resultadosBusqueda = [];
  bool _buscandoTicket = false;



  static final _fmtFecha = DateFormat('dd/MM/yyyy HH:mm');
  static final _fmtHora = DateFormat('HH:mm');

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_atajosTecladoCaja);
    _buscaProductoCtrl.dispose();
    _rncFiscalController.dispose();
    _cxcMontoCtrl.dispose();
    _recibidoCtrl.dispose();
    _focusBuscaProducto.dispose();
    super.dispose();
  }

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler(_atajosTecladoCaja);
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
          if (nombreCajero == null || nombreCajero.isEmpty) {
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

  /// Cajero opera el turno; Admin tiene acceso total (abrir/cerrar/supervisar).

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
          behavior: SnackBarBehavior.floating));
      return;
    }
    // Ya estamos en Caja: foco a búsqueda de ticket
    FiscoGestNotifications.show(const SnackBar(
      content: Text('Seleccione o busque el ticket (F2) y pulse Procesar'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _irACuentasPorCobrar() => context.push('/ventas/cobrar');

  void _irAHistorialTurno() => context.push('/ventas/cobro/historial-turno');


  Widget _chipNotif(IconData icon, Color bg, Color fg, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAbrirTurno() {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Caja unificada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'Sin turno activo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Abre el turno para comenzar.\nLa estación inicia vacía.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _procesando ? null : _dialogoAbrirCaja,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(
                  _procesando ? 'Abriendo…' : 'Abrir turno',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardUltimoTurno() {
    return FutureBuilder<CajaSesionResumen?>(
      future: ref.read(cajaRepositoryProvider).obtenerUltimaSesionCerrada(),
      builder: (context, snap) {
        final s = snap.data;
        String cierre = '—';
        String cajero = '—';
        String fecha = '—';
        String dif = '—';
        if (s != null) {
          cajero = 'Usuario #${s.usuarioId}';
          final f = s.fechaCierre ?? s.fechaApertura;
          fecha =
              '${f.day.toString().padLeft(2, '0')}/'
              '${f.month.toString().padLeft(2, '0')}/'
              '${f.year} '
              '${f.hour.toString().padLeft(2, '0')}:'
              '${f.minute.toString().padLeft(2, '0')}';
          if (s.montoContado != null) {
            cierre = formatRd(s.montoContado!);
          }
          if (s.diferencia != null) {
            final d = s.diferencia!;
            dif = d.abs() < 0.005
                ? 'Exacto'
                : (d > 0
                    ? 'Sobrante ${formatRd(d)}'
                    : 'Faltante ${formatRd(d.abs())}');
          } else if (s.montoContado != null && s.saldoTeorico != null) {
            final d = s.montoContado! - s.saldoTeorico!;
            dif = d.abs() < 0.005
                ? 'Exacto'
                : (d > 0
                    ? 'Sobrante ${formatRd(d)}'
                    : 'Faltante ${formatRd(d.abs())}');
          }
        }
        return Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen último Turno',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 16),
                  _filaResumen(
                    'Cierre de Caja anterior',
                    cierre,
                    Icons.bar_chart_rounded,
                    const Color(0xFFDBEAFE),
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  _filaResumen(
                    'Cajero',
                    cajero,
                    Icons.person_outline,
                    const Color(0xFFE0E7FF),
                    const Color(0xFF4F46E5),
                  ),
                  const SizedBox(height: 12),
                  _filaResumen(
                    'Fecha',
                    fecha,
                    Icons.calendar_today_outlined,
                    const Color(0xFFE2E8F0),
                    const Color(0xFF475569),
                  ),
                  const SizedBox(height: 12),
                  _filaResumen(
                    'Diferencia',
                    dif,
                    Icons.show_chart,
                    const Color(0xFFD1FAE5),
                    const Color(0xFF059669),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filaResumen(
    String label,
    String value,
    IconData icon,
    Color iconBg,
    Color iconFg,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconFg),
        ),
      ],
    );
  }

  Widget _cardVentasDiarias() {
    final ventasAsync = ref.watch(listaVentasProvider);
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ventasAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            'Ventas: $e',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          data: (ventas) {
            final now = DateTime.now();
            final hoy0 = DateTime(now.year, now.month, now.day);
            final montos = List<double>.filled(7, 0);
            var montoHoy = 0.0;
            var nHoy = 0;
            for (final v in ventas) {
              final f = v.fecha;
              final d0 = DateTime(f.year, f.month, f.day);
              final diff = hoy0.difference(d0).inDays;
              if (diff < 0 || diff > 6) continue;
              final numF = (v.numeroFactura ?? '').trim();
              final st = v.estadoDocumento.name.toLowerCase();
              if (numF.isEmpty && !st.contains('factur')) continue;
              final idx = 6 - diff;
              montos[idx] += v.montoTotal;
              if (diff == 0) {
                montoHoy += v.montoTotal;
                nHoy++;
              }
            }
            final maxM = montos.fold<double>(0, (a, b) => a > b ? a : b);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Ventas Diarias',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '$nHoy factura(s) hoy',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MiniBarsPainter(
                      valores: montos
                          .map((m) => maxM <= 0
                              ? 0.12
                              : (m / maxM).clamp(0.08, 1.0))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hoy',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            formatRd(montoHoy),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Últimos 7 días',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            formatRd(montos.fold(0.0, (a, b) => a + b)),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _dialogoAbrirCaja() async {
    // Admin y Cajero pueden abrir. La sesión queda a nombre del usuario logueado.
    final uid = _usuarioActual?.id;
    if (uid == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('No hay sesión de usuario. Vuelva a iniciar sesión.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    final controller = TextEditingController(text: '0');
    final ancho = MediaQuery.of(context).size.width;
    final fondo = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                    color: AppColors.textSecondary)),
                AppLayout.vM,
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fondo inicial',
                    prefixText: 'RD\$ ',
                    border: OutlineInputBorder()),
                  autofocus: true),
              ])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final err = _validarMontoNoNegativo(
                  controller.text,
                  label: 'Fondo inicial');
                if (err != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating));
                  return;
                }
                Navigator.pop(ctx, _parseMonto(controller.text));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white),
              child: const Text('Abrir')),
          ]);
      });
    if (fondo == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      final sesionId = await ref
          .read(cajaRepositoryProvider)
          .abrirSesion(
            fondoInicial: fondo,
            usuarioId: _usuarioActual!.id);
      ref.invalidate(dashCajaProvider);
      try {
        await ref.read(bitacoraOperacionesServiceProvider).registrar(
              accion: 'caja_abierta',
              entidad: 'sesion_caja',
              entidadId: sesionId,
              usuarioId: ref.read(sesionUsuarioIdProvider),
              resumen: 'Caja abierta con fondo de ${formatRd(fondo)}',
              datos: {'fondoInicial': fondo});
      } catch (_) {}
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Caja abierta. Fondo: ${formatRd(fondo)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
      await _refrescar();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
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
            'Esta caja pertenece a otro cajero. Solo él o un administrador pueden cerrarla.'),
          behavior: SnackBarBehavior.floating));
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
                            title: const Text(
                'Arqueo y cierre de caja',
                style: AppTypography.h4),
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
                            color: AppColors.textSecondary)),
                        AppLayout.vS,
                        Text(
                          '+ Ingresos efectivo ${formatRd(resumenCierre.ingresosEfectivo)}'
                          '  − Egresos ${formatRd(resumenCierre.egresosEfectivo)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                        Text(
                          'Tarjeta ${formatRd(resumenCierre.ingresosTarjeta)} · '
                          'Transfer ${formatRd(resumenCierre.ingresosTransferencia)} · '
                          'Cheque ${formatRd(resumenCierre.ingresosCheque)}'
                          ' (no se cuentan en el cajón)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                        AppLayout.vM,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Efectivo esperado',
                                style: AppTypography.labelMedium),
                              Text(
                                formatRd(teorico),
                                style: AppTypography.h4.copyWith(

                                )),
                            ])),
                        AppLayout.vM,
                        TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Efectivo contado en cajón',
                            prefixText: 'RD\$ ',
                            border: OutlineInputBorder(),
                            helperText: 'Cuente billetes y monedas del cajón'),
                          autofocus: true,
                          onChanged: (_) => setLocal(() {})),
                        AppLayout.vM,
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: difColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: difColor.withValues(alpha: 0.4))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                difLabel,
                                style: AppTypography.labelMedium.copyWith(
                                  color: difColor)),
                              Text(
                                formatRd(dif),
                                style: AppTypography.h4.copyWith(
                                  color: difColor)),
                            ])),
                        AppLayout.vM,
                        TextField(
                          controller: obsController,
                          decoration: const InputDecoration(
                            labelText: 'Observación (opcional)',
                            border: OutlineInputBorder(),
                            hintText: 'Ej. faltante por cambio, billete roto…'),
                          maxLines: 2),
                      ])))),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    final err = _validarMontoNoNegativo(
                      controller.text,
                      label: 'Efectivo contado');
                    if (err != null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating));
                      return;
                    }
                    final v = _parseMonto(controller.text)!;
                    final obs = obsController.text.trim();
                    if ((v - teorico).abs() >= 0.005 && obs.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Explique el faltante o sobrante antes de cerrar.'),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating));
                      return;
                    }
                    Navigator.pop(ctx, (
                      contado: v,
                      obs: obs.isEmpty ? null : obs));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: AppColors.white),
                  child: const Text('Confirmar cierre')),
              ]);
          });
      });
    if (result == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      final ok = await ref.read(cajaRepositoryProvider).cerrarSesion(
            sesionId: _sesion!.id,
            saldoTeorico: teorico,
            montoContado: result.contado,
            observacion: result.obs);
      ref.invalidate(dashCajaProvider);
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
                });
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
          behavior: SnackBarBehavior.floating));
      await _refrescar();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }



  Future<void> _buscarRncFiscalEnLinea() async {
    final raw = _rncFiscalController.text.replaceAll(RegExp(r'\D'), '');
    if (!DgiiRncConsultaService.esFormatoValido(raw)) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Ingrese RNC (9) o cédula (11 dígitos)'),
          backgroundColor: AppColors.warning));
      return;
    }
    setState(() {
      _buscandoRnc = true;
      _rncNombreEncontrado = null;
    });
    final svc = DgiiRncConsultaService();
    try {
      final r = await svc.consultar(raw);
      if (!mounted) return;
      setState(() {
        _rncFiscalController.text = r.rnc;
        _rncNombreEncontrado = r.estado != null
            ? '${r.nombre} · ${r.estado}'
            : r.nombre;
      });
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('RNC verificado: ${r.nombre}'),
          backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      setState(() => _rncNombreEncontrado = null);
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error));
    } finally {
      svc.dispose();
      if (mounted) setState(() => _buscandoRnc = false);
    }
  }

  Future<void> _buscarTicketCaja() async {
    final texto = _buscaProductoCtrl.text.trim();
    setState(() {
      _buscandoTicket = true;
      _resultadosBusqueda = [];
    });
    try {
      final repo = ref.read(ventasRepositoryProvider);
      if (texto.isEmpty) {
        final lista = await repo.listarPendientesCobro();
        if (!mounted) return;
        setState(() {
          _resultadosBusqueda = lista;
          _buscandoTicket = false;
        });
        return;
      }
      final porNumero = await repo.buscarPorNumeroCotizacion(texto);
      final porCliente = await repo.buscarPorNombreCliente(texto);
      final mapa = <int, Venta>{};
      if (porNumero != null && porNumero.id != null) {
        mapa[porNumero.id!] = porNumero;
      }
      for (final v in porCliente) {
        if (v.id != null) mapa[v.id!] = v;
      }
      if (!mounted) return;
      setState(() {
        _resultadosBusqueda = mapa.values.toList();
        _buscandoTicket = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _buscandoTicket = false);
      FiscoGestNotifications.show(SnackBar(
        content: Text('$e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating));
    }
  }

  void _seleccionarTicket(Venta v) {
    setState(() {
      _ticketSeleccionado = v;
      _resultadosBusqueda = [];
      _buscaProductoCtrl.clear();
    });
  }

  void _limpiarTicket() {
    setState(() {
      _ticketSeleccionado = null;
      _cxcActiva = null;
      _cxcProntoPago = null;
      _recibidoCtrl.text = '0';
      _cxcMontoCtrl.text = '';
    });
  }




  Future<void> _irCobrarTicketSeleccionado() async {
    if (_procesando) return;
    if (!_puedeCobrar) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Debe abrir la caja antes de cobrar'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating));
      return;
    }

    // ── CxC: abono + comprobante 80mm de cuota ──
    if (_cxcActiva != null) {
      final c = _cxcActiva!;
      if (c.id == null) return;
      final monto = double.tryParse(
            _cxcMontoCtrl.text.trim().replaceAll(',', '.')) ??
          0;
      if (monto <= 0) {
        FiscoGestNotifications.show(const SnackBar(
          content: Text('Indique un monto válido'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
        return;
      }
      if (monto > c.saldoPendiente + 0.01) {
        FiscoGestNotifications.show(SnackBar(
          content: Text(
            'El monto supera el saldo (${formatRd(c.saldoPendiente)})'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
        return;
      }

      setState(() => _procesando = true);
      try {
        final metodo = _formaPagoNombre();
        final cuota = _cuotaActualCxc(c);
        final saldoAnt = c.saldoPendiente;
        final recibido = double.tryParse(
          _recibidoCtrl.text.trim().replaceAll(',', '.'));
        final cambio = (recibido != null)
            ? (recibido - monto).clamp(0.0, double.infinity)
            : null;

        await ref.read(databaseProvider).transaction(() async {
          await ref.read(cuentaPorCobrarRepositoryProvider).registrarAbono(
                AbonoCredito(
                  cuentaId: c.id!,
                  monto: monto,
                  metodoPago: metodo,
                  fecha: DateTime.now(),
                  nota: _cxcProntoPago != null
                      ? 'Liquidación pronto pago · Caja'
                      : 'Abono cuota ${cuota.numero}/${cuota.total} · Caja'));
          await ref.read(cajaRepositoryProvider).registrarMovimiento(
                referencia: c.numero ?? 'CXC-${c.id}',
                monto: monto,
                tipo: 'ingreso',
                descripcion:
                    'Abono CXC ${c.numero ?? c.id} · ${c.clienteNombre ?? ''} · cuota ${cuota.numero}/${cuota.total}',
                formaPago: metodo);
        });

        if (_cxcProntoPago != null &&
            monto + 0.01 >= _cxcProntoPago!.montoLiquidacion) {
          try {
            await ProntoPagoAcuerdosDao(ref.read(databaseProvider))
                .marcarAplicado(_cxcProntoPago!.id);
          } catch (_) {}
        }

        if (!mounted) return;

        // Comprobante 80mm abono de cuota
        try {
          final empresa =
              ref.read(configuracionControllerProvider).valueOrNull;
          DateTime? vencCuota;
          try {
            final plan = c.planPago;
            final pend = (plan?.cuotas ?? const [])
                .where((q) => !q.pagada)
                .toList();
            if (pend.isNotEmpty) {
              vencCuota = pend.first.fechaVencimiento;
            }
          } catch (_) {}

          await ComprobanteAbonoCuotaPdf.imprimir(
            cuenta: c,
            montoAbonado: monto,
            cuotaNumero: cuota.numero,
            cuotaTotal: cuota.total,
            metodoPago: metodo,
            fecha: DateTime.now(),
            empresa: empresa,
            nombreCliente: c.clienteNombre,
            cajero: _nombreUsuarioCaja,
            saldoAnterior: saldoAnt,
            recibido: recibido,
            cambio: cambio,
            vencimientoCuota: vencCuota,
            montoPorCuota: cuota.monto);
        } catch (e) {
          if (mounted) {
            FiscoGestNotifications.show(SnackBar(
              content: Text('Abono OK. Impresión: $e'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating));
          }
        }

        if (!mounted) return;
        FiscoGestNotifications.show(SnackBar(
          content: Text('Abono CXC registrado: ${formatRd(monto)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
        _limpiarTicket();
      } catch (e) {
        if (mounted) {
          FiscoGestNotifications.show(SnackBar(
            content: Text('Error al cobrar CXC: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating));
        }
      } finally {
        if (mounted) setState(() => _procesando = false);
      }
      return;
    }

    // ── Ticket / cotización → cobro EN ESTA pantalla (sin CobroVentaPage) ──
    if (_ticketSeleccionado?.id == null) {
      FiscoGestNotifications.show(const SnackBar(
        content: Text('Busque y seleccione un ticket / cotización (F2)'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    await _procesarCobroTicketEnCaja();
  }



  Future<void> _asegurarNcfFiscalCaja(int ventaIdDoc) async {
    final repo = ref.read(venta_providers.ventasRepositoryProvider);
    final doc = await repo.obtenerVentaPorId(ventaIdDoc);
    final actual = (doc?.numeroFactura ?? '').trim();
    final yaFiscal = actual.startsWith('B01') ||
        actual.startsWith('B02') ||
        actual.startsWith('B14');
    if (yaFiscal) return;

    if (_tipoNcf == 'B01' || _tipoNcf == 'B14') {
      final rnc = _rncFiscalController.text
          .trim()
          .replaceAll(RegExp(r'[^0-9]'), '');
      if (rnc.length != 9 && rnc.length != 11) {
        throw StateError('B01 o B14 requiere RNC (9) o cédula (11 dígitos)');
      }
    }

    final ncf =
        await ref.read(secuenciasNcfDaoProvider).siguienteNcf(_tipoNcf);
    await repo.emitirNcfFiscal(ventaIdDoc, ncf);

    final simp = ref.read(configuracionControllerProvider).valueOrNull
            ?.modoSimplificado ??
        false;
    if (simp) return;

    try {
      final ventaEcfe = await repo.obtenerVentaPorId(ventaIdDoc);
      if (ventaEcfe == null) return;
      final tipo = ncf.length >= 3 ? ncf.substring(0, 3) : ncf;
      final resultadoEcfe = await ref.read(encolarEcfeDesdeVentaProvider)(
        venta: ventaEcfe,
        tipoNcf: tipo,
        rncCliente: _rncFiscalController.text.replaceAll(RegExp(r'\D'), ''),
        nombreCliente: _nombreClienteFactura(ventaEcfe),
      );
      final detalleEcfe = resultadoEcfe.erroresValidacion.join(' · ');
      final omisionEcfe = (resultadoEcfe.omitidoPor ?? '').trim();
      final silencioso = omisionEcfe.contains('deshabilitado') ||
          omisionEcfe.contains('sin envío');
      if (mounted &&
          !silencioso &&
          (detalleEcfe.isNotEmpty ||
              (!resultadoEcfe.encolado && omisionEcfe.isNotEmpty))) {
        FiscoGestNotifications.show(SnackBar(
          content: Text(
            'e-CF no quedó listo: ${detalleEcfe.isNotEmpty ? detalleEcfe : omisionEcfe}',
          ),
          behavior: SnackBarBehavior.floating,
        ));
      }
      try {
        ref.invalidate(ecfeColaProvider);
      } catch (_) {}
    } catch (errorEcfe) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(
          content: Text('e-CF no quedó listo: $errorEcfe'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _opcionesComprobantePdfCaja(Venta ventaConDetalle) async {
    final emp = ref.read(configuracionControllerProvider).valueOrNull;
    final simple = emp?.modoSimplificado == true;
    final ncf = (ventaConDetalle.numeroFactura ?? '').trim();
    if (ncf.isEmpty && !simple) {
      if (!mounted) return;
      FiscoGestNotifications.show(const SnackBar(
        content: Text('Sin NCF fiscal: no se puede generar el PDF'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted) return;
    final accion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        title: Text(simple ? 'Comprobante' : 'Comprobante fiscal'),
        content: Text(
          'NCF: $ncf\n\nElija imprimir o enviar (WhatsApp, correo, etc.).',
        ),
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
    if (accion == null || !mounted) return;
    try {
      final compartir = accion == 'enviar';
      String? codigoSeg;
      AmbienteDgii? ambiente;
      try {
        if (ventaConDetalle.id != null) {
          codigoSeg = await ref
              .read(ecfeRepositoryProvider)
              .codigoSeguridadPorVenta(ventaConDetalle.id!);
          ambiente =
              (await ref.read(ecfeRepositoryProvider).obtenerConfig()).ambiente;
        }
      } catch (_) {}
      await ComprobantePdf.imprimirFactura(
        ventaConDetalle,
        compartir: compartir,
        empresa: emp,
        rncCliente: _rncFiscalController.text.trim(),
        direccionCliente: '',
        telefonoCliente: '',
        codigoSeguridad: codigoSeg,
        ambienteDgii: ambiente,
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(SnackBar(
        content: Text('PDF: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _procesarCobroTicketEnCaja() async {
    if (!mounted || _procesando) return;
    final ticket = _ticketSeleccionado;
    if (ticket == null || ticket.id == null) {
      FiscoGestNotifications.show(const SnackBar(
        content: Text('Seleccione un ticket / cotización'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!_puedeCobrar) {
      FiscoGestNotifications.show(const SnackBar(
        content: Text('Debe abrir la caja antes de cobrar'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final ventaId = ticket.id!;
    final tot = _totalesTicketVivo(ticket);
    final formaPagoNombre = _formaPagoNombre();
    final recibido = double.tryParse(
          _recibidoCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    final repoCheck = ref.read(venta_providers.ventasRepositoryProvider);
    final doc = await repoCheck.obtenerVentaPorId(ventaId);

    bool esCredito = false;
    if (doc != null) {
      esCredito = doc.numeroCotizacion.startsWith('CR-') ||
          doc.estadoDocumento == EstadoDocumento.enCredito ||
          doc.formaPago.toLowerCase().contains('credito') ||
          doc.formaPago.toLowerCase().contains('crédito');
      if (esCredito && doc.estadoDocumento == EstadoDocumento.enCredito) {
        FiscoGestNotifications.show(const SnackBar(
          content: Text(
            'Pendiente de aprobación en Crédito. No se puede facturar aún.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      if (esCredito &&
          doc.estadoDocumento != EstadoDocumento.aprobado &&
          doc.estadoDocumento != EstadoDocumento.facturado) {
        FiscoGestNotifications.show(SnackBar(
          content: Text(
            'Estado ${doc.estadoDocumento.name}: no listo para cobro a crédito',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }

    final esEfectivo = formaPagoNombre.toLowerCase().contains('efectivo');
    if (!esCredito && esEfectivo && recibido + 0.009 < tot.total) {
      FiscoGestNotifications.show(SnackBar(
        content: Text('Efectivo insuficiente. Total ${formatRd(tot.total)}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (esCredito && recibido <= 0) {
      FiscoGestNotifications.show(const SnackBar(
        content: Text('Indique el abono inicial (mayor a 0)'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (esCredito && recibido > tot.total + 0.009) {
      FiscoGestNotifications.show(SnackBar(
        content: Text('El abono no puede superar ${formatRd(tot.total)}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _procesando = true);
    try {
      await _asegurarNcfFiscalCaja(ventaId);

      final repositorio = ref.read(venta_providers.ventasRepositoryProvider);
      final Venta venta;
      if (esCredito) {
        venta = await repositorio.registrarVentaConAbono(
          ventaId,
          recibido,
          '',
          formaPago: formaPagoNombre,
        );
      } else {
        venta = await repositorio.confirmarVentaBorrador(
          ventaId,
          formaPago: formaPagoNombre,
        );
      }

      final ventaConDetalle =
          await repositorio.obtenerVentaPorId(venta.id ?? ventaId);
      if (ventaConDetalle == null) {
        throw Exception('No se pudo recargar la venta facturada');
      }
      if (ventaConDetalle.detalles.isEmpty) {
        throw Exception(
          'La cotización ${ventaConDetalle.numeroCotizacion} no tiene productos '
          'en base de datos. Genere una cotización nueva con productos.',
        );
      }

      final inv = ref.read(ventaInventarioServiceProvider);
      await inv.aplicarSalidaInventario(ventaConDetalle);
      ref.invalidate(productoControllerProvider);
      try {
        ref.invalidate(kardexPorProductoProvider);
      } catch (_) {}

      final montoCaja = esCredito ? recibido : tot.total;
      if (montoCaja > 0) {
        final cajaRepo = ref.read(cajaRepositoryProvider);
        final nFactura = venta.numeroFactura ?? venta.numeroCotizacion;
        await cajaRepo.registrarMovimiento(
          referencia: nFactura,
          monto: montoCaja,
          tipo: 'ingreso',
          descripcion:
              'Cobro factura $nFactura (cotización ${venta.numeroCotizacion})',
          formaPago: formaPagoNombre,
        );
      }

      try {
        ref.invalidate(listaVentasBorradorProvider);
        ref.invalidate(listaCotizacionesProvider);
        ref.invalidate(listaVentasProvider);
      } catch (_) {}

      if (!mounted) return;
      FiscoGestNotifications.show(SnackBar(
        content: Text(
          'Facturado ${venta.numeroFactura ?? venta.numeroCotizacion} · ${formatRd(montoCaja)}',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));

      await _opcionesComprobantePdfCaja(ventaConDetalle);

      if (!mounted) return;
      _limpiarTicket();
      await _refrescar();
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(
          content: Text('Error al cobrar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  String _formaPagoNombre() {
    final v = _formaPagoUi.trim();
    return v.isEmpty ? 'Efectivo' : v;
  }


  bool _atajosTecladoCaja(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.f4) {
      _dialogoArqueoCaja();
      return true;
    }
    if (key == LogicalKeyboardKey.f6) {
      setState(() => _modoUi = 'cxc');
      _dialogoBuscarCxc();
      return true;
    }
    if (key == LogicalKeyboardKey.f3) {
      setState(() => _modoUi = 'cotizacion');
      _dialogoBuscarCotizacion();
      return true;
    }
    if (key == LogicalKeyboardKey.f12) {
      _irCobrarTicketSeleccionado();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // caja-contrast-v3 — contraste alto + negrita vía tema
    WidgetsBinding.instance.addPostFrameCallback((_) => _aplicarExtraCajaSiHay());
    final base = Theme.of(context);
    final cajaTheme = base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFF475569), width: 1.3),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );

    final mobile = AppBreakpoints.isMobile(context);
    final abierta = _cajaAbierta;

    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _refrescar, child: const Text('Reintentar')),
            ])));
    }

    if (!abierta) {
      // Dashboard pre-turno (bento). Sin arqueo/cobro hasta abrir.
      final wide = MediaQuery.sizeOf(context).width >= 900;
      return AppScaffold(
        title: 'Caja unificada',
        subtitle: 'FiscoGest',
        showAppBar: mobile,
        useAppPage: false,
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(mobile ? 12 : 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (mobile ? 24 : 40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notificaciones Rápidas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Builder(builder: (context) {
                                final alertasAsync =
                                    ref.watch(alertasOperativasProvider);
                                return alertasAsync.when(
                                  loading: () => const SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  error: (_, __) => const Text(
                                    'Sin alertas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  data: (alertas) {
                                    if (alertas.isEmpty) {
                                      return const Text(
                                        'Todo en orden · sin alertas pendientes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    }
                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final a in alertas.take(6))
                                          InkWell(
                                            onTap: () {
                                              if (a.ruta.isNotEmpty) {
                                                context.go(a.ruta);
                                              }
                                            },
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: _chipNotif(
                                              a.icon,
                                              a.color.withValues(alpha: 0.12),
                                              a.color,
                                              a.titulo,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (wide)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: _cardAbrirTurno()),
                              const SizedBox(width: 16),
                              Expanded(flex: 3, child: _cardUltimoTurno()),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: _cardVentasDiarias()),
                            ],
                          ),
                        )
                      else ...[
                        _cardAbrirTurno(),
                        const SizedBox(height: 12),
                        _cardUltimoTurno(),
                        const SizedBox(height: 12),
                        _cardVentasDiarias(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    // ABIERTA: POS 2 columnas vacío (diseño HTML, sin ticket)
    
    return AppScaffold(
      title: 'Caja unificada',
      subtitle: 'FiscoGest',
      showAppBar: mobile,
      useAppPage: false,
      backgroundColor: const Color(0xFFF1F5F9),
      body: Theme(
        data: cajaTheme,
        child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f2): () {
            _focusBuscaProducto.requestFocus();
          },
          const SingleActivator(LogicalKeyboardKey.f3): () {
            setState(() => _modoUi = 'cotizacion');
            _dialogoBuscarCotizacion();
          },
          const SingleActivator(LogicalKeyboardKey.f4): () {
            _dialogoArqueoCaja();
          },
          const SingleActivator(LogicalKeyboardKey.f6): () {
            setState(() => _modoUi = 'cxc');
            _dialogoBuscarCxc();
          },
          const SingleActivator(LogicalKeyboardKey.f12):
              _irCobrarTicketSeleccionado,
        },
        child: Focus(
          autofocus: true,
          canRequestFocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.f2) {
              _focusBuscaProducto.requestFocus();
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.f3) {
              setState(() => _modoUi = 'cotizacion');
              _dialogoBuscarCotizacion();
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.f4) {
              _dialogoArqueoCaja();
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.f6) {
              setState(() => _modoUi = 'cxc');
              _dialogoBuscarCxc();
              return KeyEventResult.handled;
            }
            if (key == LogicalKeyboardKey.f12) {
              _irCobrarTicketSeleccionado();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: ColoredBox(
            color: const Color(0xFFF1F5F9),
            child: Column(
            children: [
              _buildPosHeader(),
              Expanded(
                child: mobile
                    ? LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth.isFinite && c.maxWidth > 0
                              ? c.maxWidth
                              : MediaQuery.sizeOf(context).width - 20;
                          return SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(10, 8, 10, 24),
                            child: SizedBox(
                              width: w,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildColProducto(compact: true),
                                  const SizedBox(height: 10),
                                  _buildColCobro(compact: true),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: _buildColProducto()),
                            const SizedBox(width: 10),
                            Expanded(flex: 4, child: _buildColCobro()),
                            const SizedBox(width: 10),
                            Expanded(flex: 4, child: _buildVistaPreviaTicket()),
                          ],
                        ),
                      ),
              ),
              _buildPosFooter(),
            ],
          ), // Column
          ), // ColoredBox
        ), // Focus
      ), // CallbackShortcuts
    ), // Theme
    ); // AppScaffold
  }





  Widget _sectionLabel(String s) => Text(
        s,
        style: const TextStyle(
          fontSize: 11,

          color: Color(0xFF1E293B),
          letterSpacing: 0.6, fontWeight: FontWeight.w700));







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




  /// Igual que cobro_venta_page._seleccionarCxc / panel cuotas.
  ({int numero, double monto, int total, int pendientes}) _cuotaActualCxc(
    CuentaPorCobrar c) {
    final plan = c.planPago;
    final cuotas = plan?.cuotas ?? const [];
    if (cuotas.isNotEmpty) {
      final pend = cuotas.where((q) => !q.pagada).toList();
      final total = plan!.numeroCuotas > 0 ? plan.numeroCuotas : cuotas.length;
      if (pend.isNotEmpty) {
        final q = pend.first;
        return (
          numero: q.numeroCuota,
          monto: q.montoTotal,
          total: total,
          pendientes: pend.length);
      }
      return (numero: total, monto: 0, total: total, pendientes: 0);
    }
    final total = c.numeroCuotas < 1 ? 1 : c.numeroCuotas;
    final monto = (plan?.montoPorCuota ?? 0) > 0
        ? plan!.montoPorCuota
        : (total > 0 ? c.saldoPendiente / total : c.saldoPendiente);
    return (
      numero: 1,
      monto: monto > 0 ? monto : c.saldoPendiente,
      total: total,
      pendientes: total);
  }

  Future<void> _dialogoBuscarCotizacion() async {
    try {
      final repo = ref.read(ventasRepositoryProvider);
      final lista = await repo.listarPendientesCobro();
      if (mounted) setState(() => _pendientes = lista);
    } catch (_) {}
    if (!mounted) return;
    final qCtrl = TextEditingController();
    var items = List<Venta>.from(_pendientes);
    final seleccionada = await AppDialog.show<Venta>(
      context,
      title: 'Buscar Cotización',
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final maxH = MediaQuery.sizeOf(dialogContext).height * 0.5;
          void filtrar(String q) {
            final qq = q.trim().toLowerCase();
            setDialogState(() {
              items = _pendientes.where((v) {
                final n = v.numeroCotizacion.toLowerCase();
                final c = (v.nombreCliente ?? '').toLowerCase();
                return qq.isEmpty || n.contains(qq) || c.contains(qq);
              }).toList();
            });
          }
          return SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width > 420
                ? 400.0
                : MediaQuery.sizeOf(dialogContext).width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: qCtrl,
                  onChanged: filtrar,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'N° Cotización o Cliente...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: maxH,
                  child: items.isEmpty
                      ? const Center(
                          child: Text('Sin cotizaciones pendientes'))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final v = items[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                '${v.numeroCotizacion} — ${v.nombreCliente ?? 'Cliente'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                              trailing: Text(
                                formatRd(v.montoTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB)),
                              ),
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(v),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
    if (seleccionada == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _seleccionarTicket(seleccionada);
      setState(() => _modoUi = 'cotizacion');
    });
  }

  Future<void> _dialogoBuscarCxc() async {
    List<CuentaPorCobrar> items = [];
    try {
      final repo = ref.read(cuentaPorCobrarRepositoryProvider);
      final todas = await repo.listarCuentas();
      items = todas
          .where((c) =>
              c.id != null && !c.estaPagada && c.saldoPendiente > 0.009)
          .toList();
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(
            content: Text('Error CxC: $e'),
            backgroundColor: AppColors.error));
      }
    }
    if (!mounted) return;
    final qCtrl = TextEditingController();
    var filtered = List<CuentaPorCobrar>.from(items);
    final seleccionada = await AppDialog.show<CuentaPorCobrar>(
      context,
      title: 'Buscar Cuenta por Cobrar',
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final maxH = MediaQuery.sizeOf(dialogContext).height * 0.5;
          void filtrar(String q) {
            final qq = q.trim().toLowerCase();
            setDialogState(() {
              filtered = items.where((c) {
                final n = (c.numero ?? '').toLowerCase();
                final cl = (c.clienteNombre ?? '').toLowerCase();
                return qq.isEmpty || n.contains(qq) || cl.contains(qq);
              }).toList();
            });
          }
          return SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width > 420
                ? 400.0
                : MediaQuery.sizeOf(dialogContext).width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: qCtrl,
                  onChanged: filtrar,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'RNC, Cédula o Nombre...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: maxH,
                  child: filtered.isEmpty
                      ? const Center(child: Text('Sin cuentas por cobrar'))
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                c.clienteNombre ?? 'Cliente',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                              subtitle: Text(c.numero ?? 'CXC-${c.id}'),
                              trailing: Text(
                                formatRd(c.saldoPendiente),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF7C3AED)),
                              ),
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(c),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
    if (seleccionada == null || !mounted) return;
    if (seleccionada.id == null) return;
    CuentaPorCobrar cuenta = seleccionada;
    try {
      final full = await ref
          .read(cuentaPorCobrarRepositoryProvider)
          .obtenerPorId(seleccionada.id!);
      if (full != null) cuenta = full;
    } catch (_) {}
    ProntoPagoAcuerdoData? acuerdo;
    try {
      acuerdo = await ProntoPagoAcuerdosDao(ref.read(databaseProvider))
          .activoPorCuenta(seleccionada.id!);
    } catch (_) {}
    double montoDef = cuenta.saldoPendiente;
    if (acuerdo != null) {
      montoDef = acuerdo.montoLiquidacion;
    } else {
      final plan = cuenta.planPago;
      if (plan != null && plan.cuotas.isNotEmpty) {
        final pend = plan.cuotas.where((q) => !q.pagada).toList();
        if (pend.isNotEmpty) {
          montoDef = pend.first.montoTotal;
        } else if (plan.montoPorCuota > 0) {
          montoDef = plan.montoPorCuota;
        }
      }
    }
    // Nombre cliente (si el listado no lo trae)
    if ((cuenta.clienteNombre == null || cuenta.clienteNombre!.isEmpty) &&
        cuenta.clienteId > 0) {
      try {
        final cliRepo = ref.read(clienteRepositoryProvider);
        final cli = await cliRepo.obtenerClientePorId(cuenta.clienteId);
        if (cli != null) {
          cuenta = cuenta.copyWith(clienteNombre: cli.nombre);
        }
      } catch (_) {}
    }

    if (montoDef > cuenta.saldoPendiente) montoDef = cuenta.saldoPendiente;
    if (!mounted) return;
    setState(() {
      _modoUi = 'cxc';
      _cxcActiva = cuenta;
      _cxcProntoPago = acuerdo;
      _ticketSeleccionado = null;
      _cxcMontoCtrl.text = montoDef.toStringAsFixed(2);
      _recibidoCtrl.text = montoDef.toStringAsFixed(2);
    });
  }



  Future<void> _dialogoArqueoCaja() async {
    if (_sesion == null) {
      FiscoGestNotifications.show(
          const SnackBar(content: Text('No hay turno activo')));
      return;
    }
    final dens = <int, TextEditingController>{
      2000: TextEditingController(text: '0'),
      1000: TextEditingController(text: '0'),
      500: TextEditingController(text: '0'),
      200: TextEditingController(text: '0'),
      100: TextEditingController(text: '0'),
    };
    double teorico = _saldo ?? 0;
    try {
      final r = await ref
          .read(cajaRepositoryProvider)
          .obtenerResumenSesion(_sesion!.id);
      teorico = r.efectivoEsperado;
    } catch (_) {}
    if (!mounted) return;
    await AppDialog.show<void>(
      context,
      title: 'Arqueo & Cierre de Caja',
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          var fisico = 0.0;
          dens.forEach((den, c) {
            fisico += den * (int.tryParse(c.text.trim()) ?? 0);
          });
          return SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width > 420
                ? 400.0
                : MediaQuery.sizeOf(dialogContext).width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Esperado\n${formatRd(teorico)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text('Contado\n${formatRd(fisico)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF047857))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final den in dens.keys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('RD\$ $den')),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: dens[den],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A)),
                  onPressed: () async {
                    var fisicoNow = 0.0;
                    dens.forEach((den, c) {
                      fisicoNow +=
                          den * (int.tryParse(c.text.trim()) ?? 0);
                    });
                    final dif = fisicoNow - teorico;
                    String? obs;
                    if (dif.abs() >= 0.005) {
                      final obsCtrl = TextEditingController();
                      final okObs = await showDialog<bool>(
                        context: dialogContext,
                        builder: (c2) => AlertDialog(
                          title: const Text('Diferencia en cuadre'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Esperado: ${formatRd(teorico)}\n'
                                'Contado: ${formatRd(fisicoNow)}\n'
                                'Diferencia: ${formatRd(dif)}',
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: obsCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Explique faltante/sobrante',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c2, false),
                                child: const Text('Cancelar')),
                            FilledButton(
                              onPressed: () {
                                if (obsCtrl.text.trim().isEmpty) return;
                                Navigator.pop(c2, true);
                              },
                              child: const Text('Continuar'),
                            ),
                          ],
                        ),
                      );
                      obs = obsCtrl.text.trim();
                      if (okObs != true || obs.isEmpty) return;
                    } else {
                      obs = 'Cuadre exacto';
                    }
                    if (!dialogContext.mounted) return;
                    try {
                      final ok = await ref
                          .read(cajaRepositoryProvider)
                          .cerrarSesion(
                            sesionId: _sesion!.id,
                            saldoTeorico: teorico,
                            montoContado: fisicoNow,
                            observacion: obs,
                          );
                      try {
                        if (ok) {
                          await ref
                              .read(bitacoraOperacionesServiceProvider)
                              .registrar(
                                accion: 'caja_cerrada',
                                entidad: 'sesion_caja',
                                entidadId: _sesion!.id,
                                usuarioId:
                                    ref.read(sesionUsuarioIdProvider),
                                resumen:
                                    'Cierre arqueo dens. dif ${formatRd(dif)}',
                                datos: {
                                  'saldoTeorico': teorico,
                                  'montoContado': fisicoNow,
                                  'diferencia': dif,
                                  'observacion': obs,
                                },
                              );
                        }
                      } catch (_) {}
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (!mounted) return;
                      ref.invalidate(dashCajaProvider);
                      final String msg;
                      if (!ok) {
                        msg = 'No se pudo cerrar la sesión';
                      } else if (dif.abs() < 0.005) {
                        msg =
                            'Caja cerrada. Cuadre exacto. Informe Z listo.';
                      } else if (dif > 0) {
                        msg = 'Caja cerrada. Sobrante: ${formatRd(dif)}';
                      } else {
                        msg =
                            'Caja cerrada. Faltante: ${formatRd(dif.abs())}';
                      }
                      FiscoGestNotifications.show(SnackBar(
                        content: Text(msg),
                        backgroundColor: ok
                            ? (dif.abs() < 0.005
                                ? AppColors.success
                                : AppColors.warning)
                            : AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                      if (ok) {
                        try {
                          final repo = ref.read(cajaRepositoryProvider);
                          final resumenZ = await repo
                              .obtenerResumenSesion(_sesion!.id);
                          final emp = ref
                              .read(configuracionControllerProvider)
                              .valueOrNull;
                          if (!mounted) return;
                          await InformeZPdf.imprimir(
                            resumen: resumenZ,
                            montoContado: fisicoNow,
                            observacion: obs,
                            cerradoEn: DateTime.now(),
                            fechaApertura: _sesion?.fechaApertura,
                            nombreComercio: emp?.nombreComercial,
                            rnc: emp?.rnc,
                            telefono: emp?.telefono,
                            direccion: emp?.direccion,
                            compartir: false,
                          );
                        } catch (ePdf) {
                          if (mounted) {
                            FiscoGestNotifications.show(SnackBar(
                              content: Text('Informe Z: $ePdf'),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      }
                      await _refrescar();
                    } catch (e) {
                      if (!mounted) return;
                      FiscoGestNotifications.show(SnackBar(
                        content:
                            Text('$e'.replaceAll('Exception: ', '')),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: const Text(
                    'CERRAR TURNO Y GENERAR INFORME Z',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }


  Widget _buildPosHeader() {
    final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
    final nombre = (cfg?.nombreComercial.trim().isNotEmpty == true)
        ? cfg!.nombreComercial.trim()
        : 'Mi negocio';
    final rnc = (cfg?.rnc.trim().isNotEmpty == true) ? cfg!.rnc.trim() : '';
    final ini = nombre.length >= 2
        ? nombre.substring(0, 2).toUpperCase()
        : nombre.toUpperCase();
    final mobileH = AppBreakpoints.isMobile(context);

    Widget modeChip(String id, String label, IconData icon, Color accent) {
      final sel = _modoUi == id;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Material(
          color: sel ? accent.withValues(alpha: 0.35) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              setState(() => _modoUi = id);
              if (id == 'cotizacion') {
                _dialogoBuscarCotizacion();
              } else if (id == 'cxc') {
                _dialogoBuscarCxc();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel
                      ? accent.withValues(alpha: 0.6)
                      : const Color(0xFF334155),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14, color: sel ? accent : const Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: sel ? accent : const Color(0xFFE2E8F0),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget arqueoBtn() {
      return Material(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _dialogoArqueoCaja,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance, size: 14, color: Color(0xFF34D399)),
                SizedBox(width: 6),
                Text(
                  'F4 Arqueo',
                  style: TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final chips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        modeChip('venta', mobileH ? 'VENTA' : 'VENTA NORMAL',
            Icons.shopping_cart_outlined, const Color(0xFF60A5FA)),
        modeChip('cotizacion', mobileH ? 'F3 Cotiz' : 'Cotiz. F3',
            Icons.description_outlined, const Color(0xFFFBBF24)),
        modeChip('cxc', mobileH ? 'F6 CxC' : 'CxC F6',
            Icons.account_balance_wallet_outlined, const Color(0xFFA78BFA)),
        const SizedBox(width: 6),
        arqueoBtn(),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobileH ? 8 : 14,
        vertical: mobileH ? 8 : 10,
      ),
      color: const Color(0xFF0F172A),
      child: mobileH
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ini,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Caja unificada',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chips,
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ini,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FiscoGest · CAJA UNIFICADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        rnc.isNotEmpty
                            ? '$nombre • RNC $rnc'
                            : nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                chips,
              ],
            ),
    );
  }


  bool get _modoSimplificado =>
      ref.watch(configuracionControllerProvider).valueOrNull
          ?.modoSimplificado ??
      false;

  bool get _exigeRncFiscal =>
      !_modoSimplificado &&
      (_tipoNcf == 'B01' || _tipoNcf == 'B14');

  /// Nombre que debe salir en la factura/preview.
  String _nombreClienteFactura(Venta? ticket) {
    if (_exigeRncFiscal) {
      final rz = _razonSocialFiscal;
      if (rz != null && rz.isNotEmpty) return rz.toUpperCase();
    }
    return (ticket?.nombreCliente ?? 'CONSUMIDOR FINAL').toUpperCase();
  }

  /// ITBIS efectivo en modo normal (si la venta trae 0, deriva o calcula 18%).
  /// Totales con ITBIS por la ruta oficial: itbisDeLineas (resolver_tasa_itbis).
  /// ITBIS por ruta oficial: itbisDeLineas (resolver_tasa_itbis).
  ({double sub, double itbis, double total}) _totalesTicketVivo(Venta ticket) {
    final sub = ticket.montoSubtotal;
    if (_modoSimplificado) {
      final total = ticket.montoTotal > 0 ? ticket.montoTotal : sub;
      return (sub: sub, itbis: 0, total: total);
    }
    final dets = ticket.detalles;
    final double itbis;
    if (dets.isNotEmpty) {
      final raw = itbisDeLineas(
        subtotales: dets.map((d) => d.subtotalLinea ?? d.subtotal),
        tasas: dets.map((d) => d.tasaImpuesto),
        descuentoGeneral: 0,
      );
      itbis = double.parse(raw.toStringAsFixed(2));
    } else {
      itbis = ticket.itbis;
    }
    final totalCalc = double.parse((sub + itbis).toStringAsFixed(2));
    final total = (ticket.montoTotal - totalCalc).abs() < 0.05
        ? ticket.montoTotal
        : totalCalc;
    return (sub: sub, itbis: itbis, total: total);
  }



  Future<void> _onTipoNcfSeleccionado(String code) async {
    setState(() => _tipoNcf = code);
    if (code == 'B01' || code == 'B14') {
      final rnc = _rncFiscalController.text.replaceAll(RegExp(r'\\D'), '');
      if (rnc.length < 9) {
        FiscoGestNotifications.show(const SnackBar(
          content: Text(
            'Comprobante fiscal: indique el RNC del cliente y consulte DGII',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        // Foco al campo RNC si existe
        try {
          // ignore: unnecessary_statements
          FocusScope.of(context).requestFocus(FocusNode());
        } catch (_) {}
      } else if (_rncNombreEncontrado == null ||
          _rncNombreEncontrado!.trim().isEmpty) {
        await _buscarRncFiscalEnLinea();
      }
      setState(() {}); // refrescar preview con razón social
    }
  }


  void _aplicarExtraCajaSiHay() {
    if (_extraCajaAplicado || !mounted) return;
    final extra = GoRouterState.of(context).extra;
    if (extra is! Map) return;
    _extraCajaAplicado = true;
    final id = extra['ventaId'];
    if (id == null) return;
    // Cargar cotización completa en esta misma pantalla
    () async {
      try {
        final full = await ref
            .read(ventasRepositoryProvider)
            .obtenerVentaPorId(id is int ? id : int.tryParse('$id') ?? 0);
        if (!mounted || full == null) return;
        await _cargarTicketCompleto(full);
      } catch (e) {
        if (!mounted) return;
        FiscoGestNotifications.show(SnackBar(
          content: Text('No se pudo cargar cotización: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }();
  }

  Future<void> _cargarTicketCompleto(Venta base) async {
    Venta ticket = base;
    if (base.id != null) {
      try {
        final full = await ref
            .read(ventasRepositoryProvider)
            .obtenerVentaPorId(base.id!);
        if (full != null) ticket = full;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _ticketSeleccionado = ticket;
      _cxcActiva = null;
      _cxcProntoPago = null;
      _modoUi = 'venta';
      _recibidoCtrl.text = ticket.montoTotal.toStringAsFixed(2);
    });
  }


  String? get _razonSocialFiscal {
    final n = (_rncNombreEncontrado ?? '').trim();
    if (n.isEmpty) return null;
    final limpio = n.split('·').first.trim();
    return limpio.isEmpty ? n : limpio;
  }

  Widget _buildVistaPreviaTicket() {
    final cfg = ref.watch(configuracionControllerProvider).valueOrNull;
    final nombre = (cfg?.nombreComercial.trim().isNotEmpty == true)
        ? cfg!.nombreComercial.trim().toUpperCase()
        : 'NEGOCIO';
    final rnc = cfg?.rnc.trim() ?? '';
    final tel = cfg?.telefono.trim() ?? '';
    final dir = cfg?.direccion.trim() ?? '';
    final simp = _modoSimplificado;

    final ticket = _ticketSeleccionado;
    final cxc = _cxcActiva;

    // Totales en vivo (Venta usa montoSubtotal; fallback a subtotal si existe)
    double sub = 0;
    double itbis = 0;
    double total = 0;
    String cliente = 'CONSUMIDOR FINAL';
    List<dynamic> lineas = const [];

    if (cxc != null) {
      final q = _cuotaActualCxc(cxc);
      final mon = double.tryParse(
            _cxcMontoCtrl.text.trim().replaceAll(',', '.'),
          ) ??
          q.monto;
      total = mon;
      sub = mon;
      itbis = 0;
      cliente = (cxc.clienteNombre ?? 'CLIENTE').toUpperCase();
    } else if (ticket != null) {
      try {
        sub = ticket.montoSubtotal;

      } catch (_) {
        sub = 0;
      }
      final tot = _totalesTicketVivo(ticket);
      sub = tot.sub;
      itbis = tot.itbis;
      total = tot.total;
      cliente = _nombreClienteFactura(ticket);
      try {
        lineas = List<dynamic>.from(
          (ticket as dynamic).detalles as List? ?? const [],
        );
      } catch (_) {
        lineas = const [];
      }
    }

    final tipo = _tipoNcf == 'B01'
        ? 'CRÉDITO FISCAL'
        : (_tipoNcf == 'B14' ? 'RÉGIMEN ESPECIAL' : 'FACTURA DE CONSUMO');

    final fecha =
        '${DateTime.now().day.toString().padLeft(2, '0')}/'
        '${DateTime.now().month.toString().padLeft(2, '0')}/'
        '${DateTime.now().year} '
        '${DateTime.now().hour.toString().padLeft(2, '0')}:'
        '${DateTime.now().minute.toString().padLeft(2, '0')}';

    // Estilo ticket: negro fuerte, negrita, fondo blanco
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF334155);
    const lineC = Color(0xFF334155);

    TextStyle ts(double size, {bool bold = true, Color? color}) => TextStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color ?? ink,
          fontFamily: 'monospace',
          height: 1.35,
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 16, color: Color(0xFF5EEAD4)),
              const SizedBox(width: 6),
              Text(
                'VISTA PREVIA · EN VIVO',
                style: ts(11, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF134E4A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2DD4BF)),
                ),
                child: Text(
                  '80mm',
                  style: ts(10, color: const Color(0xFFCCFBF1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0F172A), width: 1.4),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(nombre, textAlign: TextAlign.center, style: ts(14)),
                    if (rnc.isNotEmpty)
                      Text('RNC: $rnc',
                          textAlign: TextAlign.center, style: ts(10, color: muted)),
                    if (tel.isNotEmpty)
                      Text('Tel: $tel',
                          textAlign: TextAlign.center, style: ts(9, color: muted)),
                    if (dir.isNotEmpty)
                      Text(dir,
                          textAlign: TextAlign.center, style: ts(9, color: muted)),
                    const Divider(height: 18, thickness: 1.2, color: lineC),

                    // ── Cuerpo según modo ──
                    if (cxc != null) ...[
                      Text('TIPO: COMPROBANTE DE ABONO CXC', style: ts(11)),
                      Text(
                        'CXC: ${cxc.numero ?? cxc.id}',
                        style: ts(11),
                      ),
                      Text('CLIENTE: $cliente', style: ts(11)),
                      Text('FECHA: $fecha', style: ts(10, color: muted)),
                      Text('FORMA PAGO: $_formaPagoUi', style: ts(10)),
                      const Divider(height: 16, thickness: 1, color: lineC),
                      Builder(builder: (context) {
                        final q = _cuotaActualCxc(cxc);
                        final mon = double.tryParse(
                              _cxcMontoCtrl.text
                                  .trim()
                                  .replaceAll(',', '.'),
                            ) ??
                            q.monto;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CUOTA ${q.numero} DE ${q.total}',
                                style: ts(12, color: const Color(0xFF6D28D9))),
                            Text('ABONO: ${formatRd(mon)}', style: ts(12)),
                            Text(
                              'SALDO POST: ${formatRd((cxc.saldoPendiente - mon).clamp(0, double.infinity))}',
                              style: ts(11),
                            ),
                          ],
                        );
                      }),
                    ] else ...[
                      Text(
                        simp ? 'TIPO: COMPROBANTE' : 'NCF: $_tipoNcf********',
                        style: ts(11),
                      ),
                      if (!simp) Text('TIPO: $tipo', style: ts(11)),
                      Text('CLIENTE: $cliente', style: ts(11)),
                      Text('FECHA: $fecha', style: ts(10, color: muted)),
                      Text('FORMA PAGO: $_formaPagoUi', style: ts(10)),
                      const Divider(height: 16, thickness: 1, color: lineC),

                      // Ítems en vivo — columnas tipo DGII: Artículo | ITBIS | Total
                      if (ticket == null)
                        Text(
                          '— sin ítems —',
                          textAlign: TextAlign.center,
                          style: ts(11, color: muted),
                        )
                      else if (lineas.isEmpty) ...[
                        Text('DOC: ${ticket.numeroCotizacion}', style: ts(11)),
                        Text(
                          'Sin líneas en memoria',
                          style: ts(10, color: muted),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text('ARTÍCULO',
                                    style: ts(9, color: muted)),
                              ),
                              if (!simp)
                                Expanded(
                                  flex: 2,
                                  child: Text('ITBIS',
                                      textAlign: TextAlign.right,
                                      style: ts(9, color: muted)),
                                ),
                              Expanded(
                                flex: 2,
                                child: Text('TOTAL',
                                    textAlign: TextAlign.right,
                                    style: ts(9, color: muted)),
                              ),
                            ],
                          ),
                        ),
                        ...lineas.map((raw) {
                          final d = raw as DetalleVenta;
                          final base = d.subtotalLinea ?? d.subtotal;
                          final itb = simp
                              ? 0.0
                              : double.parse(
                                  (base * tasaComoFraccion(d.tasaImpuesto))
                                      .toStringAsFixed(2),
                                );
                          final totL = double.parse(
                            (base + itb).toStringAsFixed(2),
                          );
                          final nom = (d.nombreProducto ?? 'Ítem').trim();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    '${d.cantidad}x $nom',
                                    style: ts(10),
                                  ),
                                ),
                                if (!simp)
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      formatRd(itb),
                                      textAlign: TextAlign.right,
                                      style: ts(10),
                                    ),
                                  ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    formatRd(totL),
                                    textAlign: TextAlign.right,
                                    style: ts(10),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const Divider(height: 18, thickness: 1.2, color: lineC),

                    // Totales en vivo (SIEMPRE visibles)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!simp) ...[
                            Text('SUBTOTAL: ${formatRd(sub)}', style: ts(11)),
                            Text(
                              '${lineas.isNotEmpty ? etiquetaItbisLineas(lineas.map((e) => (e as DetalleVenta).tasaImpuesto)) : 'ITBIS'}: ${formatRd(itbis)}',
                              style: ts(11),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            'TOTAL: ${formatRd(total)}',
                            style: ts(14),
                          ),
                          if (_formaPagoUi.toLowerCase().contains('efect')) ...[
                            Builder(builder: (context) {
                              final rec = double.tryParse(
                                    _recibidoCtrl.text
                                        .trim()
                                        .replaceAll(',', '.'),
                                  ) ??
                                  0;
                              final cambio = (rec - total);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('RECIBIDO: ${formatRd(rec)}',
                                      style: ts(10, color: muted)),
                                  Text(
                                    cambio >= 0
                                        ? 'CAMBIO: ${formatRd(cambio)}'
                                        : 'FALTA: ${formatRd(-cambio)}',
                                    style: ts(10,
                                        color: cambio >= 0
                                            ? const Color(0xFF047857)
                                            : const Color(0xFFB91C1C)),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'QR\nDGII',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡Gracias por su compra!',
                      textAlign: TextAlign.center,
                      style: ts(10, color: muted),
                    ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// En desktop (Row+Expanded) usa Expanded; en móvil (ListView padre) usa alto fijo.
  /// Vertical (Column): en compact no Expanded.
  /// Horizontal (Row): SIEMPRE Expanded (TextField necesita ancho acotado).
  Widget _expandOrBox({
    required bool compact,
    required Widget child,
    double height = 200,
    bool inRow = false,
  }) {
    if (inRow) return Expanded(child: child);
    if (compact) return child;
    return Expanded(child: child);
  }


  Widget _buildColProducto({bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                const Text('BUSCAR TICKET / COTIZACIÓN',
                    style: TextStyle(
                        fontSize: 11,

                        color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6)),
                  child: const Text('F2',
                      style: TextStyle(
                          fontSize: 10,

                          color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700))),
              ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: TextField(
              controller: _buscaProductoCtrl,
              focusNode: _focusBuscaProducto,
              onSubmitted: (_) => _buscarTicketCaja(),
              decoration: InputDecoration(
                hintText: 'Ej. V-000021 o nombre de cliente…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarTicketCaja),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10))))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Expanded(
                    child: Text('ARTÍCULO',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF334155), fontWeight: FontWeight.w700))),
                Text('SUBTOTAL',
                    style: TextStyle(
                        fontSize: 10,

                        color: Color(0xFF334155), fontWeight: FontWeight.w700)),
              ])),
          _expandOrBox(
            compact: compact,
            height: 200,
            child: _buscandoTicket
                ? const Center(child: CircularProgressIndicator())
                : _resultadosBusqueda.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: compact,
                        physics: compact
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _resultadosBusqueda.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final v = _resultadosBusqueda[i];
                          return ListTile(
                            dense: true,
                            tileColor: Colors.white,
                            textColor: const Color(0xFF0F172A),
                            iconColor: const Color(0xFF0F172A),
                            title: Text(v.numeroCotizacion,
                                style: const TextStyle(

                                    color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              v.nombreCliente ?? 'Consumidor Final',
                              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                            trailing: Text(formatRd(v.montoTotal),
                                style: const TextStyle(

                                    color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                            onTap: () => _seleccionarTicket(v));
                        })
                    : _cxcActiva != null
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SingleChildScrollView(
                              child: Builder(
                                builder: (context) {
                                  final c = _cxcActiva!;
                                  final q = _cuotaActualCxc(c);
                                  final plan = c.planPago;
                                  final pend = (plan?.cuotas ?? const [])
                                      .where((x) => !x.pagada)
                                      .toList();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3E8FF),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                            child: const Text(
                                              'CUENTA POR COBRAR',
                                              style: TextStyle(
                                                fontSize: 10,

                                                color: Color(0xFF7C3AED), fontWeight: FontWeight.w700))),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: _limpiarTicket,
                                            child: const Text('Limpiar')),
                                        ]),
                                      const SizedBox(height: 8),
                                      Text(
                                        c.clienteNombre ?? 'Cliente',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      Text(
                                        c.numero ?? 'CXC-${c.id}',
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 13, fontWeight: FontWeight.w700)),
                                      if (_cxcProntoPago != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                          child: Text(
                                            'Pronto pago: liquidar ${formatRd(_cxcProntoPago!.montoLiquidacion)} '
                                            '(${_cxcProntoPago!.cuotasPendientes} cuotas · desc. ${formatRd(_cxcProntoPago!.descuentoMonto)})',
                                            style: const TextStyle(
                                              fontSize: 12,

                                              color: Color(0xFF4338CA), fontWeight: FontWeight.w700))),
                                      ],
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F3FF),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFDDD6FE))),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Cuota ${q.numero} de ${q.total}',
                                              style: const TextStyle(
                                                fontSize: 13,

                                                color: Color(0xFF5B21B6), fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text(
                                              formatRd(q.monto),
                                              style: const TextStyle(
                                                fontSize: 22,

                                                color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                                            Text(
                                              q.pendientes > 1
                                                  ? 'Monto de esta cuota · ${q.pendientes} pendientes'
                                                  : 'Monto de esta cuota',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                                          ])),
                                      if (plan != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '${plan.numeroCuotas} cuotas de ${formatRd(plan.montoPorCuota)}',
                                          style: const TextStyle(
                                            fontSize: 12,

                                            color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                                      ],
                                      _posTotRow(
                                        'Saldo total cuenta',
                                        formatRd(c.saldoPendiente)),
                                      if (pend.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Cuotas pendientes',
                                          style: TextStyle(
                                            fontSize: 11,

                                            color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        ...pend.take(8).map((cq) {
                                          final sel =
                                              cq.numeroCuota == q.numero;
                                          return InkWell(
                                            onTap: () {
                                              final m = cq.montoTotal;
                                              _cxcMontoCtrl.text =
                                                  m.toStringAsFixed(2);
                                              _recibidoCtrl.text =
                                                  m.toStringAsFixed(2);
                                              setState(() {});
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: sel
                                                    ? const Color(0xFFEDE9FE)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: sel
                                                      ? const Color(0xFF8B5CF6)
                                                      : const Color(
                                                          0xFFE2E8F0))),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '#${cq.numeroCuota}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 12,
                                                      color: sel
                                                          ? const Color(
                                                              0xFF6D28D9)
                                                          : const Color(
                                                              0xFF0F172A))),
                                                  const SizedBox(width: 8),
                                                  _expandOrBox(
                                                    compact: compact,
                                                    height: 200,
                                                    child: Text(
                                                      '${cq.fechaVencimiento.day.toString().padLeft(2, '0')}/'
                                                      '${cq.fechaVencimiento.month.toString().padLeft(2, '0')}/'
                                                      '${cq.fechaVencimiento.year}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                                                  Text(
                                                    formatRd(cq.montoTotal),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 12)),
                                                ])));
                                        }),
                                      ],
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Monto a abonar (esta cuota)',
                                        style: TextStyle(
                                          fontSize: 11,

                                          color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _cxcMontoCtrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        onChanged: (v) {
                                          _recibidoCtrl.text = v;
                                          setState(() {});
                                        },
                                        decoration: InputDecoration(
                                          prefixText: 'RD\$ ',
                                          filled: true,
                                          fillColor: const Color(0xFFF1F5F9),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                          isDense: true)),
                                    ]);
                                })))
                        : _ticketSeleccionado != null
                            ? Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Ticket seleccionado',
                                          style: TextStyle(
                                            fontSize: 11,

                                            color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: _limpiarTicket,
                                          child: const Text('Limpiar')),
                                      ]),
                                    Text(
                                      _ticketSeleccionado!.numeroCotizacion,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                    Text(
                                      _ticketSeleccionado!.nombreCliente ??
                                          'Consumidor Final',
                                      style: const TextStyle(
                                          color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Total: ${formatRd(_ticketSeleccionado!.montoTotal)}',
                                      style: const TextStyle(
                                        fontSize: 16,

                                        color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                                  ]))
                            : const Center(
                                child: Text(
                                  'Escanear o buscar siguiente cobro…',
                                  style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700)))),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Column(
              children: [
                if (_cxcActiva != null) ...[
                  _posTotRow(
                    'Saldo CxC',
                    formatRd(_cxcActiva!.saldoPendiente)),
                  const Divider(height: 14),
                  _posTotRow(
                    'A ABONAR',
                    formatRd(
                      double.tryParse(
                            _cxcMontoCtrl.text
                                .trim()
                                .replaceAll(',', '.')) ??
                          _cxcActiva!.saldoPendiente),
                    bold: true),
                ] else ...[
                  _posTotRow(
                    'Subtotal',
                    formatRd(_ticketSeleccionado != null ? _totalesTicketVivo(_ticketSeleccionado!).sub : 0)),
                  if (!_modoSimplificado) _posTotRow(
                    'ITBIS',
                    formatRd(_ticketSeleccionado != null ? _totalesTicketVivo(_ticketSeleccionado!).itbis : 0)),
                  const Divider(height: 14),
                  _posTotRow(
                    'TOTAL',
                    formatRd(_ticketSeleccionado != null ? _totalesTicketVivo(_ticketSeleccionado!).total : 0),
                    bold: true),
                ],
              ])),
        ]));
  }

  Widget _posTotRow(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(k,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: const Color(0xFF0F172A))),
          const Spacer(),
          Text(v,
              style: TextStyle(
                fontSize: bold ? 16 : 13,

                color: bold
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
        ]));
  }

  Widget _buildColCobro({bool compact = false}) {
    final total = _ticketSeleccionado?.montoTotal ?? 0.0;
    final recibido = double.tryParse(
          _recibidoCtrl.text.trim().replaceAll(',', '.')) ??
        0.0;
    final cambio = recibido - total;

    Widget ncfBtn(String code, String title, String sub) {
      final sel = _tipoNcf == code;
      return Material(
        color: sel ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onTipoNcfSeleccionado(code),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF1E293B),
                width: sel ? 2 : 1)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(

                    fontSize: 11,
                    color: sel
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: sel
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF334155), fontWeight: FontWeight.w700)),
              ]))));
    }

    Widget payBtn(String id, String label, IconData icon) {
      final sel = _formaPagoUi == id;
      Color border = const Color(0xFF1E293B);
      Color bg = const Color(0xFFF1F5F9);
      Color fg = const Color(0xFF0F172A);
      if (sel) {
        if (id == 'Efectivo') {
          border = const Color(0xFF059669);
          bg = const Color(0xFFECFDF5);
          fg = const Color(0xFF064E3B);
        } else if (id == 'Tarjeta') {
          border = const Color(0xFF2563EB);
          bg = const Color(0xFFEFF6FF);
          fg = const Color(0xFF1E3A8A);
        } else {
          border = const Color(0xFF7C3AED);
          bg = const Color(0xFFF5F3FF);
          fg = const Color(0xFF5B21B6);
        }
      }
      return Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _formaPagoUi = id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: sel ? 2 : 1)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(

                      fontSize: 11,
                      color: fg, fontWeight: FontWeight.w700))),
              ]))));
    }

    final mobileCobro = AppBreakpoints.isMobile(context);
    return Container(
      padding: EdgeInsets.all(mobileCobro ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 1)),
        ]),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CLIENTE / RNC-CÉDULA',
              style: TextStyle(
                fontSize: 11,

                color: Color(0xFF1E293B),
                letterSpacing: 0.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _expandOrBox(
                  compact: compact,
                  inRow: true,
                  child: TextField(
                    controller: _rncFiscalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'RNC o cédula',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true),
                    onSubmitted: (_) => _buscarRncFiscalEnLinea())),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: _buscandoRnc ? null : _buscarRncFiscalEnLinea,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                    child: _buscandoRnc
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                        : const Text('DGII',
                            style: TextStyle(fontWeight: FontWeight.w800)))),
              ]),
            if (_rncNombreEncontrado != null) ...[
              const SizedBox(height: 6),
              Text(
                _rncNombreEncontrado!,
                style: const TextStyle(
                  fontSize: 12,

                  color: Color(0xFF047857), fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            const Text(
              '1. COMPROBANTE FISCAL (DGII)',
              style: TextStyle(
                fontSize: 11,

                color: Color(0xFF1E293B),
                letterSpacing: 0.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: w,
                    child: ncfBtn('B02', 'B02', 'Consumo')),
                  SizedBox(
                    width: w,
                    child: ncfBtn('B01', 'B01', 'Crédito')),
                  SizedBox(
                    width: w,
                    child: ncfBtn('B14', 'B14', 'Exento')),
                ]);
            }),
            const SizedBox(height: 20),
            const Text(
              '2. MÉTODO DE PAGO',
              style: TextStyle(
                fontSize: 11,

                color: Color(0xFF1E293B),
                letterSpacing: 0.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 16) / 3;
              return Row(
                children: [
                  SizedBox(width: w, child: payBtn('Efectivo', 'Efectivo', Icons.payments_outlined)),
                  const SizedBox(width: 8),
                  SizedBox(width: w, child: payBtn('Tarjeta', 'Tarjeta', Icons.credit_card)),
                  const SizedBox(width: 8),
                  SizedBox(width: w, child: payBtn('Transfer.', 'Transfer.', Icons.swap_horiz)),
                ]);
            }),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  Row(
                    children: [
                      _expandOrBox(
                        compact: compact,
                        inRow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EFECTIVO RECIBIDO (RD\$)',
                              style: TextStyle(
                                fontSize: 11,

                                color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _recibidoCtrl,
                              onChanged: (_) => setState(() {}),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1E293B), width: 2)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12))),
                          ])),
                      const SizedBox(width: 12),
                      _expandOrBox(
                        compact: compact,
                        inRow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEVUELTA / CAMBIO',
                              style: TextStyle(
                                fontSize: 11,

                                color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                color: cambio >= 0
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cambio >= 0
                                      ? const Color(0xFF6EE7B7)
                                      : const Color(0xFFFECACA))),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  cambio >= 0
                                      ? formatRd(cambio)
                                      : 'Falta ${formatRd(-cambio)}',
                                  maxLines: 1,
                                  style: TextStyle(

                                    fontSize: 16,
                                    color: cambio >= 0
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB91C1C), fontWeight: FontWeight.w700)))),
                          ])),
                    ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Rápido:',
                        style: TextStyle(
                          fontSize: 11,

                          color: Color(0xFF334155), fontWeight: FontWeight.w700)),
                      for (final label in ['Exacto', '500', '1000', '2000'])
                        OutlinedButton(
                          onPressed: () {
                            if (label == 'Exacto') {
                              _recibidoCtrl.text = total.toStringAsFixed(2);
                            } else {
                              final actual = double.tryParse(
                                    _recibidoCtrl.text
                                        .trim()
                                        .replaceAll(',', '.')) ??
                                  0;
                              _recibidoCtrl.text =
                                  (actual + double.parse(label))
                                      .toStringAsFixed(2);
                            }
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF1E293B)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text(
                            label == 'Exacto' ? 'Exacto' : '+$label',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                    ]),
                ])),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _irCobrarTicketSeleccionado,
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'PROCESAR Y COBRAR (F12)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF059669).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))))),
          ])));
  }


  Widget _buildPosFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w700),
              children: [
                const TextSpan(text: 'Cajón: '),
                TextSpan(
                  text: formatRd(_saldo ?? 0),
                  style: const TextStyle(
                    color: Color(0xFF34D399), fontWeight: FontWeight.w700)),
              ])),
          const Spacer(),
          Text(
            AppBreakpoints.isMobile(context)
                ? 'F2 · F3 · F4 · F6 · F12'
                : 'F2 Producto · F3 Cotiz · F4 Arqueo · F6 CxC · F12 Cobrar',
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11, fontWeight: FontWeight.w700)),
        ]));
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
                offset: const Offset(0, 3)),
            ]),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(

                      )),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary)),
                  ])),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey400,
                size: 22),
            ]))));
  }
}

// ─────────────────────────────────────────────
// FILA DE MOVIMIENTO
// ─────────────────────────────────────────────

class _MiniBarsPainter extends CustomPainter {
  const _MiniBarsPainter({
    this.valores = const [0.35, 0.55, 0.4, 0.7, 0.9, 0.6, 0.45],
  });
  final List<double> valores;

  @override
  void paint(Canvas canvas, Size size) {
    final bars = valores.isEmpty ? const [0.3] : valores;
    final w = size.width / (bars.length * 1.6);
    final paint = Paint()..color = const Color(0xFF3B82F6);
    final line = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < bars.length; i++) {
      final h = bars[i].clamp(0.05, 1.0) * size.height * 0.85;
      final x = i * (w * 1.6) + w * 0.3;
      final y = size.height - h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(3),
        ),
        paint,
      );
      final cx = x + w / 2;
      if (i == 0) {
        path.moveTo(cx, y);
      } else {
        path.lineTo(cx, y);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MiniBarsPainter oldDelegate) =>
      oldDelegate.valores != valores;
}
