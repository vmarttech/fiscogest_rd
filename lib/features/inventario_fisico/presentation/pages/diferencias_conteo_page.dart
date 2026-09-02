import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart';

class DiferenciasConteoPage extends ConsumerWidget {
  const DiferenciasConteoPage({super.key, required this.conteoId});
  static const routeName = 'diferencias-conteo-fisico';
  final int conteoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diferencias del Conteo')),
      body: FutureBuilder<List<DiferenciaConteo>>(
        future: ref.read(listarDiferenciasProvider).call(conteoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const Center(child: Text('No hay diferencias registradas'));
          }
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (_, i) {
              final dif = lista[i];
              return ListTile(
                title: Text(dif.nombreProducto),
                subtitle: Text(
                  'Sist: ${dif.stockSistema} | Físico: ${dif.stockFisico}',
                ),
                trailing: Text('Dif: ${dif.diferencia.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}
