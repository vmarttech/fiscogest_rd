import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';

class ListaComprasPage extends ConsumerWidget {
  const ListaComprasPage({super.key});

  static const String routeName = 'lista-compras';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listarCompras = ref.read(listarComprasUseCaseProvider);
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);

    String limpiarId(dynamic id) {
      final texto = id.toString().replaceAll(RegExp(r'[^0-9]'), '');
      return texto;
    }

    return AppScaffold(
      body: SafeArea(
        bottom: true,
        child: FutureBuilder<List<Compra>>(
          future: listarCompras(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: AppLayout.pantallaPadding,
                  child: Text('Error: ${snapshot.error}'),
                ),
              );
            }

            final compras = snapshot.data ?? [];
            if (compras.isEmpty) {
              return const Center(
                child: Padding(
                  padding: AppLayout.pantallaPadding,
                  child: Text('No hay compras registradas.'),
                ),
              );
            }

            return ListView.separated(
              padding: AppLayout.pantallaPadding,
              itemCount: compras.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, index) {
                final compra = compras[index];
                final idLimpio = limpiarId(compra.id);

                return Card(
                  child: Padding(
                    padding: AppSpacing.allS,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            'Compra ${compra.numeroComprobante}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Proveedor: ${compra.nombreProveedor}\n'
                            'Fecha: ${compra.fechaEmision.toString().split(' ')[0]} • '
                            'Total: \$${compra.totalCompra.toStringAsFixed(2)}',
                          ),
                          trailing: _buildEstadoTag(compra.estado),
                          onTap: () {
                            context.goNamed(
                              DetalleCompraPage.routeName,
                              pathParameters: {'compraId': idLimpio},
                            );
                          },
                        ),
                        if (compra.estado == EstadoCompra.borrador)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                bottom: 8,
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: const Text('Confirmar Compra'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirmar Compra'),
                                      content: const Text(
                                        '¿Confirmar esta compra?\n\n'
                                        'Se actualizará inventario, se registrará movimiento en Kardex,\n'
                                        'se actualizarán costos de producto y se actualizará el saldo del proveedor.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Sí, Confirmar'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmar == true && context.mounted) {
                                    try {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Confirmando compra...'),
                                        ),
                                      );

                                      await confirmarCompra(compra.id);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✅ Compra confirmada. Inventario y Kardex actualizados.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }

                                      ref.invalidate(listarComprasUseCaseProvider);
                                      ref.invalidate(productoControllerProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error al confirmar: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'nueva_compra',
        onPressed: () {
          context.goNamed(RegistrarCompraPage.routeName);
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEstadoTag(EstadoCompra estado) {
    final Color color;
    final String texto;

    switch (estado) {
      case EstadoCompra.borrador:
        color = Colors.orange;
        texto = 'Borrador';
        break;
      case EstadoCompra.registrada:
        color = Colors.blue;
        texto = 'Registrada';
        break;
      case EstadoCompra.confirmada:
        color = Colors.green;
        texto = 'Confirmada';
        break;
      case EstadoCompra.recibida:
        color = Colors.teal;
        texto = 'Recibida';
        break;
      case EstadoCompra.pagada:
        color = Colors.purple;
        texto = 'Pagada';
        break;
      case EstadoCompra.vencida:
        color = Colors.amber.shade700;
        texto = 'Vencida';
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
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
