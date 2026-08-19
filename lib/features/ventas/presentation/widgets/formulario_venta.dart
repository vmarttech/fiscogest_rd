import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
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
          onTap: () async {
            notificador.seleccionarCliente(1);
          },
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
                      Text(estado.clienteId != null ? 'Cliente ID ${estado.clienteId}' : 'Seleccionar cliente',
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
          onTap: () => _mostrarSelectorFormaPago(context, notificador),
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

  void _mostrarSelectorFormaPago(BuildContext context, RegistrarVentaNotifier notificador) {
    showModalBottomSheet<FormaPago>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: FormaPago.values.map((fp) {
            final credito = fp == FormaPago.credito;
            return ListTile(
              title: Text('${fp.name[0].toUpperCase()}${fp.name.substring(1)}'),
              onTap: () {
                notificador.cambiarFormaPago(fp.name, credito);
                Navigator.pop<FormaPago>(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
