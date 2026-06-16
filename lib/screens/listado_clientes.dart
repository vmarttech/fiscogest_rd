import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cliente_provider.dart';
import 'formulario_cliente.dart';

class ListadoClientes extends ConsumerWidget {
  const ListadoClientes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clienteNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Clientes'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormularioClienteScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: clientesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (clientes) {
          if (clientes.isEmpty) {
            return const Center(
              child: Text('No hay clientes registrados'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: clientes.length,
            itemBuilder: (_, i) {
              final cliente = clientes[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.purple),
                  title: Text(cliente.nombre),
                  subtitle: Text('${cliente.tipoIdentificacion}: ${cliente.identificacion}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormularioClienteScreen(cliente: cliente),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}