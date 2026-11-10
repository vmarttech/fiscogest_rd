import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/fios_provider.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';

import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/avisar_atrasados_button.dart';
class FiosListaPage extends ConsumerWidget {
  const FiosListaPage({super.key});

  static const String routeName = 'ventas-fios';
  static const String path = '/ventas/fios';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fiosPendientesProvider);
    final fechaFmt = DateFormat('dd/MM/yyyy');

    return AppScaffold(
  floatingActionButton: Consumer(builder: (context, ref, _) {
    final fios = ref.watch(fiosPendientesProvider).asData?.value ?? const [];
    final ahora = DateTime.now();
    final atrasados = fios.where((f) =>
        f.estado != 'pagado' &&
        (f.fechaCompromiso == null || f.fechaCompromiso!.isBefore(ahora))).toList();
    return FloatingActionButton.extended(
      onPressed: () => AvisarAtrasadosButton.avisar(context, ref, atrasados),
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Avisar atrasados'),
    );
  }),

      title: 'FIAO',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 48,
                      color: AppColors.grey300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay fiao pendiente',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cuando anotes un fiao desde Generar venta, aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalDeuda = lista.fold<double>(
            0,
            (s, f) => s + f.saldoPendiente,
          );

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Por cobrar: ${formatRd(totalDeuda)}',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      '${lista.length}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final f = lista[i];
                    return _FioTile(
                      fio: f,
                      fechaFmt: fechaFmt,
                      onAbonar: () => _abrirAbonar(context, ref, f),
                      onRecordatorio: () {
                        final gatesWA = LicenciaGates(ref.read(licenciaActualProvider).valueOrNull);
                        if (!gatesWA.permiteNotifWhatsappFiao) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Los recordatorios por WhatsApp están disponibles desde el plan Esencial.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        _abrirRecordatorioWhatsApp(context, ref, f);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _abrirRecordatorioWhatsApp(
    BuildContext context,
    WidgetRef ref,
    FioData fio,
  ) async {
    final telefono = await showDialog<String>(
      context: context,
      builder: (_) => _RecordatorioWhatsAppDialog(fio: fio),
    );

    if (telefono == null || !context.mounted) return;

    // Persistir teléfono en el fiao si aún no tenía
    if ((fio.telefono == null || fio.telefono!.trim().isEmpty) &&
        telefono.trim().isNotEmpty) {
      try {
        final db = ref.read(databaseProvider);
        await (db.update(db.fiosTable)..where((t) => t.id.equals(fio.id)))
            .write(FiosTableCompanion(telefono: Value(telefono.trim())));
      } catch (_) {}
    }

    try {
      final empresa = ref.read(configuracionControllerProvider).valueOrNull;
      await ref.read(recordatorioWhatsAppServiceProvider).enviarDesdeFiao(
            nombreCliente: fio.nombreCliente,
            saldoPendiente: fio.saldoPendiente,
            telefonoCliente: telefono,
            empresa: empresa,
            nota: fio.nota,
          );
    } catch (e) {
      if (context.mounted) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _abrirAbonar(
    BuildContext context,
    WidgetRef ref,
    FioData fio,
  ) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetAbonarFiao(fio: fio),
    );
    if (ok == true && context.mounted) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Abono registrado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _FioTile extends StatelessWidget {
  const _FioTile({
    required this.fio,
    required this.fechaFmt,
    required this.onAbonar,
    required this.onRecordatorio,
  });

  final FioData fio;
  final DateFormat fechaFmt;
  final VoidCallback onAbonar;
  final VoidCallback onRecordatorio;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onAbonar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fio.nombreCliente,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fechaFmt.format(fio.fecha),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (fio.nota != null && fio.nota!.isNotEmpty)
                      Text(
                        fio.nota!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Recordatorio WhatsApp',
                onPressed: onRecordatorio,
                icon: const Icon(
                  Icons.chat,
                  color: Color(0xFF059669),
                  size: 22,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRd(fio.saldoPendiente),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'Abonar',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAbonarFiao extends ConsumerStatefulWidget {
  const _SheetAbonarFiao({required this.fio});
  final FioData fio;

  @override
  ConsumerState<_SheetAbonarFiao> createState() => _SheetAbonarFiaoState();
}

class _SheetAbonarFiaoState extends ConsumerState<_SheetAbonarFiao> {
  late final TextEditingController _monto;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _monto = TextEditingController(
      text: widget.fio.saldoPendiente.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final raw = _monto.text.trim().replaceAll(',', '');
    final valor = double.tryParse(raw);
    if (valor == null || valor <= 0) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Ingrese un monto válido'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (valor > widget.fio.saldoPendiente + 0.01) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('El abono no puede ser mayor al saldo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });
    try {
      await ref.read(fiosRepositoryProvider).abonar(widget.fio.id, valor);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() { _guardando = false; });
    }
  }

  
  Widget _botonMonto(String label, double valor) {
    final saldo = widget.fio.saldoPendiente;
    final activo = valor <= saldo + 0.01;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: (_guardando || !activo)
              ? null
              : () => setState(() {
                    _monto.text = valor.toStringAsFixed(2);
                  }),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
@override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final saldo = widget.fio.saldoPendiente;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
              child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Abonar fiao',
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.fio.nombreCliente,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Saldo: ${formatRd(saldo)}',

              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 8),
            Row(children: [
              _botonMonto('50', 50),
              _botonMonto('100', 100),
              _botonMonto('200', 200),
              _botonMonto('500', 500),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardando
                    ? null
                    : () => setState(() {
                          _monto.text = saldo.toStringAsFixed(2);
                        }),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('SALDAR TODO',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _monto,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Monto a abonar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _monto.text = (saldo / 2).toStringAsFixed(2);
                  }),
                  child: const Text('Mitad'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _monto.text = saldo.toStringAsFixed(2);
                  }),
                  child: const Text('Todo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _guardando ? null : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'REGISTRAR ABONO',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            TextButton(
              onPressed: _guardando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
            ),
      ),
    );
  }
}

class _RecordatorioWhatsAppDialog extends StatefulWidget {
  const _RecordatorioWhatsAppDialog({required this.fio});

  final FioData fio;

  @override
  State<_RecordatorioWhatsAppDialog> createState() =>
      _RecordatorioWhatsAppDialogState();
}

class _RecordatorioWhatsAppDialogState
    extends State<_RecordatorioWhatsAppDialog> {
  late final TextEditingController _telefonoCtrl;

  @override
  void initState() {
    super.initState();
    // Preferir teléfono ya guardado en el fiao
    final prefill = (widget.fio.telefono ?? '').trim();
    _telefonoCtrl = TextEditingController(text: prefill);
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fio = widget.fio;

    return AlertDialog(
      title: const Text('Recordatorio WhatsApp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cliente: ${fio.nombreCliente}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saldo: ${formatRd(fio.saldoPendiente)}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp del cliente',
              hintText: '8091234567',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.pop(context, _telefonoCtrl.text.trim()),
          icon: const Icon(Icons.chat, size: 18),
          label: const Text('Enviar'),
        ),
      ],
    );
  }
}
