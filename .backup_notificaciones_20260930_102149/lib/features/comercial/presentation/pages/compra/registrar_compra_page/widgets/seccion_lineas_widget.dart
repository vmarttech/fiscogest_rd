import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/tipos_linea.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/linea_producto_widget.dart';

class SeccionLineasWidget extends StatelessWidget {
  const SeccionLineasWidget({
    super.key,
    required this.lineas,
    required this.controladores,
    required this.onAgregarLinea,
    required this.onEliminarLinea,
    required this.onSeleccionarProducto,
    required this.onValorCambiado,
    required this.esPequena,
    required this.filaResponsiva,
  });

  final List<DetalleLinea> lineas;
  final List<ControladoresLinea> controladores;
  final VoidCallback onAgregarLinea;
  final void Function(int) onEliminarLinea;
  final void Function(int) onSeleccionarProducto;
  final void Function(int, String) onValorCambiado;
  final bool esPequena;
  final Widget Function({required Widget child1, required Widget child2}) filaResponsiva;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Productos / Líneas', style: AppTypography.h4),
            ElevatedButton.icon(
              onPressed: onAgregarLinea,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        AppLayout.vS,
        if (lineas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No hay productos. Presione "Agregar" para iniciar.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else
          ...lineas.asMap().entries.map((entry) {
            final index = entry.key;
            return LineaProductoWidget(
              index: index,
              linea: lineas[index],
              ctrl: controladores[index],
              onEliminar: () => onEliminarLinea(index),
              onSeleccionarProducto: () => onSeleccionarProducto(index),
              onCantidadChanged: (_) => onValorCambiado(index, 'cantidad'),
              onCostoChanged: (_) => onValorCambiado(index, 'costo'),
              onFleteChanged: (_) => onValorCambiado(index, 'flete'),
              onSeguroChanged: (_) => onValorCambiado(index, 'seguro'),
              onArancelesChanged: (_) => onValorCambiado(index, 'aranceles'),
              onGastosChanged: (_) => onValorCambiado(index, 'gastos'),
              onDescuentoChanged: (_) => onValorCambiado(index, 'descuento'),
              esPequena: esPequena,
              filaResponsiva: filaResponsiva,
            );
          }),
      ],
    );
  }
}
