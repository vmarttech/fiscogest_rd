import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class ItemCarrito extends ConsumerWidget {

  const ItemCarrito({super.key, required this.linea, required this.indice});
  final DetalleVenta linea;
  final int indice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificador = ref.read(registrarVentaProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE8EBEF)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(linea.nombreProducto,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D3136))),
          ),
          Expanded(
            flex: 2,
            child: Text('${linea.cantidad}', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF343A40))),
          ),
          Expanded(
            flex: 3,
            child: Text('RD\$ ${linea.subtotalLinea.toStringAsFixed(2)}', textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFD32F2F)),
              onPressed: () => notificador.quitarProducto(indice),
            ),
          ),
        ],
      ),
    );
  }
}
