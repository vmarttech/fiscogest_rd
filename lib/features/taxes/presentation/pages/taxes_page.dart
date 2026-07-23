import 'package:flutter/material.dart';

class TaxesPage extends StatelessWidget {
  const TaxesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Impuestos (ITBIS/ISR) - FiscoGest RD 3.0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
