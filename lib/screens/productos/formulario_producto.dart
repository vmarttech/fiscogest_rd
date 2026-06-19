import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/providers/producto_notifier.dart';

class FormularioProductoScreen extends ConsumerStatefulWidget {
  const FormularioProductoScreen({super.key, this.producto});
  final Producto? producto;

  @override
  ConsumerState<FormularioProductoScreen> createState() =>
      _FormularioProductoScreenState();
}

class _FormularioProductoScreenState
    extends ConsumerState<FormularioProductoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late TextEditingController _codigoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _precioCompraCtrl;
  late TextEditingController _transporteCtrl;
  late TextEditingController _variosCtrl;
  late TextEditingController _precioVentaCtrl;
  late TextEditingController _margenCtrl;
  late TextEditingController _stockActualCtrl;
  late TextEditingController _stockMinimoCtrl;

  // Variables para cálculos e inventario
  double _costoSinImpuesto = 0.0;
  double _impuestos = 0.0;
  double _costoFinal = 0.0;
  double _precioSugerido = 0.0;
  double _ganancia = 0.0;
  double _margenReal = 0.0;

  String _regimenSeleccionado = '';
  bool _aplicaImpuesto = false;
  double _tasaImpuesto = 0.0;
  bool _esSelectivo = false;

  String _unidadSeleccionada = 'UNIDAD';
  bool _permiteDecimales = false;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;

    _codigoCtrl = TextEditingController(text: p?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCompraCtrl = TextEditingController(
      text: p?.precioCompra.toString() ?? '0',
    );
    _transporteCtrl = TextEditingController(
      text: p?.gastosTransporte.toString() ?? '0',
    );
    _variosCtrl = TextEditingController(
      text: p?.gastosVarios.toString() ?? '0',
    );
    _precioVentaCtrl = TextEditingController(
      text: p?.precioVenta.toString() ?? '0',
    );
    _margenCtrl = TextEditingController(
      text: p?.margenGanancia.toString() ?? '20',
    );
    _stockActualCtrl = TextEditingController(
      text: p?.stockActual.toString() ?? '0',
    );
    _stockMinimoCtrl = TextEditingController(
      text: p?.stockMinimo.toString() ?? '0',
    );

    if (p != null) {
      _regimenSeleccionado = p.regimenImpuesto;
      _aplicaImpuesto = p.aplicaImpuesto;
      _tasaImpuesto = p.porcentajeImpuesto;
      _esSelectivo = p.esImpuestoSelectivo;
      _unidadSeleccionada = p.unidadMedida;
      _permiteDecimales = p.permiteDecimales;
      _actualizarCalculos();
    }
  }

  void _actualizarCalculos() {
    final precioCompra = double.tryParse(_precioCompraCtrl.text) ?? 0.0;
    final transporte = double.tryParse(_transporteCtrl.text) ?? 0.0;
    final varios = double.tryParse(_variosCtrl.text) ?? 0.0;
    final precioVenta = double.tryParse(_precioVentaCtrl.text) ?? 0.0;
    final margen = double.tryParse(_margenCtrl.text) ?? 0.0;

    _costoSinImpuesto = precioCompra + transporte + varios;
    _impuestos = _aplicaImpuesto
        ? _costoSinImpuesto * (_tasaImpuesto / 100)
        : 0.0;
    _costoFinal = _costoSinImpuesto + _impuestos;
    _precioSugerido = _costoFinal > 0 ? _costoFinal * (1 + margen / 100) : 0.0;
    _ganancia = precioVenta - _costoFinal;
    _margenReal = precioVenta > 0
        ? (_ganancia / precioVenta * 100).clamp(0, 100)
        : 0.0;

    setState(() {});
  }

  void _cambiarRegimen(Map<String, dynamic> regimen) {
    setState(() {
      _regimenSeleccionado = regimen['nombre'];
      _aplicaImpuesto = regimen['aplicaImpuesto'];
      _tasaImpuesto = regimen['tasa'];
      _esSelectivo = regimen['esSelectivo'];
    });
    _actualizarCalculos();
  }

  void _cambiarUnidad(String unidad) {
    setState(() {
      _unidadSeleccionada = unidad;
      _permiteDecimales = Producto.verificarSiPermiteDecimales(unidad);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final stockActual = _permiteDecimales
        ? double.tryParse(_stockActualCtrl.text) ?? 0.0
        : int.tryParse(_stockActualCtrl.text) ?? 0;

    final stockMinimo = _permiteDecimales
        ? double.tryParse(_stockMinimoCtrl.text) ?? 0.0
        : int.tryParse(_stockMinimoCtrl.text) ?? 0;

    final producto = Producto(
      id: widget.producto?.id,
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      precioCompra: double.tryParse(_precioCompraCtrl.text) ?? 0.0,
      gastosTransporte: double.tryParse(_transporteCtrl.text) ?? 0.0,
      gastosVarios: double.tryParse(_variosCtrl.text) ?? 0.0,
      precioVenta: double.tryParse(_precioVentaCtrl.text) ?? 0.0,
      margenGanancia: double.tryParse(_margenCtrl.text) ?? 0.0,
      valorITBIS: _impuestos,
      porcentajeImpuesto: _tasaImpuesto,
      aplicaImpuesto: _aplicaImpuesto,
      categoria: _regimenSeleccionado.split('(')[0].trim(),
      regimenImpuesto: _regimenSeleccionado,
      esImpuestoSelectivo: _esSelectivo,
      unidadMedida: _unidadSeleccionada,
      permiteDecimales: _permiteDecimales,
      stockActual: stockActual,
      stockMinimo: stockMinimo,
      fechaRegistro: DateTime.now(),
    );

    await ref.read(productoNotifierProvider.notifier).guardar(producto);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _guardar),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- DATOS BÁSICOS ---
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (v) => v!.isEmpty ? 'Ingrese el código' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // --- UNIDAD DE MEDIDA ✅ CORREGIDO ---
              DropdownButtonFormField<String>(
                initialValue: _unidadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Unidad de Medida',
                ),
                items: Producto.listaUnidadesMedida
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (u) {
                  if (u != null) _cambiarUnidad(u);
                },
              ),
              const SizedBox(height: 16),

              // --- INVENTARIO ---
              const Text(
                '📦 Control de Inventario',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _stockActualCtrl,
                decoration: InputDecoration(
                  labelText: 'Stock Actual',
                  helperText: _permiteDecimales
                      ? 'Admite decimales'
                      : 'Solo números enteros',
                ),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: _permiteDecimales,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el stock actual';
                  final valor = num.tryParse(v);
                  if (valor == null) return 'Ingrese un número válido';
                  if (!_permiteDecimales && valor is double && valor % 1 != 0) {
                    return 'Para esta unidad no se permiten decimales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stockMinimoCtrl,
                decoration: InputDecoration(
                  labelText: 'Stock Mínimo (alerta)',
                  helperText: _permiteDecimales
                      ? 'Admite decimales'
                      : 'Solo números enteros',
                ),
                keyboardType: TextInputType.numberWithOptions(
                  decimal: _permiteDecimales,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el stock mínimo';
                  final valor = num.tryParse(v);
                  if (valor == null) return 'Ingrese un número válido';
                  if (!_permiteDecimales && valor is double && valor % 1 != 0) {
                    return 'Para esta unidad no se permiten decimales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- PRECIOS Y GASTOS ---
              TextFormField(
                controller: _precioCompraCtrl,
                decoration: const InputDecoration(
                  labelText: 'Precio de Compra',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _actualizarCalculos(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _transporteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gastos de Transporte',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _actualizarCalculos(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _variosCtrl,
                decoration: const InputDecoration(labelText: 'Gastos Varios'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => _actualizarCalculos(),
              ),
              const SizedBox(height: 16),

              // --- RÉGIMEN FISCAL ✅ YA CORREGIDO ANTES ---
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: _regimenSeleccionado.isNotEmpty
                    ? Producto.listaRegimenesRD.firstWhere(
                        (r) => r['nombre'] == _regimenSeleccionado,
                      )
                    : null,
                decoration: const InputDecoration(labelText: 'Régimen Fiscal'),
                items: Producto.listaRegimenesRD.map((regimen) {
                  return DropdownMenuItem(
                    value: regimen,
                    child: Text(regimen['nombre']),
                  );
                }).toList(),
                onChanged: (regimen) {
                  if (regimen != null) _cambiarRegimen(regimen);
                },
                validator: (v) => v == null ? 'Seleccione un régimen' : null,
              ),
              const SizedBox(height: 20),

              // --- RESUMEN DE CÁLCULOS ---
              Card(
                elevation: 3,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Resumen de Costos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _fila('Costo sin impuesto', _costoSinImpuesto),
                      _fila('Impuestos aplicables', _impuestos),
                      const Divider(),
                      _fila('Costo final total', _costoFinal, negrita: true),
                      const SizedBox(height: 8),
                      _fila(
                        'Precio sugerido',
                        _precioSugerido,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _precioVentaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Precio de Venta Final',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _actualizarCalculos(),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _margenCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Margen de ganancia (%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _actualizarCalculos(),
                      ),
                      const SizedBox(height: 12),

                      _fila(
                        'Ganancia neta',
                        _ganancia,
                        color: _ganancia >= 0 ? Colors.green : Colors.red,
                      ),
                      _fila('Margen real', _margenReal, sufijo: '%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(
    String titulo,
    double valor, {
    bool negrita = false,
    Color? color,
    String sufijo = ' RD\$',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${valor.toStringAsFixed(2)}$sufijo',
            style: TextStyle(
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
