// [CAMPANAS_FASE1] Panel del negocio: ofertas vigentes que puede aprovechar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/enterprise_page_header.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/campanas/data/oferta_reserva_pago_store.dart';
import 'package:fiscogest_rd/features/campanas/domain/campana_promocional.dart';
import 'package:fiscogest_rd/features/campanas/presentation/providers/campanas_providers.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_estado.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

class OfertasDisponiblesPage extends ConsumerWidget {
  const OfertasDisponiblesPage({super.key});

  static const routeName = 'ofertas-disponibles';

  bool _aplica(CampanaPromocional campana, LicenciaInfo? licencia) {
    switch (campana.segmentoObjetivo) {
      case 'nuevas_cuentas':
        return false;
      case 'negocios_activos':
        return licencia?.estado == 'activa';
      case 'plan_especifico':
        return licencia != null &&
            licencia.plan.toLowerCase() ==
                (campana.planAplicar ?? '').toLowerCase();
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licencia = ref.watch(licenciaActualProvider).valueOrNull;
    final campanasAsync = ref.watch(campanasVigentesProvider);
    final aplicadas =
        ref.watch(misCampanasAplicadasProvider).valueOrNull ?? const <String>{};
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return AppScaffold(
      title: 'Ofertas disponibles',
      showAppBar: !desktop,
      actions: [
        IconButton(
          tooltip: 'Actualizar ofertas',
          onPressed: () => ref.read(campanasTickProvider.notifier).state++,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: campanasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EstadoOfertas(
          icon: Icons.cloud_off_outlined,
          title: 'No se pudieron cargar las ofertas',
          detail: 'Revisa tu conexión e inténtalo de nuevo.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(campanasTickProvider.notifier).state++,
        ),
        data: (vigentes) {
          final ofertas = vigentes
              .where((campana) => _aplica(campana, licencia))
              .toList(growable: false);

          return LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth;
              final columns = contentWidth >= 850 ? 2 : 1;
              const gap = 14.0;
              final cardWidth =
                  (contentWidth - gap * (columns - 1)).clamp(0.0, 1200.0) /
                  columns;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.read(campanasTickProvider.notifier).state++;
                  await ref.read(campanasVigentesProvider.future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 12 : 28,
                    mobile ? 12 : 20,
                    mobile ? 12 : 28,
                    mobile ? 24 : 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const EnterprisePageHeader(
                            title: 'Ofertas disponibles',
                            subtitle:
                                'Promociones vigentes para tu negocio y licencia.',
                          ),
                          if (ofertas.isEmpty)
                            const _EstadoOfertas(
                              icon: Icons.local_offer_outlined,
                              title: 'No hay ofertas disponibles',
                              detail:
                                  'Cuando haya una promoción aplicable, aparecerá aquí.',
                            )
                          else
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (final oferta in ofertas)
                                  SizedBox(
                                    width: cardWidth,
                                    child: _OfertaCard(
                                      oferta: oferta,
                                      aplicada: aplicadas.contains(oferta.id),
                                      onTap: () => _aprovechar(context, oferta),
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
            },
          );
        },
      ),
    );
  }

  Future<void> _aprovechar(
    BuildContext context,
    CampanaPromocional oferta,
  ) async {
    try {
      await OfertaReservaPagoStore.guardar(
        OfertaReserva(
          campanaId: oferta.id,
          titulo: oferta.nombre,
          valor: oferta.valor,
          efectoTipo: oferta.tipo,
        ),
      );
      if (!context.mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text(
            'Oferta reservada. Se aplicará al confirmar el pago del plan.',
          ),
        ),
      );
      await context.push('/licencia/comprar');
    } catch (error) {
      if (!context.mounted) return;
      FiscoGestNotifications.show(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    required this.oferta,
    required this.aplicada,
    required this.onTap,
  });

  final CampanaPromocional oferta;
  final bool aplicada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E6),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: Color(0xFFEA580C),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      oferta.nombre,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (aplicada) ...[
                  const SizedBox(width: 8),
                  const _OfferTag(
                    label: 'Aplicada',
                    background: Color(0xFFDBEAFE),
                    foreground: Color(0xFF1D4ED8),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OfferTag(
                  label:
                      '${oferta.tipoEtiqueta} · ${oferta.valor.isEmpty ? '—' : oferta.valor}',
                  background: const Color(0xFFFFF7ED),
                  foreground: const Color(0xFF9A3412),
                ),
                _OfferTag(
                  label: oferta.segmentoEtiqueta,
                  background: const Color(0xFFF1F5F9),
                  foreground: const Color(0xFF475569),
                ),
              ],
            ),
            if (oferta.descripcion.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                oferta.descripcion,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Válida hasta ${_fecha(oferta.fechaFin)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (oferta.diasRestantes != null)
                  Text(
                    '${oferta.diasRestantes} días',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: aplicada ? null : onTap,
                icon: Icon(
                  aplicada
                      ? Icons.check_circle_outline
                      : Icons.card_giftcard_outlined,
                  size: 19,
                ),
                label: Text(aplicada ? 'Oferta aplicada' : 'Aprovechar oferta'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTag extends StatelessWidget {
  const _OfferTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          height: 1.15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EstadoOfertas extends StatelessWidget {
  const _EstadoOfertas({
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fecha(DateTime? fecha) {
  if (fecha == null) return '—';
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
