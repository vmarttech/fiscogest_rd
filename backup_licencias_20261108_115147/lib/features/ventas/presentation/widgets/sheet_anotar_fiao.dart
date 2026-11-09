import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/licencias/presentation/providers/licencia_providers.dart';
import 'package:fiscogest_rd/features/licencias/domain/licencia_gates.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/fios_provider.dart';

class SheetAnotarFiao extends ConsumerStatefulWidget {
  const SheetAnotarFiao({
    super.key,
    required this.total,
    this.nombreInicial,
    this.ventaId,
  });

  final double total;
  final String? nombreInicial;
  final int? ventaId;

  static Future<bool?> show(
    BuildContext context, {
    required double total,
    String? nombreInicial,
    int? ventaId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetAnotarFiao(
        total: total,
        nombreInicial: nombreInicial,
        ventaId: ventaId,
      ),
    );
  }

  @override
  ConsumerState<SheetAnotarFiao> createState() => _SheetAnotarFiaoState();
}

class _SheetAnotarFiaoState extends ConsumerState<SheetAnotarFiao> {
  late final TextEditingController _nombre;
  late final TextEditingController _nota;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.nombreInicial ?? '');
    _nota = TextEditingController();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _nota.dispose();
    super.dispose();
  }

  Future<void> _buscarClienteLista() async {
    final cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      setState(() {
        _nombre.text = cliente.nombre;
      });
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Escriba un nombre o elija un cliente de la lista'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (widget.total <= 0) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('El monto debe ser mayor a cero'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }


    final lic = ref.read(licenciaActualProvider).valueOrNull;
    final gates = LicenciaGates(lic);
    if (!gates.permiteFiao) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text(
            'Su plan no incluye Fiao. Use el módulo de créditos o actualice el plan.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final maxFiao = gates.maxCuentasFiao;
    if (maxFiao != null) {
      final repo = ref.read(fiosRepositoryProvider);
      final abiertos = await repo.contarFiosAbiertos();
      if (abiertos >= maxFiao) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(
              gates.mensajeTope('fiao (máx. $maxFiao cuentas abiertas)'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      final db = ref.read(databaseProvider);
      await db
          .into(db.fiosTable)
          .insert(
            FiosTableCompanion.insert(
              nombreCliente: nombre,
              montoOriginal: widget.total,
              saldoPendiente: widget.total,
              nota: Value(_nota.text.trim().isEmpty ? null : _nota.text.trim()),
              ventaId: Value(widget.ventaId),
            ),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al guardar fiao: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final totalTxt = formatRd(widget.total);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
            const SizedBox(height: 14),
            Text(
              'Anotar fiao',
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: $totalTxt',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 14),
            // Nombre: lista O a mano
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombre,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nombre de quien debe',
                      hintText: 'Escribir o elegir de la lista',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _guardando ? null : _buscarClienteLista,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.person_search_rounded, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Puede buscar en la lista de clientes o escribir el nombre a mano.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nota,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: paga el viernes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
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
                        'GUARDAR FIAO',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            TextButton(
              onPressed: _guardando ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
