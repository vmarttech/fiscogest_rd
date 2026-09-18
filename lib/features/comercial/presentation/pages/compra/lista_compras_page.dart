import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';

class ListaComprasPage extends ConsumerWidget {
  const ListaComprasPage({super.key});
  static const String routeName = 'lista-compras';

  String _limpiarId(dynamic id) => id.toString().replaceAll(RegExp(r'[^0-9]'), '');
  String _formatearFecha(DateTime fecha) => fecha.toString().split(' ')[0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comprasAsync = ref.watch(listadoComprasProvider);
    final confirmarCompra = ref.read(confirmarCompraUseCaseProvider);
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 768;

    Widget infoItem(String etiqueta, String valor, {bool destacado = false}) {
      return RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$etiqueta: ',
              style: TextStyle(
                fontSize: 12,
                color: destacado ? Colors.red.shade700 : Colors.grey.shade600,
              ),
            ),
            TextSpan(
              text: valor,
              style: TextStyle(
                fontSize: 12,
                fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
                color: destacado ? Colors.red.shade700 : null,
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Compras',
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva_compra',
        onPressed: () => context.goNamed(RegistrarCompraPage.routeName),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Compra', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        bottom: true,
        child: comprasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
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
          data: (compras) {
            if (compras.isEmpty) {
              return const Center(
                child: Padding(
                  padding: AppLayout.pantallaPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay compras registradas.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Presiona el botón "+" para registrar tu primera compra.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: AppLayout.pantallaPadding,
              itemCount: compras.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, index) {
                final compra = compras[index];
                final idLimpio = _limpiarId(compra.id);
                final vencida = compra.estaVencida;

                Widget buildEstadoTag() {
                  if (vencida && compra.estado == EstadoCompra.registrada) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Vencida',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  final (color, texto) = switch (compra.estado) {
                    EstadoCompra.borrador => (Colors.orange, 'Borrador'),
                    EstadoCompra.registrada when !vencida => (Colors.blue, 'Registrada'),
                    EstadoCompra.registrada => (Colors.red, 'Vencida'),
                    EstadoCompra.confirmada => (Colors.green, 'Confirmada'),
                    EstadoCompra.recibida => (Colors.teal, 'Recibida'),
                    EstadoCompra.pagada => (Colors.purple, 'Pagada'),
                    EstadoCompra.anulada => (Colors.red.shade700, 'Anulada'),
                    _ => (Colors.grey, 'Desconocida'),
                  };
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

                void verDetalle() {
                  if (idLimpio.isNotEmpty) {
                    context.goNamed(
                      DetalleCompraPage.routeName,
                      pathParameters: {'compraId': idLimpio},
                    );
                  }
                }

                Future<void> confirmar() async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar Compra'),
                      content: const Text(
                        '¿Confirmar esta compra?\n\n'
                        'Se actualizará inventario, Kardex, costos de producto '
                        'y el saldo del proveedor.',
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
                  if (confirmar != true || !context.mounted) return;

                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Confirmando compra...')),
                    );
                    await confirmarCompra(compra.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compra confirmada ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    ref.invalidate(listadoComprasProvider);
                    ref.invalidate(productoControllerProvider);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }

                return Card(
                  elevation: vencida ? 2 : 1,
                  color: vencida ? Colors.red.shade50 : null,
                  child: Padding(
                    padding: AppSpacing.allM,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    compra.numeroComprobante.isNotEmpty
                                        ? compra.numeroComprobante
                                        : 'Compra #${compra.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    compra.nombreProveedor,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            buildEstadoTag(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            infoItem('Fecha', _formatearFecha(compra.fechaEmision)),
                            if (compra.ncf.isNotEmpty) infoItem('NCF', compra.ncf),
                            infoItem('Tipo', compra.tipoComprobante),
                            infoItem('Pago', compra.esCredito ? 'Crédito' : 'Contado'),
                            if (compra.esCredito)
                              infoItem(
                                compra.diasCredito > 0 ? 'Plazo' : 'Vence',
                                compra.fechaVencimientoCalculada != null
                                    ? _formatearFecha(compra.fechaVencimientoCalculada!)
                                    : '${compra.diasCredito} días',
                                destacado: vencida,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: RD\$ ${compra.totalCompra.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (!esPequena)
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('Ver'),
                                    onPressed: verDetalle,
                                  ),
                                  if (compra.estado == EstadoCompra.borrador) ...[
                                    const SizedBox(width: 4),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Confirmar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: confirmar,
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                        if (esPequena)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.visibility, size: 16),
                                    label: const Text('Ver Detalle'),
                                    onPressed: verDetalle,
                                  ),
                                ),
                                if (compra.estado == EstadoCompra.borrador) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Confirmar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: confirmar,
                                    ),
                                  ),
                                ],
                              ],
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
}
