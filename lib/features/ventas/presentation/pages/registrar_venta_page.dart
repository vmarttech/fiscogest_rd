import 'package:flutter/material.dart';

class RegistrarVentaPage extends StatelessWidget {

  const RegistrarVentaPage({super.key});
  static const routeName = 'registrar-venta';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venta')),
      body: const Center(child: Text('Formulario de Registro de Venta')),
    );
  }
}
