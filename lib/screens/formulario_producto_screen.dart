import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../providers/producto_providers.dart';

class FormularioProductoScreen extends ConsumerStatefulWidget {
  final Producto? producto;
  const FormularioProductoScreen({super.key, this.producto});

  @override
  ConsumerState<FormularioProductoScreen> createState() => _FormularioProductoScreenState();
}

class _FormularioProductoScreenState extends ConsumerState<FormularioProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _ctrlCodigo = TextEditingController();
  final _ctrlNombre = TextEditingController();
  final _ctrlDescripcion = TextEditingController();
  final _ctrlPrecioCompra = TextEditingController();
  final _ctrlMargen = TextEditingController();
  final _ctrlPrecioVenta = TextEditingController();
  final _ctrlStockActual = TextEditingController();
  final _ctrlStockMinimo = TextEditingController();

  final _ctrlGastosTransporte = TextEditingController(text: '0.00');
  final _ctrlGastosVarios = TextEditingController(text: '0.00');

  final List<Map<String, dynamic>> _categoriasFiscales = const [
    {'nombre': 'GENERAL (18% ITBIS)', 'impuesto': 18.0, 'exento': false},
    {'nombre': 'EXENTO (0% ITBIS)', 'impuesto': 0.0, 'exento': true},
    {'nombre': 'MEDICAMENTOS (0% ITBIS)', 'impuesto': 0.0, 'exento': true},
    {'nombre': 'EXPORTACIÓN (0% ITBIS)', 'impuesto': 0.0, 'exento': true},
    {'nombre': 'SERVICIOS (18% ITBIS)', 'impuesto': 18.0, 'exento': false},
  ];

  Map<String, dynamic> _categoriaSeleccionada = {'nombre': 'GENERAL (18% ITBIS)', 'impuesto': 18.0, 'exento': false};
  String _unidadMedida = 'UNIDAD';
  
  double _costoTotal = 0.0;
  double _baseImponible = 0.0;
  double _valorItbis = 0.0;
  double _gananciaNeta = 0.0;
  double _precioFinal = 0.0;
  bool _modoCalculando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosExistentes();
    _agregarListeners();
  }

  void _cargarDatosExistentes() {
    if (widget.producto != null) {
      final prod = widget.producto!;
      _ctrlCodigo.text = prod.codigo;
      _ctrlNombre.text = prod.nombre;
      _ctrlDescripcion.text = prod.descripcion ?? '';
      _ctrlPrecioCompra.text = prod.precioCompra.toStringAsFixed(2);
      _ctrlGastosTransporte.text = prod.gastosTransporte.toStringAsFixed(2);
      _ctrlGastosVarios.text = prod.gastosVarios.toStringAsFixed(2);
      _ctrlMargen.text = prod.margenGanancia.toStringAsFixed(2);
      _ctrlPrecioVenta.text = prod.precioVenta.toStringAsFixed(2);
      _ctrlStockActual.text = prod.stockActual.toString();
      _ctrlStockMinimo.text = prod.stockMinimo.toString();
      _unidadMedida = prod.unidadMedida;

      for (var cat in _categoriasFiscales) {
        if (cat['impuesto'] == prod.porcentajeImpuesto && cat['exento'] == !prod.aplicaImpuesto) {
          _categoriaSeleccionada = cat;
          break;
        }
      }
    }
  }

  void _agregarListeners() {
    _ctrlPrecioCompra.addListener(_actualizarCostos);
    _ctrlGastosTransporte.addListener(_actualizarCostos);
    _ctrlGastosVarios.addListener(_actualizarCostos);
    _ctrlMargen.addListener(_calcularDesdeMargen);
    _ctrlPrecioVenta.addListener(_calcularDesdePrecio);
  }

  @override
  void dispose() {
    _ctrlCodigo.dispose();
    _ctrlNombre.dispose();
    _ctrlDescripcion.dispose();
    _ctrlPrecioCompra.dispose();
    _ctrlGastosTransporte.dispose();
    _ctrlGastosVarios.dispose();
    _ctrlMargen.dispose();
    _ctrlPrecioVenta.dispose();
    _ctrlStockActual.dispose();
    _ctrlStockMinimo.dispose();
    super.dispose();
  }

  void _actualizarCostos() {
    final compra = double.tryParse(_ctrlPrecioCompra.text) ?? 0.0;
    final transporte = double.tryParse(_ctrlGastosTransporte.text) ?? 0.0;
    final varios = double.tryParse(_ctrlGastosVarios.text) ?? 0.0;

    setState(() {
      _costoTotal = compra + transporte + varios;
    });
    _calcularDesdeMargen();
  }

  void _calcularDesdeMargen() {
    if (_modoCalculando || _costoTotal <= 0) return;
    _modoCalculando = true;

    final margen = double.tryParse(_ctrlMargen.text) ?? 0.0;
    setState(() {
      _baseImponible = _costoTotal * (1 + (margen / 100));
      _gananciaNeta = _baseImponible - _costoTotal;
      
      if (_categoriaSeleccionada['exento']) {
        _valorItbis = 0.0;
        _precioFinal = _baseImponible;
      } else {
        _valorItbis = _baseImponible * (_categoriaSeleccionada['impuesto'] / 100);
        _precioFinal = _baseImponible + _valorItbis;
      }

      _ctrlPrecioVenta.text = _precioFinal.toStringAsFixed(2);
    });

    _modoCalculando = false;
  }

  void _calcularDesdePrecio() {
    if (_modoCalculando) return;
    _modoCalculando = true;

    final precioFinal = double.tryParse(_ctrlPrecioVenta.text) ?? 0.0;
    if (precioFinal <= 0 || _costoTotal <= 0) {
      _modoCalculando = false;
      return;
    }

    setState(() {
      if (_categoriaSeleccionada['exento']) {
        _baseImponible = precioFinal;
        _valorItbis = 0.0;
      } else {
        _baseImponible = precioFinal / (1 + (_categoriaSeleccionada['impuesto'] / 100));
        _valorItbis = precioFinal - _baseImponible;
      }

      _gananciaNeta = _baseImponible - _costoTotal;
      final margenCalc = ((_baseImponible - _costoTotal) / _costoTotal) * 100;
      _ctrlMargen.text = margenCalc.toStringAsFixed(2);
    });

    _modoCalculando = false;
  }

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      final producto = Producto(
        id: widget.producto?.id,
        codigo: _ctrlCodigo.text.trim(),
        nombre: _ctrlNombre.text.trim(),
        descripcion: _ctrlDescripcion.text.trim(),
        precioCompra: double.parse(_ctrlPrecioCompra.text),
        gastosTransporte: double.parse(_ctrlGastosTransporte.text),
        gastosVarios: double.parse(_ctrlGastosVarios.text),
        precioVenta: _precioFinal,
        margenGanancia: double.parse(_ctrlMargen.text),
        valorITBIS: _valorItbis,
        porcentajeImpuesto: _categoriaSeleccionada['impuesto'],
        aplicaImpuesto: !_categoriaSeleccionada['exento'],
        stockActual: int.parse(_ctrlStockActual.text),
        stockMinimo: int.parse(_ctrlStockMinimo.text),
        unidadMedida: _unidadMedida,
        fechaRegistro: DateTime.now(),
      );

      try {
        await ref.read(productoNotifierProvider.notifier).guardar(producto);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto guardado correctamente'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al guardar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.producto != null ? 'Editar Producto' : 'Nuevo Producto'),
        centerTitle: true,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: _guardarProducto,
              child: const Text('GUARDAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
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
              const Text('📋 INFORMACIÓN BÁSICA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlCodigo,
                decoration: const InputDecoration(labelText: 'Código / Referencia', border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctrlNombre,
                decoration: const InputDecoration(labelText: 'Nombre o Descripción', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctrlDescripcion,
                decoration: const InputDecoration(labelText: 'Descripción Larga (Opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text('💰 ESTRUCTURA DE COSTOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlPrecioCompra,
                decoration: const InputDecoration(labelText: 'Costo del Producto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlGastosTransporte,
                decoration: const InputDecoration(labelText: 'Gastos de Transporte', border: OutlineInputBorder(), prefixIcon: Icon(Icons.local_shipping)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlGastosVarios,
                decoration: const InputDecoration(labelText: 'Otros Gastos / Impuestos Adicionales', border: OutlineInputBorder(), prefixIcon: Icon(Icons.receipt_long)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF5FF),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  'COSTO TOTAL: RD\$ ${_costoTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              const Text('⚖️ CLASIFICACIÓN FISCAL (DGII)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(labelText: 'Régimen de Impuesto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_balance)),
                items: _categoriasFiscales.map((cat) => DropdownMenuItem(value: cat, child: Text(cat['nombre']))).toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _categoriaSeleccionada = valor);
                    _calcularDesdeMargen();
                  }
                },
                selectedItemBuilder: (context) => _categoriasFiscales.map((cat) {
                  return Text(
                    _categoriaSeleccionada['nombre'],
                    style: const TextStyle(color: Colors.black87),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('📈 RENTABILIDAD Y PRECIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _ctrlMargen, decoration: const InputDecoration(labelText: 'Margen %', border: OutlineInputBorder(), prefixIcon: Icon(Icons.percent)), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _ctrlPrecioVenta, decoration: const InputDecoration(labelText: 'Precio Final', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sell)), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFDEE2E6)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📊 RESUMEN DE CÁLCULOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Divider(height: 20),
                    // ✅ CORREGIDO LÍNEA 325: Row marcado como const
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Imponible:'),
                        Text('RD\$ 0.00'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ITBIS (${_categoriaSeleccionada['impuesto']}%):'),
                        Text(
                          'RD\$ ${_valorItbis.toStringAsFixed(2)}',
                          style: TextStyle(color: _valorItbis > 0 ? Colors.red : Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ganancia Neta:'),
                        Text(
                          'RD\$ ${_gananciaNeta.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.teal),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL A PAGAR:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'RD\$ ${_precioFinal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('📦 INVENTARIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Unidad de Medida', border: OutlineInputBorder()),
                items: const ['UNIDAD', 'CAJA', 'PAQUETE', 'LITRO', 'KILO'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _unidadMedida = v);
                },
                selectedItemBuilder: (context) => ['UNIDAD', 'CAJA', 'PAQUETE', 'LITRO', 'KILO'].map((val) {
                  return Text(
                    _unidadMedida,
                    style: const TextStyle(color: Colors.black87),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _ctrlStockActual, decoration: const InputDecoration(labelText: 'Existencia Actual', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(controller: _ctrlStockMinimo, decoration: const InputDecoration(labelText: 'Stock Mínimo', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requerido' : null)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}