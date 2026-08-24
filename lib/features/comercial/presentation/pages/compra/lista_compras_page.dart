import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';

class ListaComprasPage extends ConsumerWidget {
  const ListaComprasPage({super.key});

  static const String routeName = 'lista-compras';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listarCompras = ref.read(listarComprasUseCaseProvider);

    return AppScaffold(
      title: 'Compras',
      body: FutureBuilder<List<Compra>>(
        future: listarCompras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: AppSpacing.allM,
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          final compras = snapshot.data ?? [];
          if (compras.isEmpty) {
            return const Center(
              child: Padding(
                padding: AppSpacing.allM,
                child: Text('No hay compras registradas.'),
              ),
            );
          }
          return ListView.separated(
            padding: AppSpacing.allM,
            itemCount: compras.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              final compra = compras[index];
              return Card(
                child: ListTile(
                  title: Text('Compra ${compra.numeroComprobante}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Proveedor: ${compra.nombreProveedor}\n'
                    'Fecha: ${compra.fechaEmision.toString().split(' ')[0]} • '
                    'Total: \$${compra.totalCompra.toStringAsFixed(2)}',
                  ),
                  trailing: _buildEstadoTag(compra.estado),
                  onTap: () {
                    context.goNamed(DetalleCompraPage.routeName, pathParameters: {'compraId': compra.id});
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva Compra'),
        onPressed: () {
          context.goNamed(RegistrarCompraPage.routeName);
        },
      ),
    );
  }

  Widget _buildEstadoTag(EstadoCompra estado) {
    Color color;
    String texto;
    switch (estado) {
      case EstadoCompra.borrador:
        color = Colors.orange;
        texto = 'Borrador';
        break;
      case EstadoCompra.confirmada:
        color = Colors.green;
        texto = 'Confirmada';
        break;
      case EstadoCompra.anulada:
        color = Colors.red;
        texto = 'Anulada';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(texto, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
