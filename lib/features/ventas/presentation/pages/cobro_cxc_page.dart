import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/services/bitacora_operaciones_service.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/cuota.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart'
    show cajaRepositoryProvider;
import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart'
    show listadoCuentasCobrarProvider;

/// Cobro de cuota / abono CXC **desde Caja**.
/// Misma idea que cobrar cotización: solo monto + forma de pago + confirmar.
class CobroCxcPage extends ConsumerStatefulWidget {
  const CobroCxcPage({super.key, required this.cuentaId});

  static const String routeName = 'cobro-cxc';
  static const String path = '/ventas/cobro/cxc/:id';

  final int cuentaId;

  @override
  ConsumerState<CobroCxcPage> createState() => _CobroCxcPageState();
}

class _CobroCxcPageState extends ConsumerState<CobroCxcPage> {
  CuentaPorCobrar? _cuenta;
  bool _cargando = true;
  String? _error;
  bool _procesando = false;

  final _montoCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _efectivoCtrl = TextEditingController();
  String _formaPago = 'Efectivo';
  static final _fmtFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _refCtrl.dispose();
    _efectivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final c = await ref
          .read(cuentaPorCobrarRepositoryProvider)
          .obtenerPorId(widget.cuentaId);
      if (c == null) {
        setState(() {
          _error = 'Cuenta no encontrada';
          _cargando = false;
        });
        return;
      }
      if (c.estaPagada) {
        setState(() {
          _cuenta = c;
          _error = 'Esta cuenta ya está saldada';
          _cargando = false;
        });
        return;
      }
      final pendientes =
          c.planPago?.cuotas.where((q) => !q.pagada).toList() ?? <Cuota>[];
      final sugerido = pendientes.isNotEmpty
          ? pendientes.first.montoTotal.clamp(0.01, c.saldoPendiente)
          : c.saldoPendiente;
      _montoCtrl.text = sugerido.toStringAsFixed(2);
      _efectivoCtrl.text = sugerido.toStringAsFixed(2);
      setState(() {
        _cuenta = c;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  double get _monto {
    final raw = _montoCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _cobrar() async {
    final c = _cuenta;
    if (c == null || c.id == null || _procesando) return;
    final monto = _monto;
    if (monto <= 0) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Indique un monto válido')),
      );
      return;
    }
    if (monto > c.saldoPendiente + 0.01) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'El monto supera el saldo (${formatRd(c.saldoPendiente)})',
          ),
        ),
      );
      return;
    }
    if (_formaPago == 'Efectivo') {
      final rec = double.tryParse(
            _efectivoCtrl.text.trim().replaceAll(',', '.'),
          ) ??
          0;
      if (rec + 0.001 < monto) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('Efectivo recibido insuficiente')),
        );
        return;
      }
    }

    setState(() => _procesando = true);
    try {
      final pendientes =
          c.planPago?.cuotas.where((q) => !q.pagada).toList() ?? <Cuota>[];
      final nota = pendientes.isNotEmpty
          ? 'Cuota #${pendientes.first.numeroCuota} · Caja'
          : 'Abono · Caja';

      await ref.read(databaseProvider).transaction(() async {
        await ref.read(cuentaPorCobrarRepositoryProvider).registrarAbono(
              AbonoCredito(
                cuentaId: c.id!,
                monto: monto,
                metodoPago: _formaPago,
                fecha: DateTime.now(),
                nota: nota,
              ),
            );
        await ref.read(cajaRepositoryProvider).registrarMovimiento(
              referencia: c.numero ?? 'CXC-${c.id}',
              monto: monto,
              tipo: 'ingreso',
              descripcion:
                  'Abono CXC ${c.numero ?? c.id} · ${c.clienteNombre ?? ''}',
              formaPago: _formaPago,
            );
      });

      try {
        await ref.read(bitacoraOperacionesServiceProvider).registrar(
              accion: 'pago_caja_cxc',
              entidad: 'cuenta_por_cobrar',
              entidadId: c.id,
              usuarioId: ref.read(sesionUsuarioIdProvider),
              resumen:
                  'Caja cobró ${formatRd(monto)} de ${c.clienteNombre ?? 'CXC'}',
              datos: {'metodoPago': _formaPago},
            );
      } catch (_) {}

      ref.invalidate(listadoCuentasCobrarProvider(0));

      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Cobro registrado: ${formatRd(monto)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/ventas/cobro');
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Error al cobrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final c = _cuenta;

    return AppScaffold(
      title: 'COBRO EN CAJA',
      showAppBar: !AppBreakpoints.isDesktop(context),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/ventas/cobro');
          }
        },
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null && c == null
              ? Center(child: Text(_error!))
              : Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 16 : 24,
                      16,
                      mobile ? 16 : 24,
                      32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Resumen deuda (como cotización)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long,
                                        color: Color(0xFF059669),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c?.numero ?? 'CXC-${widget.cuentaId}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            c?.clienteNombre ??
                                                'Cliente #${c?.clienteId ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                _rowInfo(
                                  'Saldo pendiente',
                                  formatRd(c?.saldoPendiente ?? 0),
                                ),
                                if (c?.ventaId != null)
                                  _rowInfo('Venta', '#${c!.ventaId}'),
                                _rowInfo(
                                  'Vence',
                                  c != null
                                      ? _fmtFecha.format(c.fechaVencimiento)
                                      : '—',
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text(
                                      'TOTAL A COBRAR',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      formatRd(_monto > 0
                                          ? _monto
                                          : (c?.saldoPendiente ?? 0)),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Monto a cobrar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _montoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixText: 'RD\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              hintText: 'Monto de la cuota o abono',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Puede cobrar la cuota sugerida o un abono parcial/total del saldo.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Forma de pago',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final f in [
                                'Efectivo',
                                'Tarjeta',
                                'Transferencia',
                              ])
                                ChoiceChip(
                                  label: Text(f),
                                  selected: _formaPago == f,
                                  onSelected: (_) =>
                                      setState(() => _formaPago = f),
                                  selectedColor: const Color(0xFFD1FAE5),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _formaPago == f
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                            ],
                          ),
                          if (_formaPago == 'Efectivo') ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Efectivo recibido',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _efectivoCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'RD\$ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                          if (_formaPago != 'Efectivo') ...[
                            const SizedBox(height: 14),
                            const Text(
                              'N° referencia',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _refCtrl,
                              decoration: InputDecoration(
                                hintText: 'Ej: TR-99882',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _procesando ||
                                      (c?.estaPagada ?? true)
                                  ? null
                                  : _cobrar,
                              icon: _procesando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.point_of_sale),
                              label: Text(
                                _procesando
                                    ? 'Procesando…'
                                    : 'COBRAR ABONO / CUOTA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
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
                  ),
                ),
    );
  }

  Widget _rowInfo(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            k,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const Spacer(),
          Text(
            v,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
