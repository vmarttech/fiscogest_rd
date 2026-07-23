import 'package:flutter/material.dart';

class PantallaVentaUnificada extends StatefulWidget {
  const PantallaVentaUnificada({super.key});

  @override
  State<PantallaVentaUnificada> createState() => _PantallaVentaUnificadaState();
}

class _PantallaVentaUnificadaState extends State<PantallaVentaUnificada> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _documentoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _comprobanteCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController(text: '0.00');

  // Estados
  bool _esVentaConComprobante = false;
  bool _buscandoRnc = false;

  // Productos de prueba
  final List<Map<String, dynamic>> _productosDisponibles = const [
    {'nombre': 'Arroz 5lb', 'precio': 75.00},
    {'nombre': 'Aceite 1gal', 'precio': 280.00},
    {'nombre': 'Azúcar 5lb', 'precio': 90.00},
    {'nombre': 'Café 1lb', 'precio': 160.00},
    {'nombre': 'Jabón 10u', 'precio': 220.00},
  ];

  // Items de la venta actual
  final List<Map<String, dynamic>> _items = [];
  double _subtotal = 0.0;
  double _descuentosTotal = 0.0;
  double _itbis = 0.0;
  double _delivery = 0.0;
  double _total = 0.0;

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _nombreCtrl.dispose();
    _comprobanteCtrl.dispose();
    _deliveryCtrl.dispose();
    super.dispose();
  }

  void _calcularTotales() {
    double subtotalTemp = 0;
    double descuentosTemp = 0;

    for (var item in _items) {
      double cant = item['cantidad'] ?? 1.0;
      double prec = item['precio'] ?? 0.0;
      double desc = item['descuento'] ?? 0.0;

      subtotalTemp += cant * prec;
      descuentosTemp += desc;
    }

    double base = subtotalTemp - descuentosTemp;
    _delivery = double.tryParse(_deliveryCtrl.text) ?? 0.0;

    setState(() {
      _subtotal = subtotalTemp;
      _descuentosTotal = descuentosTemp;
      _itbis = (_esVentaConComprobante && base > 0) ? base / 1.18 * 0.18 : 0.0;
      _total = base + _itbis + _delivery;
    });
  }

  Future<void> _buscarRnc() async {
    final doc = _documentoCtrl.text.trim();
    if (doc.isEmpty) return;

    setState(() => _buscandoRnc = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() {
      if (doc.length == 9) {
        _nombreCtrl.text = 'EMPRESA COMERCIAL SRL';
      } else if (doc.length == 11) {
        _nombreCtrl.text = 'PERSONA FÍSICA';
      } else {
        _nombreCtrl.clear();
      }
      _buscandoRnc = false;
    });
  }

  void _agregarProducto(Map<String, dynamic> prod) {
    _items.add({
      'nombre': prod['nombre'],
      'precio': prod['precio'],
      'cantidad': 1.0,
      'descuento': 0.0,
    });
    _calcularTotales();
  }

  void _aplicarDescuento(int indice) {
    final item = _items[indice];
    final ctrl = TextEditingController(text: item['descuento'].toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descuento por producto'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto en RD\$',
            prefixText: 'RD\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              double valor = double.tryParse(ctrl.text) ?? 0;
              double maximo = (item['cantidad'] ?? 1) * (item['precio'] ?? 0);
              if (valor > maximo) valor = maximo;

              item['descuento'] = valor;
              _calcularTotales();
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _mostrarProductos() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seleccionar Producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _productosDisponibles.length,
                itemBuilder: (_, i) {
                  final p = _productosDisponibles[i];
                  return ListTile(
                    title: Text(p['nombre']),
                    subtitle: Text('Precio: RD\$ ${p['precio'].toStringAsFixed(2)}'),
                    onTap: () {
                      _agregarProducto(p);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _guardarVenta() {
    if (_esVentaConComprobante && !_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregue al menos un producto')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venta registrada correctamente')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: const Color(0xFF0A2463),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _guardarVenta,
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
              // ✅ TIPO DE OPERACIÓN - SIN DESBORDE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de operación:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: _esVentaConComprobante,
                          onChanged: (v) {
                            setState(() {
                              _esVentaConComprobante = v;
                              if (!v) {
                                _documentoCtrl.clear();
                                _nombreCtrl.clear();
                                _comprobanteCtrl.clear();
                              }
                              _calcularTotales();
                            });
                          },
                          activeColor: const Color(0xFF0A2463),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _esVentaConComprobante ? 'Con Comprobante' : 'Consumidor Final',
                            style: TextStyle(
                              color: _esVentaConComprobante ? const Color(0xFF0A2463) : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campos solo para venta con comprobante
              if (_esVentaConComprobante) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _documentoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'RNC / Cédula',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                        onFieldSubmitted: (_) => _buscarRnc(),
                        validator: (v) => v != null && v.isNotEmpty ? null : 'Ingrese el documento',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buscandoRnc
                          ? const LinearProgressIndicator()
                          : TextFormField(
                              controller: _nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre o Razón Social',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v != null && v.isNotEmpty ? null : 'Ingrese el nombre',
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comprobanteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Número de Comprobante Fiscal',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Ingrese el número de comprobante',
                ),
                const SizedBox(height: 24),
              ],

              // Buscar producto
              TextField(
                readOnly: true,
                onTap: _mostrarProductos,
                decoration: const InputDecoration(
                  hintText: 'Seleccionar producto',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Lista de productos agregados
              if (_items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('No hay productos agregados', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    double cant = item['cantidad'] ?? 1.0;
                    double prec = item['precio'] ?? 0.0;
                    double subt = cant * prec;
                    double desc = item['descuento'] ?? 0.0;
                    double neto = subt - desc;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        if (cant > 1) {
                                          item['cantidad']--;
                                          _calcularTotales();
                                        }
                                      },
                                    ),
                                    Text('$cant'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        item['cantidad']++;
                                        _calcularTotales();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Precio: RD\$ ${prec.toStringAsFixed(2)}'),
                                Text('Subtotal: RD\$ ${subt.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _aplicarDescuento(i),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: desc > 0 ? Colors.green.shade50 : const Color(0xFF0A2463),
                                  ),
                                  child: Text(
                                    desc > 0 ? 'Descuento: RD\$ ${desc.toStringAsFixed(2)}' : 'Aplicar Descuento',
                                    style: TextStyle(color: desc > 0 ? Colors.green.shade800 : Colors.white),
                                  ),
                                ),
                                Text('Neto: RD\$ ${neto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _items.removeAt(i);
                                    _calcularTotales();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Delivery
              TextFormField(
                controller: _deliveryCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Costo de Delivery RD\$',
                  prefixIcon: Icon(Icons.local_shipping),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calcularTotales(),
              ),

              const SizedBox(height: 24),

              // Resumen final
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text('RD\$ ${_subtotal.toStringAsFixed(2)}')]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Descuentos:'), Text('- RD\$ ${_descuentosTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Base Imponible:'), Text('RD\$ ${(_subtotal - _descuentosTotal).toStringAsFixed(2)}')]),
                    if (_esVentaConComprobante)
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('ITBIS (18%):'), Text('RD\$ ${_itbis.toStringAsFixed(2)}')]),
                    if (_delivery > 0)
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Delivery:'), Text('RD\$ ${_delivery.toStringAsFixed(2)}')]),
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
}
