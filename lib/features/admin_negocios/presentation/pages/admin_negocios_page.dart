// [ADMIN_FASE2]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/enterprise_page_header.dart';
import 'package:fiscogest_rd/features/admin_negocios/data/admin_negocios_remote.dart';
import 'package:fiscogest_rd/features/admin_negocios/presentation/providers/admin_negocios_providers.dart';

class AdminNegociosPage extends ConsumerStatefulWidget {
  const AdminNegociosPage({super.key});
  static const routeName = 'admin-negocios';
  static const path = '/admin/negocios';
  @override
  ConsumerState<AdminNegociosPage> createState() => _AdminNegociosPageState();
}

class _AdminNegociosPageState extends ConsumerState<AdminNegociosPage> {
  final _busquedaCtrl = TextEditingController();

  static const _estados = [
    MapEntry('', 'Todos'),
    MapEntry('activa', 'Activa'),
    MapEntry('gracia', 'Gracia (3 días)'),
    MapEntry('prueba', 'Prueba / promoción'),
    MapEntry('vencida', 'Vencida'),
    MapEntry('suspendida', 'Suspendida'),
    MapEntry('sin_licencia', 'Sin licencia'),
  ];
  static const _planes = [
    MapEntry('', 'Todos los planes'),
    MapEntry('demo', 'Demo'),
    MapEntry('gratis', 'Gratis'),
    MapEntry('basico', 'Básico'),
    MapEntry('simplificado', 'Simplificado'),
    MapEntry('pro', 'Pro'),
    MapEntry('profesional', 'Profesional'),
    MapEntry('empresa', 'Empresa'),
    MapEntry('desarrollador', 'Desarrollador'),
  ];
  static const _ordenes = [
    MapEntry('reciente', 'Más recientes'),
    MapEntry('nombre', 'Nombre A-Z'),
    MapEntry('vencimiento', 'Vencimiento próximo'),
    MapEntry('usuarios', 'Más usuarios'),
  ];

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtros = ref.watch(adminNegociosFiltrosProvider);
    final lista = ref.watch(adminNegociosListaProvider);
    final notifier = ref.read(adminNegociosListaProvider.notifier);
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    return AppScaffold(
      title: 'Negocios registrados',
      showAppBar: !desktop,
      body: RefreshIndicator(
        onRefresh: notifier.recargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            mobile ? 16 : 28,
            20,
            mobile ? 16 : 28,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EnterprisePageHeader(
                    title: 'Negocios registrados',
                    subtitle:
                        'Consulta y administra el acceso de los negocios en VendiFlux.',
                    showBack: true,
                    backFallbackRoute: '/',
                  ),
                  _ResumenNegocios(filas: lista.filas),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _busquedaCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por nombre, RNC o teléfono...',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                            ),
                            onSubmitted: (valor) =>
                                ref
                                    .read(adminNegociosFiltrosProvider.notifier)
                                    .state = filtros.copyWith(
                                  busqueda: valor,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Buscar',
                          icon: const Icon(Icons.search),
                          onPressed: () =>
                              ref
                                  .read(adminNegociosFiltrosProvider.notifier)
                                  .state = filtros.copyWith(
                                busqueda: _busquedaCtrl.text,
                              ),
                        ),
                        IconButton(
                          tooltip: 'Actualizar',
                          icon: const Icon(Icons.refresh),
                          onPressed: () => ref
                              .read(adminNegociosTickProvider.notifier)
                              .state++,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final angosto = constraints.maxWidth < 620;
                        final widgets = [
                          _dropEstado(filtros),
                          _dropPlan(filtros),
                          _dropOrden(filtros),
                        ];
                        if (angosto) {
                          return Column(spacing: 8, children: widgets);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < widgets.length; i++) ...[
                              Expanded(child: widgets[i]),
                              if (i < widgets.length - 1)
                                const SizedBox(width: 12),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _cuerpo(lista, notifier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropEstado(AdminNegociosFiltros f) => DropdownButtonFormField<String>(
    initialValue: f.estado,
    isDense: true,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Estado', isDense: true),
    items: _estados
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) => ref.read(adminNegociosFiltrosProvider.notifier).state = f
        .copyWith(estado: v ?? ''),
  );

  Widget _dropPlan(AdminNegociosFiltros f) => DropdownButtonFormField<String>(
    initialValue: f.plan,
    isDense: true,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Plan', isDense: true),
    items: _planes
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) => ref.read(adminNegociosFiltrosProvider.notifier).state = f
        .copyWith(plan: v ?? ''),
  );

  Widget _dropOrden(AdminNegociosFiltros f) => DropdownButtonFormField<String>(
    initialValue: f.orden,
    isDense: true,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Ordenar por', isDense: true),
    items: _ordenes
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) => ref.read(adminNegociosFiltrosProvider.notifier).state = f
        .copyWith(orden: v ?? 'reciente'),
  );

  Widget _cuerpo(
    AdminNegociosListaEstado lista,
    AdminNegociosListaNotifier notifier,
  ) {
    if (lista.inicializando && lista.filas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lista.error != null && lista.filas.isEmpty) {
      return _ErrorRetry(mensaje: lista.error!, onRetry: notifier.recargar);
    }
    if (lista.filas.isEmpty) return const _Vacio();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 2 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final row in lista.filas)
                  SizedBox(
                    width: width,
                    child: _Tarjeta(row: row),
                  ),
              ],
            ),
            _Pie(lista: lista, onCargarMas: notifier.cargarMas),
          ],
        );
      },
    );
  }
}

class _ResumenNegocios extends StatelessWidget {
  const _ResumenNegocios({required this.filas});
  final List<AdminNegocioRow> filas;

  @override
  Widget build(BuildContext context) {
    final activos = filas.where((r) => r.estado == 'activa').length;
    final pruebas = filas.where((r) => r.estado == 'prueba').length;
    final vencidos = filas.where((r) => r.estado == 'vencida').length;
    final suspendidos = filas.where((r) => r.estado == 'suspendida').length;
    final items = [
      (
        'Visibles',
        filas.length,
        const Color(0xFF2563EB),
        Icons.business_outlined,
      ),
      ('Activos', activos, const Color(0xFF059669), Icons.check_circle_outline),
      ('Prueba', pruebas, const Color(0xFF7C3AED), Icons.hourglass_top_rounded),
      (
        'Vencidos / suspendidos',
        vencidos + suspendidos,
        const Color(0xFFDC2626),
        Icons.pause_circle_outline,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 850
            ? 4
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(item.$4, color: item.$3),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.$2}',
                                style: AppTypography.h3.copyWith(
                                  color: item.$3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Color _colorEstado(String e) {
  switch (e) {
    case 'activa':
      return const Color(0xFF059669);
    case 'prueba':
      return const Color(0xFF2563EB);
    case 'gracia':
      return const Color(0xFFD97706);
    case 'vencida':
      return const Color(0xFFDC2626);
    case 'suspendida':
      return const Color(0xFF6B7280);
    default:
      return const Color(0xFF64748B);
  }
}

Widget _chip(String texto, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(99),
  ),
  child: Text(
    texto,
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
  ),
);

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.row});
  final AdminNegocioRow row;

  @override
  Widget build(BuildContext context) {
    final subtitulo = [
      row.rnc,
      row.telefonoContacto,
    ].where((e) => e.isNotEmpty).join(' · ');
    final mobile = AppBreakpoints.isMobile(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('${AdminNegociosPage.path}/${row.id}'),
        child: Padding(
          padding: EdgeInsets.all(mobile ? 14 : 16),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          row.estado.isEmpty ? row.estadoBruto : row.estado,
                          _colorEstado(row.estado),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitulo.isEmpty ? row.plan : '$subtitulo · ${row.plan}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      row.usuariosActivos == 0
                          ? 'Sin usuarios activos'
                          : '${row.usuariosActivos} usuario(s) activo(s)',
                      style: AppTypography.labelMedium,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitulo.isEmpty
                                ? row.plan
                                : '$subtitulo · ${row.plan}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _chip(
                          row.estado.isEmpty ? row.estadoBruto : row.estado,
                          _colorEstado(row.estado),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.usuariosActivos == 0
                              ? 'sin usuarios'
                              : '${row.usuariosActivos} usuario(s)',
                          style: AppTypography.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.lista, required this.onCargarMas});
  final AdminNegociosListaEstado lista;
  final VoidCallback onCargarMas;

  @override
  Widget build(BuildContext context) {
    if (lista.cargandoMas) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (lista.error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              lista.error!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            TextButton.icon(
              onPressed: onCargarMas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (!lista.hayMas) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Total: ${lista.filas.length} negocio(s)',
            style: AppTypography.bodySmall,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: onCargarMas,
          icon: const Icon(Icons.add),
          label: const Text('Cargar más'),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.business_outlined, size: 56, color: Colors.grey),
        SizedBox(height: 12),
        Text('Sin negocios que coincidan'),
      ],
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.mensaje, required this.onRetry});
  final String mensaje;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
