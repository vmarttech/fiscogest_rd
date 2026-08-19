import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class CotizacionesPage extends ConsumerStatefulWidget {
  const CotizacionesPage({super.key});
  static const String routeName = 'cotizaciones';

  @override
  ConsumerState<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends ConsumerState<CotizacionesPage> {
  @override
  Widget build(BuildContext context) {
    final listaCotizaciones = ref.watch(listaCotizacionesProvider);

    return AppScaffold(
      title: 'Cotizaciones',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: listaCotizaciones.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('❌ Error al cargar cotizaciones: $error'),
          ),
          data: (cotizaciones) {
            if (cotizaciones.isEmpty) {
              return const Center(child: Text('No hay cotizaciones registradas'));
            }
            return AppSection(
              title: 'Cotizaciones (${cotizaciones.length})',
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Vencimiento')),
                      DataColumn(label: Text('Cliente')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Estado')),
                    ],
                    rows: cotizaciones.map((cot) {
                      return DataRow(cells: [
                        DataCell(Text('${cot['id']}')),
                        DataCell(Text('${cot['fecha']}')),
                        DataCell(Text('${cot['fechaVencimiento']}')),
                        DataCell(Text('${cot['clienteNombre'] ?? '-'}')),
                        DataCell(Text('RD\$ ${cot['montoTotal'] ?? 0}')),
                        DataCell(Text('${cot['estado'] ?? '-'}')),
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
