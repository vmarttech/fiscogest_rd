import 'package:flutter/material.dart';

class CotizacionesPage extends StatelessWidget {

  const CotizacionesPage({super.key});
  static const routeName = 'cotizaciones';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cotizaciones')),
      body: const Center(child: Text('Listado y Gestión de Cotizaciones')),
    );
  }
}
