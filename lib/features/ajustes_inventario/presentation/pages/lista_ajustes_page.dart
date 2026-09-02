import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';

class ListaAjustesPage extends ConsumerStatefulWidget {
  const ListaAjustesPage({super.key});
  static const String routeName = 'lista-ajustes';
  @override
  ConsumerState<ListaAjustesPage> createState() => _ListaAjustesPageState();
}

class _ListaAjustesPageState extends ConsumerState<ListaAjustesPage> {
  @override
  Widget build(BuildContext context) {
    final listaAsync = ref.watch(ajusteInventarioListaProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              tooltip: 'Nuevo Ajuste',
              onPressed: () => context.pushNamed(RegistrarAjustePage.routeName),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ajusteInventarioListaProvider.future),
        child: listaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Center(child: Text('Error: $e')),
          data: (List<AjusteInventario> lista) => lista.isEmpty
              ? const Center(child: Text('No hay ajustes registrados'))
              : ListView.separated(
                  padding: AppSpacing.allM,
                  itemCount: lista.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.s),
                  itemBuilder: (_, int i) {
                    final AjusteInventario a = lista[i];
                    return Card(
                      child: Padding(
                        padding: AppSpacing.allS,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Producto ID: ${a.productoId}',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tipo: ${a.tipoAjuste} • Cantidad: ${a.cantidad}',
                            ),
                            Text('Motivo: ${a.motivo}'),
                            Text(
                              'Fecha: ${a.fechaCreacion.day}/${a.fechaCreacion.month}/${a.fechaCreacion.year} '
                              '${a.fechaCreacion.hour}:${a.fechaCreacion.minute.toString().padLeft(2, '0')}',
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
