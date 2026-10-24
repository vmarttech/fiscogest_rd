import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/widgets/plan_requerido.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/transferencias/domain/entities/transferencia.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/providers/transferencia_form_provider.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/widgets/selector_almacen_widget.dart';
import 'package:fiscogest_rd/features/transferencias/presentation/pdf/manifiesto_transferencia_pdf.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';

/// Transferencias — UI viva, datos conectados, form + dashboard.
class RegistrarTransferenciaPage extends ConsumerStatefulWidget {
  const RegistrarTransferenciaPage({super.key});
  static const String routeName = 'registrar-transferencia';

  @override
  ConsumerState<RegistrarTransferenciaPage> createState() =>
      _RegistrarTransferenciaPageState();
}

class _RegistrarTransferenciaPageState
    extends ConsumerState<RegistrarTransferenciaPage> {
  final _cantCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  final _prodBusca = TextEditingController();

  /// null = todos | 'completa' | 'pendiente' | 'error'
  String? _filtroEstado;

  static const _bg = Color(0xFFF3F4F6);
  static const _border = Color(0xFFD1D5DB);
  static const _textDark = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF4B5563);
  static const _accent = Color(0xFF00BDCC);
  static const _header = Color(0xFF009AA6);
  static const _sidebar = Color(0xFF0E1E38);
  static const _danger = Color(0xFFDC2626);
  static const _dangerBg = Color(0xFFFEE2E2);
  static const _ok = Color(0xFF10B981);
  static const _warn = Color(0xFFF59E0B);

  static const _bold = TextStyle(fontWeight: FontWeight.w800, color: _textDark);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productoControllerProvider.notifier).cargarProductos();
    });
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    _notaCtrl.dispose();
    _prodBusca.dispose();
    super.dispose();
  }

  /// Clasificación real desde productos activos.
  ({int healthy, int low, int critical, int total}) _stockStats(
    List<Producto> productos,
  ) {
    var h = 0, l = 0, c = 0;
    for (final p in productos) {
      if (!p.activo) continue;
      final s = p.stock ?? 0;
      final min = p.stockMinimo ?? 0;
      if (s <= 0) {
        c++;
      } else if (min > 0 && s <= min) {
        l++;
      } else {
        h++;
      }
    }
    return (healthy: h, low: l, critical: c, total: h + l + c);
  }

  BoxDecoration _cardDec({Color? accentBorder}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: accentBorder ?? _border,
        width: accentBorder != null ? 1.8 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (accentBorder ?? _sidebar).withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  InputDecoration _fieldDec({String? hint, IconData? prefix, Color? focus}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
      ),
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, size: 18, color: _header),
      filled: true,
      fillColor: const Color(0xFFFAFBFC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: focus ?? _accent, width: 2),
      ),
    );
  }

  Future<void> _procesar() async {
    final creada =
        await ref.read(transferenciaFormProvider.notifier).enviar();
    if (creada != null && mounted) {
      _cantCtrl.clear();
      _notaCtrl.clear();
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('✅ Transferencia registrada'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      // Manifiesto / packing list si está activo en Configuración → Documentos
      try {
        final cfgAsync = ref.read(configuracionControllerProvider);
        final cfg = cfgAsync.valueOrNull;
        if (cfg != null && cfg.transfImprimirManifiesto) {
          await ManifiestoTransferenciaPdf.imprimir(t: creada, cfg: cfg);
        }
      } catch (_) {
        // No bloquear el flujo si falla la impresión
      }
    }
  }

  void _detalleTransferencia(Transferencia t) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: _header, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'TF-${t.id ?? '—'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                ),
                _estadoPill(t.estado),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Producto',
                '${t.productoCodigo ?? ''} ${t.productoNombre ?? '#${t.productoId}'}'),
            _detailRow(
                'Origen', t.origenNombre ?? 'Almacén ${t.almacenOrigenId}'),
            _detailRow(
                'Destino', t.destinoNombre ?? 'Almacén ${t.almacenDestinoId}'),
            _detailRow('Cantidad', t.cantidad.toStringAsFixed(2)),
            _detailRow('Fecha', fmt.format(t.fecha)),
            if ((t.nota ?? '').isNotEmpty) _detailRow('Nota', t.nota!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _header,
                  side: const BorderSide(color: _accent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: _textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoPill(String estado) {
    final e = estado.toLowerCase();
    Color bg = const Color(0xFFECFDF5);
    Color fg = _ok;
    if (e.contains('pend')) {
      bg = const Color(0xFFFFFBEB);
      fg = _warn;
    } else if (e.contains('cancel') || e.contains('error')) {
      bg = _dangerBg;
      fg = _danger;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(almacenesHabilitadosProvider)) {
      return const PlanRequeridoAlmacenes(titulo: 'Transferencias');
    }

    final isMobile = AppBreakpoints.isMobile(context);
    final form = ref.watch(transferenciaFormProvider);
    final historial = ref.watch(transferenciasHistorialProvider);
    final stockOrigen = ref.watch(stockOrigenProvider);
    final productos =
        ref.watch(productoControllerProvider).valueOrNull ?? <Producto>[];
    final stats = _stockStats(productos);
    final q = _prodBusca.text.trim().toLowerCase();
    final filtrados = productos
        .where((p) {
          if (q.isEmpty) return true;
          return p.nombre.toLowerCase().contains(q) ||
              p.codigo.toLowerCase().contains(q);
        })
        .take(80)
        .toList();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppScaffold(
      // Móvil: AppBar como el resto de pantallas. Desktop: sin AppBar.
      title: isMobile ? 'Transferencias' : null,
      subtitle: isMobile ? 'Mover stock entre almacenes' : null,
      showAppBar: isMobile,
      showBackButton: isMobile,
      backgroundColor: _bg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: isMobile
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                    children: [
                      const SizedBox(height: 10),
                      _formCard(form, filtrados, stockOrigen, isMobile: true),
                      const SizedBox(height: 16),
                      // En móvil: mini resumen conectado
                      _resumenCard(stats, historial, fmt, compact: true),
                      const SizedBox(height: 12),
                      _historialPanel(historial, fmt),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Volver',
                          onPressed: () => safeBack(context, fallback: '/'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0E1E38),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 12,
                            child: _formCard(
                              form,
                              filtrados,
                              stockOrigen,
                              isMobile: false,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 10,
                            child: Column(
                              children: [
                                _resumenCard(
                                    stats, historial, fmt, compact: false),
                                const SizedBox(height: 16),
                                _historialPanel(historial, fmt),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── FORMULARIO ─────────────────────────────────────────────────────────
  Widget _formCard(
    TransferenciaFormState form,
    List<Producto> filtrados,
    AsyncValue<double> stockOrigen, {
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: _cardDec(accentBorder: _accent.withValues(alpha: 0.35)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Nueva Transferencia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner flujo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _header.withValues(alpha: 0.08),
                  _accent.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(child: _flowNode('Origen', Icons.outbox_rounded)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      size: 18, color: Colors.white),
                ),
                Expanded(child: _flowNode('Destino', Icons.inbox_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (isMobile) ...[
            SelectorAlmacenWidget(
              label: 'Almacén origen',
              initialValue: form.almacenOrigen,
              excludeId: form.almacenDestino,
              onChanged: (v) => ref
                  .read(transferenciaFormProvider.notifier)
                  .seleccionarAlmacenOrigen(v),
            ),
            const SizedBox(height: 12),
            SelectorAlmacenWidget(
              label: 'Almacén destino',
              initialValue: form.almacenDestino,
              excludeId: form.almacenOrigen,
              onChanged: (v) => ref
                  .read(transferenciaFormProvider.notifier)
                  .seleccionarAlmacenDestino(v),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectorAlmacenWidget(
                    label: 'Almacén origen',
                    initialValue: form.almacenOrigen,
                    excludeId: form.almacenDestino,
                    onChanged: (v) => ref
                        .read(transferenciaFormProvider.notifier)
                        .seleccionarAlmacenOrigen(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectorAlmacenWidget(
                    label: 'Almacén destino',
                    initialValue: form.almacenDestino,
                    excludeId: form.almacenOrigen,
                    onChanged: (v) => ref
                        .read(transferenciaFormProvider.notifier)
                        .seleccionarAlmacenDestino(v),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          TextField(
            controller: _prodBusca,
            style: _bold.copyWith(fontSize: 14),
            decoration: _fieldDec(
              hint: 'Buscar producto…',
              prefix: Icons.search_rounded,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          InputDecorator(
            decoration: _fieldDec(hint: 'Seleccione producto'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                isDense: true,
                style: _bold.copyWith(fontSize: 14),
                hint: const Text(
                  'Seleccione producto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                value: filtrados.any((p) => p.id == form.productoId)
                    ? form.productoId
                    : null,
                items: [
                  for (final p in filtrados)
                    if (p.id != null)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.codigo} — ${p.nombre}',
                          style: _bold.copyWith(fontSize: 13),
                        ),
                      ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref
                        .read(transferenciaFormProvider.notifier)
                        .seleccionarProducto(v);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stock badges vivos + táctiles
          stockOrigen.when(
            loading: () => const LinearProgressIndicator(
              color: _accent,
              minHeight: 3,
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (s) {
              // Sin producto u origen: no mostrar falso 'crítico'
              final formNow = ref.read(transferenciaFormProvider);
              final sinContexto = formNow.productoId == null ||
                  formNow.almacenOrigen == null;
              if (sinContexto) {
                return Row(
                  children: [
                    Expanded(
                      child: _liveBadge(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock origen',
                        value: '—',
                        color: _textMuted,
                        onTap: () {
                          FiscoGestNotifications.show(
                            const SnackBar(
                              content: Text(
                                'Seleccione almacén origen y producto',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _liveBadge(
                        icon: Icons.info_outline_rounded,
                        label: 'Alerta',
                        value: '—',
                        color: _textMuted,
                        onTap: () {
                          FiscoGestNotifications.show(
                            const SnackBar(
                              content: Text(
                                'Seleccione almacén origen y producto',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              final critico = s <= 0;
              return Row(
                children: [
                  Expanded(
                    child: _liveBadge(
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock origen',
                      value: s.toStringAsFixed(2),
                      color: critico ? _danger : _ok,
                      onTap: () {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text(
                              critico
                                  ? 'Sin existencias en el almacén origen'
                                  : 'Disponible en origen: ${s.toStringAsFixed(2)}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _liveBadge(
                      icon: Icons.warning_amber_rounded,
                      label: 'Alerta',
                      value: critico ? 'CRÍTICO' : 'OK',
                      color: critico ? _danger : _ok,
                      solid: critico,
                      onTap: () {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text(
                              critico
                                  ? 'No podrá transferir hasta reponer stock'
                                  : 'Stock suficiente para transferir',
                            ),
                            backgroundColor:
                                critico ? _danger : const Color(0xFF059669),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _cantCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: _bold.copyWith(fontSize: 14),
            decoration: _fieldDec(hint: 'Cantidad', prefix: Icons.numbers),
            onChanged: (v) =>
                ref.read(transferenciaFormProvider.notifier).asignarCantidad(v),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notaCtrl,
            style: _bold.copyWith(fontSize: 14),
            decoration:
                _fieldDec(hint: 'Nota (opcional)', prefix: Icons.notes_rounded),
            onChanged: (v) =>
                ref.read(transferenciaFormProvider.notifier).asignarNota(v),
          ),

          if (form.error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                form.error!,
                style: const TextStyle(
                  color: _danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: form.esValido && !form.enviando ? _procesar : null,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withValues(alpha: 0.4),
                elevation: 2,
                shadowColor: _accent.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                form.enviando
                    ? 'PROCESANDO…'
                    : 'PROCESAR TRANSFERENCIA',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flowNode(String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _sidebar.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 26, color: _sidebar),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _textMuted,
          ),
        ),
      ],
    );
  }

  Widget _liveBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool solid = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: solid ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: solid ? 0 : 0.35),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: solid ? Colors.white : color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: solid
                            ? Colors.white.withValues(alpha: 0.9)
                            : _textMuted,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: solid ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── RESUMEN (torta + últimos) ──────────────────────────────────────────
  Widget _resumenCard(
    ({int healthy, int low, int critical, int total}) stats,
    AsyncValue<List<Transferencia>> historial,
    DateFormat fmt, {
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDec(accentBorder: _header.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: _header,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Resumen de Transferencias Recientes y Estado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (compact)
            Column(
              children: [
                _estadoStockCard(stats),
                const SizedBox(height: 12),
                _ultimosMovimientosCard(historial),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _estadoStockCard(stats)),
                const SizedBox(width: 12),
                Expanded(child: _ultimosMovimientosCard(historial)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _estadoStockCard(
    ({int healthy, int low, int critical, int total}) stats,
  ) {
    final t = stats.total == 0 ? 1 : stats.total;
    final pH = stats.healthy / t;
    final pL = stats.low / t;
    // critical = resto

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _ok.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado General del Stock',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Pie real por proporciones
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _PiePainter(
                    healthy: pH,
                    low: pL,
                  ),
                  child: Center(
                    child: Text(
                      '${stats.total}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _legendTap(
                      _ok,
                      'Healthy',
                      stats.healthy,
                      () {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text(
                              '${stats.healthy} producto(s) con stock saludable',
                            ),
                          ),
                        );
                      },
                    ),
                    _legendTap(
                      _warn,
                      'Low',
                      stats.low,
                      () {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text(
                              '${stats.low} producto(s) bajo mínimo',
                            ),
                            backgroundColor: _warn,
                          ),
                        );
                      },
                    ),
                    _legendTap(
                      _danger,
                      'Critical',
                      stats.critical,
                      () {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text(
                              '${stats.critical} producto(s) sin stock',
                            ),
                            backgroundColor: _danger,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendTap(Color c, String label, int n, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Text(
                '● ',
                style: TextStyle(color: c, fontWeight: FontWeight.w900),
              ),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _textMuted,
                  ),
                ),
              ),
              Text(
                '$n',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: c,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ultimosMovimientosCard(
    AsyncValue<List<Transferencia>> historial,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, _accent.withValues(alpha: 0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos Movimientos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 10),
          historial.when(
            loading: () => const LinearProgressIndicator(
              color: _accent,
              minHeight: 3,
            ),
            error: (_, __) => const Text(
              'Sin datos',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Sin movimientos aún',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in rows.take(3))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _detalleTransferencia(t),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'TF-${t.id ?? '—'} · '
                                  '${t.origenNombre ?? 'Origen'} → '
                                  '${t.destinoNombre ?? 'Destino'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                              const Text(
                                'Completa',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: _ok,
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── HISTORIAL PANEL ────────────────────────────────────────────────────
  Widget _historialPanel(
    AsyncValue<List<Transferencia>> historial,
    DateFormat fmt,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDec(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: _sidebar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Transferencias Pendientes / Recientes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () =>
                    ref.invalidate(transferenciasHistorialProvider),
                icon: const Icon(Icons.refresh_rounded, color: _header),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filtros por estado (funcionales)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', null),
                const SizedBox(width: 6),
                _filterChip('Completas', 'completa'),
                const SizedBox(width: 6),
                _filterChip('Pendientes', 'pendiente'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          historial.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: _accent)),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(
                color: _danger,
                fontWeight: FontWeight.w800,
              ),
            ),
            data: (rows) {
              var list = rows;
              if (_filtroEstado != null) {
                list = rows
                    .where((t) =>
                        t.estado.toLowerCase().contains(_filtroEstado!))
                    .toList();
                // "completa" / "registrada" ≈ completa
                if (_filtroEstado == 'completa') {
                  list = rows
                      .where((t) {
                        final e = t.estado.toLowerCase();
                        return e.contains('completa') ||
                            e.contains('registrad') ||
                            e == 'ok';
                      })
                      .toList();
                }
              }
              if (list.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no hay transferencias registradas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Las actividades generadas durante el día aparecerán listadas en este panel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final t in list.take(15))
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _detalleTransferencia(t),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.swap_horiz,
                                    size: 18, color: _header),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TF-${t.id ?? '—'} · '
                                      '${t.productoCodigo ?? ''} '
                                      '${t.productoNombre ?? 'Producto ${t.productoId}'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${t.origenNombre ?? t.almacenOrigenId} → '
                                      '${t.destinoNombre ?? t.almacenDestinoId}'
                                      ' · ${t.cantidad}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _estadoPill(t.estado),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? key) {
    final selected = _filtroEstado == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _filtroEstado = key),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _sidebar : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _sidebar : _border,
              width: 1.4,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : _textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Torta Healthy / Low / Critical (proporciones reales).
class _PiePainter extends CustomPainter {
  _PiePainter({required this.healthy, required this.low});
  final double healthy;
  final double low;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    var start = -90.0 * 3.14159265 / 180;

    void slice(double portion, Color color) {
      if (portion <= 0) return;
      final sweep = portion * 2 * 3.14159265;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }

    final critical = (1.0 - healthy - low).clamp(0.0, 1.0);
    if (healthy + low + critical < 0.01) {
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFE2E8F0));
    } else {
      slice(healthy, const Color(0xFF10B981));
      slice(low, const Color(0xFFF59E0B));
      slice(critical, const Color(0xFFEF4444));
    }
    // donut hole
    canvas.drawCircle(c, r * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.healthy != healthy || old.low != low;
}
