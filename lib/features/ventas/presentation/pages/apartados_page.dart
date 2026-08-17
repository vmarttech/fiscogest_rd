import 'package:flutter/material.dart';

class ApartadosPage extends StatelessWidget {

  const ApartadosPage({super.key});
  static const routeName = 'apartados';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apartados')),
      body: const Center(child: Text('Gestión de Apartados')),
    );
  }
}
