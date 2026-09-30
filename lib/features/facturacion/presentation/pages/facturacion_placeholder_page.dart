import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';

class FacturacionPlaceholderPage extends StatelessWidget {
  const FacturacionPlaceholderPage({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: titulo.toUpperCase(),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales');
          }
        },
      ),
      body: const Center(
        child: Text(
          'Módulo en construcción (F0)\nDisponible en la siguiente fase.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
