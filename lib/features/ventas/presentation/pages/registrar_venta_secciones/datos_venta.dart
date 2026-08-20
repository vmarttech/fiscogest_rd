import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class DatosVenta extends ConsumerWidget {

  const DatosVenta({
    super.key,
    required this.alSeleccionarCliente,
    required this.alSeleccionarFormaPago,
  });
  final VoidCallback alSeleccionarCliente;
  final VoidCallback alSeleccionarFormaPago;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLocal = ref.watch(registrarVentaProvider);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Datos de la Venta', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildFilaDato(
              Icons.person,
              'Cliente',
              estadoLocal.clienteId != null ? 'Cliente ID ${estadoLocal.clienteId}' : 'Seleccionar',
              alSeleccionarCliente,
            ),
            const SizedBox(height: 10),
            _buildFilaDato(
              Icons.payment,
              'Forma de Pago',
              estadoLocal.tipoPago.isNotEmpty
                  ? '${estadoLocal.tipoPago[0].toUpperCase()}${estadoLocal.tipoPago.substring(1)}${estadoLocal.esCredito ? ' (Crédito)' : ''}'
                  : 'Seleccionar',
              alSeleccionarFormaPago,
            ),
            const Divider(height: 24),
            _buildFilaTotal('Subtotal', estadoLocal.subtotal),
            _buildFilaTotal('ITBIS (18%)', estadoLocal.itbis),
            const Divider(),
            _buildFilaTotal('TOTAL A PAGAR', estadoLocal.total, esTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaDato(IconData icono, String etiqueta, String valor, VoidCallback alPresionar) {
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icono, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(child: Text(etiqueta)),
            Row(children: [
              Text(valor, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 16 : 14)),
          Text('RD\$ ${monto.toStringAsFixed(2)}', style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 18 : 14, color: esTotal ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }
}
