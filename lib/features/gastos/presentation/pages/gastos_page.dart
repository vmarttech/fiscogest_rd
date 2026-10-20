import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/gastos/domain/entities/gasto.dart';
import 'package:fiscogest_rd/features/gastos/presentation/providers/gastos_providers.dart';

/// Gastos — UI según mock HTML (KPI x3, filtros, tabla).
class GastosPage extends ConsumerStatefulWidget {
  const GastosPage({super.key});

  static const String routeName = 'gastos';

  @override
  ConsumerState<GastosPage> createState() => _GastosPageState();
}

enum _PeriodoFiltro { todos, ultimos7, esteMes }

class _GastosPageState extends ConsumerState<GastosPage> {
  final _fmt = DateFormat('dd MMM yyyy', 'es');
  final _fmtCorto = DateFormat('dd/MM/yyyy');
  String _filtro = '';
  _PeriodoFiltro _periodo = _PeriodoFiltro.esteMes;
  String? _categoriaFiltro; // null = todas

  static const _cats = [
    'General',
    'Alquiler',
    'Servicios',
    'Nómina',
    'Transporte',
    'Mantenimiento',
    'Impuestos',
    'Marketing',
    'Otros',
  ];
  static const _formas = [
    'efectivo',
    'transferencia',
    'tarjeta',
    'cheque',
    'otro',
  ];

  IconData _iconCat(String cat) {
    switch (cat.toLowerCase()) {
      case 'transporte':
        return Icons.directions_car_rounded;
      case 'alquiler':
        return Icons.home_work_outlined;
      case 'servicios':
        return Icons.bolt_outlined;
      case 'nómina':
      case 'nomina':
        return Icons.groups_outlined;
      case 'impuestos':
        return Icons.account_balance_outlined;
      case 'marketing':
        return Icons.campaign_outlined;
      case 'mantenimiento':
        return Icons.build_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _colorCat(String cat) {
    switch (cat.toLowerCase()) {
      case 'transporte':
        return const Color(0xFFE67E22);
      case 'alquiler':
        return const Color(0xFF7C3AED);
      case 'servicios':
        return const Color(0xFF2563EB);
      case 'nómina':
      case 'nomina':
        return const Color(0xFF0F766E);
      case 'impuestos':
        return const Color(0xFFDC2626);
      case 'marketing':
        return const Color(0xFF6366F1);
      case 'mantenimiento':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF64748B);
    }
  }

  List<Gasto> _aplicarFiltros(List<Gasto> lista) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    return lista.where((g) {
      final f = DateTime(g.fecha.year, g.fecha.month, g.fecha.day);
      if (_periodo == _PeriodoFiltro.ultimos7) {
        if (f.isBefore(hoy.subtract(const Duration(days: 6)))) return false;
      } else if (_periodo == _PeriodoFiltro.esteMes) {
        if (f.year != now.year || f.month != now.month) return false;
      }
      if (_categoriaFiltro != null &&
          g.categoria.toLowerCase() != _categoriaFiltro!.toLowerCase()) {
        return false;
      }
      if (_filtro.isEmpty) return true;
      final q = _filtro;
      return g.descripcion.toLowerCase().contains(q) ||
          g.categoria.toLowerCase().contains(q) ||
          g.formaPago.toLowerCase().contains(q);
    }).toList();
  }

  ({double mesActual, double mesAnterior, double pct}) _resumenMes(
    List<Gasto> lista,
  ) {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    double actual = 0;
    double anterior = 0;
    for (final g in lista) {
      if (g.fecha.year == now.year && g.fecha.month == now.month) {
        actual += g.monto;
      }
      if (g.fecha.year == prev.year && g.fecha.month == prev.month) {
        anterior += g.monto;
      }
    }
    double pct = 0;
    if (anterior > 0) {
      pct = ((actual - anterior) / anterior) * 100;
    } else if (actual > 0) {
      pct = 100;
    }
    return (mesActual: actual, mesAnterior: anterior, pct: pct);
  }

  ({String nombre, double monto, double pct}) _categoriaTop(
    List<Gasto> filtrados,
    double totalFiltrado,
  ) {
    if (filtrados.isEmpty) {
      return (nombre: '—', monto: 0, pct: 0);
    }
    final map = <String, double>{};
    for (final g in filtrados) {
      map[g.categoria] = (map[g.categoria] ?? 0) + g.monto;
    }
    var top = map.entries.first;
    for (final e in map.entries) {
      if (e.value > top.value) top = e;
    }
    final pct = totalFiltrado > 0 ? (top.value / totalFiltrado) * 100 : 0.0;
    return (nombre: top.key, monto: top.value, pct: pct);
  }

  Future<void> _abrirForm({Gasto? edit}) async {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final descCtrl = TextEditingController(text: edit?.descripcion ?? '');
    final montoCtrl = TextEditingController(
      text: edit != null ? edit.monto.toStringAsFixed(2) : '',
    );
    final notasCtrl = TextEditingController(text: edit?.notas ?? '');
    var categoria = edit?.categoria ?? 'General';
    var formaPago = edit?.formaPago ?? 'efectivo';
    var fecha = edit?.fecha ?? DateTime.now();

    Future<void> guardar(BuildContext ctx) async {
      final desc = descCtrl.text.trim();
      final monto = double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0;
      if (desc.isEmpty || monto <= 0) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('Descripción y monto válidos son requeridos'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final g = Gasto(
        id: edit?.id,
        fecha: DateTime(fecha.year, fecha.month, fecha.day),
        categoria: categoria,
        descripcion: desc,
        monto: monto,
        formaPago: formaPago,
        notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
        creadoEn: edit?.creadoEn ?? DateTime.now(),
        actualizadoEn: DateTime.now(),
      );
      await ref.read(gastosRepositoryProvider).guardar(g);
      ref.invalidate(gastosListaProvider);
      if (ctx.mounted) Navigator.pop(ctx);
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            edit == null ? 'Gasto registrado' : 'Gasto actualizado',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }

    Widget formBody(void Function(void Function()) setLocal) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (d != null) setLocal(() => fecha = d);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('Fecha: ${_fmtCorto.format(fecha)}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: categoria,
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                for (final c in _cats)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) {
                if (v != null) setLocal(() => categoria = v);
              },
            ),
            const SizedBox(height: 14),
            AppTextField(label: 'Descripción *', controller: descCtrl),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Monto *',
              controller: montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: formaPago,
              decoration: InputDecoration(
                labelText: 'Forma de pago',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                for (final f in _formas)
                  DropdownMenuItem(value: f, child: Text(f)),
              ],
              onChanged: (v) {
                if (v != null) setLocal(() => formaPago = v);
              },
            ),
            const SizedBox(height: 14),
            AppTextField(label: 'Notas', controller: notasCtrl),
          ],
        ),
      );
    }

    Widget header(BuildContext ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edit == null ? 'Registrar gasto' : 'Editar gasto',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Text(
                      'Egreso operativo del negocio',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );

    if (mobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              final media = MediaQuery.of(ctx);
              final h = media.size.height -
                  media.viewInsets.bottom -
                  media.padding.top;
              return Padding(
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: SizedBox(
                  height: (h * 0.92).clamp(0.0, h),
                  child: Column(
                    children: [
                      header(ctx),
                      const Divider(height: 1),
                      Expanded(child: formBody(setLocal)),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: AppButton(
                                  text: 'Guardar',
                                  onPressed: () => guardar(ctx),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 480,
                  height: MediaQuery.sizeOf(ctx).height * 0.72,
                  child: Column(
                    children: [
                      header(ctx),
                      const Divider(height: 1),
                      Expanded(child: formBody(setLocal)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => guardar(ctx),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Guardar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Future<void> _verDetalle(Gasto g) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle del gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Descripción', g.descripcion),
            _kv('Categoría', g.categoria),
            _kv('Fecha', _fmtCorto.format(g.fecha)),
            _kv('Forma de pago', g.formaPago),
            _kv('Monto', formatRd(g.monto)),
            if ((g.notas ?? '').isNotEmpty) _kv('Notas', g.notas!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _abrirForm(edit: g);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                k,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _eliminar(Gasto g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('Eliminar "${g.descripcion}" (${formatRd(g.monto)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && g.id != null) {
      await ref.read(gastosRepositoryProvider).eliminar(g.id!);
      ref.invalidate(gastosListaProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);
    final async = ref.watch(gastosListaProvider);

    return AppScaffold(
      title: 'GASTOS',
      subtitle: 'Egresos operativos del negocio',
      showAppBar: !desktop,
      actions: const [],

      floatingActionButton: mobile
          ? FloatingActionButton.extended(
              onPressed: () => _abrirForm(),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
      body: ColoredBox(
        color: const Color(0xFFF3F4F6),
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (lista) {
              final filtrados = _aplicarFiltros(lista);
              final totalFiltrado =
                  filtrados.fold<double>(0, (s, g) => s + g.monto);
              final resumen = _resumenMes(lista);
              final top = _categoriaTop(filtrados, totalFiltrado);

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 16 : 24,
                      mobile ? 12 : 20,
                      mobile ? 16 : 24,
                      32,
                    ),
                    children: [
                      // —— Encabezado ——
                      if (desktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gastos',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Registro de egresos operativos, por categoría y forma de pago.',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _abrirForm(),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Registrar Gasto'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (desktop) const SizedBox(height: 20),

                      // —— KPI x3 ——
                      LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 900;
                          final cards = [
                            _KpiCard(
                              icon: Icons.calendar_month_rounded,
                              iconBg: const Color(0xFFE2F0FD),
                              iconFg: const Color(0xFF2563EB),
                              label: 'RESUMEN MES',
                              title: formatRd(resumen.mesActual),
                              subtitle: 'Total Gastado (Este Mes)',
                              badge: resumen.mesAnterior == 0 &&
                                      resumen.mesActual == 0
                                  ? null
                                  : '${resumen.pct >= 0 ? '+' : ''}${resumen.pct.toStringAsFixed(0)}% vs Mes Anterior',
                              badgePositive: resumen.pct <= 0,
                            ),
                            _KpiCard(
                              icon: Icons.swap_horiz_rounded,
                              iconBg: const Color(0xFFF3F4F6),
                              iconFg: const Color(0xFF6B7280),
                              label: 'TRANSACCIONES',
                              title: '${filtrados.length}',
                              subtitle:
                                  'Registros filtrados de ${lista.length} totales',
                            ),
                            _KpiCard(
                              icon: _iconCat(
                                top.nombre == '—' ? 'General' : top.nombre,
                              ),
                              iconBg: _colorCat(
                                top.nombre == '—' ? 'General' : top.nombre,
                              ).withValues(alpha: 0.12),
                              iconFg: _colorCat(
                                top.nombre == '—' ? 'General' : top.nombre,
                              ),
                              label: 'CATEGORÍA TOP',
                              title: top.nombre,
                              subtitle:
                                  'Mayor gasto  ${formatRd(top.monto)} / ${top.pct.toStringAsFixed(0)}%',
                            ),
                          ];
                          if (wide) {
                            return Row(
                              children: [
                                for (var i = 0; i < cards.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 16),
                                  Expanded(child: cards[i]),
                                ],
                              ],
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                cards[i],
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // —— Filtros ——
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final stack = c.maxWidth < 720;
                            final search = TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Buscar descripción, categoría o forma de pago...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  size: 20,
                                  color: Color(0xFF9CA3AF),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                isDense: true,
                              ),
                              onChanged: (v) =>
                                  setState(() => _filtro = v.toLowerCase()),
                            );
                            final chips = Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChipBtn(
                                  label: 'Últimos 7 días',
                                  selected:
                                      _periodo == _PeriodoFiltro.ultimos7,
                                  onTap: () => setState(
                                    () => _periodo = _PeriodoFiltro.ultimos7,
                                  ),
                                ),
                                _FilterChipBtn(
                                  label: 'Este Mes',
                                  selected:
                                      _periodo == _PeriodoFiltro.esteMes,
                                  onTap: () => setState(
                                    () => _periodo = _PeriodoFiltro.esteMes,
                                  ),
                                ),
                                _FilterChipBtn(
                                  label: 'Todos',
                                  selected:
                                      _periodo == _PeriodoFiltro.todos,
                                  onTap: () => setState(
                                    () => _periodo = _PeriodoFiltro.todos,
                                  ),
                                ),
                                PopupMenuButton<String?>(
                                  onSelected: (v) =>
                                      setState(() => _categoriaFiltro = v),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: null,
                                      child: Text('Todas las categorías'),
                                    ),
                                    for (final c in _cats)
                                      PopupMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _categoriaFiltro == null
                                              ? 'Filtrar por Categoría'
                                              : _categoriaFiltro!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                            if (stack) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  search,
                                  const SizedBox(height: 10),
                                  chips,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: search),
                                const SizedBox(width: 12),
                                chips,
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // —— Tabla ——
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: filtrados.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 48,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.money_off_csred_outlined,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'No hay gastos con estos filtros',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Use «Registrar Gasto» arriba para agregar uno.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: mobile ? 720 : 900,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      const Color(0xFFF9FAFB),
                                    ),
                                    headingRowHeight: 44,
                                    dataRowMinHeight: 56,
                                    dataRowMaxHeight: 64,
                                    horizontalMargin: 20,
                                    columnSpacing: 24,
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'ICONO',
                                          style: _th,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'DESCRIPCIÓN',
                                          style: _th,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'CATEGORÍA',
                                          style: _th,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text('FECHA', style: _th),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'MÉTODO DE PAGO',
                                          style: _th,
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text('MONTO', style: _th),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'ACCIONES',
                                          style: _th,
                                        ),
                                        numeric: true,
                                      ),
                                    ],
                                    rows: [
                                      for (final g in filtrados)
                                        DataRow(
                                          cells: [
                                            DataCell(
                                              Center(
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: _colorCat(g.categoria)
                                                        .withValues(alpha: 0.12),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    _iconCat(g.categoria),
                                                    size: 18,
                                                    color: _colorCat(
                                                      g.categoria,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                g.descripcion,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF111827),
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF3F4F6),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  g.categoria,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF4B5563),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                _fmt.format(g.fecha),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                g.formaPago.isEmpty
                                                    ? '—'
                                                    : '${g.formaPago[0].toUpperCase()}${g.formaPago.substring(1)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                formatRd(g.monto),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip: 'Editar',
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 18,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                    onPressed: () =>
                                                        _abrirForm(edit: g),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Eliminar',
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 18,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                    onPressed: () =>
                                                        _eliminar(g),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Ver',
                                                    icon: const Icon(
                                                      Icons.visibility_outlined,
                                                      size: 18,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                    onPressed: () =>
                                                        _verDetalle(g),
                                                  ),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

const _th = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.6,
  color: Color(0xFF9CA3AF),
);

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgePositive = true,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final String title;
  final String subtitle;
  final String? badge;
  final bool badgePositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconFg, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF030712),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgePositive
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgePositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
