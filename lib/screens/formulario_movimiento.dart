import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/models/existencia.dart';
import 'package:fiscogestrd/providers/existencia_provider.dart';

class FormularioMovimientoScreen extends ConsumerStatefulWidget {
  const FormularioMovimientoScreen({super.key, this.existencia});
  final Existencia? existencia;

  @override
  ConsumerState<FormularioMovimientoScreen> createState() =>
      _FormularioMovimientoScreenState();
}

class _FormularioMovimientoScreenState
    extends ConsumerState<FormularioMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _minimoController = TextEditingController();
  final _maximoController = TextEditingController();
  final _ubicacionController = TextEditingController();

  String _tipoMovimiento = 'entrada';
  late Existencia _existencia;
  bool _modificarDatos = false;

  // ✅ Función auxiliar para conversión segura
  double _toDoubleSeguro(String valor, [double porDefecto = 0.0]) {
    final limpio = valor.trim().replaceAll(',', '.');
    return double.tryParse(limpio) ?? porDefecto;
  }

  @override
  void initState() {
    super.initState();
    _inicializarExistencia();
    _cargarValoresIniciales();
  }

  void _inicializarExistencia() {
    _existencia = widget.existencia ??
        Existencia(
          productoId: 0,
          codigoProducto: '',
          nombreProducto: '',
          cantidadDisponible: 0.0,
          cantidadReservada: 0.0,
          cantidadMinima: 5.0,
          cantidadMaxima: 1000.0,
          ubicacion: 'Almacén Principal',
        );
  }

  void _cargarValoresIniciales() {
    _minimoController.text = _existencia.cantidadMinima.toStringAsFixed(2);
    _maximoController.text = _existencia.cantidadMaxima.toStringAsFixed(2);
    _ubicacionController.text = _existencia.ubicacion;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _minimoController.dispose();
    _maximoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Existencia _aplicarReglasMovimiento(double cantidad, Existencia temp) {
    switch (_tipoMovimiento) {
      case 'entrada':
        return temp.copyWith(
          cantidadDisponible: temp.cantidadDisponible + cantidad,
        );
      case 'salida':
        if (cantidad > temp.cantidadReal) {
          throw Exception('Cantidad mayor a la existente o reservada');
        }
        return temp.copyWith(
          cantidadDisponible: temp.cantidadDisponible - cantidad,
        );
      case 'reserva':
        return temp.copyWith(
          cantidadReservada: temp.cantidadReservada + cantidad,
        );
      case 'ajuste':
        return temp.copyWith(cantidadDisponible: cantidad);
      default:
        return temp;
    }
  }

  Future<void> _procesarMovimiento() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final cantidad = _toDoubleSeguro(_cantidadController.text);

      final temp = _existencia.copyWith(
        cantidadMinima: _modificarDatos
            ? _toDoubleSeguro(_minimoController.text)
            : _existencia.cantidadMinima,
        cantidadMaxima: _modificarDatos
            ? _toDoubleSeguro(_maximoController.text)
            : _existencia.cantidadMaxima,
        ubicacion: _modificarDatos
            ? _ubicacionController.text.trim()
            : _existencia.ubicacion,
      );

      final existenciaActualizada = _aplicarReglasMovimiento(cantidad, temp);

      setState(() => _existencia = existenciaActualizada);

      await ref
          .read(existenciaNotifierProvider.notifier)
          .guardar(_existencia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Movimiento registrado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final mensaje = e.toString().contains('Exception')
            ? e.toString().replaceAll('Exception: ', '')
            : 'Error al guardar el movimiento';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $mensaje')),
        );
      }
    }
  }

  PreferredSizeWidget _construirAppBar() {
    return AppBar(
      title: Text(
        widget.existencia != null
            ? 'Movimiento: ${_existencia.nombreProducto}'
            : 'Nuevo Movimiento de Inventario',
      ),
    );
  }

  Widget _construirPanelInformacion() {
    final colorFondo = _existencia.tieneExcesoStock
        ? Colors.deepOrange.shade50
        : _existencia.estaBajoMinimo
            ? Colors.red.shade50
            : Colors.green.shade50;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Producto: ${_existencia.codigoProducto} - ${_existencia.nombreProducto}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('✅ Stock Real Disponible: ${_existencia.cantidadReal.toStringAsFixed(2)}'),
          Text('📦 Total Almacenado: ${_existencia.cantidadDisponible.toStringAsFixed(2)}'),
          Text('🔒 Reservado: ${_existencia.cantidadReservada.toStringAsFixed(2)}'),
          Text('⚠️ Mínimo: ${_existencia.cantidadMinima.toStringAsFixed(2)} | 🚀 Máximo: ${_existencia.cantidadMaxima.toStringAsFixed(2)}'),
          Text('📍 Ubicación: ${_existencia.ubicacion}'),
          Text(
            '⏱️ Último movimiento: ${_existencia.fechaFormateada}',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _construirSeccionEdicionDatos() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Modificar datos de inventario'),
          subtitle: const Text('Mínimo, Máximo y Ubicación'),
          value: _modificarDatos,
          onChanged: (valor) => setState(() => _modificarDatos = valor),
          secondary: const Icon(Icons.edit_note),
        ),
        const SizedBox(height: 10),
        if (_modificarDatos) ...[
          Row(
            children: [
              Expanded(child: _campoStockMinimo()),
              const SizedBox(width: 8),
              Expanded(child: _campoStockMaximo()),
            ],
          ),
          const SizedBox(height: 12),
          _campoUbicacion(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _campoStockMinimo() {
    return TextFormField(
      controller: _minimoController,
      decoration: const InputDecoration(
        labelText: 'Stock Mínimo',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        final valorMin = _toDoubleSeguro(v, -1);
        if (valorMin < 0) return 'Valor inválido';
        final valorMax = _toDoubleSeguro(_maximoController.text, 999999);
        if (valorMin >= valorMax) return 'Debe ser menor al máximo';
        return null;
      },
    );
  }

  Widget _campoStockMaximo() {
    return TextFormField(
      controller: _maximoController,
      decoration: const InputDecoration(
        labelText: 'Stock Máximo',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        final valor = _toDoubleSeguro(v, -1);
        if (valor < 0) return 'Valor inválido';
        return null;
      },
    );
  }

  Widget _campoUbicacion() {
    return TextFormField(
      controller: _ubicacionController,
      decoration: const InputDecoration(
        labelText: 'Ubicación / Pasillo / Estante',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ingrese una ubicación' : null,
    );
  }

  Widget _construirSelectorTipoMovimiento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Movimiento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _tipoMovimiento,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'entrada', child: Text('Entrada / Compra')),
            DropdownMenuItem(value: 'salida', child: Text('Salida / Venta')),
            DropdownMenuItem(value: 'reserva', child: Text('Reservar / Apartar')),
            DropdownMenuItem(value: 'ajuste', child: Text('Ajuste de Inventario')),
          ],
          onChanged: (valor) {
            if (valor != null) setState(() => _tipoMovimiento = valor);
          },
        ),
      ],
    );
  }

  Widget _construirCampoCantidad() {
    return TextFormField(
      controller: _cantidadController,
      decoration: const InputDecoration(
        labelText: 'Cantidad a mover',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Ingrese la cantidad';
        final valor = _toDoubleSeguro(v, -1);
        return valor <= 0 ? 'Debe ser mayor a 0' : null;
      },
    );
  }

  Widget _construirBotonGuardar() {
    return ElevatedButton(
      onPressed: _procesarMovimiento,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: const Text('REGISTRAR MOVIMIENTO'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _construirAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.existencia != null) ...[
                _construirPanelInformacion(),
                const SizedBox(height: 20),
                _construirSeccionEdicionDatos(),
              ],
              _construirSelectorTipoMovimiento(),
              const SizedBox(height: 16),
              _construirCampoCantidad(),
              const SizedBox(height: 24),
              _construirBotonGuardar(),
            ],
          ),
        ),
      ),
    );
  }
}