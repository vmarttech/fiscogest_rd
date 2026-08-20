import 'package:flutter/material.dart';

class BuscadorProductosVenta extends StatelessWidget {

  const BuscadorProductosVenta({
    super.key,
    required this.controlador,
    required this.alBuscar,
  });
  final TextEditingController controlador;
  final Future<void> Function(String) alBuscar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controlador,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () {
                    final valor = controlador.text.trim();
                    if (valor.isNotEmpty) alBuscar(valor);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (valor) {
                if (valor.trim().isNotEmpty) alBuscar(valor.trim());
              },
            ),
          ],
        ),
      ),
    );
  }
}
