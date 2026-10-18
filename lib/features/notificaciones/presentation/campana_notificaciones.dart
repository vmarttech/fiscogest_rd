import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/alerta_operativa.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/notificaciones_provider.dart';

/// Campana del top bar: badge + menú con alertas operativas (Fase 2: leídas).
class CampanaNotificaciones extends ConsumerWidget {
  const CampanaNotificaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertasOperativasProvider);
    final count = async.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return IconButton(
      tooltip: count > 0 ? '$count alerta(s)' : 'Notificaciones',
      onPressed: () => _abrirPanel(context, ref, async.valueOrNull ?? const []),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFDC2626),
        child: Icon(
          count > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_outlined,
          size: 22,
          color: const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Future<void> _abrirPanel(
    BuildContext context,
    WidgetRef ref,
    List<AlertaOperativa> alertas,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      topLeft.dx - 280 + box.size.width,
      topLeft.dy + box.size.height,
      overlay.size.width - topLeft.dx - box.size.width,
      0,
    );

    final selected = await showMenu<Object?>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      constraints: const BoxConstraints(minWidth: 340, maxWidth: 360),
      items: [
        PopupMenuItem<Object?>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _Cabecera(
            count: alertas.length,
            onMarcarTodas: alertas.isEmpty
                ? null
                : () async {
                    Navigator.pop(context, '_marcar_todas');
                  },
          ),
        ),
        if (alertas.isEmpty)
          PopupMenuItem<Object?>(
            enabled: false,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 20, color: Colors.green.shade600),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Todo en orden. Sin alertas pendientes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...alertas.map(
            (a) => PopupMenuItem<Object?>(
              value: a,
              padding: EdgeInsets.zero,
              child: _ItemAlerta(alerta: a),
            ),
          ),
        PopupMenuItem<Object?>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.pop(context, '_refresh');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text(
                    'Actualizar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (selected == '_marcar_todas') {
      await marcarTodasAlertasLeidas(ref, alertas.map((a) => a.id));
      return;
    }
    if (selected == '_refresh') {
      ref.invalidate(alertasActivasProvider);
      ref.invalidate(alertasOperativasProvider);
      return;
    }
    if (selected is AlertaOperativa) {
      // Al abrir la ruta, marcar como leída
      await marcarAlertaLeida(ref, selected.id);
      if (context.mounted) context.push(selected.ruta);
    }
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.count, this.onMarcarTodas});
  final int count;
  final VoidCallback? onMarcarTodas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Text(
            'Alertas operativas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          if (count > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
            if (onMarcarTodas != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onMarcarTodas,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF2563EB),
                ),
                child: const Text(
                  'Marcar leídas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItemAlerta extends StatelessWidget {
  const _ItemAlerta({required this.alerta});
  final AlertaOperativa alerta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: alerta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(alerta.icon, size: 18, color: alerta.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alerta.cuerpo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
