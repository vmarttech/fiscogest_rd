import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';

class BuscadorProductosVenta extends ConsumerWidget {
  const BuscadorProductosVenta({
    super.key,
    required this.controlador,
    this.alBuscar,
    this.alAgregar,
  });

  final TextEditingController controlador;
  final Future<void> Function(String)? alBuscar;
  final Future<void> Function(String)? alAgregar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: AppSpacing.allM,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agregar Producto', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: controlador,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                onPressed: () async {
                  final valor = controlador.text.trim();
                  if (valor.isNotEmpty && alBuscar != null) {
                    await alBuscar!(valor);
                  } else {
                    if (alAgregar != null) {
                      await alAgregar!('');
                    }
                    if (context.mounted) {
                      ref.read(ventasNavegacionProvider.notifier)
                        ..cambiarCategoria(CategoriaProducto.productos)
                        ..cambiarVista(VistaActual.inventario);
                    }
                  }
                },
              ),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (valor) async {
              final texto = valor.trim();
              if (texto.isNotEmpty && alBuscar != null) await alBuscar!(texto);
            },
          ),
        ],
      ),
    );
  }
}
