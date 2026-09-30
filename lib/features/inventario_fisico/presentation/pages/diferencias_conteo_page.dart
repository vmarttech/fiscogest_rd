import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class DiferenciasConteoPage extends ConsumerStatefulWidget {
  const DiferenciasConteoPage({super.key, required this.conteoId});

  static const routeName = 'diferencias-conteo-fisico';
  final int conteoId;

  @override
  ConsumerState<DiferenciasConteoPage> createState() =>
      _DiferenciasConteoPageState();
}

class _DiferenciasConteoPageState extends ConsumerState<DiferenciasConteoPage> {
  bool _aprobando = false;

  Future<void> _aprobar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar ajustes'),
        content: const Text(
          'Se actualizará el stock de cada producto al valor físico contado. ¿Continuar?',
        ),
        actions: [
          IconButton(
            tooltip: 'Reporte',
            icon: const Icon(Icons.description_outlined, color: Colors.white),
            onPressed: _exportarReporte,
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _aprobando = true);
    try {
      // usuarioId: 1 por defecto si no hay auth en contexto
      final uid = ref.read(usuarioAutenticadoProvider);
      if (uid == null) {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(content: Text('No hay sesión activa')),
          );
        }
        return;
      }
      await ref.read(aprobarAjustesProvider).call(widget.conteoId, uid);
      ref.invalidate(diferenciasConteoProvider(widget.conteoId));
      ref.invalidate(listaConteosProvider);
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('Ajustes aplicados y conteo aprobado')),
        );
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _aprobando = false);
    }
  }

  Future<void> _exportarReporte() async {
    try {
      final bytes = await ref
          .read(generarReporteProvider)
          .call(widget.conteoId);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'conteo_\${widget.conteoId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(content: Text('Error reporte: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final async = ref.watch(diferenciasConteoProvider(widget.conteoId));

    return AppScaffold(
      title: 'Diferencias #${widget.conteoId}',
      subtitle: isMobile ? null : 'Sistema vs físico',
      actions: [
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppButton(
              text: 'Aprobar ajustes',
              onPressed: _aprobando ? null : _aprobar,
              isLoading: _aprobando,
            ),
          ),
      ],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (lista) {
                  if (lista.isEmpty) {
                    return const Center(
                      child: Text('No hay diferencias registradas'),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 8,
                      16,
                      isMobile ? 16 : 8,
                      16,
                    ),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = lista[i];
                      return ListTile(
                        title: Text(d.nombreProducto),
                        subtitle: Text(
                          '${d.codigoProducto} · Sis ${d.stockSistema.toStringAsFixed(2)} · '
                          'Fís ${d.stockFisico.toStringAsFixed(2)} · ${d.estado}',
                        ),
                        trailing: Text(
                          d.diferencia.toStringAsFixed(2),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: d.diferencia == 0
                                ? AppColors.textSecondary
                                : (d.diferencia > 0
                                      ? AppColors.success
                                      : AppColors.error),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (isMobile)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Aprobar ajustes',
                    onPressed: _aprobando ? null : _aprobar,
                    isLoading: _aprobando,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
