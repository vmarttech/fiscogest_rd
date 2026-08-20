import 'package:flutter/material.dart';

class PanelProductos extends StatelessWidget {

  const PanelProductos({
    super.key,
    required this.controlador,
    required this.alAgregar,
  });
  final TextEditingController controlador;
  final Future<void> Function(String) alAgregar;

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
                    if (valor.isNotEmpty) alAgregar(valor);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (valor) {
                if (valor.trim().isNotEmpty) alAgregar(valor.trim());
              },
            ),
          ],
        ),
      ),
    );
  }
}
