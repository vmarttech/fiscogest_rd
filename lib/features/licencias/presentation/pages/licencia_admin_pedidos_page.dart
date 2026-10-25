import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/auth/dueno_plataforma.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_config.dart';
import 'package:fiscogest_rd/core/sync/supabase/supabase_rest_client.dart';
import 'package:fiscogest_rd/core/sync/supabase/pedido_sync.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

class LicenciaAdminPedidosPage extends ConsumerStatefulWidget {
  const LicenciaAdminPedidosPage({super.key});

  static const routeName = 'licencia-admin';
  static const path = '/licencia/admin';

  @override
  ConsumerState<LicenciaAdminPedidosPage> createState() =>
      _LicenciaAdminPedidosPageState();
}

class _LicenciaAdminPedidosPageState
    extends ConsumerState<LicenciaAdminPedidosPage> {
  int _tick = 0;
  bool _sincronizandoNube = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pullPedidosPlataforma();
    });
  }

  /// Dueño plataforma: importa pedidos de todos los negocios desde Supabase.
  Future<void> _pullPedidosPlataforma() async {
    final sesion = ref.read(sesionProvider);
    if (!esDuenoPlataforma(sesion?.username)) return;
    if (!SupabaseConfig.isConfigured) return;
    if (_sincronizandoNube) return;
    setState(() => _sincronizandoNube = true);
    try {
      final remotos = await SupabaseRestClient().select(
        table: 'pedidos_licencia',
        filters: {
          'select':
              'referencia,plan,vigencia_tipo,monto,estado,created_at,expires_at,negocio_id',
          'order': 'created_at.desc',
        },
      );
      final db = ref.read(databaseProvider);
      for (final r in remotos) {
        final refCode = (r['referencia'] as String?) ?? '';
        if (refCode.isEmpty) continue;
        final existing = await (db.select(db.pedidosLicenciaTable)
              ..where((t) => t.referencia.equals(refCode)))
            .getSingleOrNull();
        final plan = (r['plan'] as String?) ?? '';
        final vigencia = (r['vigencia_tipo'] as String?) ?? '';
        final monto = (r['monto'] is num)
            ? (r['monto'] as num).toDouble()
            : double.tryParse('${r['monto']}') ?? 0.0;
        final estado = (r['estado'] as String?) ?? 'pendiente_pago';
        final created =
            (r['created_at'] as String?) ?? DateTime.now().toIso8601String();
        final expires = (r['expires_at'] as String?) ?? '';
        if (existing == null) {
          await db.into(db.pedidosLicenciaTable).insert(
                PedidosLicenciaTableCompanion.insert(
                  referencia: refCode,
                  plan: plan,
                  vigenciaTipo: vigencia,
                  monto: monto,
                  estado: estado,
                  fechaCreacion: created,
                  fechaExpiracionPedido: expires,
                ),
              );
        } else {
          await (db.update(db.pedidosLicenciaTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(
            PedidosLicenciaTableCompanion(
              plan: Value(plan),
              vigenciaTipo: Value(vigencia),
              monto: Value(monto),
              estado: Value(estado),
              fechaExpiracionPedido: Value(expires),
            ),
          );
        }
      }
      if (mounted) setState(() => _tick++);
    } catch (e, st) {
      debugPrint('Admin pedidos pull nube: $e');
      debugPrint('$st');
    } finally {
      if (mounted) setState(() => _sincronizandoNube = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final esMovil = MediaQuery.sizeOf(context).width < 700;
    return AppScaffold(
      title: 'Pedidos de licencia',
      body: FutureBuilder(
        key: ValueKey(_tick),
        future: (db.select(db.pedidosLicenciaTable)
              ..orderBy([(t) => OrderingTerm.desc(t.id)]))
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Sin pedidos aún',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando un cliente genere FG-XXXXX, aparecerá aquí.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(esMovil ? 16 : 24, 16, esMovil ? 16 : 24, 32),
            itemCount: rows.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${rows.length} pedido(s) · PayPal auto emite licencia; revisión manual solo si hace falta',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final p = rows[i - 1];
              final puedeMarcar =
                  p.estado == 'pendiente_pago' || p.estado == 'pago_reportado';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.referencia,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.plan} · ${p.vigenciaTipo}\n'
                            '${_adminMontoLabel(p)} · ${p.estado}' '${p.medioPagoPreferido == null ? '' : ' · ${p.medioPagoPreferido}'}'
                            '${p.medioPagoPreferido != null ? ' · ${p.medioPagoPreferido}' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (puedeMarcar)
                      FilledButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(licenciaServiceProvider)
                                .marcarPagadoYEmitirLicencia(p.referencia);
                            try {
                              await PedidoSync(ref.read(databaseProvider))
                                  .pushTodos();
                            } catch (e) {
                              debugPrint('Push pedido tras emitir: $e');
                            }
                            ref.invalidate(licenciaActualProvider);
                            FiscoGestNotifications.show(
                              SnackBar(content: Text('Licencia emitida: ${p.referencia}')),
                            );
                            setState(() => _tick++);
                          } catch (e) {
                            FiscoGestNotifications.show(
                              SnackBar(
                                content: Text('$e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Pagado'),
                      )
                    else
                      Text(
                        p.estado,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _adminMontoLabel(PedidosLicenciaTableData p) {
  final medio = p.medioPagoPreferido?.toLowerCase() ?? '';
  final mon = p.moneda.toUpperCase();
  final m = p.monto;
  if (medio == 'paypal' || mon == 'USD') {
    return 'US\$ ${m.toStringAsFixed(2)}';
  }
  return 'RD\$ ${m.toStringAsFixed(0)}';
}
