import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/providers/producto_providers.dart';

// ✅ Nombre corregido para coincidir con tu archivo
class VentaConComprobanteScreen extends ConsumerStatefulWidget {
  const VentaConComprobanteScreen({super.key});

  @override
  ConsumerState<VentaConComprobanteScreen> createState() => _VentaConComprobanteScreenState();
}

class _VentaConComprobanteScreenState extends ConsumerState<VentaConComprobanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rncCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
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
    if (!_formKey.currentState!.validate() || _items.isEmpty) return;
    // Aquí irá la lógica de guardado con datos fiscales
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Factura registrada correctamente')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final listaProductos = ref.watch(productoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta con Comprobante'),
        actions: [
          TextButton.icon(
            onPressed: _items.isNotEmpty ? _guardarVenta : null,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos del Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rncCtrl,
                      decoration: const InputDecoration(
                        labelText: 'RNC / Cédula',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Ingrese el documento' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o Razón Social',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingrese el nombre' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comprobanteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Número de Comprobante Fiscal',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Ingrese el número de comprobante' : null,
              ),
              const SizedBox(height: 24),

              const Text('Productos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _mostrarSelectorProductos(listaProductos),
              ),
              const SizedBox(height: 16),

              _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No hay productos agregados', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    )
                  : Column(
                      children: _items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item['producto'].nombre),
                            subtitle: Text('RD\$ ${item['precioUnitario'].toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
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
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      item['cantidad']++;
                                      _calcularTotales();
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
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
                      }).toList(),
                    ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
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
                        const Text('TOTAL A PAGAR:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('RD\$ ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A2463))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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