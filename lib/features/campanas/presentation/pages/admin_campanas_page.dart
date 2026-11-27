// [CAMPANAS_FASE1] Panel del dueño: listado y gestión de campañas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/enterprise_page_header.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/campanas/domain/campana_promocional.dart';
import 'package:fiscogest_rd/features/campanas/presentation/providers/campanas_providers.dart';
import 'package:fiscogest_rd/features/campanas/data/campana_oferta_notifier.dart';
import 'package:fiscogest_rd/core/i18n/servicio_idioma.dart';

class AdminCampanasPage extends ConsumerWidget {
  const AdminCampanasPage({super.key});
  static const routeName = 'admin-campanas';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(campanasAdminProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'Ofertas y campañas',
      showAppBar: !desktop,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/campanas/nueva'),
        icon: const Icon(Icons.add),
        label: Text(ServicioIdioma.t(context, 'Nueva campaña')),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(campanasTickProvider.notifier).state++,
                child: Text(ServicioIdioma.t(context, 'Reintentar')),
              ),
            ],
          ),
        ),
        data: (lista) {
          final padding = EdgeInsets.fromLTRB(
            mobile ? 16 : 28,
            20,
            mobile ? 16 : 28,
            100,
          );
          final contenido = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EnterprisePageHeader(
                    title: 'Ofertas y campañas',
                    subtitle: 'Administra campañas, ofertas y su vigencia.',
                    showBack: true,
                    backFallbackRoute: '/',
                  ),
                  if (lista.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Sin campañas. Crea la primera oferta con el botón.',
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 850 ? 2 : 1;
                        const gap = 14.0;
                        final width =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final c in lista)
                              SizedBox(
                                width: width,
                                child: _TarjetaCampana(campana: c),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          );
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            child: contenido,
          );
        },
      ),
    );
  }
}

class _TarjetaCampana extends ConsumerWidget {
  const _TarjetaCampana({required this.campana});
  final CampanaPromocional campana;

  Color get _estadoColor => switch (campana.estadoEtiqueta) {
    'Vigente' => const Color(0xFF059669),
    'Próxima' => const Color(0xFF2563EB),
    'Vencida' => const Color(0xFF64748B),
    _ => const Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usoTxt = campana.limiteUsos == null
        ? '${campana.usosActuales} uso(s)'
        : '${campana.usosActuales}/${campana.limiteUsos} usos';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campana.nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    campana.estadoEtiqueta,
                    style: TextStyle(
                      color: _estadoColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              campana.segmentoEtiqueta,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${campana.tipoEtiqueta} · Valor: ${campana.valor.isEmpty ? '—' : campana.valor}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              '${_fecha(campana.fechaInicio)} → ${_fecha(campana.fechaFin)} · $usoTxt'
              '${campana.diasRestantes != null ? ' · ${campana.diasRestantes} días restantes' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (campana.descripcion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                campana.descripcion,
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: campana.activa,
                  onChanged: (v) async {
                    try {
                      await ref
                          .read(campanasRemoteProvider)
                          .alternar(campana.id, v);
                      ref.read(campanasTickProvider.notifier).state++;
                      if (v) {
                        try {
                          await CampanaOfertaNotifier.anunciarActivacion(
                            campana,
                          );
                        } catch (_) {}
                      }
                      if (context.mounted) {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text(
                              v ? 'Campaña activada' : 'Campaña pausada',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        FiscoGestNotifications.show(
                          SnackBar(
                            content: Text('$e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                Text(
                  ServicioIdioma.t(context, 'Activa'),
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Registro: ${campana.mostrarRegistro ? "sí" : "no"} · Panel: ${campana.mostrarPanel ? "sí" : "no"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fecha(DateTime? d) => d == null
    ? '—'
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
