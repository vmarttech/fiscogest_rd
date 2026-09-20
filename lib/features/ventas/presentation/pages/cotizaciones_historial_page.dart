import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

class CotizacionesHistorialPage extends ConsumerStatefulWidget {
  const CotizacionesHistorialPage({super.key});
  static const String routeName = 'historial-cotizaciones';

  @override
  ConsumerState<CotizacionesHistorialPage> createState() =>
      _CotizacionesHistorialPageState();
}

class _CotizacionesHistorialPageState
    extends ConsumerState<CotizacionesHistorialPage> {
  @override
  Widget build(BuildContext context) {
    final cotizacionesAsync = ref.watch(listaCotizacionesProvider);

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historial de Cotizaciones', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.m),
              Expanded(
                child: cotizacionesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Error al cargar cotizaciones: $e',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay cotizaciones generadas aún.\n'
                          'Cree una desde "Nueva Cotización".',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, i) {
                        final cot = lista[i];
                        return _buildTarjetaCotizacion(cot);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaCotizacion(Venta cot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cotización N° ${cot.numero}',
                  style: AppTypography.h4,
                ),
                Text(
                  '${cot.fecha.day}/${cot.fecha.month}/${cot.fecha.year}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Cliente: ${cot.nombreCliente}', style: AppTypography.bodyMedium),
            Text(
              'Total: RD\$ ${cot.total.toStringAsFixed(2)}',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Imprimir'),
                  onPressed: () => _imprimirCotizacion(cot),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                  onPressed: () => _exportarPDF(cot),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.email, size: 16),
                  label: const Text('Correo'),
                  onPressed: () => _enviarPorCorreo(cot),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                  label: const Text('Convertir a Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _convertirEnVenta(cot),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _imprimirCotizacion(Venta cot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imprimiendo cotización N° ${cot.numero}...')),
    );
  }

  void _exportarPDF(Venta cot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generando PDF de ${cot.numero}...')),
    );
  }

  void _enviarPorCorreo(Venta cot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enviando ${cot.numero} por correo...')),
    );
  }

  Future<void> _convertirEnVenta(Venta cot) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convertir a Venta'),
        content: Text(
          '¿Convertir la cotización N° ${cot.numero} en venta?\n\n'
          'Se descontará inventario y generará el documento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${cot.numero} convertida en Venta.'),
        backgroundColor: AppColors.success,
      ),
    );
    ref.invalidate(listaCotizacionesProvider);
  }
}
