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

  String _limpiarId(dynamic id) {
    final texto = id.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return texto;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comprasAsync = ref.watch(listadoComprasProvider);
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);

    return AppScaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'nueva_compra',
        onPressed: () => context.goNamed(RegistrarCompraPage.routeName),
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        bottom: true,
        child: comprasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace? _) => Center(
            child: Padding(
              padding: AppLayout.pantallaPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar compras',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          data: (List<Compra> compras) {
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
              itemBuilder: (BuildContext context, int index) {
                final compra = compras[index];
                final idLimpio = _limpiarId(compra.id);
                final numeroComprobante = compra.numeroComprobante;
                final nombreProveedor = compra.nombreProveedor;
                final fechaTexto = compra.fechaEmision.toString().split(' ')[0];
                final total = compra.totalCompra;

                return Card(
                  child: Padding(
                    padding: AppSpacing.allS,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            numeroComprobante.isNotEmpty
                                ? 'Compra $numeroComprobante'
                                : 'Compra sin número',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Proveedor: $nombreProveedor\n'
                            'Fecha: $fechaTexto • Total: \$${total.toStringAsFixed(2)}',
                          ),
                          trailing: _buildEstadoTag(compra.estado),
                          onTap: () {
                            if (idLimpio.isNotEmpty) {
                              context.goNamed(
                                DetalleCompraPage.routeName,
                                pathParameters: {'compraId': idLimpio},
                              );
                            }
                          },
                        ),
                        if (compra.estado == EstadoCompra.borrador)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16, bottom: 8),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Confirmar Compra'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext ctx) => AlertDialog(
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
                                  if (result == true && context.mounted) {
                                    try {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Confirmando compra...')),
                                      );
                                      await confirmarCompra(compra.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Compra confirmada. Inventario y Kardex actualizados.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                      ref.invalidate(listadoComprasProvider);
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
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
