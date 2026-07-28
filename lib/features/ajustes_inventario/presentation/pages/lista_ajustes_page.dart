import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart';

class ListaAjustesPage extends ConsumerStatefulWidget {
  const ListaAjustesPage({super.key});
  static const routeName = 'lista-ajustes';

  @override
  ConsumerState<ListaAjustesPage> createState() => _ListaAjustesPageState();
}

class _ListaAjustesPageState extends ConsumerState<ListaAjustesPage> {
  @override
  Widget build(BuildContext context) {
    final listaAsync = ref.watch(ajusteInventarioListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Ajustes'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Nuevo Ajuste',
            onPressed: () => context.pushNamed(RegistrarAjustePage.routeName),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ajusteInventarioListProvider.future),
        child: listaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (lista) => lista.isEmpty
              ? const Center(child: Text('No hay ajustes registrados'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final a = lista[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Producto ID: ${a.idProducto}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Tipo: ${a.tipoAjuste} • Cantidad: ${a.cantidad}'),
                            Text('Motivo: ${a.motivo}'),
                            Text('Fecha: ${a.fechaCreacion.day}/${a.fechaCreacion.month}/${a.fechaCreacion.year} ${a.fechaCreacion.hour}:${a.fechaCreacion.minute}'),
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
