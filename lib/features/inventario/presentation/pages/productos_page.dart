import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
import 'package:fiscogest_rd/features/categorias/presentation/pages/categorias_page.dart';
import 'package:fiscogest_rd/features/marcas/presentation/pages/marcas_page.dart';
import 'package:fiscogest_rd/features/unidades/presentation/pages/unidades_page.dart';
import 'package:fiscogest_rd/features/inventario/domain/enums/tipo_movimiento.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroProductos = '';
  String _filtroKardex = '';
  TipoMovimiento? _filtroTipoKardex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Gestión Integral de Inventario'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined, color: Colors.white, size: 22),
            tooltip: 'Ajustes de Inventario',
            onPressed: () => context.pushNamed('lista-ajustes'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelColor: Colors.white70,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Kardex'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Categorías'),
            Tab(icon: Icon(Icons.branding_watermark_outlined), text: 'Marcas'),
            Tab(icon: Icon(Icons.straighten_outlined), text: 'Unidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeccionProductos(context),
          _buildSeccionKardex(context),
          const CategoriasPage(),
          const MarcasPage(),
          const UnidadesPage(),
        ],
      ),
    );
  }

  Widget _buildSeccionProductos(BuildContext context) {
    final AsyncValue<List<Producto>> productosAsync = ref.watch(productoControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Listado General de Productos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => context.push('/productos/nuevo'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (String v) => setState(() => _filtroProductos = v),
            decoration: InputDecoration(
              hintText: 'Buscar por código, nombre...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace? _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (List<Producto> productos) {
                final List<Producto> filtrados = productos
                    .where((Producto p) => p.codigo.toLowerCase().contains(_filtroProductos) || p.nombre.toLowerCase().contains(_filtroProductos))
                    .toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text('El inventario está listo para registrar elementos.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final Producto prod = filtrados[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50, margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E293B), size: 24),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${prod.codigo} • ${prod.nombre}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Wrap(spacing: 8, runSpacing: 4, children: [
                                    RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), children: [const TextSpan(text: 'Stock: '), TextSpan(text: '${prod.stock}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))])),
                                    RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), children: [const TextSpan(text: 'Compra: '), TextSpan(text: '${prod.precioCompra}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10B981)))])),
                                    RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), children: [const TextSpan(text: 'Venta: '), TextSpan(text: '${prod.precioVenta}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEF4444)))])),
                                  ]),
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
        ],
      ),
    );
  }

  Widget _buildSeccionKardex(BuildContext context) {
    final AsyncValue<List<Kardex>> movimientosAsync = ref.watch(kardexPorProductoProvider(''));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de Movimientos (Kardex)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: TextField(
                onChanged: (String v) => setState(() => _filtroKardex = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por producto, documento...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<TipoMovimiento>(
                initialValue: _filtroTipoKardex,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                ),
                hint: const Text('Tipo Movimiento', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                items: TipoMovimiento.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase(), style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _filtroTipoKardex = v),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: movimientosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (movimientos) {
                final filtrados = movimientos.where((m) {
                  final coincideTexto = m.productoId.toString().contains(_filtroKardex) || (m.documentoReferencia?.contains(_filtroKardex) ?? false);
                  final coincideTipo = _filtroTipoKardex == null || m.tipoMovimiento == _filtroTipoKardex;
                  return coincideTexto && coincideTipo;
                }).toList();

                if (filtrados.isEmpty) return const Center(child: Text('Aquí aparecerá el historial completo de entradas, salidas y ajustes de inventario.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15), textAlign: TextAlign.center));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final mov = filtrados[i];
                    final colorTipo = switch (mov.tipoMovimiento) {
                      TipoMovimiento.entrada => const Color(0xFF10B981),
                      TipoMovimiento.salida => const Color(0xFFEF4444),
                      TipoMovimiento.ajuste => const Color(0xFFF59E0B),
                      _ => const Color(0xFF6366F1),
                    };
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(width: 8, height: 60, decoration: BoxDecoration(color: colorTipo, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(mov.tipoMovimiento.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colorTipo)),
                              const SizedBox(height: 6),
                              Text('Producto: ${mov.productoId}\nDocumento: ${mov.documentoReferencia ?? 'Sin doc'}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3)),
                              const SizedBox(height: 6),
                              Text('Cantidad: ${mov.cantidad}  |  Saldo: ${mov.saldoAnterior} → ${mov.saldoNuevo}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${mov.fechaMovimiento!.day}/${mov.fechaMovimiento!.month}/${mov.fechaMovimiento!.year}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: colorTipo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(mov.tipoMovimiento == TipoMovimiento.entrada ? 'Entrante' : 'Saliente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorTipo)),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}