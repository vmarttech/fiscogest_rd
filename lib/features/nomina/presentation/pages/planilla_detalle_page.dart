import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/planilla.dart';
import 'package:fiscogest_rd/features/nomina/presentation/providers/nomina_providers.dart';
import 'package:fiscogest_rd/features/nomina/presentation/pdf/planilla_pdf.dart';
import 'package:fiscogest_rd/features/nomina/presentation/pdf/comprobante_empleado_pdf.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_nomina_rd.dart';

class PlanillaDetallePage extends ConsumerWidget {
  const PlanillaDetallePage({super.key, required this.planillaId});

  static const String routeName = 'nomina-planilla-detalle';
  final int planillaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(planillaDetalleProvider(planillaId));
    // montos vía formatRd()
    final mobile = AppBreakpoints.isMobile(context);
    final desktop = AppBreakpoints.isDesktop(context);

    return async.when(
      loading: () => const AppScaffold(
        title: 'Planilla',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppScaffold(
        title: 'Planilla',
        body: Center(child: Text('Error: $e')),
      ),
      data: (p) {
        if (p == null) {
          return const AppScaffold(
            title: 'Planilla',
            body: Center(child: Text('No encontrada')),
          );
        }
        final editable = p.esBorrador;
        final totalNeto = p.lineas.fold<double>(0, (s, l) => s + l.montoNeto);
        final totalAfp = p.lineas.fold<double>(0, (s, l) => s + l.tssAfp);
        final totalSfs = p.lineas.fold<double>(0, (s, l) => s + l.tssSfs);
        final totalIsr = p.lineas.fold<double>(0, (s, l) => s + l.isr);

        return AppScaffold(
          title: 'Planilla ${p.periodo}',
          actions: [
            IconButton(
              tooltip: 'PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () async {
                try {
                  await PlanillaPdf.compartir(planilla: p);
                } catch (e) {
                  FiscoGestNotifications.show(
                    SnackBar(
                      content: Text('PDF: $e'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              },
            ),
            if (editable)
              IconButton(
                tooltip: 'Cerrar planilla',
                icon: const Icon(Icons.lock_outline),
                onPressed: () => _cerrar(context, ref),
              ),
            if (p.esCerrada)
              IconButton(
                tooltip: 'Marcar pagada',
                icon: const Icon(Icons.payments_outlined),
                onPressed: () => _pagar(context, ref),
              ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _eliminar(context, ref, p.periodo),
            ),
          ],
          body: Column(
            children: [
              _ResumenBar(
                mobile: mobile,
                desktop: desktop,
                estado: p.esPagada
                    ? 'Pagada'
                    : (p.esCerrada ? 'Cerrada' : 'Borrador'),
                cerrada: p.esCerrada || p.esPagada,
                bruto: formatRd(p.totalBruto),
                neto: formatRd(totalNeto),
                afp: formatRd(totalAfp),
                sfs: formatRd(totalSfs),
                isr: formatRd(totalIsr),
              ),
              Expanded(
                child: desktop
                    ? _TablaLineas(
                        lineas: p.lineas,
                        editable: editable,
                        onEdit: (l) => _editarLinea(context, ref, l),
                        onComprobante: (l) => _comprobanteLinea(context, p, l),
                      )
                    : _ListaLineas(
                        lineas: p.lineas,
                        mobile: mobile,
                        editable: editable,
                        onEdit: (l) => _editarLinea(context, ref, l),
                        onComprobante: (l) => _comprobanteLinea(context, p, l),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _comprobanteLinea(
    BuildContext context,
    Planilla planilla,
    PlanillaLinea linea,
  ) async {
    try {
      await ComprobanteEmpleadoPdf.compartir(planilla: planilla, linea: linea);
    } catch (e) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Comprobante: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _pagar(BuildContext context, WidgetRef ref) async {
    final ok = await showPremiumConfirm(
      context,
      title: 'Marcar como pagada',
      message: 'Confirma que el pago a empleados ya fue ejecutado.',
      confirmLabel: 'Pagada',
      icon: Icons.payments_outlined,
      destructive: false,
    );
    if (ok == true) {
      await ref.read(planillaRepositoryProvider).marcarPagada(planillaId);
      ref.invalidate(planillaDetalleProvider(planillaId));
      ref.invalidate(planillasListaProvider);
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Planilla marcada como pagada')),
      );
    }
  }

  Future<void> _cerrar(BuildContext context, WidgetRef ref) async {
    final ok = await showPremiumConfirm(
      context,
      title: 'Cerrar planilla',
      message: 'Al cerrarla no podrás editar montos ni descuentos. ¿Continuar?',
      confirmLabel: 'Cerrar',
      icon: Icons.lock_outline,
      destructive: false,
    );
    if (ok == true) {
      await ref.read(planillaRepositoryProvider).cerrar(planillaId);
      ref.invalidate(planillaDetalleProvider(planillaId));
      ref.invalidate(planillasListaProvider);
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Planilla cerrada')),
      );
    }
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    String periodo,
  ) async {
    final ok = await showPremiumConfirm(
      context,
      title: 'Eliminar planilla',
      message: '¿Eliminar el periodo $periodo y todas sus líneas?',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (ok == true && context.mounted) {
      await ref.read(planillaRepositoryProvider).eliminar(planillaId);
      ref.invalidate(planillasListaProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _editarLinea(
    BuildContext context,
    WidgetRef ref,
    PlanillaLinea l,
  ) async {
    final ctrl = TextEditingController(text: l.montoBruto.toStringAsFixed(2));
    final ok = await showPremiumMontoDialog(
      context,
      nombre: l.nombreEmpleado,
      controller: ctrl,
      brutoActual: l.montoBruto,
      afp: l.tssAfp,
      sfs: l.tssSfs,
      isr: l.isr,
      neto: l.montoNeto,
    );
    if (ok == true && l.id != null) {
      final monto =
          double.tryParse(
            ctrl.text.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), ''),
          ) ??
          l.montoBruto;
      final repo = ref.read(planillaRepositoryProvider);
      await repo.actualizarLineaMonto(l.id!, monto);
      await repo.recalcularTotal(planillaId);
      ref.invalidate(planillaDetalleProvider(planillaId));
      ref.invalidate(planillasListaProvider);
    }
  }
}

// ── Resumen superior ──────────────────────────────────────────

class _ResumenBar extends StatelessWidget {
  const _ResumenBar({
    required this.mobile,
    required this.desktop,
    required this.estado,
    required this.cerrada,
    required this.bruto,
    required this.neto,
    required this.afp,
    required this.sfs,
    required this.isr,
  });

  final bool mobile;
  final bool desktop;
  final String estado;
  final bool cerrada;
  final String bruto;
  final String neto;
  final String afp;
  final String sfs;
  final String isr;

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      label: Text(estado),
      backgroundColor: (cerrada ? AppColors.textSecondary : AppColors.success)
          .withValues(alpha: 0.15),
    );

    Widget kpi(String label, String value, {bool emphasize = false}) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 10 : 14,
          vertical: mobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style:
                  (emphasize
                          ? AppTypography.bodyLarge
                          : AppTypography.bodyMedium)
                      .copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    final items = [
      kpi('Bruto', bruto, emphasize: true),
      kpi('AFP', afp),
      kpi('SFS', sfs),
      kpi('ISR', isr),
      kpi('Neto', neto, emphasize: true),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [chip, const Spacer()]),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (ctx, c) {
              final cols = mobile ? 2 : (c.maxWidth >= 1100 ? 5 : 3);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in items)
                    SizedBox(
                      width: (c.maxWidth - 8 * (cols - 1)) / cols,
                      child: w,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Lista móvil / tablet ──────────────────────────────────────

class _ListaLineas extends StatelessWidget {
  const _ListaLineas({
    required this.lineas,
    required this.mobile,
    required this.editable,
    required this.onEdit,
    required this.onComprobante,
  });

  final List<PlanillaLinea> lineas;
  final bool mobile;
  final bool editable;
  final void Function(PlanillaLinea) onEdit;
  final void Function(PlanillaLinea) onComprobante;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = mobile ? 1 : (c.maxWidth >= 900 ? 2 : 1);
        if (cols == 1) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: lineas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _LineaCard(
              l: lineas[i],
              editable: editable,
              onEdit: onEdit,
              onComprobante: onComprobante,
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: lineas.length,
          itemBuilder: (ctx, i) => _LineaCard(
            l: lineas[i],
            editable: editable,
            onEdit: onEdit,
            onComprobante: onComprobante,
          ),
        );
      },
    );
  }
}

class _LineaCard extends StatelessWidget {
  const _LineaCard({
    required this.l,
    required this.editable,
    required this.onEdit,
    required this.onComprobante,
  });

  final PlanillaLinea l;
  final bool editable;
  final void Function(PlanillaLinea) onEdit;
  final void Function(PlanillaLinea) onComprobante;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: editable ? () => onEdit(l) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.nombreEmpleado,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Comprobante PDF',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    onPressed: () => onComprobante(l),
                  ),
                ],
              ),
              Text(
                l.cargo ?? 'Sin cargo',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Neto ${formatRd(l.montoNeto)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Bruto ${formatRd(l.montoBruto)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'AFP ${formatRd(l.tssAfp)} · SFS ${formatRd(l.tssSfs)} · ISR ${formatRd(l.isr)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tabla desktop ─────────────────────────────────────────────

class _TablaLineas extends StatelessWidget {
  const _TablaLineas({
    required this.lineas,
    required this.editable,
    required this.onEdit,
    required this.onComprobante,
  });

  final List<PlanillaLinea> lineas;
  final bool editable;
  final void Function(PlanillaLinea) onEdit;
  final void Function(PlanillaLinea) onComprobante;

  @override
  Widget build(BuildContext context) {
    const headers = ['Empleado', 'Bruto', 'AFP', 'SFS', 'ISR', 'Neto', 'PDF'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(1.1),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.0),
          4: FlexColumnWidth(1.0),
          5: FlexColumnWidth(1.1),
          6: FlexColumnWidth(0.55),
        },
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.border),
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.grey100),
            children: [
              for (var index = 0; index < headers.length; index++)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    headers[index],
                    textAlign: index == 0
                        ? TextAlign.left
                        : index == 6
                        ? TextAlign.center
                        : TextAlign.right,
                    style: AppTypography.labelSmallSemiBold.copyWith(
                      color: AppColors.grey600,
                      letterSpacing: 0.35,
                    ),
                  ),
                ),
            ],
          ),
          for (final l in lineas)
            TableRow(
              children: [
                InkWell(
                  onTap: editable ? () => onEdit(l) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.nombreEmpleado,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          l.cargo ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _td(formatRd(l.montoBruto)),
                _td(formatRd(l.tssAfp)),
                _td(formatRd(l.tssSfs)),
                _td(formatRd(l.isr)),
                _td(formatRd(l.montoNeto), bold: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: IconButton(
                    tooltip: 'Comprobante',
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    onPressed: () => onComprobante(l),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _td(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      t,
      textAlign: TextAlign.right,
      style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
    ),
  );
}

// ── Diálogos premium ──────────────────────────────────────────

Future<bool?> showPremiumConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required IconData icon,
  bool destructive = false,
}) {
  final color = destructive
      ? AppColors.error
      : Theme.of(context).colorScheme.primary;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<bool?> showPremiumMontoDialog(
  BuildContext context, {
  required String nombre,
  required TextEditingController controller,
  required double brutoActual,
  required double afp,
  required double sfs,
  required double isr,
  required double neto,
}) {
  // montos vía formatRd()
  var previewAfp = afp;
  var previewSfs = sfs;
  var previewIsr = isr;
  var previewNeto = neto;

  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          void recalc(String raw) {
            final m =
                double.tryParse(
                  raw.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), ''),
                ) ??
                0;
            final c = CalculadoraNominaRd.desdeBruto(m);
            setLocal(() {
              previewAfp = c.afp;
              previewSfs = c.sfs;
              previewIsr = c.isr;
              previewNeto = c.neto;
            });
          }

          Widget row(String a, String b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  a,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  b,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 22,
                  bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        nombre,
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajusta el bruto; AFP, SFS e ISR se recalculan con tablas 2026.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: recalc,
                        decoration: InputDecoration(
                          labelText: r'Monto bruto (RD$)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            row('AFP (2.87 %)', formatRd(previewAfp)),
                            row('SFS (3.04 %)', formatRd(previewSfs)),
                            row('ISR', formatRd(previewIsr)),
                            const Divider(height: 14),
                            row('Neto estimado', formatRd(previewNeto)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Guardar'),
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
  );
}
