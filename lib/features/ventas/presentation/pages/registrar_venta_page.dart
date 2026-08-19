import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';

class RegistrarVentaPage extends ConsumerStatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = 'registrar-ventas';

  @override
  ConsumerState<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends ConsumerState<RegistrarVentaPage> {
  bool _guardando = false;

  Future<void> _procesarGuardado() async {
    final notificador = ref.read(registrarVentaProvider.notifier);
    final estado = ref.read(registrarVentaProvider);

    if (!notificador.validarAntesDeGuardar()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete cliente, forma de pago y al menos un producto')),
        );
      }
      return;
    }

    setState(() => _guardando = true);

    try {
      final venta = Venta(
        numero: estado.numero,
        clienteId: estado.clienteId!,
        usuarioId: estado.usuarioId!,
        fecha: DateTime.now(),
        detalles: estado.detalles,
        subtotal: estado.subtotal,
        itbis: estado.itbis,
        total: estado.total,
        tipoPago: estado.tipoPago,
        esCredito: estado.esCredito,
      );

      final casoUso = ref.read(registrarVentaUseCaseProvider);
      final ventaGuardada = await casoUso(venta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta registrada. ID: ${ventaGuardada.id}')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC62828),
            content: Text('Error al guardar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registrarVentaProvider);
    final bool esDesktop = MediaQuery.of(context).size.width >= 950;

    return AppScaffold(
      title: 'Registrar Venta',
      body: LayoutBuilder(
        builder: (context, restricciones) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              esDesktop ? 28 : 16,
              20,
              esDesktop ? 28 : 16,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEncabezado(esDesktop, estado.numero),
                const SizedBox(height: 20),
                const FormularioVenta(),
                const SizedBox(height: 24),
                if (esDesktop)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: PanelProductos()),
                      SizedBox(width: 20),
                      Expanded(flex: 5, child: PanelCarrito()),
                    ],
                  )
                else ...const [
                  PanelProductos(),
                  SizedBox(height: 16),
                  PanelCarrito(),
                ],
                const SizedBox(height: 24),
                _buildBotonGuardado(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEncabezado(bool esDesktop, String numeroVenta) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: esDesktop ? 22 : 18,
        vertical: esDesktop ? 18 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E7ED)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: esDesktop ? 48 : 44,
            height: esDesktop ? 48 : 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF1565C0), size: 25),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva venta',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF20242A))),
                Text('Agrega productos y completa los datos',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E6EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('N.º VENTA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .7, color: Color(0xFF71717A))),
                const SizedBox(height: 2),
                Text(numeroVenta,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonGuardado() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _guardando ? null : _procesarGuardado,
        icon: _guardando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(_guardando ? 'Guardando...' : 'Guardar Venta', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9EB9D7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
