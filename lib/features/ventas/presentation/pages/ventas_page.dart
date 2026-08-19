import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});
  static const String routeName = 'ventas';

  @override
  ConsumerState<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends ConsumerState<VentasPage> {
  final _buscadorController = TextEditingController();

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listaVentas = ref.watch(listaVentasProvider);

    return AppScaffold(
      title: 'Historial de Ventas',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Buscar venta',
              prefixIcon: Icons.search,
              controller: _buscadorController,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listaVentas.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('❌ Error al cargar ventas: $error'),
                ),
                data: (ventas) {
                  if (ventas.isEmpty) {
                    return const Center(child: Text('No hay ventas registradas'));
                  }
                  return AppSection(
                    title: 'Ventas (${ventas.length})',
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Estado')),
                          ],
                          rows: ventas.map((venta) {
                            return DataRow(cells: [
                              DataCell(Text('${venta['id']}')),
                              DataCell(Text('${venta['fecha']}')),
                              DataCell(Text('${venta['clienteNombre'] ?? '-'}')),
                              DataCell(Text('RD\$ ${venta['montoTotal'] ?? 0}')),
                              DataCell(Text('${venta['estado'] ?? '-'}')),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
