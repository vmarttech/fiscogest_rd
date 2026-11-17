import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/providers/gastronomia_providers.dart';

class ReporteGastronomiaPage extends ConsumerWidget {
  const ReporteGastronomiaPage({super.key});
  static const routeName = 'reporte-gastronomia';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = ref.watch(topPlatosProvider);
    final horas = ref.watch(ventasPorHoraProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte gastronomía')),
      body: ListView(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('Platos más vendidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        top.when(
          data: (list) => list.isEmpty
              ? const Padding(padding: EdgeInsets.all(16), child: Text('Sin datos todavía.'))
              : Column(children: [
                  for (final r in list)
                    ListTile(
                      leading: CircleAvatar(child: Text('${(r['cantidad'] as double).toInt()}')),
                      title: Text(r['nombre'] as String),
                      trailing: Text('RD\$ ${(r['monto'] as double).toStringAsFixed(2)}'),
                    ),
                ]),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
        ),
        const Padding(padding: EdgeInsets.all(16), child: Text('Ventas por hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        horas.when(
          data: (list) => Column(children: [
            for (final r in list)
              ListTile(
                title: Text('${r['hora']}:00 h'),
                trailing: Text('${r['cantidad']} pedidos · RD\$ ${(r['monto'] as double).toStringAsFixed(2)}'),
              ),
          ]),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e')),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
