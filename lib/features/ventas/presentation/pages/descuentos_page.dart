import 'package:flutter/material.dart';

class DescuentosPage extends StatelessWidget {

  const DescuentosPage({super.key});
  static const routeName = 'descuentos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descuentos')),
      body: const Center(child: Text('Configuración y Listado de Descuentos')),
    );
  }
}
