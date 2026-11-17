
import 'dart:io';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/gastronomia/domain/entities/gastronomia_entities.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/providers/gastronomia_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fiscogest_rd/features/gastronomia/presentation/pdf/comprobante_rapido_pdf.dart';

class VentaRapidaPage extends ConsumerStatefulWidget {
  const VentaRapidaPage({super.key});
  static const routeName = 'venta-rapida-gastro';
  @override
  ConsumerState<VentaRapidaPage> createState() => _VentaRapidaPageState();
}

class _VentaRapidaPageState extends ConsumerState<VentaRapidaPage> {
  int? _categoriaId;
  bool _ocupado = false;
  String _formaPago = 'efectivo';
  double _descuento = 0;
  double _propina = 0;
  String _busqueda = '';
  final _busquedaCtrl = TextEditingController();

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _productosMenu(AppDatabase db) async {
    final productosQuery = db.select(db.productosTable)
      ..where((t) => t.activo.equals(1));
    final cat = _categoriaId;
    if (cat != null) {
      productosQuery.where((t) => t.categoriaId.equals(cat));
    }
    final productos = await productosQuery.get();
    final ids = productos.map((p) => p.id).toList();
    final metaMap =
        await ref.read(gastronomiaServiceProvider).metaDeProductos(ids);
    final resultado = <Map<String, dynamic>>[];
    for (final p in productos) {
      final m = metaMap[p.id];
      // Solo menú gastronómico disponible (no disponibles no se ofrecen a la venta)
      if (m == null || !m.esGastronomico || !m.disponibleMenu) continue;
      resultado.add({'producto': p, 'meta': m});
    }
    // Destacados primero, luego nombre
    resultado.sort((a, b) {
      final ma = a['meta'] as ProductoGastroMeta;
      final mb = b['meta'] as ProductoGastroMeta;
      if (ma.destacado != mb.destacado) {
        return ma.destacado ? -1 : 1;
      }
      final pa = a['producto'] as ProductoData;
      final pb = b['producto'] as ProductoData;
      return pa.nombre.toLowerCase().compareTo(pb.nombre.toLowerCase());
    });
    return resultado;
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> item) async {
    final p = item['producto'] as ProductoData;
    final extras = await ref.read(gastronomiaServiceProvider).extrasDeProducto(p.id);
    List<ExtraGastronomico> seleccionados = [];
    if (extras.isNotEmpty && mounted) {
      seleccionados = await showModalBottomSheet<List<ExtraGastronomico>>(
            context: context,
            builder: (ctx) => _ExtrasSheet(extras: extras),
          ) ??
          [];
    }
    if (!mounted) return;
    ref.read(carritoGastroProvider.notifier).agregar(LineaCarritoGastro(
          productoId: p.id, nombre: p.nombre,
          precioUnitario: p.precioVenta ?? 0.0, extras: seleccionados));
  }

  Future<void> _checkout() async {
    final lineas = ref.read(carritoGastroProvider);
    if (lineas.isEmpty || _ocupado) return;
    setState(() => _ocupado = true);
    try {
      final subtotal = ref.read(carritoGastroProvider.notifier).subtotal;
      final desc = _descuento.clamp(0.0, subtotal);
      final base = double.parse((subtotal - desc).toStringAsFixed(2));
      const tasa = 0.18;
      final itbis = double.parse((base * tasa).toStringAsFixed(2));
      final propina = _propina;
      final total = double.parse((base + itbis + propina).toStringAsFixed(2));
      final detalles = lineas
          .map((l) => DetalleVenta(
                productoId: l.productoId,
                cantidad: l.cantidad,
                precioUnitario: l.precioUnitario + l.precioExtras,
                subtotal: l.subtotal,
                nombreProducto: l.nombre,
                tasaImpuesto: tasa,
              ))
          .toList();
      final estado = RegistrarVentaState(
        usuarioId: (ref.read(sesionUsuarioIdProvider) ?? 1),
        clienteId: 0,
        clienteNombre: 'Consumidor Final',
        tipoPago: _formaPago,
        esCredito: false,
        abonoInicial: total,
        detalles: detalles,
        subtotal: subtotal,
        itbis: itbis,
        costoEnvio: 0,
        total: total,
        montoDescuento: desc,
      );
      final venta = await ref.read(registrarVentaUseCaseProvider).ejecutar(estado);
      final ventaId = venta.id;
      if (ventaId == null || ventaId <= 0) {
        throw Exception('La venta se creó pero no devolvió un ID válido');
      }
      await ref.read(gastronomiaServiceProvider).registrarCajaYPedido(
        ventaId: ventaId,
        monto: total,
        formaPago: _formaPago,
        pedido: PedidoGastronomia(
          tipo: 'local',
          estado: 'confirmado',
          nombreCliente: 'Consumidor Final',
          subtotal: subtotal,
          itbis: itbis,
          total: total,
          propina: propina,
          formaPago: _formaPago,
          ventaId: ventaId,
          usuarioId: (ref.read(sesionUsuarioIdProvider) ?? 1),
        ),
        lineas: lineas,
      );
      await ref.read(gastronomiaServiceProvider).marcarVentaFacturada(ventaId);

      ref.read(carritoGastroProvider.notifier).limpiar();
      if (mounted) {
        setState(() { _descuento = 0; _propina = 0; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta registrada #$ventaId · RD\$ ${total.toStringAsFixed(2)}')));
        try {
          await ComprobanteRapidoPdf.compartir(
            ventaId: ventaId,
            lineas: lineas,
            subtotal: subtotal,
            descuento: desc,
            itbis: itbis,
            propina: propina,
            total: total,
            formaPago: _formaPago,
          );
        } catch (e) {
          // Si falla el PDF, al menos mostramos el texto como respaldo
          final texto = _textoComprobante(
            ventaId: ventaId,
            lineas: lineas,
            subtotal: subtotal,
            descuento: desc,
            itbis: itbis,
            total: total,
            formaPago: _formaPago,
          );
          await Share.share(texto);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _textoComprobante({
    required int ventaId,
    required List<LineaCarritoGastro> lineas,
    required double subtotal,
    required double descuento,
    required double itbis,
    required double total,
    required String formaPago,
  }) {
    final b = StringBuffer();
    b.writeln('FISCOGEST RD · Venta rápida');
    b.writeln('Venta #$ventaId · ${DateTime.now().toString().substring(0, 16)}');
    b.writeln('Cliente: Consumidor Final');
    b.writeln('--------------------------------');
    for (final l in lineas) {
      final extras = l.extras.isNotEmpty
          ? ' (+${l.extras.map((e) => e.nombre).join(', ')})'
          : '';
      b.writeln('${l.cantidad.toInt()} x ${l.nombre}$extras');
      b.writeln('    RD\$ ${l.subtotal.toStringAsFixed(2)}');
    }
    b.writeln('--------------------------------');
    b.writeln('Subtotal:  RD\$ ${subtotal.toStringAsFixed(2)}');
    if (descuento > 0) {
      b.writeln('Descuento: -RD\$ ${descuento.toStringAsFixed(2)}');
    }
    b.writeln('ITBIS 18%: RD\$ ${itbis.toStringAsFixed(2)}');
    b.writeln('TOTAL:     RD\$ ${total.toStringAsFixed(2)}');
    b.writeln('Pago: ${_etiquetaFormaPago(formaPago)}');
    b.writeln('¡Gracias por su compra!');
    return b.toString();
  }

  static String _etiquetaFormaPago(String fp) {
    switch (fp) {
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      case 'cheque':
        return 'Cheque';
      default:
        return 'Efectivo';
    }
  }

  Future<void> _editarDescuento() async {
    final ctrl = TextEditingController(
        text: _descuento > 0 ? _descuento.toStringAsFixed(2) : '');
    final res = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descuento de la venta'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Monto en RD\$', prefixText: 'RD\$ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 0.0),
              child: const Text('Quitar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
                Navigator.pop(ctx, v < 0 ? 0.0 : v);
              },
              child: const Text('Aplicar')),
        ],
      ),
    );
    if (res == null) return;
    setState(() => _descuento = res);
  }

  Future<void> _editarPropina() async {
    final ctrl = TextEditingController(text: _propina > 0 ? _propina.toStringAsFixed(2) : '');
    final res = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Propina'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Monto en RD\$', prefixText: 'RD\$ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 0.0), child: const Text('Quitar')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
                Navigator.pop(ctx, v < 0 ? 0.0 : v);
              },
              child: const Text('Aplicar')),
        ],
      ),
    );
    if (res == null) return;
    setState(() => _propina = res);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final carrito = ref.watch(carritoGastroProvider);
    final subtotal = ref.read(carritoGastroProvider.notifier).subtotal;
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')), title: const Text('Venta Rápida · Gastronomía'), actions: [
        IconButton(
          tooltip: 'Catálogo',
          icon: const Icon(Icons.menu_book),
          onPressed: () => context.push('/gastronomia/catalogo'),
        ),
        IconButton(
          tooltip: 'Enviar carrito a Delivery',
          icon: const Icon(Icons.delivery_dining),
          onPressed: () {
            final n = ref.read(carritoGastroProvider).length;
            if (n == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agrega productos al carrito primero')),
              );
              return;
            }
            context.push('/gastronomia/delivery');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Carrito con $n ítem(s). Usa «Nuevo pedido» para completar datos.')),
            );
          },
        ),
      ]),
      body: LayoutBuilder(builder: (ctx, constraints) {
        final ancho = constraints.maxWidth;
        final panelLateral = ancho >= 700;
        final productosArea = Column(children: [
          // Búsqueda rápida
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: _busquedaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => setState(() => _busqueda = v.trim()),
            ),
          ),
          SizedBox(
            height: 48,
            child: _CategoriasChips(
              onSelect: (id) => setState(() => _categoriaId = id),
              seleccionado: _categoriaId,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _productosMenu(db),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var items = snap.data!;
                // Filtro por texto de búsqueda (nombre)
                if (_busqueda.isNotEmpty) {
                  final q = _busqueda.toLowerCase();
                  items = items.where((it) {
                    final p = it['producto'] as ProductoData;
                    return p.nombre.toLowerCase().contains(q);
                  }).toList();
                }
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _busqueda.isNotEmpty
                                ? Icons.search_off
                                : Icons.restaurant_menu,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _busqueda.isNotEmpty
                                ? 'Sin resultados para "$_busqueda"'
                                : (_categoriaId != null
                                    ? 'No hay productos en esta categoría'
                                    : 'Sin productos en el menú'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _busqueda.isNotEmpty
                                ? 'Prueba otro nombre o limpia la búsqueda'
                                : 'Marca productos como gastronómicos y disponibles\nen Catálogo Gastro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_busqueda.isEmpty) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/gastronomia/catalogo'),
                              icon: const Icon(Icons.menu_book, size: 18),
                              label: const Text('Ir al catálogo'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ancho >= 1000 ? 6 : ancho >= 700 ? 5 : ancho >= 480 ? 4 : 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final p = items[i]['producto'] as ProductoData;
                    final m = items[i]['meta'] as ProductoGastroMeta;
                    return InkWell(
                      onTap: () => _agregarAlCarrito(items[i]),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  m.fotoPath.isNotEmpty &&
                                          File(m.fotoPath).existsSync()
                                      ? Image.file(File(m.fotoPath),
                                          fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.restaurant,
                                              size: 48, color: Colors.grey),
                                        ),
                                  if (m.destacado)
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade700,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star,
                                                size: 12, color: Colors.white),
                                            SizedBox(width: 2),
                                            Text(
                                              'Destacado',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'RD\$ ${(p.precioVenta ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
        ]);
        final cartPanel = _CarritoPanel(
          expandir: panelLateral,
          lineas: carrito, subtotal: subtotal, ocupado: _ocupado,
          descuento: _descuento,
          propina: _propina,
          formaPago: _formaPago,
          onQuitar: (i) => ref.read(carritoGastroProvider.notifier).quitar(i),
          onCantidad: (i, d) => ref.read(carritoGastroProvider.notifier).cambiarCantidad(i, d),
          onFormaPago: (v) => setState(() => _formaPago = v),
          onEditarDescuento: _editarDescuento,
          onEditarPropina: _editarPropina,
          onCheckout: _checkout);
        if (panelLateral) {
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 320, child: cartPanel),
            Expanded(child: productosArea),
          ]);
        }
        return Column(children: [
          Expanded(child: productosArea),
          if (carrito.isNotEmpty) cartPanel,
        ]);
      }),
    );
  }
}

class _CategoriasChips extends ConsumerWidget {
  const _CategoriasChips({required this.onSelect, required this.seleccionado});
  final void Function(int?) onSelect;
  final int? seleccionado;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return FutureBuilder<List<CategoriaData>>(
      future: (db.select(db.categorias)..where((t) => t.activo.equals(true))).get(),
      builder: (ctx, snap) {
        final cats = snap.data ?? [];
        return ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: [
          Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: const Text('Todas'), selected: seleccionado == null,
                onSelected: (_) => onSelect(null))),
          for (final c in cats)
            Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(c.nombre), selected: seleccionado == c.id,
                  onSelected: (_) => onSelect(c.id))),
        ]);
      });
  }
}

class _CarritoPanel extends StatelessWidget {
  const _CarritoPanel({
    required this.lineas,
    required this.subtotal,
    required this.ocupado,
    required this.descuento,
    required this.formaPago,
    required this.onFormaPago,
    required this.onEditarDescuento,
    required this.propina,
    required this.onEditarPropina,
    required this.onQuitar,
    required this.onCantidad,
    required this.onCheckout,
    this.expandir = false,
  });
  final List<LineaCarritoGastro> lineas;
  final double subtotal;
  final bool ocupado;
  final bool expandir;
  final double descuento;
  final String formaPago;
  final void Function(String) onFormaPago;
  final VoidCallback onEditarDescuento;
  final double propina;
  final VoidCallback onEditarPropina;
  final void Function(int) onQuitar;
  final void Function(int, double) onCantidad;
  final VoidCallback onCheckout;

  static const _formasPago = [
    ['efectivo', 'Efectivo'],
    ['tarjeta', 'Tarjeta'],
    ['transferencia', 'Transferencia'],
    ['cheque', 'Cheque'],
  ];

  @override
  Widget build(BuildContext context) {
    final base = (subtotal - descuento).clamp(0.0, double.infinity);
    final itbis = double.parse((base * 0.18).toStringAsFixed(2));
    final total = double.parse((base + itbis + propina).toStringAsFixed(2));
    return Container(
      color: Colors.grey.shade100,
      constraints: expandir
          ? const BoxConstraints.expand()
          : const BoxConstraints(maxHeight: 380),
      child: Column(children: [
        Expanded(child: lineas.isEmpty
            ? const Center(child: Text('Carrito vacío\nTocá un producto para agregarlo',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
            : ListView.builder(itemCount: lineas.length, itemBuilder: (ctx, i) {
          final l = lineas[i];
          return ListTile(
            dense: true,
            title: Text(l.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('RD\$ ${l.subtotal.toStringAsFixed(2)}'
                '${l.extras.isNotEmpty ? ' · +${l.extras.length} extra(s)' : ''}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onCantidad(i, -1)),
              Text('${l.cantidad.toInt()}'),
              IconButton(icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onCantidad(i, 1)),
              IconButton(icon: const Icon(Icons.delete_outline),
                  onPressed: () => onQuitar(i)),
            ]),
          );
        })),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Wrap(spacing: 6, runSpacing: 2, children: [
            for (final f in _formasPago)
              ChoiceChip(
                label: Text(f[1], style: const TextStyle(fontSize: 12)),
                selected: formaPago == f[0],
                onSelected: (_) => onFormaPago(f[0]),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(children: [
            OutlinedButton.icon(
              onPressed: onEditarDescuento,
              icon: const Icon(Icons.discount_outlined, size: 16),
              label: Text(
                  descuento > 0
                      ? 'Descuento -RD\$ ${descuento.toStringAsFixed(2)}'
                      : 'Descuento',
                  style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onEditarPropina,
              icon: const Icon(Icons.room_service_outlined, size: 16),
              label: Text(propina > 0 ? 'Propina RD\$ ${propina.toStringAsFixed(2)}' : 'Propina', style: const TextStyle(fontSize: 12)),
            ),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Subtotal: RD\$ ${subtotal.toStringAsFixed(2)}'),
              if (descuento > 0)
                Text('Descuento: -RD\$ ${descuento.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green)),
              Text('ITBIS: RD\$ ${itbis.toStringAsFixed(2)}'),
              if (propina > 0)
                Text('Propina: RD\$ ${propina.toStringAsFixed(2)}'),
              Text('TOTAL: RD\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            FilledButton.icon(
                onPressed: (ocupado || lineas.isEmpty) ? null : onCheckout,
                icon: ocupado
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.point_of_sale),
                label: const Text('Cobrar')),
          ])),
      ]),
    );
  }
}

class _ExtrasSheet extends StatefulWidget {
  const _ExtrasSheet({required this.extras});
  final List<ExtraGastronomico> extras;
  @override
  State<_ExtrasSheet> createState() => _ExtrasSheetState();
}
class _ExtrasSheetState extends State<_ExtrasSheet> {
  final _sel = <int>{};
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('Agregar extras',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ...widget.extras.map((e) => CheckboxListTile(
            title: Text(e.nombre),
            subtitle: Text('+RD\$ ${e.precio.toStringAsFixed(2)}'),
            value: _sel.contains(e.id),
            onChanged: (v) => setState(() => v == true ? _sel.add(e.id) : _sel.remove(e.id)),
          )),
      Padding(padding: const EdgeInsets.all(16),
        child: FilledButton(onPressed: () => Navigator.pop(context,
            widget.extras.where((e) => _sel.contains(e.id)).toList()),
          child: const Text('Agregar al pedido'))),
    ]));
  }
}
