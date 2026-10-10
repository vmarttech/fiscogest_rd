import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/navigation/safe_back.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/almacenes/domain/entities/almacen.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/providers/almacen_providers.dart';
import 'package:fiscogest_rd/features/almacenes/presentation/widgets/plan_requerido.dart';

class AlmacenesPage extends ConsumerStatefulWidget {
  const AlmacenesPage({super.key});

  static const routeName = 'almacenes';
  static const path = '/almacenes';

  @override
  ConsumerState<AlmacenesPage> createState() => _AlmacenesPageState();
}

class _AlmacenesPageState extends ConsumerState<AlmacenesPage> {
  String _filtro = '';
  String _chip = 'todos'; // todos | activos | principal

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(almacenesHabilitadosProvider)) {
      return const PlanRequeridoAlmacenes(titulo: 'Almacenes');
    }
    final mobile = AppBreakpoints.isMobile(context);
    final async = ref.watch(almacenesControllerProvider);

    return AppScaffold(
      title: 'Almacenes',
      subtitle: 'Sucursales, depósitos y stock por ubicación',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => safeBack(context, fallback: '/'),
        style: IconButton.styleFrom(foregroundColor: Colors.white),
      ),
      actions: [
        AppButton(
          text: mobile ? 'Nuevo' : 'Nuevo almacén',
          icon: Icons.warehouse_outlined,
          onPressed: () => _formulario(context),
        ),
      ],
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 560 : 980),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 24,
                16,
                mobile ? 16 : 24,
                24,
              ),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (lista) {
                  final activos = lista.where((a) => a.activo).length;
                  final stock = lista.fold<double>(
                    0,
                    (s, a) => s + a.stockTotal,
                  );
                  final visible = lista.where((a) {
                    if (_chip == 'activos' && !a.activo) return false;
                    if (_chip == 'principal' && !a.esPrincipal) return false;
                    if (_filtro.isEmpty) return true;
                    final q = _filtro.toLowerCase();
                    return a.codigo.toLowerCase().contains(q) ||
                        a.nombre.toLowerCase().contains(q) ||
                        (a.responsable ?? '').toLowerCase().contains(q);
                  }).toList();
                  return Column(
                    children: [
                      Row(
                        children: [
                          _kpi(
                            'Almacenes',
                            '${lista.length}',
                            AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _kpi('Activos', '$activos', AppColors.success),
                          const SizedBox(width: 8),
                          _kpi(
                            'Unidades',
                            stock.toStringAsFixed(0),
                            AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (mobile)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: _panelDecoration(),
                          child: Column(
                            children: [
                              _campoBusqueda(),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _filtros(),
                              ),
                            ],
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: _panelDecoration(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 360, child: _campoBusqueda()),
                                const SizedBox(width: 10),
                                ..._filtros().asMap().entries.expand(
                                  (entry) => [
                                    if (entry.key > 0) const SizedBox(width: 6),
                                    entry.value,
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: visible.isEmpty
                            ? const Center(
                                child: Text('Sin almacenes para este filtro.'),
                              )
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final a = visible[i];
                                  return Material(
                                    color: Colors.white,
                                    elevation: 1,
                                    shadowColor: AppColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: a.esPrincipal
                                              ? AppColors.primary.withValues(
                                                  alpha: 0.28,
                                                )
                                              : AppColors.border,
                                        ),
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: a.activo
                                            ? AppColors.primary.withValues(
                                                alpha: 0.12,
                                              )
                                            : AppColors.grey200,
                                        child: Icon(
                                          Icons.warehouse_outlined,
                                          color: a.activo
                                              ? AppColors.primary
                                              : AppColors.grey600,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        a.nombre,
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${a.codigo} · ${a.tipo.label}'
                                        '${a.activo ? '' : ' · Inactivo'}\n'
                                        'Stock ${a.stockTotal.toStringAsFixed(2)} · ${a.skus} SKU'
                                        '${a.responsable == null || a.responsable!.isEmpty ? '' : ' · ${a.responsable}'}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.grey700,
                                          fontWeight: FontWeight.w500,
                                          height: 1.45,
                                        ),
                                      ),
                                      isThreeLine: true,
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (v) async {
                                          if (v == 'editar') {
                                            await _formulario(
                                              context,
                                              existente: a,
                                            );
                                          } else if (v == 'principal' &&
                                              a.id != null) {
                                            await ref
                                                .read(
                                                  almacenesControllerProvider
                                                      .notifier,
                                                )
                                                .marcarPrincipal(a.id!);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'editar',
                                            child: Text('Editar'),
                                          ),
                                          if (!a.esPrincipal)
                                            const PopupMenuItem(
                                              value: 'principal',
                                              child: Text(
                                                'Marcar como principal',
                                              ),
                                            ),
                                        ],
                                      ),
                                      onTap: () =>
                                          _formulario(context, existente: a),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _searchDecoration() => InputDecoration(
    hintText: 'Buscar código, nombre o responsable…',
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey500),
    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  Widget _campoBusqueda() => TextField(
    style: AppTypography.bodyMedium.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    decoration: _searchDecoration(),
    onChanged: (v) => setState(() => _filtro = v.trim()),
  );

  List<Widget> _filtros() => [
    for (final filtro in [
      ('todos', 'Todos', AppColors.primary),
      ('activos', 'Activos', AppColors.success),
      ('principal', 'Principal', AppColors.info),
    ])
      ChoiceChip(
        label: Text(
          filtro.$2,
          style: AppTypography.labelMedium.copyWith(
            color: _chip == filtro.$1 ? filtro.$3 : AppColors.grey700,
            fontWeight: _chip == filtro.$1 ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: _chip == filtro.$1,
        selectedColor: filtro.$3.withValues(alpha: 0.14),
        backgroundColor: AppColors.white,
        side: BorderSide(
          color: _chip == filtro.$1
              ? filtro.$3.withValues(alpha: 0.38)
              : AppColors.border,
        ),
        onSelected: (_) => setState(() => _chip = filtro.$1),
      ),
  ];

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: AppColors.grey900.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _kpi(String l, String v, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              v,
              style: AppTypography.h3.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              l,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _formulario(BuildContext context, {Almacen? existente}) async {
    final codigoCtrl = TextEditingController(text: existente?.codigo ?? '');
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final dirCtrl = TextEditingController(text: existente?.direccion ?? '');
    final telCtrl = TextEditingController(text: existente?.telefono ?? '');
    final respCtrl = TextEditingController(text: existente?.responsable ?? '');
    var tipo = existente?.tipo ?? TipoAlmacen.tienda;
    var activo = existente?.activo ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                existente == null ? 'Nuevo almacén' : 'Editar almacén',
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: codigoCtrl,
                        label: 'Código',
                        hint: 'ALM-02',
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: nombreCtrl,
                        label: 'Nombre',
                        hint: 'Depósito norte',
                      ),
                      const SizedBox(height: 10),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TipoAlmacen>(
                            isExpanded: true,
                            value: tipo,
                            items: [
                              for (final t in TipoAlmacen.values)
                                DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) setLocal(() => tipo = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: dirCtrl,
                        label: 'Dirección (opcional)',
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: telCtrl,
                        label: 'Teléfono (opcional)',
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: respCtrl,
                        label: 'Responsable (opcional)',
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Activo'),
                        value: activo,
                        onChanged: (v) => setLocal(() => activo = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    final codigo = codigoCtrl.text.trim();
    final nombre = nombreCtrl.text.trim();
    if (codigo.isEmpty || nombre.isEmpty) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Código y nombre son obligatorios')),
      );
      return;
    }
    try {
      await ref
          .read(almacenesControllerProvider.notifier)
          .guardar(
            Almacen(
              id: existente?.id,
              codigo: codigo,
              nombre: nombre,
              tipo: tipo,
              direccion: dirCtrl.text.trim().isEmpty
                  ? null
                  : dirCtrl.text.trim(),
              telefono: telCtrl.text.trim().isEmpty
                  ? null
                  : telCtrl.text.trim(),
              responsable: respCtrl.text.trim().isEmpty
                  ? null
                  : respCtrl.text.trim(),
              activo: activo,
            ),
          );
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Almacén guardado')),
      );
    } catch (e) {
      FiscoGestNotifications.show(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}
