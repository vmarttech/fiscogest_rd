import 'package:fiscogest_rd/features/e_cf/presentation/ecfe_solo_lectura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_checklist_item.dart';
import 'package:fiscogest_rd/features/e_cf/domain/entities/ecfe_spec_version.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';

class EcfeSpecPage extends ConsumerWidget {
  const EcfeSpecPage({super.key});
  static const routeName = 'ecfe-spec';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ecfeSpecVersionsProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return AppScaffold(
      title: 'Especificación e-CF',
      subtitle: ecfeSoloLectura
          ? 'Solo consulta. Para emitir, FiscoGest versión PC'
          : 'Versiones, circulares DGII y checklist de certificación',
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 720 : 1200),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Sin versiones registradas'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: EdgeInsets.all(mobile ? 14 : 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF8F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFB9E4DE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.fact_check_outlined,
                              color: Color(0xFF008F83),
                              size: 25,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Versiones y certificación e-CF',
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: const Color(0xFF075B55),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Administra las versiones de especificación, '
                                    'revisa las circulares DGII y completa las '
                                    'pruebas de cada ambiente. El checklist es '
                                    'un control interno; no certifica por sí solo '
                                    'al emisor ante la DGII.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: const Color(0xFF376965),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final s = list[i - 1];
                    return _SpecCard(
                      spec: s,
                      fmt: fmt,
                      onChanged: () {
                        ref.invalidate(ecfeSpecVersionsProvider);
                        ref.invalidate(ecfeSpecPorIdProvider(s.id!));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecCard extends ConsumerStatefulWidget {
  const _SpecCard({
    required this.spec,
    required this.fmt,
    required this.onChanged,
  });
  final EcfeSpecVersion spec;
  final DateFormat fmt;
  final VoidCallback onChanged;

  @override
  ConsumerState<_SpecCard> createState() => _SpecCardState();
}

class _SpecCardState extends ConsumerState<_SpecCard> {
  bool _busy = false;

  EcfeRepository get _repo => ref.read(ecfeRepositoryProvider);

  List<EcfeChecklistItem> get _items =>
      _repo.parseChecklist(widget.spec.checklistJson);

  Future<void> _toggle(String itemId, bool done) async {
    setState(() => _busy = true);
    try {
      await _repo.actualizarChecklistItem(
        specId: widget.spec.id!,
        itemId: itemId,
        done: done,
      );
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('No se pudo actualizar el checklist: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activar({
    bool precert = false,
    bool cert = false,
    bool prod = false,
  }) async {
    setState(() => _busy = true);
    try {
      await _repo.activarSpec(
        id: widget.spec.id!,
        precert: precert,
        cert: cert,
        produccion: prod,
      );
      widget.onChanged();
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(content: Text('Especificación activada')),
      );
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nuevaVersion() async {
    final codigo = TextEditingController();
    final nombre = TextEditingController();
    final circular = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva versión de especificación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codigo,
              decoration: const InputDecoration(
                labelText: 'Código (ej. 1.1)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: circular,
              decoration: const InputDecoration(
                labelText: 'Circular / doc. DGII',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (codigo.text.trim().isEmpty || nombre.text.trim().isEmpty) return;
    await _repo.insertarSpecVersion(
      codigo: codigo.text.trim(),
      nombre: nombre.text.trim(),
      circularDgii: circular.text.trim().isEmpty ? null : circular.text.trim(),
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    final items = _items;
    final done = items.where((e) => e.done).length;
    final total = items.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE1E7EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.codigo} · ${s.nombre}',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Nueva versión (circular)',
                  onPressed: _busy ? null : _nuevaVersion,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if ((s.circularDgii ?? '').isNotEmpty)
              Text(
                'Circular: ${s.circularDgii}',
                style: AppTypography.bodySmall,
              ),
            if ((s.notas ?? '').isNotEmpty)
              Text(s.notas!, style: AppTypography.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (s.activaPrecert)
                  Chip(
                    label: const Text('TesteCF'),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                if (s.activaCert)
                  Chip(
                    label: const Text('CerteCF'),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                if (s.activaProduccion)
                  Chip(
                    label: const Text('Producción'),
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  ),
                Text(
                  'Checklist $done/$total',
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                AppButton(
                  text: 'Activar TesteCF',
                  onPressed: _busy ? null : () => _activar(precert: true),
                ),
                AppButton(
                  text: 'Activar CerteCF',
                  onPressed: _busy ? null : () => _activar(cert: true),
                ),
                AppButton(
                  text: 'Activar Producción',
                  onPressed: _busy
                      ? null
                      : () async {
                          if (done < total) {
                            FiscoGestNotifications.show(
                              SnackBar(
                                content: Text(
                                  'Checklist incompleto ($done/$total). '
                                  'Completa las pruebas antes de producción.',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          await _activar(prod: true);
                        },
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Checklist de certificación',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final it in items)
              CheckboxListTile(
                dense: true,
                value: it.done,
                onChanged: _busy ? null : (v) => _toggle(it.id, v ?? false),
                title: Text(it.label, style: AppTypography.bodySmall),
                subtitle: it.doneAt != null
                    ? Text(widget.fmt.format(it.doneAt!))
                    : Text(it.categoria),
                controlAffinity: ListTileControlAffinity.leading,
              ),
          ],
        ),
      ),
    );
  }
}
