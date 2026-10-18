import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/alerta_operativa.dart';
import 'package:fiscogest_rd/features/notificaciones/data/alertas_leidas_store.dart';
import 'package:fiscogest_rd/features/creditos/presentation/pages/cuentas_cobrar_page.dart'
    show creditoTotalesProvider;
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/core/presentation/pages/dashboard_desktop_proto.dart'
    show dashCajaProvider;

/// Tick para forzar recarga tras marcar leídas.
final alertasRefreshTickProvider = StateProvider<int>((ref) => 0);

/// Todas las alertas activas (sin filtrar leídas).
final alertasActivasProvider =
    FutureProvider.autoDispose<List<AlertaOperativa>>((ref) async {
  ref.watch(alertasRefreshTickProvider);
  final alertas = <AlertaOperativa>[];

  // 1) Créditos vencidos
  try {
    final tot = await ref.watch(creditoTotalesProvider.future);
    if (tot.vencido > 0) {
      alertas.add(
        AlertaOperativa(
          id: 'credito_vencido',
          tipo: TipoAlertaOperativa.creditoVencido,
          titulo: 'Créditos vencidos',
          cuerpo:
              '${formatRd(tot.vencido)} en ${tot.clientes} cliente(s) con saldo vencido',
          ruta: '/creditos/cuentas',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFDC2626),
        ),
      );
    }
  } catch (_) {}

  // 2) Stock agotado
  try {
    final productosAsync = ref.watch(productoControllerProvider);
    final productos = productosAsync.valueOrNull ?? const [];
    final agotados =
        productos.where((p) => (p.stock ?? 0) <= 0).toList(growable: false);
    if (agotados.isNotEmpty) {
      final nombres = agotados
          .take(3)
          .map((p) => p.nombre)
          .where((n) => n.trim().isNotEmpty)
          .join(', ');
      final extra = agotados.length > 3 ? ' y ${agotados.length - 3} más' : '';
      alertas.add(
        AlertaOperativa(
          id: 'stock_agotado',
          tipo: TipoAlertaOperativa.stockAgotado,
          titulo: agotados.length == 1
              ? 'Producto agotado'
              : '${agotados.length} productos agotados',
          cuerpo: nombres.isEmpty
              ? 'Hay artículos sin existencias'
              : '$nombres$extra',
          ruta: '/inventario',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFFEA580C),
        ),
      );
    }
  } catch (_) {}

  // 3) Caja cerrada
  try {
    final caja = await ref.watch(dashCajaProvider.future);
    if (!caja.abierta) {
      alertas.add(
        AlertaOperativa(
          id: 'caja_cerrada',
          tipo: TipoAlertaOperativa.cajaCerrada,
          titulo: 'Caja cerrada',
          cuerpo: 'No hay turno abierto. Abra caja para cobrar en efectivo.',
          ruta: '/ventas/cobro',
          icon: Icons.point_of_sale_outlined,
          color: const Color(0xFF64748B),
        ),
      );
    }
  } catch (_) {}

  // Limpiar leídas de condiciones ya resueltas (pueden volver a avisar)
  await alertasLeidasStore.sincronizarActivas(alertas.map((a) => a.id).toSet());

  return alertas;
});

/// Solo no leídas (badge + lista principal).
final alertasOperativasProvider =
    FutureProvider.autoDispose<List<AlertaOperativa>>((ref) async {
  final activas = await ref.watch(alertasActivasProvider.future);
  final leidas = await alertasLeidasStore.obtenerLeidas();
  return activas.where((a) => !leidas.contains(a.id)).toList(growable: false);
});

Future<void> marcarAlertaLeida(WidgetRef ref, String id) async {
  await alertasLeidasStore.marcarLeida(id);
  ref.read(alertasRefreshTickProvider.notifier).state++;
  ref.invalidate(alertasActivasProvider);
  ref.invalidate(alertasOperativasProvider);
}

Future<void> marcarTodasAlertasLeidas(
  WidgetRef ref,
  Iterable<String> ids,
) async {
  await alertasLeidasStore.marcarVarias(ids);
  ref.read(alertasRefreshTickProvider.notifier).state++;
  ref.invalidate(alertasActivasProvider);
  ref.invalidate(alertasOperativasProvider);
}
