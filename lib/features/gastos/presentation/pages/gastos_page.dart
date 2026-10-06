import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/gastos/domain/entities/gasto.dart';
import 'package:fiscogest_rd/features/gastos/presentation/providers/gastos_providers.dart';

class GastosPage extends ConsumerStatefulWidget {
  const GastosPage({super.key});
  static const String routeName = 'gastos';
  @override
  ConsumerState<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends ConsumerState<GastosPage> {
  final _fmt = DateFormat('dd/MM/yyyy');
  String _filtro = '';

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
    const cats = [
      'General', 'Alquiler', 'Servicios', 'Nómina', 'Transporte',
      'Mantenimiento', 'Impuestos', 'Marketing', 'Otros',
    ];
    const formas = ['efectivo', 'transferencia', 'tarjeta', 'cheque', 'otro'];

    Future<void> guardar(BuildContext ctx) async {
      final desc = descCtrl.text.trim();
      final monto = double.tryParse(montoCtrl.text.replaceAll(',', '.')) ?? 0;
      if (desc.isEmpty || monto <= 0) {
        FiscoGestNotifications.show(const SnackBar(
          content: Text('Descripción y monto válidos son requeridos'),
          backgroundColor: AppColors.error,
        ));
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
      FiscoGestNotifications.show(SnackBar(
        content: Text(edit == null ? 'Gasto registrado' : 'Gasto actualizado'),
        backgroundColor: AppColors.success,
      ));
    }

    Widget formBody(void Function(void Function()) setLocal) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
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
              label: Text('Fecha: ${_fmt.format(fecha)}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in cats)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) {
                if (v != null) setLocal(() => categoria = v);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Descripción *', controller: descCtrl),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Monto *',
              controller: montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formaPago,
              decoration: const InputDecoration(
                labelText: 'Forma de pago',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final f in formas)
                  DropdownMenuItem(value: f, child: Text(f)),
              ],
              onChanged: (v) {
                if (v != null) setLocal(() => formaPago = v);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Notas', controller: notasCtrl),
          ],
        ),
      );
    }

    if (mobile) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SizedBox(
                  height: (MediaQuery.sizeOf(ctx).height -
                          MediaQuery.viewInsetsOf(ctx).bottom)
                      .clamp(360.0, MediaQuery.sizeOf(ctx).height * 0.9),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    edit == null ? 'Nuevo gasto' : 'Editar gasto',
                                    style: AppTypography.h4.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Registre el egreso de su negocio',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
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
                      ),
                      const Divider(height: 1),
                      Expanded(child: formBody(setLocal)),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: 'Guardar',
                                onPressed: () => guardar(ctx),
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
              return AlertDialog(
                title: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(edit == null ? 'Nuevo gasto' : 'Editar gasto'),
                          const SizedBox(height: 2),
                          Text(
                            'Registre el egreso de su negocio',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 500,
                  height: MediaQuery.sizeOf(ctx).height * 0.62,
                  child: formBody(setLocal),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => guardar(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _eliminar(Gasto g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          'Eliminar "${g.descripcion}" (${formatRd(g.monto)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    final async = ref.watch(gastosListaProvider);
    return AppScaffold(
      title: 'GASTOS',
      subtitle: 'Egresos operativos del negocio',
      actions: [
        if (!mobile)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _abrirForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo gasto'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
      ],
      floatingActionButton: mobile
          ? FloatingActionButton(
              onPressed: () => _abrirForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 720 : 960),
            child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (lista) {
            final filtrados = _filtro.isEmpty
                ? lista
                : lista
                    .where(
                      (g) =>
                          g.descripcion.toLowerCase().contains(_filtro) ||
                          g.categoria.toLowerCase().contains(_filtro),
                    )
                    .toList();
            final total =
                filtrados.fold<double>(0, (s, g) => s + g.monto);
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 16 : 24,
                    12,
                    mobile ? 16 : 24,
                    8,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por descripción o categoría…',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            setState(() => _filtro = v.toLowerCase()),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Total filtrado',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              formatRd(total),
                              style: AppTypography.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtrados.isEmpty
                      ? Center(
                          child: Text(
                            'No hay gastos registrados',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 16 : 24,
                            4,
                            mobile ? 16 : 24,
                            24,
                          ),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final g = filtrados[i];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _abrirForm(edit: g),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.error
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.money_off_csred_outlined,
                                          color: AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              g.descripcion,
                                              style: AppTypography.bodyLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${g.categoria} · ${_fmt.format(g.fecha)} · ${g.formaPago}',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatRd(g.monto),
                                            style: AppTypography.bodyLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: AppColors.error,
                                            ),
                                            onPressed: () => _eliminar(g),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
    );
  }
}
