import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/alerta_operativa.dart';
import 'package:fiscogest_rd/features/notificaciones/domain/aviso_remoto.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/notificaciones_provider.dart';
import 'package:fiscogest_rd/features/notificaciones/presentation/providers/avisos_provider.dart';

/// Envoltorio para distinguir el valor de un aviso remoto en el menú.
class _AvisoPayload {
  const _AvisoPayload(this.aviso);
  final AvisoRemoto aviso;
}

IconData _iconoAviso(String tipo) {
  switch (tipo) {
    case 'oferta':
      return Icons.card_giftcard_outlined;
    case 'vencimiento':
      return Icons.schedule_outlined;
    case 'suspension':
      return Icons.block_outlined;
    case 'renovacion':
      return Icons.event_repeat_outlined;
    case 'sistema':
      return Icons.info_outline;
    default:
      return Icons.campaign_outlined;
  }
}

Color _colorAviso(String prioridad) {
  switch (prioridad) {
    case 'urgente':
      return const Color(0xFFDC2626);
    case 'alta':
      return const Color(0xFFEA580C);
    default:
      return const Color(0xFF2563EB);
  }
}

/// Campana del top bar: badge combinado (alertas locales + avisos de plataforma).
class CampanaNotificaciones extends ConsumerWidget {
  const CampanaNotificaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertasOperativasProvider);
    final locales = async.valueOrNull ?? const <AlertaOperativa>[];
    final remotos =
        ref.watch(avisosRemotosProvider).valueOrNull ?? const <AvisoRemoto>[];
    final remotosNoLeidos = remotos
        .where((a) => !a.leido)
        .toList(growable: false);
    final count = locales.length + remotosNoLeidos.length;

    return IconButton(
      tooltip: count > 0 ? '$count notificación(es)' : 'Notificaciones',
      onPressed: () => _abrirPanel(context, ref, locales, remotosNoLeidos),
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
    List<AvisoRemoto> avisos,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final menuWidth = screenWidth < 304
        ? screenWidth - 16
        : (screenWidth - 24).clamp(280.0, 360.0).toDouble();
    final horizontalMargin = (screenWidth - menuWidth) / 2;
    final left = (topLeft.dx + box.size.width - menuWidth)
        .clamp(horizontalMargin, screenWidth - menuWidth - horizontalMargin)
        .toDouble();
    final position = RelativeRect.fromLTRB(
      left,
      topLeft.dy + box.size.height,
      overlay.size.width - left - menuWidth,
      0,
    );

    final selected = await showMenu<Object?>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth),
      items: [
        PopupMenuItem<Object?>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _Cabecera(
            count: alertas.length,
            onMarcarTodas: alertas.isEmpty
                ? null
                : () => Navigator.pop(context, '_marcar_todas_local'),
          ),
        ),
        if (alertas.isEmpty && avisos.isEmpty)
          PopupMenuItem<Object?>(
            enabled: false,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Todo en orden. Sin notificaciones pendientes.',
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
        else ...[
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
            child: _CabeceraAvisos(
              count: avisos.length,
              onMarcarTodas: avisos.isEmpty
                  ? null
                  : () => Navigator.pop(context, '_marcar_todas_avisos'),
            ),
          ),
          ...avisos.map(
            (a) => PopupMenuItem<Object?>(
              value: _AvisoPayload(a),
              padding: EdgeInsets.zero,
              child: _ItemAviso(aviso: a),
            ),
          ),
        ],
        PopupMenuItem<Object?>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => Navigator.pop(context, '_refresh'),
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

    if (selected == '_marcar_todas_local') {
      await marcarTodasAlertasLeidas(ref, alertas.map((a) => a.id));
      invalidarAvisos(ref);
      return;
    }
    if (selected == '_marcar_todas_avisos') {
      await marcarAvisosTodosLeidos(ref);
      return;
    }
    if (selected == '_refresh') {
      ref.invalidate(alertasActivasProvider);
      ref.invalidate(alertasOperativasProvider);
      invalidarAvisos(ref);
      return;
    }
    if (selected is AlertaOperativa) {
      await marcarAlertaLeida(ref, selected.id);
      if (context.mounted) await context.push(selected.ruta);
      return;
    }
    if (selected is _AvisoPayload) {
      final aviso = selected.aviso;
      await marcarAvisoLeido(ref, aviso.id);
      if (!context.mounted) return;
      if (aviso.tipo == 'oferta') {
        await context.push('/ofertas-disponibles');
      } else {
        _mostrarAviso(context, aviso);
      }
    }
  }

  void _mostrarAviso(BuildContext context, AvisoRemoto a) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a.titulo),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${a.tipoEtiqueta} · Prioridad ${a.prioridadEtiqueta}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                a.mensaje,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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

class _CabeceraAvisos extends StatelessWidget {
  const _CabeceraAvisos({required this.count, this.onMarcarTodas});
  final int count;
  final VoidCallback? onMarcarTodas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 15,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 6),
          const Text(
            'Avisos de plataforma',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          if (count > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
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
                  'Marcar todos',
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

class _ItemAviso extends StatelessWidget {
  const _ItemAviso({required this.aviso});
  final AvisoRemoto aviso;

  @override
  Widget build(BuildContext context) {
    final color = _colorAviso(aviso.prioridad);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconoAviso(aviso.tipo), size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aviso.titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aviso.mensaje,
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
          if (!aviso.leido)
            Container(
              margin: const EdgeInsets.only(top: 4, right: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
