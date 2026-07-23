import 'package:flutter/material.dart';
import 'registrar_entrada_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/producto.dart';
import '../providers/producto_providers.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categorias = ['Muebles', 'Tecnología', 'Oficina'];
  final List<String> _marcas = ['Genérica', 'OfficePro', 'Executive'];
  final List<String> _unidades = ['Unidades', 'Libras', 'Litros', 'Cajas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _mostrarModalProducto({Producto? productoEdicion}) {
    final nombreController = TextEditingController(text: productoEdicion?.nombre ?? '');
    final skuController = TextEditingController(text: productoEdicion?.codigo ?? '');
    final costoController = TextEditingController(text: productoEdicion?.precioCompra.toString() ?? '');
    final ventaController = TextEditingController(text: productoEdicion?.precioVenta.toString() ?? '');
    final stockController = TextEditingController(text: productoEdicion?.stock.toString() ?? '0.0');
    final stockMinimoController = TextEditingController(text: productoEdicion?.stockMinimo.toString() ?? '0.0');
    bool activo = productoEdicion?.activo ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(productoEdicion == null ? Icons.add_box : Icons.edit, color: const Color(0xFF1E293B)),
              const SizedBox(width: 8),
              Text(productoEdicion == null ? 'Registrar Nuevo Producto' : 'Editar Producto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Producto',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: skuController,
                    decoration: InputDecoration(
                      labelText: 'SKU / Código de Barra',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Costo (RD\$)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.payments_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: ventaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Precio Venta (RD\$)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.sell_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Existencia Actual',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.format_list_numbered),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: stockMinimoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Stock Mínimo (Alerta)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.warning_amber_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Producto Activo para la Venta'),
                    value: activo,
                    onChanged: (val) => setStateModal(() => activo = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (nombreController.text.isEmpty) return;
                
                final double stockVal = double.tryParse(stockController.text) ?? 0.0;
                final double stockMinVal = double.tryParse(stockMinimoController.text) ?? 0.0;

                if (stockVal < 0 || stockMinVal < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Las cantidades de existencia no pueden ser negativas')),
                  );
                  return;
                }

                final nuevoProducto = Producto(
                  id: productoEdicion?.id,
                  codigo: skuController.text.isEmpty ? 'SKU-${DateTime.now().millisecondsSinceEpoch}' : skuController.text,
                  nombre: nombreController.text,
                  descripcion: productoEdicion?.descripcion,
                  precioCompra: double.tryParse(costoController.text) ?? 0.0,
                  precioVenta: double.tryParse(ventaController.text) ?? 0.0,
                  stock: stockVal,
                  stockMinimo: stockMinVal,
                  categoriaId: productoEdicion?.categoriaId ?? 1,
                  marcaId: productoEdicion?.marcaId ?? 1,
                  unidadId: productoEdicion?.unidadId ?? 1,
                  activo: activo,
                );

                if (productoEdicion == null) {
                  ref.read(productoControllerProvider.notifier).guardar(nuevoProducto);
                } else {
                  ref.read(productoControllerProvider.notifier).actualizar(nuevoProducto);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(productoEdicion == null ? '¡Producto registrado con éxito!' : '¡Producto actualizado correctamente!')),
                );
              },
              child: Text(productoEdicion == null ? 'Guardar Producto' : 'Actualizar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarProducto(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto del inventario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(productoControllerProvider.notifier).eliminar(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado.')));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Gestión Integral de Inventario y Catálogo'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelColor: Colors.white70,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Categorías'),
            Tab(icon: Icon(Icons.branding_watermark_outlined), text: 'Marcas'),
            Tab(icon: Icon(Icons.straighten_outlined), text: 'Unidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          productosAsync.when(
            data: (productos) {
              int totalSkus = productos.length;
              int activosCount = productos.where((p) => p.activo).length;
              int alertasCount = productos.where((p) => p.stock <= p.stockMinimo).length;
              double valorTotalInventario = productos.fold(0.0, (sum, p) => sum + (p.precioCompra * p.stock));

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inventario y Catálogo',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestión de existencias, validación de stock y control de inventario en tiempo real.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _mostrarModalProducto(),
                          icon: const Icon(Icons.add),
                          label: const Text('Nuevo Producto'),
                        ),
                      ],
                    ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _CardMetricaWidget(titulo: 'TOTAL SKUs', valor: '$totalSkus', sub: 'Registrados', icono: Icons.inventory_2_outlined, color: Colors.blue),
                        const SizedBox(width: 16),
                        _CardMetricaWidget(titulo: 'ACTIVOS', valor: '$activosCount', sub: 'Habilitados venta', icono: Icons.check_circle_outline, color: Colors.teal),
                        const SizedBox(width: 16),
                        _CardMetricaWidget(titulo: 'ALERTAS STOCK', valor: '$alertasCount', sub: 'Bajo mínimo', icono: Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 16),
                        _CardValorWidget(titulo: 'VALOR INVENTARIO', valor: 'RD\$ ${valorTotalInventario.toStringAsFixed(2)}', sub: 'Costo total', icono: Icons.payments_outlined),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: productos.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(child: Text('No hay productos registrados en el inventario.')),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: productos.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final prod = productos[index];
                                bool stockBajo = prod.stock <= prod.stockMinimo;
                                return _FilaProductoWidget(
                                  id: prod.id ?? 0,
                                  nombre: prod.nombre,
                                  sku: prod.codigo,
                                  costo: 'Costo: RD\$ ${prod.precioCompra.toStringAsFixed(2)}',
                                  venta: 'RD\$ ${prod.precioVenta.toStringAsFixed(2)}',
                                  existenciaActual: '${prod.stock} unids',
                                  existenciaDisponible: '${prod.stock} unids',
                                  activo: prod.activo,
                                  stockBajo: stockBajo,
                                  onEdit: () => _mostrarModalProducto(productoEdicion: prod),
                                  onDelete: () => _eliminarProducto(prod.id!),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error al cargar inventario: $e')),
          ),

          _PantallaCRUDDinamica(
            titulo: 'Gestión de Categorías',
            icono: Icons.category_outlined,
            entidad: 'Categoría',
            elementos: _categorias,
            onAgregar: (nuevo) => setState(() => _categorias.add(nuevo)),
            onEditar: (index, nuevo) => setState(() => _categorias[index] = nuevo),
            onEliminar: (index) => setState(() => _categorias.removeAt(index)),
          ),

          _PantallaCRUDDinamica(
            titulo: 'Gestión de Marcas',
            icono: Icons.branding_watermark_outlined,
            entidad: 'Marca',
            elementos: _marcas,
            onAgregar: (nuevo) => setState(() => _marcas.add(nuevo)),
            onEditar: (index, nuevo) => setState(() => _marcas[index] = nuevo),
            onEliminar: (index) => setState(() => _marcas.removeAt(index)),
          ),

          _PantallaCRUDDinamica(
            titulo: 'Unidades de Medida',
            icono: Icons.straighten_outlined,
            entidad: 'Unidad de Medida',
            elementos: _unidades,
            onAgregar: (nuevo) => setState(() => _unidades.add(nuevo)),
            onEditar: (index, nuevo) => setState(() => _unidades[index] = nuevo),
            onEliminar: (index) => setState(() => _unidades.removeAt(index)),
          ),
        ],
      ),
    );
  }
}

class _PantallaCRUDDinamica extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String entidad;
  final List<String> elementos;
  final ValueChanged<String> onAgregar;
  final void Function(int index, String valor) onEditar;
  final ValueChanged<int> onEliminar;

  const _PantallaCRUDDinamica({
    required this.titulo,
    required this.icono,
    required this.entidad,
    required this.elementos,
    required this.onAgregar,
    required this.onEditar,
    required this.onEliminar,
  });

  void _mostrarModalForm(BuildContext context, {String? valorActual, int? index}) {
    final controller = TextEditingController(text: valorActual ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(valorActual == null ? 'Nueva $entidad' : 'Editar $entidad', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nombre de la $entidad',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(icono),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.isEmpty) return;
              if (index == null) {
                onAgregar(controller.text);
              } else {
                onEditar(index, controller.text);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(index == null ? '$entidad guardada correctamente' : '$entidad actualizada')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Icon(icono, color: Colors.teal.shade700),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _mostrarModalForm(context),
                icon: const Icon(Icons.add),
                label: Text('Nueva $entidad'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: elementos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icono, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No hay registros en $titulo',
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: elementos.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade50,
                            child: Icon(icono, color: Colors.teal.shade700, size: 20),
                          ),
                          title: Text(elementos[index], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _mostrarModalForm(context, valorActual: elementos[index], index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => onEliminar(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMetricaWidget extends StatelessWidget {
  final String titulo;
  final String valor;
  final String sub;
  final IconData icono;
  final Color color;

  const _CardMetricaWidget({required this.titulo, required this.valor, required this.sub, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                Icon(icono, size: 20, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _CardValorWidget extends StatelessWidget {
  final String titulo;
  final String valor;
  final String sub;
  final IconData icono;

  const _CardValorWidget({required this.titulo, required this.valor, required this.sub, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                Icon(icono, size: 20, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _FilaProductoWidget extends StatelessWidget {
  final int id;
  final String nombre;
  final String sku;
  final String costo;
  final String venta;
  final String existenciaActual;
  final String existenciaDisponible;
  final bool activo;
  final bool stockBajo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FilaProductoWidget({
    required this.id,
    required this.nombre,
    required this.sku,
    required this.costo,
    required this.venta,
    required this.existenciaActual,
    required this.existenciaDisponible,
    required this.activo,
    required this.stockBajo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: activo ? Colors.teal.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activo ? 'ACTIVO' : 'INACTIVO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activo ? Colors.teal.shade700 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(sku, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(costo, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Act: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(existenciaActual, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('Disp: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(
                      existenciaDisponible,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stockBajo ? Colors.orange.shade800 : Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.input, size: 18, color: Colors.teal),
                tooltip: 'Registrar Entrada',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrarEntradaPage(
                        productoId: id,
                        nombreProducto: nombre,
                      ),
                    ),
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}
