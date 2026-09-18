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
  static String routeName = 'registrar-compra';
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
  double get baseImponibleLinea => subtotalLinea;
  double get tasaImpuestoLinea => 0.18;
  double get itbisLinea => baseImponibleLinea * tasaImpuestoLinea;
  double get totalLinea => baseImponibleLinea + itbisLinea + gastosAsociados;
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
  final _ncfController = TextEditingController();
  String _tipoComprobante = 'B01';
  String _formaPago = 'contado';
  final _condicionPagoController = TextEditingController(text: 'contado');
  final _diasCreditoController = TextEditingController(text: '0');
  final _fechaVencimientoController = TextEditingController();
  EstadoCompra _estadoGuardado = EstadoCompra.borrador;
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
    _ncfController.dispose();
    _condicionPagoController.dispose();
    _diasCreditoController.dispose();
    _fechaVencimientoController.dispose();
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
      _controladores[index].dispose();
      _lineas.removeAt(index);
      _controladores.removeAt(index);
    });
  }

  double get _subtotalSinImpuestos =>
      _lineas.fold(0.0, (sum, linea) => sum + linea.subtotalLinea);
  double get _descuentoGlobal =>
      _lineas.fold(0.0, (sum, linea) => sum + linea.montoDescuentoLinea);
  double get _tasaImpuesto => 0.18;
  double get _montoImpuesto =>
      _lineas.fold(0.0, (sum, linea) => sum + linea.itbisLinea);
  double get _totalCompra =>
      _lineas.fold(0.0, (sum, linea) => sum + linea.totalLinea);

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
                title: Text(prov.nombreEmpresa, style: AppTypography.bodyMedium),
                subtitle: Text('ID: ${prov.id ?? ''}', style: AppTypography.bodySmall),
                onTap: () {
                  _proveedorIdController.text = prov.id?.toString() ?? '';
                  _proveedorNombreController.text = prov.nombreEmpresa;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
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
        title: const Text(
          'Seleccionar Producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFormaPago(String valor, String etiqueta) {
    final seleccionado = _formaPago == valor;
    return InkWell(
      onTap: () => setState(() => _formaPago = valor),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: seleccionado
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: seleccionado
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: AppTypography.bodyMedium.copyWith(
                color: seleccionado ? Theme.of(context).primaryColor : null,
                fontWeight: seleccionado ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipTipoComprobante(String valor, String etiqueta) {
    final seleccionado = _tipoComprobante == valor;
    return InkWell(
      onTap: () => setState(() => _tipoComprobante = valor),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
        ),
        child: Text(
          '$valor • $etiqueta',
          style: AppTypography.bodySmall.copyWith(
            color: seleccionado ? Theme.of(context).primaryColor : null,
            fontWeight: seleccionado ? FontWeight.w500 : null,
          ),
        ),
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
      _lineas[i].arancelesUnitario =
          double.tryParse(ctrl.arancelesUnitario.text) ?? 0;
      _lineas[i].gastosUnitario = double.tryParse(ctrl.gastosUnitario.text) ?? 0;
      _lineas[i].descuentoPorcentaje =
          double.tryParse(ctrl.descuento.text) ?? 0;
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
          SnackBar(
            content: Text('⚠️ Línea ${i + 1}: Cantidad debe ser mayor a cero'),
          ),
        );
        return;
      }
      if (linea.costoUnitario <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Línea ${i + 1}: Costo unitario debe ser mayor a cero',
            ),
          ),
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
    final diasCredito = int.tryParse(_diasCreditoController.text) ?? 0;
    final fechaVencimientoTexto = _fechaVencimientoController.text.trim();
    final fechaVencimiento = fechaVencimientoTexto.isNotEmpty
        ? DateTime.tryParse(fechaVencimientoTexto)
        : null;

    final compra = Compra(
      id: compraId,
      proveedorId: proveedorId,
      nombreProveedor: _proveedorNombreController.text.trim(),
      fechaEmision: ahora,
      fechaVencimiento: fechaVencimiento,
      fechaConfirmacion: null,
      fechaRecepcion: null,
      numeroComprobante: _comprobanteController.text.trim(),
      ncf: _ncfController.text.trim(),
      tipoComprobante: _tipoComprobante,
      formaPago: _formaPago,
      condicionPago: _condicionPagoController.text.trim(),
      diasCredito: diasCredito,
      subtotalSinImpuestos: _subtotalSinImpuestos,
      montoDescuentoGlobal: _descuentoGlobal,
      tasaImpuesto: _tasaImpuesto,
      montoImpuesto: _montoImpuesto,
      totalCompra: _totalCompra,
      observaciones: _observacionesController.text.trim(),
      estado: _estadoGuardado,
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
        baseImponibleLinea: linea.baseImponibleLinea,
        tasaImpuestoLinea: linea.tasaImpuestoLinea,
        itbisLinea: linea.itbisLinea,
        totalLinea: linea.totalLinea,
      );
    }).toList();

    try {
      await ref
          .read(registrarCompraUseCaseProvider)
          .call(compra: compra, detalles: detalles);
      if (mounted) {
        final mensaje = _estadoGuardado == EstadoCompra.registrada
            ? '✅ Compra registrada correctamente'
            : '✅ Compra guardada como borrador';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
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

  Future<void> _guardarComoBorrador() async {
    _estadoGuardado = EstadoCompra.borrador;
    await _guardarCompra();
  }

  Future<void> _registrarCompraDirecta() async {
    _estadoGuardado = EstadoCompra.registrada;
    await _guardarCompra();
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPequena = anchoPantalla < 700;

    Widget filaResponsiva({required Widget child1, required Widget child2}) {
      if (esPequena) {
        return Column(
          children: [
            child1,
            AppLayout.vM,
            child2,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          AppLayout.hM,
          Expanded(child: child2),
        ],
      );
    }

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
                filaResponsiva(
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
                filaResponsiva(
                  child1: AppTextField(
                    controller: _comprobanteController,
                    label: 'Comprobante / Nº Factura',
                    prefixIcon: Icons.receipt_outlined,
                  ),
                  child2: AppTextField(
                    controller: _ncfController,
                    label: 'NCF (ej: B01-00000000)',
                    prefixIcon: Icons.confirmation_num_outlined,
                  ),
                ),
                AppLayout.vM,
                const Text(
                  'Tipo de Comprobante',
                  style: AppTypography.labelMedium,
                ),
                AppLayout.vS,
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    _buildChipTipoComprobante('B01', 'Gastos'),
                    _buildChipTipoComprobante('B02', 'Activos'),
                    _buildChipTipoComprobante('B14', 'Gastos Menores'),
                    _buildChipTipoComprobante('B15', 'Exento'),
                  ],
                ),
                AppLayout.vM,
                const Text(
                  'Forma de Pago',
                  style: AppTypography.labelMedium,
                ),
                AppLayout.vS,
                Row(
                  children: [
                    _buildBotonFormaPago('contado', 'Contado'),
                    AppLayout.hM,
                    _buildBotonFormaPago('credito', 'Crédito'),
                  ],
                ),
                AppLayout.vM,
                if (_formaPago == 'credito') ...[
                  filaResponsiva(
                    child1: AppTextField(
                      controller: _condicionPagoController,
                      label: 'Condición de Pago (ej: 30 días)',
                    ),
                    child2: AppTextField(
                      controller: _diasCreditoController,
                      label: 'Días de Crédito',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  AppLayout.vM,
                ],
                AppTextField(
                  controller: _fechaVencimientoController,
                  label: 'Fecha de Vencimiento (YYYY-MM-DD)',
                  prefixIcon: Icons.event_outlined,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ..._lineas.asMap().entries.map((entry) {
                    final index = entry.key;
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
                                  style: AppTypography.labelMedium,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
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
                            const SizedBox(height: 4),
                            filaResponsiva(
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
                            const Text(
                              'Costos',
                              style: AppTypography.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            filaResponsiva(
                              child1: AppTextField(
                                controller: ctrl.cantidad,
                                label: 'Cantidad',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,4}'),
                                  ),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: AppTextField(
                                controller: ctrl.costoUnitario,
                                label: 'Costo Compra (RD\$)',
                                prefixIcon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 8),
                            filaResponsiva(
                              child1: AppTextField(
                                controller: ctrl.fleteUnitario,
                                label: 'Flete por unidad',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: AppTextField(
                                controller: ctrl.seguroUnitario,
                                label: 'Seguro por unidad',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 8),
                            filaResponsiva(
                              child1: AppTextField(
                                controller: ctrl.arancelesUnitario,
                                label: 'Aranceles por unidad',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                              child2: AppTextField(
                                controller: ctrl.gastosUnitario,
                                label: 'Otros Gastos por unidad',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              controller: ctrl.descuento,
                              label: 'Descuento (%)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Subtotal: RD\$ ${_lineas[index].subtotalLinea.toStringAsFixed(2)}',
                                    style: AppTypography.bodyMedium,
                                  ),
                                  Text(
                                    'ITBIS (18%): RD\$ ${_lineas[index].itbisLinea.toStringAsFixed(2)}',
                                    style: AppTypography.bodyMedium,
                                  ),
                                  const Divider(height: 8),
                                  Text(
                                    'Total Línea: RD\$ ${_lineas[index].totalLinea.toStringAsFixed(2)}',
                                    style: AppTypography.labelLarge,
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
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: AppSpacing.allM,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('RD\$ ${_subtotalSinImpuestos.toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Descuentos:'),
                            Text('RD\$ ${_descuentoGlobal.toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ITBIS (18%):'),
                            Text('RD\$ ${_montoImpuesto.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL COMPRA:', style: AppTypography.labelLarge),
                            Text(
                              'RD\$ ${_totalCompra.toStringAsFixed(2)}',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AppLayout.vL,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _guardarComoBorrador,
                        child: const Text('Guardar Borrador'),
                      ),
                    ),
                    AppLayout.hM,
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: 'Registrar Compra',
                        onPressed: _registrarCompraDirecta,
                      ),
                    ),
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
