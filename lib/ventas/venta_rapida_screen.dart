import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/providers/producto_providers.dart';

class VentaRapidaScreen extends ConsumerStatefulWidget {
  const VentaRapidaScreen({super.key});

  @override
  ConsumerState<VentaRapidaScreen> createState() => _VentaRapidaScreenState();
}

class _VentaRapidaScreenState extends ConsumerState<VentaRapidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _items = [];
  double _subtotal = 0.0;
  double _itbis = 0.0;
  double _total = 0.0;

  void _agregarProducto(Producto producto) {
    setState(() {
      _items.add({
        'producto': producto,
        'cantidad': 1.0,
        'precioUnitario': producto.precioVenta,
      });
      _calcularTotales();
    });
  }

  void _calcularTotales() {
    _subtotal = 0.0;
    for (var item in _items) {
      _subtotal += item['cantidad'] * item['precioUnitario'];
    }
    _itbis = _subtotal * 0.18;
    _total = _subtotal + _itbis;
  }

  void _guardarVenta() {
    if (_items.isEmpty) return;
    // Aquí irá la lógica de guardado en base de datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venta registrada correctamente')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final listaProductos = ref.watch(productoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta Rápida'),
        actions: [
          TextButton.icon(
            onPressed: _items.isNotEmpty ? _guardarVenta : null,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          // Buscador de productos
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar producto por código o nombre...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onTap: () => _mostrarSelectorProductos(listaProductos),
            ),
          ),

          // Lista de productos agregados
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 16),
                        Text('No hay productos agregados', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                        Text('Busca y selecciona uno para comenzar', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item['producto'].nombre),
                          subtitle: Text('RD\$ ${item['precioUnitario'].toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (item['cantidad'] > 1) {
                                    setState(() {
                                      item['cantidad']--;
                                      _calcularTotales();
                                    });
                                  }
                                },
                              ),
                              Text('${item['cantidad']}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    item['cantidad']++;
                                    _calcularTotales();
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                    _calcularTotales();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Resumen final
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('RD\$ ${_subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ITBIS (18%):'),
                    Text('RD\$ ${_itbis.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('RD\$ ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2463))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorProductos(List<Producto> lista) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seleccionar Producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final prod = lista[index];
                    return ListTile(
                      title: Text(prod.nombre),
                      subtitle: Text('Código: ${prod.codigo} | Precio: RD\$ ${prod.precioVenta.toStringAsFixed(2)}'),
                      onTap: () {
                        _agregarProducto(prod);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}