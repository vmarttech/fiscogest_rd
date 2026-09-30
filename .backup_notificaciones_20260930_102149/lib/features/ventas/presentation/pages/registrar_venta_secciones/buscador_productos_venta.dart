import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
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
    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.allL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar Producto',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controlador,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, código o escanear...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                tooltip: 'Agregar / Ir a inventario',
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
              filled: true,
              fillColor: AppColors.grey50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
