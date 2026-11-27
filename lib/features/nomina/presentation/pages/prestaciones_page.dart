import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:fiscogest_rd/features/nomina/domain/entities/empleado.dart';
import 'package:fiscogest_rd/features/nomina/domain/services/calculadora_prestaciones_rd.dart';
import 'package:fiscogest_rd/features/nomina/presentation/providers/nomina_providers.dart';
import 'package:fiscogest_rd/features/nomina/presentation/pdf/liquidacion_pdf.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

/// Liquidación de prestaciones laborales (orientativo RD).
class PrestacionesPage extends ConsumerStatefulWidget {
  const PrestacionesPage({super.key, this.empleadoId});

  static const routeName = 'nomina-prestaciones';
  static const path = '/nomina/prestaciones';

  final int? empleadoId;

  @override
  ConsumerState<PrestacionesPage> createState() => _PrestacionesPageState();
}

class _PrestacionesPageState extends ConsumerState<PrestacionesPage> {
  Empleado? _empleado;
  DateTime _salida = DateTime.now();
  bool _preaviso = true;
  bool _cesantia = true;
  bool _vacaciones = true;
  bool _regalia = true;

  Future<void> _pdf() async {
    final e = _empleado;
    if (e == null || e.fechaIngreso == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Seleccione empleado con fecha de ingreso'),
        ),
      );
      return;
    }
    final liq = CalculadoraPrestacionesRd.calcular(
      salarioMensual: e.salarioBase,
      fechaIngreso: e.fechaIngreso!,
      fechaSalida: _salida,
      incluirPreaviso: _preaviso,
      incluirCesantia: _cesantia,
      incluirVacaciones: _vacaciones,
      incluirRegalia: _regalia,
    );
    try {
      await LiquidacionPdf.compartir(
        nombreEmpleado: e.nombreCompleto,
        cargo: e.cargo,
        liq: liq,
      );
    } catch (err) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('PDF: $err'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _guardar() async {
    final e = _empleado;
    if (e == null || e.id == null || e.fechaIngreso == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Seleccione empleado con fecha de ingreso'),
        ),
      );
      return;
    }
    final liq = CalculadoraPrestacionesRd.calcular(
      salarioMensual: e.salarioBase,
      fechaIngreso: e.fechaIngreso!,
      fechaSalida: _salida,
      incluirPreaviso: _preaviso,
      incluirCesantia: _cesantia,
      incluirVacaciones: _vacaciones,
      incluirRegalia: _regalia,
    );
    try {
      await ref
          .read(liquidacionRepositoryProvider)
          .guardar(
            empleadoId: e.id!,
            nombreEmpleado: e.nombreCompleto,
            liq: liq,
          );
      ref.invalidate(liquidacionesHistorialProvider);
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Liquidación guardada en historial')),
      );
    } catch (err) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error: $err'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(empleadosListaProvider);

    return AppScaffold(
      title: 'Prestaciones laborales',
      actions: [
        IconButton.filled(
          tooltip: 'PDF liquidación',
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: () => _pdf(),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFD7193F),
            foregroundColor: Colors.white,
            hoverColor: const Color(0xFFB51232),
          ),
        ),
        IconButton.filled(
          tooltip: 'Guardar en historial',
          icon: const Icon(Icons.save_outlined),
          onPressed: () => _guardar(),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFD7193F),
            foregroundColor: Colors.white,
            hoverColor: const Color(0xFFB51232),
          ),
        ),
      ],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (lista) {
          // Preselección por id
          if (_empleado == null && widget.empleadoId != null) {
            final found = lista.where((e) => e.id == widget.empleadoId);
            if (found.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _empleado = found.first);
              });
            }
          }

          final liq = _empleado == null || _empleado!.fechaIngreso == null
              ? null
              : CalculadoraPrestacionesRd.calcular(
                  salarioMensual: _empleado!.salarioBase,
                  fechaIngreso: _empleado!.fechaIngreso!,
                  fechaSalida: _salida,
                  incluirPreaviso: _preaviso,
                  incluirCesantia: _cesantia,
                  incluirVacaciones: _vacaciones,
                  incluirRegalia: _regalia,
                );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _hero(),
              const SizedBox(height: 18),
              Text(
                'Cálculo orientativo según Código de Trabajo y regalía pascual. '
                'Verifique con su asesor laboral antes de pagar.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF47203D).withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB04E79,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF9A416A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Base de cálculo',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const Text(
                                'Selecciona la persona y fecha de salida',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 860;
                        final width = twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: width,
                              child: DropdownButtonFormField<int>(
                                initialValue: _empleado?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Empleado',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: lista
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          '${e.nombreCompleto} · ${formatRd(e.salarioBase)}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (id) {
                                  final e = lista
                                      .where((x) => x.id == id)
                                      .firstOrNull;
                                  setState(() => _empleado = e);
                                },
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Fecha de salida'),
                                  subtitle: Text(_fmt(_salida)),
                                  trailing: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _salida,
                                      firstDate: DateTime(1990),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (d != null) {
                                      setState(() => _salida = d);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_empleado != null) ...[
                const SizedBox(height: 12),
                _infoChip(
                  _empleado!.fechaIngreso == null
                      ? 'Sin fecha de ingreso — complete la ficha del empleado'
                      : 'Ingreso: ${_fmt(_empleado!.fechaIngreso!)} · '
                            'Salario: ${formatRd(_empleado!.salarioBase)}',
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF47203D).withValues(alpha: 0.055),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.checklist_rounded,
                          color: Color(0xFF9A416A),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Conceptos a incluir',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 900;
                        final width = twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        Widget materialTile(Widget child) => Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: child,
                        );
                        final options = <Widget>[
                          materialTile(
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Preaviso'),
                              activeThumbColor: const Color(0xFF9A416A),
                              value: _preaviso,
                              onChanged: (v) => setState(() => _preaviso = v),
                            ),
                          ),
                          materialTile(
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Auxilio de cesantía'),
                              activeThumbColor: const Color(0xFF9A416A),
                              value: _cesantia,
                              onChanged: (v) => setState(() => _cesantia = v),
                            ),
                          ),
                          materialTile(
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Vacaciones proporcionales'),
                              activeThumbColor: const Color(0xFF9A416A),
                              value: _vacaciones,
                              onChanged: (v) => setState(() => _vacaciones = v),
                            ),
                          ),
                          materialTile(
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Regalía pascual (proporcional)',
                              ),
                              activeThumbColor: const Color(0xFF9A416A),
                              value: _regalia,
                              onChanged: (v) => setState(() => _regalia = v),
                            ),
                          ),
                        ];
                        return Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            for (final option in options)
                              SizedBox(width: width, child: option),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (liq != null) ...[const SizedBox(height: 12), _resumen(liq)],
              const SizedBox(height: 24),
              Text(
                'Historial de liquidaciones',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final hAsync = ref.watch(liquidacionesHistorialProvider);
                  return hAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Error historial: $e'),
                    data: (items) {
                      if (items.isEmpty) {
                        return Text(
                          'Aún no hay liquidaciones guardadas.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final h in items)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  h.nombreEmpleado,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  'Salida ${_fmt(h.fechaSalida)} · ${formatRd(h.total)}',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    if (h.id == null) return;
                                    await ref
                                        .read(liquidacionRepositoryProvider)
                                        .eliminar(h.id!);
                                    ref.invalidate(
                                      liquidacionesHistorialProvider,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: AppTypography.bodySmall),
    );
  }

  Widget _hero() {
    const tono = Color(0xFF47203D);
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF32152F), tono, Color(0xFF8F466A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -58,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 28,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GESTIÓN LABORAL',
                          style: AppTypography.labelSmallSemiBold.copyWith(
                            color: const Color(0xFFF5D7E4),
                            letterSpacing: 1.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prestaciones\nlaborales',
                          style: AppTypography.h1.copyWith(
                            color: Colors.white,
                            fontSize: 29,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Un cálculo claro para cerrar cada etapa con confianza.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 38,
                      color: Color(0xFFFFD6A8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumen(LiquidacionPrestaciones l) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF47203D).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB04E79).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF9A416A),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Estimación de prestaciones',
                    style: AppTypography.h4Bold.copyWith(letterSpacing: -0.3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ESTIMADO',
                    style: AppTypography.labelSmallSemiBold.copyWith(
                      color: const Color(0xFF9A5B22),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Antigüedad: ${l.aniosServicio.toStringAsFixed(2)} años '
              '(${l.mesesServicio} meses) · Diario ${formatRd(l.salarioDiario)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 24),
            _row('Preaviso (${l.diasPreaviso} días)', l.montoPreaviso),
            _row(
              'Cesantía (${l.diasCesantia.toStringAsFixed(1)} días)',
              l.montoCesantia,
            ),
            _row(
              'Vacaciones (${l.diasVacaciones.toStringAsFixed(1)} días)',
              l.montoVacaciones,
            ),
            _row('Regalía pascual', l.montoRegalia),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF47203D), Color(0xFF743D62)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL A RECIBIR',
                    style: AppTypography.labelSmallSemiBold.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    formatRd(l.total),
                    style: AppTypography.h4Bold.copyWith(
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orientativo. No incluye salarios adeudados ni horas extras.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double monto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(
            formatRd(monto),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}/${p(d.month)}/${d.year}';
  }
}
