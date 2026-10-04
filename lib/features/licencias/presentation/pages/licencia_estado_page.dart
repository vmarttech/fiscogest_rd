import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';

class LicenciaEstadoPage extends ConsumerWidget {
  const LicenciaEstadoPage({super.key});

  static const routeName = 'licencia';
  static const path = '/licencia';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(licenciaActualProvider);
    final width = MediaQuery.sizeOf(context).width;
    final esMovil = width < 700;

    return AppScaffold(
      title: 'Licencia',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lic) {
          if (lic == null) {
            return const Center(child: Text('Sin licencia'));
          }
          final gates = LicenciaGates(lic);
          final esDev = lic.esDesarrollador;
          final colorEstado = switch (lic.estado) {
            'activa' => const Color(0xFF0F766E),
            'gracia' => Colors.orange.shade800,
            'vencida' => AppColors.error,
            _ => AppColors.textSecondary,
          };

          return ListView(
            padding: EdgeInsets.fromLTRB(esMovil ? 16 : 24, 16, esMovil ? 16 : 24, 32),
            children: [
              // Hero (estilo Reportes móvil / Centro de datos desktop)
              _HeroLicencia(
                esMovil: esMovil,
                esDev: esDev,
                estado: lic.estado.toUpperCase(),
                colorEstado: colorEstado,
                plan: esDev ? 'Desarrollador' : lic.plan,
                subtitulo: esDev
                    ? 'Acceso vitalicio MartTech · sin llave'
                    : gates.textoDispositivos,
              ),
              const SizedBox(height: 20),

              if (esMovil) ...[
                _MetricGrid(children: [
                  _MetricCard(
                    icon: Icons.event_available_outlined,
                    label: 'Vigencia',
                    value: esDev ? 'Vitalicia' : lic.vigenciaTipo,
                  ),
                  _MetricCard(
                    icon: Icons.timer_outlined,
                    label: esDev ? 'Vence' : 'Días restantes',
                    value: esDev
                        ? '—'
                        : (lic.diasRestantes != null
                            ? '${lic.diasRestantes}'
                            : '—'),
                  ),
                  _MetricCard(
                    icon: Icons.devices_outlined,
                    label: 'Equipos',
                    value: '${lic.maxDispositivos}',
                  ),
                  _MetricCard(
                    icon: Icons.point_of_sale_outlined,
                    label: 'Cajas',
                    value: '${lic.maxCajas}',
                  ),
                ]),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Detalle',
                  children: [
                    _kv('Plan', esDev ? 'Desarrollador' : lic.plan),
                    if (lic.fechaFin != null && !esDev)
                      _kv(
                        'Vence',
                        '${lic.fechaFin!.day.toString().padLeft(2, '0')}/'
                        '${lic.fechaFin!.month.toString().padLeft(2, '0')}/'
                        '${lic.fechaFin!.year}',
                      ),
                    _kv('e-CF', lic.ecfHabilitado ? 'Incluido' : 'No incluido'),
                    if (gates.esSimplificado)
                      _kv('Fiscal', 'Sin impuestos (ambulantes)'),
                  ],
                ),
              ] else ...[
                // Desktop: tarjetas tipo Import/Export
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _DesktopPanel(
                        title: 'Resumen del plan',
                        child: Column(
                          children: [
                            _kv('Plan', esDev ? 'Desarrollador' : lic.plan),
                            _kv('Vigencia', esDev ? 'Vitalicia' : lic.vigenciaTipo),
                            if (lic.fechaFin != null && !esDev)
                              _kv(
                                'Vence',
                                '${lic.fechaFin!.day.toString().padLeft(2, '0')}/'
                                '${lic.fechaFin!.month.toString().padLeft(2, '0')}/'
                                '${lic.fechaFin!.year}'
                                '${lic.diasRestantes != null ? '  (${lic.diasRestantes} días)' : ''}',
                              ),
                            _kv('Máx. equipos', '${lic.maxDispositivos}'),
                    const SizedBox(height: 12),
                    Text(
                      'Dispositivos en este negocio',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ref.watch(dispositivosListaProvider).when(
                          data: (list) {
                            if (list.isEmpty) {
                              return const Text(
                                'Ningún equipo registrado aún.',
                                style: AppTypography.bodySmall,
                              );
                            }
                            return Column(
                              children: [
                                for (final d in list)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      d.tipo == 'movil'
                                          ? Icons.phone_android
                                          : Icons.computer,
                                      color: d.esEsteEquipo
                                          ? const Color(0xFF0F766E)
                                          : null,
                                    ),
                                    title: Text(
                                      d.esEsteEquipo
                                          ? '${d.alias} (este equipo)'
                                          : d.alias,
                                    ),
                                    subtitle: Text(
                                      '${d.plataforma} · ${d.tipo}'
                                      '${d.pendienteSync ? ' · pendiente sync' : ''}',
                                    ),
                                  ),
                                Text(
                                  '${list.length} / ${lic.maxDispositivos} cupos',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Dispositivos: $e'),
                        ),

                    const SizedBox(height: 12),
                    Text(
                      'Dispositivos en este negocio',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ref.watch(dispositivosListaProvider).when(
                          data: (list) {
                            if (list.isEmpty) {
                              return const Text(
                                'Ningún equipo registrado aún.',
                                style: AppTypography.bodySmall,
                              );
                            }
                            return Column(
                              children: [
                                for (final d in list)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      d.tipo == 'movil'
                                          ? Icons.phone_android
                                          : Icons.computer,
                                      color: d.esEsteEquipo
                                          ? const Color(0xFF0F766E)
                                          : null,
                                    ),
                                    title: Text(
                                      d.esEsteEquipo
                                          ? '${d.alias} (este equipo)'
                                          : d.alias,
                                    ),
                                    subtitle: Text(
                                      '${d.plataforma} · ${d.tipo}'
                                      '${d.pendienteSync ? ' · pendiente sync' : ''}',
                                    ),
                                  ),
                                Text(
                                  '${list.length} / ${lic.maxDispositivos} cupos',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Dispositivos: $e'),
                        ),
                            _kv('Máx. cajas', '${lic.maxCajas}'),
                            _kv('e-CF', lic.ecfHabilitado ? 'Incluido' : 'No incluido'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DesktopPanel(
                        title: 'Notas',
                        child: Text(
                          esDev
                              ? 'Este equipo está autorizado de forma permanente. No requiere código ni pago.'
                              : gates.esSimplificado
                                  ? 'Plan sin impuestos ni facturación fiscal. Un dispositivo. Pago anual.'
                                  : 'En modo normal puedes usar 1 celular gratis con las mismas funciones contratadas en la PC.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              const Text('Acciones', style: AppTypography.labelLarge),
              const SizedBox(height: 10),

              if (!esDev) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/licencia/comprar'),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Comprar / renovar licencia'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/licencia/activar'),
                    icon: const Icon(Icons.key_outlined),
                    label: const Text('Activar con código (opcional)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/licencia/admin'),
                  child: const Text('Administrar pedidos de pago'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Los clientes pagan por transferencia o Toke. '
                'Tú confirmas el pago y el sistema emite la licencia.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroLicencia extends StatelessWidget {
  const _HeroLicencia({
    required this.esMovil,
    required this.esDev,
    required this.estado,
    required this.colorEstado,
    required this.plan,
    required this.subtitulo,
  });

  final bool esMovil;
  final bool esDev;
  final String estado;
  final Color colorEstado;
  final String plan;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(esMovil ? 20 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  esDev ? Icons.verified : Icons.workspace_premium_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esDev ? 'Acceso vitalicio' : 'Estado de licencia',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (subtitulo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              subtitulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: children,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF0F766E)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
