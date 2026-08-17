import 'package:flutter/material.dart';

class PagarPage extends StatelessWidget {

  const PagarPage({super.key});
  static const routeName = 'pagar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas por Pagar')),
      body: const Center(child: Text('Gestión de Pagos y Compromisos')),
    );
  }
}
