import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class ApartadosPage extends ConsumerStatefulWidget {
  const ApartadosPage({super.key});
  static const String routeName = 'apartados';

  @override
  ConsumerState<ApartadosPage> createState() => _ApartadosPageState();
}

class _ApartadosPageState extends ConsumerState<ApartadosPage> {
  @override
  Widget build(BuildContext context) {
    final listaApartados = ref.watch(listaApartadosProvider);

    return AppScaffold(
      title: 'Productos Apartados',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: listaApartados.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('❌ Error al cargar apartados: $error'),
          ),
          data: (apartados) {
            if (apartados.isEmpty) {
              return const Center(child: Text('No hay productos apartados'));
            }
            return AppSection(
              title: 'Apartados (${apartados.length})',
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Cantidad')),
                      DataColumn(label: Text('Cliente')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Estado')),
                    ],
                    rows: apartados.map((apt) {
                      return DataRow(cells: [
                        DataCell(Text('${apt['id']}')),
                        DataCell(Text('${apt['productoNombre'] ?? '-'}')),
                        DataCell(Text('${apt['cantidad']}')),
                        DataCell(Text('${apt['clienteNombre'] ?? '-'}')),
                        DataCell(Text('${apt['fechaApartado']}')),
                        DataCell(Text('${apt['estado']}')),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
