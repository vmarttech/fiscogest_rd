import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/proveedores/domain/entities/proveedor.dart';
import 'package:fiscogest_rd/features/proveedores/presentation/providers/proveedor_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

class RegistrarCompraPage extends ConsumerStatefulWidget {
  const RegistrarCompraPage({super.key});
  static const String routeName = 'registrar-compra';

  @override
  ConsumerState<RegistrarCompraPage> createState() =>
      _RegistrarCompraPageState();
}

class _DetalleLinea {
  int? productoId;
  String nombreProducto = '';
  double cantidad = 0.0;
  double costoUnitario = 0.0;
  double fleteUnitario = 0.0;
  double seguroUnitario = 0.0;
  double arancelesUnitario = 0.0;
  double gastosUnitario = 0.0;
  double descuentoPorcentaje = 0.0;

  double get gastosAsociados =>
      fleteUnitario + seguroUnitario + arancelesUnitario + gastosUnitario;
  double get costoReal => costoUnitario + gastosAsociados;
  double get importeBruto => cantidad * costoUnitario;
  double get montoDescuentoLinea => importeBruto * (descuentoPorcentaje / 100);
  double get subtotalLinea => importeBruto - montoDescuentoLinea;
}

class _ControladoresLinea {
  final productoId = TextEditingController();
  final nombreProducto = TextEditingController();
  final cantidad = TextEditingController();
  final costoUnitario = TextEditingController();
  final fleteUnitario = TextEditingController();
  final seguroUnitario = TextEditingController();
  final arancelesUnitario = TextEditingController();
  final gastosUnitario = TextEditingController();
  final descuento = TextEditingController();

  void dispose() {
    productoId.dispose();
    nombreProducto.dispose();
    cantidad.dispose();
    costoUnitario.dispose();
    fleteUnitario.dispose();
    seguroUnitario.dispose();
    arancelesUnitario.dispose();
    gastosUnitario.dispose();
    descuento.dispose();
  }
}

class _RegistrarCompraPageState extends ConsumerState<RegistrarCompraPage> {
  final _formKey = GlobalKey<FormState>();
  final _fechaController = TextEditingController();
  final _proveedorIdController = TextEditingController();
  final _proveedorNombreController = TextEditingController();
  final _comprobanteController = TextEditingController();
  final _observacionesController = TextEditingController();
  final List<_DetalleLinea> _lineas = [];
  final List<_ControladoresLinea> _controladores = [];

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toLocal().toString().split(' ')[0];
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _proveedorIdController.dispose();
    _proveedorNombreController.dispose();
    _comprobanteController.dispose();
    _observacionesController.dispose();
    for (final c in _controladores) {
      c.dispose();
    }
    super.dispose();
  }

  void _agregarLinea() {
    setState(() {
      _lineas.add(_DetalleLinea());
      _controladores.add(_ControladoresLinea());
    });
  }

  void _eliminarLinea(int index) {
    setState(() {
      _lineas.removeAt(index);
      _controladores[index].dispose();
      _controladores.removeAt(index);
    });
  }

  double get _subtotalSinImpuestos =>
      _lineas.fold(0.0, (sum, linea) => sum + linea.subtotalLinea);
  double get _descuentoGlobal =>
      _lineas.fold(0.0, (sum, linea) => sum + linea.montoDescuentoLinea);
  double get _tasaImpuesto => 0.18;
  double get _montoImpuesto => _subtotalSinImpuestos * _tasaImpuesto;
  double get _totalCompra => _subtotalSinImpuestos + _montoImpuesto;

  Future<void> _seleccionarProveedor() async {
    final estado = ref.read(proveedorControllerProvider);
    final listaProveedores = estado.valueOrNull;
    if (!mounted) return;
    if (listaProveedores?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay proveedores registrados')),
      );
      return;
    }
    await showDialog<Proveedor>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Proveedor', style: AppTypography.h2),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: listaProveedores!.length,
            itemBuilder: (context, index) {
              final prov = listaProveedores[index];
              return ListTile(
                title: Text(prov.nombre, style: AppTypography.bodyMedium),
                subtitle: Text('ID: ${prov.id ?? ''}', style: AppTypography.bodySmall),
                onTap: () {
                  _proveedorIdController.text = prov.id?.toString() ?? '';
                  _proveedorNombreController.text = prov.nombre;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  Future<void> _seleccionarProducto(int indexLinea) async {
    final estado = ref.read(productoControllerProvider);
    final listaProductos = estado.valueOrNull;
    if (!mounted) return;
    if (listaProductos?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay productos registrados')),
      );
      return;
    }
    await showDialog<Producto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: listaProductos!.length,
            itemBuilder: (context, index) {
              final prod = listaProductos[index];
              return ListTile(
                title: Text(prod.nombre),
                subtitle: Text('Código: ${prod.codigo} | ID: ${prod.id ?? ''}'),
                onTap: () {
                  setState(() {
                    final ctrl = _controladores[indexLinea];
                    ctrl.productoId.text = prod.id?.toString() ?? '';
                    ctrl.nombreProducto.text = prod.nombre;
                    _lineas[indexLinea].productoId = prod.id;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  Future<void> _guardarCompra() async {
    for (var i = 0; i < _lineas.length; i++) {
      final ctrl = _controladores[i];
      _lineas[i].productoId = int.tryParse(ctrl.productoId.text.trim());
      _lineas[i].nombreProducto = ctrl.nombreProducto.text.trim();
      _lineas[i].cantidad = double.tryParse(ctrl.cantidad.text) ?? 0;
      _lineas[i].costoUnitario = double.tryParse(ctrl.costoUnitario.text) ?? 0;
      _lineas[i].fleteUnitario = double.tryParse(ctrl.fleteUnitario.text) ?? 0;
      _lineas[i].seguroUnitario = double.tryParse(ctrl.seguroUnitario.text) ?? 0;
      _lineas[i].arancelesUnitario = double.tryParse(ctrl.arancelesUnitario.text) ?? 0;
      _lineas[i].gastosUnitario = double.tryParse(ctrl.gastosUnitario.text) ?? 0;
      _lineas[i].descuentoPorcentaje = double.tryParse(ctrl.descuento.text) ?? 0;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Debe agregar al menos un producto')),
      );
      return;
    }
    final int? proveedorId = int.tryParse(_proveedorIdController.text.trim());
    for (var i = 0; i < _lineas.length; i++) {
      final linea = _lineas[i];
      if (linea.productoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Línea ${i + 1}: Seleccione el producto')),
        );
        return;
      }
      if (linea.cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Línea ${i + 1}: Cantidad debe ser mayor a cero')),
        );
        return;
      }
      if (linea.costoUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Línea ${i + 1}: Costo unitario debe ser mayor a cero')),
        );
        return;
      }
    }
    if (proveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Seleccione un proveedor')),
      );
      return;
    }
    final ahora = DateTime.now();
    final compraId = ahora.millisecondsSinceEpoch;
    final compra = Compra(
      id: compraId,
      proveedorId: proveedorId,
      nombreProveedor: _proveedorNombreController.text.trim(),
      fechaEmision: ahora,
      fechaConfirmacion: null,
      numeroComprobante: _comprobanteController.text.trim(),
      subtotalSinImpuestos: _subtotalSinImpuestos,
      montoDescuentoGlobal: _descuentoGlobal,
      tasaImpuesto: _tasaImpuesto,
      montoImpuesto: _montoImpuesto,
      totalCompra: _totalCompra,
      observaciones: _observacionesController.text.trim(),
      estado: EstadoCompra.borrador,
      creadoEn: ahora,
      actualizadoEn: null,
    );
    final detalles = _lineas.asMap().entries.map((entry) {
      final i = entry.key;
      final linea = entry.value;
      return DetalleCompra(
        id: compraId * 1000 + i,
        compraId: compraId,
        productoId: linea.productoId!,
        nombreProducto: linea.nombreProducto,
        cantidad: linea.cantidad,
        costoUnitario: linea.costoUnitario,
        fleteUnitario: linea.fleteUnitario,
        seguroUnitario: linea.seguroUnitario,
        arancelesUnitario: linea.arancelesUnitario,
        gastosUnitario: linea.gastosUnitario,
        costoAdquisicion: linea.costoReal,
        descuentoPorcentaje: linea.descuentoPorcentaje,
        montoDescuentoLinea: linea.montoDescuentoLinea,
        subtotalLinea: linea.subtotalLinea,
      );
    }).toList();
    try {
      await ref
          .read(registrarCompraUseCaseProvider)
          .call(compra: compra, detalles: detalles);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Compra guardada como borrador')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrar Compra',
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Datos de la Compra', style: AppTypography.h4),
                AppLayout.vS,
                AppTextField(
                  controller: _fechaController,
                  label: 'Fecha Emisión',
                  enabled: false,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                AppLayout.vM,
                ResponsiveRow(
                  child1: AppTextField(
                    controller: _proveedorIdController,
                    label: 'ID Proveedor',
                  ),
                  child2: GestureDetector(
                    onTap: _seleccionarProveedor,
                    child: AbsorbPointer(
                      child: AppTextField(
                        controller: _proveedorNombreController,
                        label: 'Proveedor',
                        prefixIcon: Icons.search,
                      ),
                    ),
                  ),
                ),
                AppLayout.vM,
                AppTextField(
                  controller: _comprobanteController,
                  label: 'Comprobante / Nº Factura',
                  prefixIcon: Icons.receipt_outlined,
                ),
                AppLayout.vM,
                AppTextField(
                  controller: _observacionesController,
                  label: 'Observaciones',
                  prefixIcon: Icons.notes_outlined,
                ),
                AppLayout.vL,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Productos / Líneas', style: AppTypography.h4),
                    ElevatedButton.icon(
                      onPressed: _agregarLinea,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                AppLayout.vS,
                if (_lineas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No hay productos. Presione "Agregar" para iniciar.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._lineas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final linea = entry.value;
                    final ctrl = _controladores[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      child: Padding(
                        padding: AppSpacing.allM,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Línea ${index + 1}', style: AppTypography.labelMedium),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _eliminarLinea(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ResponsiveRow(
                              child1: AppTextField(
                                controller: ctrl.productoId,
                                label: 'ID',
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: GestureDetector(
                                onTap: () => _seleccionarProducto(index),
                                child: AbsorbPointer(
                                  child: AppTextField(
                                    controller: ctrl.nombreProducto,
                                    label: 'Seleccionar Producto',
                                    prefixIcon: Icons.search,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Costos', style: AppTypography.labelMedium),
                            const SizedBox(height: 4),
                            ResponsiveRow(
                              child1: AppTextField(
                                controller: ctrl.cantidad,
                                label: 'Cantidad',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}'))],
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: AppTextField(
                                controller: ctrl.costoUnitario,
                                label: 'Costo Compra (RD\$)',
                                prefixIcon: Icons.payments_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ResponsiveRow(
                              child1: AppTextField(
                                controller: ctrl.fleteUnitario,
                                label: 'Flete por unidad',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: AppTextField(
                                controller: ctrl.seguroUnitario,
                                label: 'Seguro por unidad',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ResponsiveRow(
                              child1: AppTextField(
                                controller: ctrl.arancelesUnitario,
                                label: 'Aranceles por unidad',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: AppTextField(
                                controller: ctrl.gastosUnitario,
                                label: 'Otros Gastos por unidad',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              controller: ctrl.descuento,
                              label: 'Descuento (%)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gastos Asociados: RD\$ ${linea.gastosAsociados.toStringAsFixed(2)}',
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.blue.shade700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Costo Real: RD\$ ${linea.costoReal.toStringAsFixed(2)}',
                                    style: AppTypography.labelMedium.copyWith(color: Colors.blue.shade900),
                                  ),
                                  const Divider(height: 8),
                                  Text(
                                    'Subtotal Línea: RD\$ ${linea.subtotalLinea.toStringAsFixed(2)}',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                AppLayout.vL,
                const Divider(height: 1),
                AppLayout.vM,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: RD\$ ${_subtotalSinImpuestos.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                        Text('Descuentos: RD\$ ${_descuentoGlobal.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                        Text('ITBIS (18%): RD\$ ${_montoImpuesto.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                        const Divider(),
                        Text('TOTAL: RD\$ ${_totalCompra.toStringAsFixed(2)}', style: AppTypography.labelLarge),
                      ],
                    ),
                  ],
                ),
                AppLayout.vL,
                Row(
                  children: [
                    Expanded(child: AppButton(text: 'Cancelar', icon: Icons.close, onPressed: () => Navigator.pop(context))),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(child: AppButton(text: 'Guardar Compra', icon: Icons.check_circle_outline, onPressed: _guardarCompra)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
