import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Gestión Integral de Inventario'),
        backgroundColor: const Color(0xFF1E293B),
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
          // --- PESTAÑA 1: PRODUCTOS ---
          _buildSeccionProductos(context),

          // --- PESTAÑA 2: CATEGORÍAS ---
          _buildSeccionInterna(
            context,
            'Gestión de Categorías',
            'Organiza tus artículos por departamentos o tipos (Ej. Bebidas, Abarrotes, Cuidado Personal).',
            Icons.category_outlined,
            '/categorias',
          ),

          // --- PESTAÑA 3: MARCAS ---
          _buildSeccionInterna(
            context,
            'Gestión de Marcas',
            'Administra los fabricantes y marcas comerciales de los productos en existencia.',
            Icons.branding_watermark_outlined,
            '/marcas',
          ),

          // --- PESTAÑA 4: UNIDADES DE MEDIDA ---
          _buildSeccionInterna(
            context,
            'Unidades de Medida',
            'Define cómo se venden tus productos (Unidades, Libras, Kilogramos, Metros, Litros, etc.).',
            Icons.straighten_outlined,
            '/unidades',
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionProductos(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Listado General de Productos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  // Acción para nuevo producto
                },
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
              child: const Center(
                child: Text(
                  'El inventario está listo para registrar elementos.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionInterna(BuildContext context, String titulo, String descripcion, IconData icono, String rutaAlternativa) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.teal.shade50,
                  child: Icon(icono, size: 32, color: Colors.teal.shade700),
                ),
                const SizedBox(height: 20),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  descripcion,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      context.push(rutaAlternativa);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir Panel de Gestión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
