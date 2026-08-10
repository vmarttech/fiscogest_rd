import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class ListarConteosPage extends ConsumerWidget {
  const ListarConteosPage({super.key});
  static const routeName = 'lista-conteos-fisicos';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteosAsync = ref.watch(listaConteosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Inventario Físico'),
        backgroundColor: const Color(0xFF0A2463),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Nuevo Conteo',
            onPressed: () => context.pushNamed('registrar-conteo-fisico'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: conteosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Text('No hay conteos registrados. Cree el primero.', style: TextStyle(color: Color(0xFF64748B))),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = lista[i];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(c.nombreConteo, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  subtitle: Text('Fecha: ${c.fechaConteo.day}/${c.fechaConteo.month}/${c.fechaConteo.year} • Estado: ${c.estado.name.toUpperCase()}', style: const TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
                  onTap: () => context.pushNamed('diferencias-conteo', extra: c.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
