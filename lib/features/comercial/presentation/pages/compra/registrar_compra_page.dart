import 'package:flutter/material.dart';
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
  double descuentoPorcentaje = 0.0;

  double get importeBruto => cantidad * costoUnitario;
  double get montoDescuentoLinea => importeBruto * (descuentoPorcentaje / 100);
  double get subtotalLinea => importeBruto - montoDescuentoLinea;
}

class _ControladoresLinea {
  final productoId = TextEditingController();
  final nombreProducto = TextEditingController();
  final cantidad = TextEditingController();
  final costoUnitario = TextEditingController();
  final descuento = TextEditingController();

  void dispose() {
    productoId.dispose();
    nombreProducto.dispose();
    cantidad.dispose();
    costoUnitario.dispose();
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

  double get _subtotalSinImpuestos {
    return _lineas.fold(0.0, (sum, linea) => sum + linea.subtotalLinea);
  }

  double get _descuentoGlobal {
    return _lineas.fold(0.0, (sum, linea) => sum + linea.montoDescuentoLinea);
  }

  double get _tasaImpuesto => 0.18;
  double get _montoImpuesto => _subtotalSinImpuestos * _tasaImpuesto;
  double get _totalCompra => _subtotalSinImpuestos + _montoImpuesto;

  Future<void> _seleccionarProveedor() async {
    final estado = ref.read(proveedorControllerProvider);
    final listaProveedores = estado.valueOrNull;
    if (!mounted) return;
    if (listaProveedores?.isEmpty ?? true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ No hay proveedores registrados',
              style: TextStyle(fontSize: 12),
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await showDialog<Proveedor>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Seleccionar Proveedor',
          style: AppTypography.h2.copyWith(fontSize: 14),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: listaProveedores!.length,
            itemBuilder: (context, index) {
              final prov = listaProveedores[index];
              return ListTile(
                title: Text(
                  prov.nombre,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
                subtitle: Text(
                  'ID: ${prov.id ?? ''}',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
                onTap: () {
                  _proveedorIdController.text = prov.id?.toString() ?? '';
                  _proveedorNombreController.text = prov.nombre;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) Navigator.pop(context);
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.pop(context);
              });
            },
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarProducto(int indexLinea) async {
    final estado = ref.read(productoControllerProvider);
    final listaProductos = estado.valueOrNull;
    if (listaProductos?.isEmpty ?? true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ No hay productos registrados',
              style: TextStyle(fontSize: 12),
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    await showDialog<Producto>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Seleccionar Producto',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: listaProductos!.length,
            itemBuilder: (context, index) {
              final prod = listaProductos[index];
              return ListTile(
                title: Text(prod.nombre, style: const TextStyle(fontSize: 12)),
                subtitle: Text(
                  'Código: ${prod.codigo} | ID: ${prod.id ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  setState(() {
                    final ctrl = _controladores[indexLinea];
                    ctrl.productoId.text = prod.id?.toString() ?? '';
                    ctrl.nombreProducto.text = prod.nombre;
                    _lineas[indexLinea].productoId = prod.id;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) Navigator.pop(context);
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) Navigator.pop(context);
              });
            },
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
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
      _lineas[i].descuentoPorcentaje =
          double.tryParse(ctrl.descuento.text) ?? 0;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Debe agregar al menos un producto',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
      return;
    }

    final int? proveedorId = int.tryParse(_proveedorIdController.text.trim());

    for (var i = 0; i < _lineas.length; i++) {
      final linea = _lineas[i];
      if (linea.productoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Línea ${i + 1}: Seleccione o ingrese el producto',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
        return;
      }
      if (linea.cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Línea ${i + 1}: La cantidad debe ser mayor a cero',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
        return;
      }
      if (linea.costoUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Línea ${i + 1}: El costo unitario debe ser mayor a cero',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
        return;
      }
    }

    final ahora = DateTime.now();
    final compraId = ahora.millisecondsSinceEpoch;

    if (proveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Seleccione un proveedor',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
      return;
    }

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
          const SnackBar(
            content: Text(
              '✅ Compra guardada como borrador',
              style: TextStyle(fontSize: 12),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
          ),
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
                const Text(
                  'Datos de la Compra',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  controller: _fechaController,
                  label: 'Fecha Emisión',
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _proveedorIdController,
                        label: 'ID Prov.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _seleccionarProveedor,
                        child: AbsorbPointer(
                          child: AppTextField(
                            controller: _proveedorNombreController,
                            label: 'Proveedor',
                            enabled: false,
                            prefixIcon: Icons.search,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  controller: _comprobanteController,
                  label: 'Comprobante',
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  controller: _observacionesController,
                  label: 'Observaciones',
                ),
                const SizedBox(height: AppSpacing.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Productos / Líneas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _agregarLinea,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(80, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                if (_lineas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No hay productos. Presione "Agregar".',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 12,
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
                                Text(
                                  'Línea ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => _eliminarLinea(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: AppTextField(
                                    controller: ctrl.productoId,
                                    label: 'ID',
                                    onChanged: (v) => setState(
                                      () => linea.productoId = int.tryParse(v),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    onTap: () => _seleccionarProducto(index),
                                    child: AbsorbPointer(
                                      child: AppTextField(
                                        controller: ctrl.nombreProducto,
                                        label: 'Producto',
                                        enabled: false,
                                        prefixIcon: Icons.search,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: ctrl.cantidad,
                                    label: 'Cant.',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (v) {
                                      setState(() {
                                        linea.cantidad =
                                            double.tryParse(v) ?? 0;
                                        ctrl.cantidad.selection =
                                            TextSelection.collapsed(
                                              offset: ctrl.cantidad.text.length,
                                            );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: AppTextField(
                                    controller: ctrl.costoUnitario,
                                    label: 'Costo',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (v) {
                                      setState(() {
                                        linea.costoUnitario =
                                            double.tryParse(v) ?? 0;
                                        ctrl.costoUnitario.selection =
                                            TextSelection.collapsed(
                                              offset: ctrl
                                                  .costoUnitario
                                                  .text
                                                  .length,
                                            );
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: AppTextField(
                                    controller: ctrl.descuento,
                                    label: '%Desc',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged: (v) {
                                      setState(() {
                                        linea.descuentoPorcentaje =
                                            double.tryParse(v) ?? 0;
                                        ctrl.descuento.selection =
                                            TextSelection.collapsed(
                                              offset:
                                                  ctrl.descuento.text.length,
                                            );
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Subtotal: \$${linea.subtotalLinea.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.l),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Subtotal: \$${_subtotalSinImpuestos.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Descuentos: \$${_descuentoGlobal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'ITBIS (18%): \$${_montoImpuesto.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Divider(),
                        Text(
                          'TOTAL: \$${_totalCompra.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Guardar Compra',
                    onPressed: _guardarCompra,
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
