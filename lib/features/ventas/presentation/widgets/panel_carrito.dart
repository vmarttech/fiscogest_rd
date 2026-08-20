import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';

class PanelCarrito extends ConsumerWidget {
  const PanelCarrito({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoLocal = ref.watch(registrarVentaProvider);
    final notificador = ref.read(registrarVentaProvider.notifier);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () {
                    notificador.vaciarVenta();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Venta reiniciada')),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Nueva venta'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF68717D)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const FormularioVenta(),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE6E9ED)),
            const SizedBox(height: 16),
            _buildTotales(estadoLocal),
            const SizedBox(height: 20),
            const _BotonCobrar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotales(dynamic estadoLocal) {
    return Column(
      children: [
        _buildTotalFila('Artículos', '${estadoLocal.detalles.length}'),
        const SizedBox(height: 9),
        _buildTotalFila('Subtotal', 'RD\$ ${estadoLocal.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 9),
        _buildTotalFila('ITBIS', 'RD\$ ${estadoLocal.itbis.toStringAsFixed(2)}'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE3E6EA))),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF20242A)),
                ),
              ),
              Text(
                'RD\$ ${estadoLocal.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalFila(String titulo, String valor) {
    return Row(
      children: [
        Expanded(child: Text(titulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF343A40))),
      ],
    );
  }
}

class _BotonCobrar extends ConsumerStatefulWidget {
  const _BotonCobrar();

  @override
  ConsumerState<_BotonCobrar> createState() => _BotonCobrarState();
}

class _BotonCobrarState extends ConsumerState<_BotonCobrar> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _validarYCobrar,
        icon: _cargando
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : const Icon(Icons.point_of_sale_rounded, size: 20),
        label: Text(_cargando ? 'Registrando venta...' : 'Cobrar y registrar salida'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9EB9D7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _validarYCobrar() {
    final notifier = ref.read(registrarVentaProvider.notifier);
    if (!notifier.validarAntesDeGuardar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa: cliente, forma de pago y al menos un producto.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Validación correcta — listo para guardar')),
    );
  }
}
