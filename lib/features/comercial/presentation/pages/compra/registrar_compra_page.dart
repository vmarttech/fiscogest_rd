import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/tipos_linea.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/cabecera_compra_widget.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/seccion_lineas_widget.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/totales_compra_widget.dart';
import 'package:fiscogest_rd/features/comercial/presentation/pages/compra/registrar_compra_page/widgets/botones_accion_widget.dart';
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

  final List<DetalleLinea> _lineas = [];
  final List<ControladoresLinea> _controladores = [];

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
      _lineas.add(DetalleLinea());
      _controladores.add(ControladoresLinea());
    });
  }

  void _eliminarLinea(int index) {
    setState(() {
      _controladores[index].dispose();
      _lineas.removeAt(index);
      _controladores.removeAt(index);
    });
  }

  /// ✅ FUNCIÓN CLAVE: Leer controlador → actualizar modelo → recálculo automático
  void _actualizarLineaEnTiempoReal(int index, String campo) {
    setState(() {
      _lineas[index] = _controladores[index].haciaLinea();
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
        title: const Text('Seleccionar Proveedor', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: listaProveedores!.length,
            itemBuilder: (context, index) {
              final prov = listaProveedores[index];
              return ListTile(
                title: Text(prov.nombreEmpresa),
                subtitle: Text('ID: ${prov.id ?? ''}'),
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
                CabeceraCompraWidget(
                  fechaController: _fechaController,
                  proveedorIdController: _proveedorIdController,
                  proveedorNombreController: _proveedorNombreController,
                  onSeleccionarProveedor: _seleccionarProveedor,
                  comprobanteController: _comprobanteController,
                  ncfController: _ncfController,
                  tipoComprobante: _tipoComprobante,
                  onTipoComprobanteChanged: (v) => setState(() => _tipoComprobante = v),
                  formaPago: _formaPago,
                  onFormaPagoChanged: (v) => setState(() => _formaPago = v),
                  condicionPagoController: _condicionPagoController,
                  diasCreditoController: _diasCreditoController,
                  fechaVencimientoController: _fechaVencimientoController,
                  observacionesController: _observacionesController,
                  esPequena: esPequena,
                  filaResponsiva: filaResponsiva,
                ),
                AppLayout.vL,
                SeccionLineasWidget(
                  lineas: _lineas,
                  controladores: _controladores,
                  onAgregarLinea: _agregarLinea,
                  onEliminarLinea: _eliminarLinea,
                  onSeleccionarProducto: _seleccionarProducto,
                  onValorCambiado: _actualizarLineaEnTiempoReal, // ✅ CONECTADO
                  esPequena: esPequena,
                  filaResponsiva: filaResponsiva,
                ),
                AppLayout.vL,
                const Divider(height: 1),
                AppLayout.vM,
                TotalesCompraWidget(
                  subtotalSinImpuestos: _subtotalSinImpuestos,
                  descuentoGlobal: _descuentoGlobal,
                  montoImpuesto: _montoImpuesto,
                  totalCompra: _totalCompra,
                ),
                AppLayout.vL,
                BotonesAccionWidget(
                  onGuardarBorrador: _guardarComoBorrador,
                  onRegistrarCompra: _registrarCompraDirecta,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
