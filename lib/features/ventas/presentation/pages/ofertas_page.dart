import 'package:flutter/material.dart';

class OfertasPage extends StatelessWidget {

  const OfertasPage({super.key});
  static const routeName = 'ofertas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas y Promociones')),
      body: const Center(child: Text('Gestión de Ofertas y Promociones Comerciales')),
    );
  }
}
