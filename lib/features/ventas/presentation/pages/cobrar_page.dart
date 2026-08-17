import 'package:flutter/material.dart';

class CobrarPage extends StatelessWidget {

  const CobrarPage({super.key});
  static const routeName = 'cobrar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas por Cobrar')),
      body: const Center(child: Text('Gestión de Créditos y Cobros')),
    );
  }
}
