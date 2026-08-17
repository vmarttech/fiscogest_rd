import 'package:flutter/material.dart';

class DevolucionesPage extends StatelessWidget {

  const DevolucionesPage({super.key});
  static const routeName = 'devoluciones';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devoluciones')),
      body: const Center(child: Text('Registro y Consulta de Devoluciones')),
    );
  }
}
