import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

typedef AgregarProductoCallback = Future<void> Function(Producto producto, double cantidad);

class PanelProductos extends ConsumerStatefulWidget {
  const PanelProductos({
    super.key,
    required this.alAgregar,
  });

  final AgregarProductoCallback alAgregar;

  @override
  ConsumerState<PanelProductos> createState() => _PanelProductosState();
}

class _PanelProductosState extends ConsumerState<PanelProductos> {
  final TextEditingController _buscador = TextEditingController();
  List<Producto> _resultados = [];
  String _ultimoTexto = '';

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    final limpio = texto.trim().toLowerCase();
    if (limpio == _ultimoTexto) return;
    _ultimoTexto = limpio;

    final todos = ref.read(productoControllerProvider);
    setState(() {
      _resultados = todos.maybeWhen(
        data: (lista) => lista
            .where((p) => p.activo && p.nombre.toLowerCase().contains(limpio))
            .toList(),
        orElse: () => <Producto>[],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _buscador,
          decoration: const InputDecoration(
            hintText: 'Buscar producto por nombre...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: _buscar,
        ),
        const SizedBox(height: AppSpacing.s),
        productosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Error al cargar productos: $e',
            style: const TextStyle(color: AppColors.error),
          ),
          data: (_) {
            final lista = _resultados;
            if (_buscador.text.trim().isEmpty) {
              return const Text(
                'Escriba para buscar productos del inventario',
                style: AppTypography.bodySmall,
              );
            }
            if (lista.isEmpty) {
              return const Text(
                'No se encontraron productos',
                style: AppTypography.bodySmall,
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final prod = lista[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    title: Text(prod.nombre),
                    subtitle: Text(
                      'Precio: ${formatRd(prod.precioVenta)}'
                      '${prod.stock != null ? ' • Stock: ${prod.stock}' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => widget.alAgregar(prod, 1.0),
                      child: const Text('Agregar'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
