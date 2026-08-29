import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/lista_precios.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/lista_precios_provider.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';

class EditarPreciosProductoPage extends ConsumerStatefulWidget {

  const EditarPreciosProductoPage({super.key, required this.producto});
  final Producto producto;

  @override
  ConsumerState<EditarPreciosProductoPage> createState() => _EditarPreciosProductoPageState();
}

class _EditarPreciosProductoPageState extends ConsumerState<EditarPreciosProductoPage> {
  late final TextEditingController _costoCtrl;
  late final TextEditingController _precioVentaCtrl;
  late final TextEditingController _margenCtrl;
  late final TextEditingController _precioMinimoCtrl;
  late final TextEditingController _precioMayoristaCtrl;
  late final TextEditingController _precioEspecialCtrl;

  @override
  void initState() {
    super.initState();
    _costoCtrl = TextEditingController(text: widget.producto.precioCompra.toStringAsFixed(2));
    _precioVentaCtrl = TextEditingController(text: widget.producto.precioVenta.toStringAsFixed(2));
    _margenCtrl = TextEditingController(text: widget.producto.margenGanancia?.toStringAsFixed(2) ?? '0.00');
    _precioMinimoCtrl = TextEditingController(text: widget.producto.precioMinimo?.toStringAsFixed(2) ?? '');
    _precioMayoristaCtrl = TextEditingController(text: widget.producto.precioMayorista?.toStringAsFixed(2) ?? '');
    _precioEspecialCtrl = TextEditingController(text: widget.producto.precioEspecial?.toStringAsFixed(2) ?? '');
  }

  void _calcularPrecioDesdeMargen() {
    final calcular = ref.read(calcularPrecioDesdeMargenProvider);
    final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
    final margen = double.tryParse(_margenCtrl.text) ?? 0.0;
    if (costo > 0 && margen >= 0) {
      final precio = calcular(costo: costo, margen: margen);
      _precioVentaCtrl.text = precio.toStringAsFixed(2);
    }
  }

  void _calcularMargenDesdePrecio() {
    final calcular = ref.read(calcularMargenProvider);
    final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
    final precio = double.tryParse(_precioVentaCtrl.text) ?? 0.0;
    if (costo > 0 && precio > 0) {
      final margen = calcular(precioVenta: precio, costo: costo);
      _margenCtrl.text = margen.toStringAsFixed(2);
    }
  }

  Future<void> _guardar() async {
    final lista = ListaPrecios(
      productoId: widget.producto.id.toString(),
      precioVenta: double.tryParse(_precioVentaCtrl.text) ?? 0.0,
      margenGanancia: double.tryParse(_margenCtrl.text),
      precioMinimo: double.tryParse(_precioMinimoCtrl.text),
      precioMayorista: double.tryParse(_precioMayoristaCtrl.text),
      precioEspecial: double.tryParse(_precioEspecialCtrl.text),
    );
    await ref.read(listaPreciosRepositoryProvider).guardar(lista);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _costoCtrl.dispose();
    _precioVentaCtrl.dispose();
    _margenCtrl.dispose();
    _precioMinimoCtrl.dispose();
    _precioMayoristaCtrl.dispose();
    _precioEspecialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Precios de Venta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Producto: ${widget.producto.nombre}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _costoCtrl,
              decoration: const InputDecoration(
                labelText: 'Costo (solo lectura)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _margenCtrl,
              decoration: InputDecoration(
                labelText: 'Margen de ganancia %',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: _calcularPrecioDesdeMargen,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularPrecioDesdeMargen(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioVentaCtrl,
              decoration: InputDecoration(
                labelText: 'Precio de Venta',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: _calcularMargenDesdePrecio,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularMargenDesdePrecio(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioMinimoCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio Mínimo',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioMayoristaCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio Mayorista',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioEspecialCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio Especial',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar Precios'),
            ),
          ],
        ),
      ),
    );
  }
}
