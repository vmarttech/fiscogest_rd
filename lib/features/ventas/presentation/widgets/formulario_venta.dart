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
        const Text('Datos de la venta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => notificador.seleccionarCliente(null),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E8EC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF68717D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cliente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B737D))),
                      const SizedBox(height: 2),
                      Text(estado.clienteId != null ? 'Cliente seleccionado' : 'Seleccionar cliente',
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
          onTap: () => notificador.cambiarFormaPago('', false),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E8EC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF68717D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Forma de pago', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B737D))),
                      const SizedBox(height: 2),
                      Text(estado.tipoPago.isNotEmpty
                          ? '${estado.tipoPago[0].toUpperCase()}${estado.tipoPago.substring(1)}${estado.esCredito ? ' (Crédito)' : ''}'
                          : 'Seleccionar forma de pago',
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
}
