import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class FormularioVenta extends ConsumerWidget {
  const FormularioVenta({
    super.key,
    required this.alSeleccionarCliente,
    required this.alSeleccionarFormaPago,
  });

  final VoidCallback alSeleccionarCliente;
  final VoidCallback alSeleccionarFormaPago;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrarVentaProvider);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Datos de la Venta', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: alSeleccionarCliente,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blueGrey),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Cliente')),
                    Row(children: [
                      Text(
                        estado.clienteNombre.isNotEmpty ? estado.clienteNombre : 'Seleccionar',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: alSeleccionarFormaPago,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.blueGrey),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Forma de Pago')),
                    Row(children: [
                      Text(
                        estado.tipoPago.isNotEmpty
                            ? '${estado.tipoPago[0].toUpperCase()}${estado.tipoPago.substring(1)}${estado.esCredito ? ' (Crédito)' : ''}'
                            : 'Seleccionar',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: estado.tipoPago.isNotEmpty ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
