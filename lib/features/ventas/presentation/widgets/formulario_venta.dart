import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class FormularioVenta extends ConsumerWidget {
  const FormularioVenta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(registrarVentaProvider);
    final notificador = ref.read(registrarVentaProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTituloSeccion(
          icono: Icons.person_outline_rounded,
          titulo: 'Datos de la venta',
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => notificador.seleccionarCliente(1),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E8EC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 20, color: Color(0xFF68717D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cliente',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B737D))),
                      const SizedBox(height: 2),
                      Text(estado.clienteId != null ? 'Cliente seleccionado' : 'Consumidor final',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF30363D))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9AA2AB)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => notificador.cambiarFormaPago('efectivo', false),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E8EC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 20, color: Color(0xFF68717D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Forma de pago',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B737D))),
                      const SizedBox(height: 2),
                      Text(estado.tipoPago.isNotEmpty
                          ? '${estado.tipoPago[0].toUpperCase()}${estado.tipoPago.substring(1)}${estado.esCredito ? ' (Crédito)' : ''}'
                          : 'Seleccionar',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF30363D))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9AA2AB)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTituloSeccion({required IconData icono, required String titulo}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 18, color: const Color(0xFF1565C0)),
        ),
        const SizedBox(width: 10),
        Text(titulo,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF252A30))),
      ],
    );
  }
}
