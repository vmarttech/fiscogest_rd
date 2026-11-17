import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/providers/gastronomia_providers.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/utils/gastro_whatsapp.dart';

class HistorialPedidosGastroPage extends ConsumerStatefulWidget {
  const HistorialPedidosGastroPage({super.key});
  static const routeName = 'historial-pedidos-gastro';
  @override
  ConsumerState<HistorialPedidosGastroPage> createState() =>
      _HistorialPedidosGastroPageState();
}

class _HistorialPedidosGastroPageState
    extends ConsumerState<HistorialPedidosGastroPage> {
  String? _filtro;

  @override
  Widget build(BuildContext context) {
    final pedidos = ref.watch(pedidosGastroHistorialProvider(_filtro));
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de pedidos')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(spacing: 6, children: [
            _chip('Todos', _filtro == null, () => setState(() => _filtro = null)),
            _chip('Pendientes', _filtro == 'pendiente',
                () => setState(() => _filtro = 'pendiente')),
            _chip('En camino', _filtro == 'en_camino',
                () => setState(() => _filtro = 'en_camino')),
            _chip('Entregados', _filtro == 'entregado',
                () => setState(() => _filtro = 'entregado')),
            _chip('Cancelados', _filtro == 'cancelado',
                () => setState(() => _filtro = 'cancelado')),
          ]),
        ),
        Expanded(
          child: pedidos.when(
            data: (list) => list.isEmpty
                ? const Center(child: Text('Sin pedidos en este filtro.'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final pe = list[i];
                      final activo = pe.estado != 'entregado' &&
                          pe.estado != 'cancelado';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text('#${pe.id} · ${pe.nombreCliente}'),
                          subtitle: Text(
                            '${pe.estado} · RD\$ ${pe.total.toStringAsFixed(2)} · '
                            '${pe.fecha.day}/${pe.fecha.month}/${pe.fecha.year} '
                            '${pe.fecha.hour}:${pe.fecha.minute.toString().padLeft(2, '0')}'
                            '${pe.telefono.isNotEmpty ? ' · ${pe.telefono}' : ''}',
                          ),
                          isThreeLine: pe.direccionReferencia.isNotEmpty,
                          trailing: Wrap(spacing: 0, children: [
                            if (pe.telefono.trim().isNotEmpty)
                              IconButton(
                                tooltip: 'WhatsApp',
                                icon: const Icon(Icons.chat),
                                onPressed: () async {
                                  final msg = GastroWhatsapp.mensajePedido(
                                    pedidoId: pe.id,
                                    nombreCliente: pe.nombreCliente,
                                    total: pe.total,
                                    estado: pe.estado,
                                    direccion: pe.direccionReferencia,
                                  );
                                  await GastroWhatsapp.abrir(pe.telefono,
                                      mensaje: msg);
                                },
                              ),
                            if (activo)
                              TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(gastronomiaServiceProvider)
                                      .cancelarPedido(pe.id);
                                  ref.invalidate(
                                      pedidosGastroHistorialProvider(_filtro));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Pedido #${pe.id} cancelado')));
                                  }
                                },
                                child: const Text('Cancelar'),
                              ),
                          ]),
                          onTap: () => _detalle(context, pe),
                        ),
                      );
                    }),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) =>
      ChoiceChip(label: Text(label), selected: sel, onSelected: (_) => onTap());

  void _detalle(BuildContext context, PedidoGastronomiaData pe) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pedido #${pe.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fila('Estado', pe.estado),
              _fila('Entrega', pe.estadoEntrega),
              _fila('Cliente', pe.nombreCliente),
              if (pe.telefono.isNotEmpty) _fila('Telefono', pe.telefono),
              if (pe.direccionReferencia.isNotEmpty)
                _fila('Direccion', pe.direccionReferencia),
              _fila('Subtotal', 'RD\$ ${pe.subtotal.toStringAsFixed(2)}'),
              if (pe.descuento > 0)
                _fila('Descuento', '-RD\$ ${pe.descuento.toStringAsFixed(2)}'),
              if (pe.propina > 0)
                _fila('Propina', 'RD\$ ${pe.propina.toStringAsFixed(2)}'),
              if (pe.costoEnvio > 0)
                _fila('Envio', 'RD\$ ${pe.costoEnvio.toStringAsFixed(2)}'),
              _fila('ITBIS', 'RD\$ ${pe.itbis.toStringAsFixed(2)}'),
              _fila('Total', 'RD\$ ${pe.total.toStringAsFixed(2)}'),
              _fila('Pago', pe.formaPago),
              if (pe.notas.isNotEmpty) _fila('Notas', pe.notas),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _fila(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 90,
              child: Text(k,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(v)),
        ]),
      );
}
