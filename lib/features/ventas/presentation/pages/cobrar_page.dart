import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

final listadoCuentasCobrarProvider = FutureProvider<List<CuentaCobrarItem>>((
  ref,
) async {
  final db = ref.watch<AppDatabase>(appDatabaseProvider);
  final dao = CuentasCobrarDao(db);
  final registros = await dao.listarCuentasPorCobrar();

  final idsClientes = registros.map((r) => r.clienteId).toSet();
  final clientes = await (db.select(db.clientesTable)
    ..where((t) => t.id.isIn(idsClientes)))
    .get();
  final mapaClientes = {for (var c in clientes) c.id: c.nombre};

  return registros.map((reg) {
    final nombreCliente = mapaClientes[reg.clienteId] ?? 'Cliente #${reg.clienteId}';
    final estadoTexto = switch (reg.estado) {
      CobrarEstado.pagado => 'Pagado',
      CobrarEstado.vencido => 'Vencido',
      CobrarEstado.parcial => 'Parcial',
      _ => 'Pendiente',
    };
    return CuentaCobrarItem(
      clienteNombre: nombreCliente,
      montoOriginal: reg.montoOriginal,
      montoAbonado: reg.montoAbonado,
      saldoPendiente: reg.saldoPendiente,
      fechaVencimiento: reg.fechaVencimiento,
      estado: estadoTexto,
    );
  }).toList();
});

class CuentaCobrarItem {

  const CuentaCobrarItem({
    required this.clienteNombre,
    required this.montoOriginal,
    required this.montoAbonado,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
  });
  final String clienteNombre;
  final double montoOriginal;
  final double montoAbonado;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final String estado;
}

class CobrarPage extends ConsumerStatefulWidget {

  const CobrarPage({super.key});
  static const String routeName = '/cobrar-page';

  @override
  ConsumerState<CobrarPage> createState() => _CobrarPageState();
}

class _CobrarPageState extends ConsumerState<CobrarPage> {
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}';
  }

  Color _colorEstado(String estado) {
    return switch (estado) {
      'Pendiente' => Colors.orange,
      'Parcial' => Colors.blue,
      'Pagado' => Colors.green,
      'Vencido' => Colors.red,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(listadoCuentasCobrarProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas por Cobrar')),
      body: cuentasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cuentas) {
          if (cuentas.isEmpty) {
            return const Center(child: Text('No hay cuentas por cobrar'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cuentas.length,
            itemBuilder: (context, i) {
              final c = cuentas[i];
              final vencida = c.estado == 'Vencido';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: vencida ? Colors.red.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.clienteNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Total: RD\$ ${c.montoOriginal.toStringAsFixed(2)}'),
                      Text('Abonado: RD\$ ${c.montoAbonado.toStringAsFixed(2)}'),
                      Text(
                        'Saldo pendiente: RD\$ ${c.saldoPendiente.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: vencida ? Colors.red.shade700 : Colors.blue.shade700,
                        ),
                      ),
                      Text('Vence: ${_formatearFecha(c.fechaVencimiento)}'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _colorEstado(c.estado),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          c.estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
