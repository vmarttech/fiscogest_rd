import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/detalle_compra_page.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

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

                Future<void> duplicar() async {
                  try {
                    final repo = ref.read(compraRepositoryProvider);
                    final detalles = await repo.listarDetallesDeCompra(compra.id);
                    final ahora = DateTime.now();
                    final nuevoId = ahora.millisecondsSinceEpoch;

                    final nuevaCompra = compra.copyWith(
                      id: nuevoId,
                      numeroComprobante: '${compra.numeroComprobante}-COPIA',
                      estado: EstadoCompra.borrador,
                      fechaEmision: ahora,
                      fechaConfirmacion: null,
                      creadoEn: ahora,
                      actualizadoEn: null,
                      observaciones: 'Duplicado de #${compra.id}',
                    );

                    final nuevosDetalles = <DetalleCompra>[];
                    for (var i = 0; i < detalles.length; i++) {
                      final d = detalles[i];
                      nuevosDetalles.add(
                        d.copyWith(
                          id: nuevoId * 1000 + i,
                          compraId: nuevoId,
                        ),
                      );
                    }

                    await repo.registrarCompra(
                      compra: nuevaCompra,
                      detalles: nuevosDetalles,
                    );

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compra duplicada como borrador ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    ref.invalidate(listadoComprasProvider);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al duplicar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }

                Future<void> imprimir() async {
                  final buffer = StringBuffer();
                  buffer.writeln('══════════════════════════════════');
                  buffer.writeln('       COMPROBANTE DE COMPRA');
                  buffer.writeln('══════════════════════════════════');
                  buffer.writeln('Nº: ${compra.numeroComprobante.isNotEmpty ? compra.numeroComprobante : compra.id}');
                  buffer.writeln('Fecha: ${_formatearFecha(compra.fechaEmision)}');
                  buffer.writeln('Proveedor: ${compra.nombreProveedor}');
                  if (compra.ncf.isNotEmpty) buffer.writeln('NCF: ${compra.ncf}');
                  buffer.writeln('Tipo: ${compra.tipoComprobante}');
                  buffer.writeln('Pago: ${compra.esCredito ? 'Crédito (${compra.diasCredito} días)' : 'Contado'}');
                  buffer.writeln('Estado: ${compra.estado.name}');
                  buffer.writeln('──────────────────────────────────');
                  buffer.writeln('Subtotal:  RD\$ ${compra.subtotalSinImpuestos.toStringAsFixed(2)}');
                  buffer.writeln('Descuento: RD\$ ${compra.montoDescuentoGlobal.toStringAsFixed(2)}');
                  buffer.writeln('ITBIS:     RD\$ ${compra.montoImpuesto.toStringAsFixed(2)}');
                  buffer.writeln('TOTAL:     RD\$ ${compra.totalCompra.toStringAsFixed(2)}');
                  buffer.writeln('══════════════════════════════════');
                  buffer.writeln('FiscoGest RD');

                  await Share.share(
                    buffer.toString(),
                    subject: 'Compra ${compra.numeroComprobante.isNotEmpty ? compra.numeroComprobante : '#${compra.id}'}',
                  );
                }

                Future<void> anular() async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Anular Compra'),
                      content: const Text('¿Anular esta compra?\n\nEsta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sí, Anular'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                  try {
                    await ref.read(compraRepositoryProvider).anularCompra(compra.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compra anulada ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    ref.invalidate(listadoComprasProvider);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                            // MENÚ DE ACCIONES
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'ver':
                                    verDetalle();
                                    break;
                                  case 'editar':
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Edición de borradores: próximamente (requiere precarga en RegistrarCompraPage)',
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'duplicar':
                                    await duplicar();
                                    break;
                                  case 'imprimir':
                                    await imprimir();
                                    break;
                                  case 'confirmar':
                                    await confirmar();
                                    break;
                                  case 'anular':
                                    await anular();
                                    break;
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'ver',
                                  child: ListTile(
                                    leading: Icon(Icons.visibility, size: 20),
                                    title: Text('Ver'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                if (compra.estado == EstadoCompra.borrador)
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: ListTile(
                                      leading: Icon(Icons.edit, size: 20),
                                      title: Text('Editar'),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'duplicar',
                                  child: ListTile(
                                    leading: Icon(Icons.copy, size: 20),
                                    title: Text('Duplicar'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'imprimir',
                                  child: ListTile(
                                    leading: Icon(Icons.print, size: 20),
                                    title: Text('Imprimir'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                if (compra.estado == EstadoCompra.borrador)
                                  const PopupMenuItem(
                                    value: 'confirmar',
                                    child: ListTile(
                                      leading: Icon(Icons.check_circle, size: 20, color: Colors.green),
                                      title: Text('Confirmar'),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                if (compra.estado != EstadoCompra.anulada &&
                                    compra.estado != EstadoCompra.borrador)
                                  const PopupMenuItem(
                                    value: 'anular',
                                    child: ListTile(
                                      leading: Icon(Icons.cancel, size: 20, color: Colors.red),
                                      title: Text('Anular'),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                              ],
                            ),
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
                              TextButton.icon(
                                icon: const Icon(Icons.visibility, size: 16),
                                label: const Text('Ver'),
                                onPressed: verDetalle,
                              ),
                          ],
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
