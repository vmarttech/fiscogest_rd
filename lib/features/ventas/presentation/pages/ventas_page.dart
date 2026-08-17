import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/navegacion_ventas.dart';

class VentasPage extends StatelessWidget {

  const VentasPage({super.key});
  static const routeName = 'ventas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Módulo de Ventas')),
      body: const Row(
        children: [
          NavegacionVentas(),
          Expanded(child: Center(child: Text('Seleccione una opción del menú'))),
        ],
      ),
    );
  }
}
