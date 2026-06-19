import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/producto.dart';
import 'package:fiscogestrd/providers/producto_providers.dart';
import 'package:fiscogestrd/screens/productos_por_regimen_screen.dart';

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
  final _ctrlUnidadPersonalizada =
      TextEditingController(); // ✅ NUEVO para "OTRA..."

  // ✅ FUNCIÓN SEGURA ADAPTADA A FORMATO RD (COMA → PUNTO, VALOR 0.0 SI FALLA)
  double _toDoubleSeguro(String valor) {
    final limpio = valor.trim().replaceAll(',', '.');
    return double.tryParse(limpio) ?? 0.0;
  }

  // ✅ LISTA DE RÉGIMENES (IGUAL)
  final List<Map<String, dynamic>> _listaRegimenesCompleta =
      Producto.listaRegimenesRD;
  // ✅ LISTA DE UNIDADES ACTUALIZADA SEGÚN PROPUESTA
  final List<String> _listaUnidades = Producto.listaUnidadesMedida;

  Map<String, dynamic> _categoriaSeleccionada = {};
  String _unidadMedida = 'UNIDAD';
  bool _permiteDecimales = false; // ✅ NUEVO
  bool _mostrarCampoUnidad = false; // ✅ NUEVO para "OTRA..."

  double _costoTotal = 0.0;
  double _baseImponible = 0.0;
  double _valorImpuesto = 0.0;
  double _gananciaNeta = 0.0;
  double _precioFinal = 0.0;
  bool _modoCalculando = false;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = _listaRegimenesCompleta[0];
    _cargarDatosExistentes();
    _agregarListeners();
    // ✅ Inicializar si permite decimales según unidad por defecto
    _permiteDecimales = Producto.verificarSiPermiteDecimales(_unidadMedida);
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

      // ✅ CARGA DE DATOS DE UNIDAD
      _unidadMedida = prod.unidadMedida;
      _permiteDecimales = prod.permiteDecimales;
      // Si la unidad no está en la lista, asumimos que es personalizada
      if (!_listaUnidades.contains(_unidadMedida)) {
        _mostrarCampoUnidad = true;
        _ctrlUnidadPersonalizada.text = _unidadMedida;
      }

      _categoriaSeleccionada = _listaRegimenesCompleta.firstWhere(
        (reg) => reg['nombre'] == prod.regimenImpuesto,
        orElse: () => _listaRegimenesCompleta[0],
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _calcularDesdeMargen(),
      );
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
    _ctrlUnidadPersonalizada.dispose(); // ✅ NUEVO
    super.dispose();
  }

  void _actualizarCostos() {
    // ✅ USO DE FUNCIÓN SEGURA
    final compra = _toDoubleSeguro(_ctrlPrecioCompra.text);
    final transporte = _toDoubleSeguro(_ctrlGastosTransporte.text);
    final varios = _toDoubleSeguro(_ctrlGastosVarios.text);

    setState(() {
      _costoTotal = compra + transporte + varios;
    });
    _calcularDesdeMargen();
  }

  void _calcularDesdeMargen() {
    if (_modoCalculando || _costoTotal <= 0) return;
    _modoCalculando = true;

    // ✅ USO DE FUNCIÓN SEGURA
    final margen = _toDoubleSeguro(_ctrlMargen.text);
    setState(() {
      _baseImponible = _costoTotal * (1 + (margen / 100));
      _gananciaNeta = _baseImponible - _costoTotal;

      if (!_categoriaSeleccionada['aplicaImpuesto']) {
        _valorImpuesto = 0.0;
        _precioFinal = _baseImponible;
      } else {
        _valorImpuesto =
            _baseImponible * (_categoriaSeleccionada['tasa'] / 100);
        _precioFinal = _baseImponible + _valorImpuesto;
      }

      _ctrlPrecioVenta.text = _precioFinal.toStringAsFixed(2);
    });

    _modoCalculando = false;
  }

  void _calcularDesdePrecio() {
    if (_modoCalculando) return;
    _modoCalculando = true;

    // ✅ USO DE FUNCIÓN SEGURA
    final precioFinal = _toDoubleSeguro(_ctrlPrecioVenta.text);
    if (precioFinal <= 0 || _costoTotal <= 0) {
      _modoCalculando = false;
      return;
    }

    setState(() {
      if (!_categoriaSeleccionada['aplicaImpuesto']) {
        _baseImponible = precioFinal;
        _valorImpuesto = 0.0;
      } else {
        _baseImponible =
            precioFinal / (1 + (_categoriaSeleccionada['tasa'] / 100));
        _valorImpuesto = precioFinal - _baseImponible;
      }

      _gananciaNeta = _baseImponible - _costoTotal;
      final margenCalc = ((_baseImponible - _costoTotal) / _costoTotal) * 100;
      _ctrlMargen.text = margenCalc.toStringAsFixed(2);
    });

    _modoCalculando = false;
  }

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      // ✅ DEFINIR UNIDAD FINAL (SI ES PERSONALIZADA)
      String unidadFinal = _unidadMedida;
      if (_unidadMedida == 'OTRA...') {
        unidadFinal = _ctrlUnidadPersonalizada.text.trim().toUpperCase();
        if (unidadFinal.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingrese el nombre de la unidad personalizada'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      final Producto producto = Producto(
        id: widget.producto?.id,
        codigo: _ctrlCodigo.text.trim(),
        nombre: _ctrlNombre.text.trim(),
        descripcion: _ctrlDescripcion.text.trim(),
        // ✅ CONVERSIÓN SEGURA EN TODOS LOS CAMPOS NUMÉRICOS
        precioCompra: _toDoubleSeguro(_ctrlPrecioCompra.text),
        gastosTransporte: _toDoubleSeguro(_ctrlGastosTransporte.text),
        gastosVarios: _toDoubleSeguro(_ctrlGastosVarios.text),
        precioVenta: _precioFinal,
        margenGanancia: _toDoubleSeguro(_ctrlMargen.text),
        valorITBIS: _valorImpuesto,
        porcentajeImpuesto: _categoriaSeleccionada['tasa'],
        aplicaImpuesto: _categoriaSeleccionada['aplicaImpuesto'],
        categoria: _categoriaSeleccionada['nombre'].split('(')[0].trim(),
        regimenImpuesto: _categoriaSeleccionada['nombre'],
        esImpuestoSelectivo: _categoriaSeleccionada['esSelectivo'],
        // ✅ GUARDADO DE NUEVOS CAMPOS
        unidadMedida: unidadFinal,
        permiteDecimales: _permiteDecimales,
        // ✅ STOCK CONVERTIDO DE FORMA SEGURA Y COMPATIBLE
        stockActual: _permiteDecimales
            ? _toDoubleSeguro(_ctrlStockActual.text)
            : _toDoubleSeguro(_ctrlStockActual.text).round(),
        stockMinimo: _permiteDecimales
            ? _toDoubleSeguro(_ctrlStockMinimo.text)
            : _toDoubleSeguro(_ctrlStockMinimo.text).round(),
        fechaRegistro: DateTime.now(),
      );

      try {
        await ref.read(productoNotifierProvider.notifier).guardar(producto);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Producto guardado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.producto != null ? 'Editar Producto' : 'Nuevo Producto',
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _guardarProducto,
            child: const Text(
              'GUARDAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📋 INFORMACIÓN BÁSICA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlCodigo,
                decoration: const InputDecoration(
                  labelText: 'Código / Referencia',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctrlNombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre o Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctrlDescripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción Larga (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                '💰 ESTRUCTURA DE COSTOS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlPrecioCompra,
                decoration: const InputDecoration(
                  labelText: 'Costo del Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlGastosTransporte,
                decoration: const InputDecoration(
                  labelText: 'Gastos de Transporte',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ctrlGastosVarios,
                decoration: const InputDecoration(
                  labelText: 'Otros Gastos / Impuestos Adicionales',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // ✅ SECCIÓN CORREGIDA (EVITA DESBORDAMIENTO)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚖️ CLASIFICACIÓN FISCAL (DGII - RD)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: const Text('Ver productos de este régimen'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductosPorRegimenScreen(
                            nombreRegimen: _categoriaSeleccionada['nombre'],
                            tasa: _categoriaSeleccionada['tasa'],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ✅ DROPDOWN RÉGIMEN (CORREGIDO initialValue)
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(
                  labelText: 'Régimen de Impuesto Aplicable',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                  helperText: 'Seleccione según normativa DGII',
                ),
                isExpanded: true,
                items: _listaRegimenesCompleta.map((regimen) {
                  return DropdownMenuItem(
                    value: regimen,
                    child: Text(regimen['nombre']),
                  );
                }).toList(),
                initialValue: _categoriaSeleccionada,
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => _categoriaSeleccionada = valor);
                    _calcularDesdeMargen();
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  _categoriaSeleccionada['descripcion'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                '📈 RENTABILIDAD Y PRECIO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ctrlMargen,
                      decoration: const InputDecoration(
                        labelText: 'Margen %',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _ctrlPrecioVenta,
                      decoration: const InputDecoration(
                        labelText: 'Precio Final',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sell),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
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
                    const Text(
                      '📊 RESUMEN DE CÁLCULOS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Imponible:'),
                        Text('RD\$ ${_baseImponible.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_categoriaSeleccionada['esSelectivo'] ? 'Impuesto Selectivo' : 'ITBIS'} (${_categoriaSeleccionada['tasa']}%):',
                        ),
                        Text(
                          'RD\$ ${_valorImpuesto.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _valorImpuesto > 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
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
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL A PAGAR:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'RD\$ ${_precioFinal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ SECCIÓN DE UNIDADES DE MEDIDA ACTUALIZADA
              const Text(
                '📦 INVENTARIO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Unidad de Medida',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                isExpanded: true,
                // ✅ LISTA AMPLIADA
                items: _listaUnidades
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                // ✅ CORREGIDO initialValue
                initialValue: _unidadMedida,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _unidadMedida = v;
                      // ✅ LÓGICA AUTOMÁTICA DECIMALES
                      _permiteDecimales = Producto.verificarSiPermiteDecimales(
                        v,
                      );
                      // ✅ MOSTRAR CAMPO SI ES OTRA
                      _mostrarCampoUnidad = (v == 'OTRA...');
                    });
                  }
                },
              ),

              // ✅ CAMPO DINÁMICO PARA UNIDAD PERSONALIZADA
              if (_mostrarCampoUnidad) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ctrlUnidadPersonalizada,
                  decoration: const InputDecoration(
                    labelText: 'Ingrese nombre de la unidad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                    helperText: 'Ej: FUNDA, TABLETA, SERVICIO, HORA...',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (val) {
                    if (_unidadMedida == 'OTRA...' &&
                        (val == null || val.isEmpty)) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ],

              // ✅ INDICADOR VISUAL DE DECIMALES
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  _permiteDecimales
                      ? '✅ Permite valores decimales (ej: 1.5 Kilo, 2.25 Litros)'
                      : 'ℹ️ Solo valores enteros (ej: 1 Caja, 5 Unidades)',
                  style: TextStyle(
                    fontSize: 11,
                    color: _permiteDecimales
                        ? Colors.green.shade700
                        : Colors.blueGrey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ctrlStockActual,
                      decoration: const InputDecoration(
                        labelText: 'Existencia Actual',
                        border: OutlineInputBorder(),
                      ),
                      // ✅ TECLADO SEGÚN PERMITE DECIMALES
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: _permiteDecimales,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        // ✅ VALIDACIÓN DE FORMATO CON FUNCIÓN SEGURA
                        final valor = _toDoubleSeguro(v);
                        if (!_permiteDecimales &&
                            valor != valor.roundToDouble()) {
                          return 'Solo números enteros';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _ctrlStockMinimo,
                      decoration: const InputDecoration(
                        labelText: 'Stock Mínimo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: _permiteDecimales,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final valor = _toDoubleSeguro(v);
                        if (!_permiteDecimales &&
                            valor != valor.roundToDouble()) {
                          return 'Solo números enteros';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
