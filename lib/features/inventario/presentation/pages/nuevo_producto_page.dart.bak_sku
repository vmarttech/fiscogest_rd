import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/marca.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/unidad_medida.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/features/impuestos/presentation/providers/impuesto_providers.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_page.dart';
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_action_bar.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';

class NuevoProductoPage extends ConsumerStatefulWidget {
  const NuevoProductoPage({super.key, this.producto});

  final Producto? producto;
  static const String routeName = 'nuevo-producto';

  @override
  ConsumerState<NuevoProductoPage> createState() => _NuevoProductoPageState();
}

class _NuevoProductoPageState extends ConsumerState<NuevoProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _stockMinCtrl = TextEditingController(text: '0');

  // Nuevos controladores para precios
  final _precioCompraCtrl = TextEditingController(text: '0.00');
  final _gastosAsocCtrl = TextEditingController(text: '0.00');
  final _margenCtrl = TextEditingController(text: '0.00');
  final _precioVentaCtrl = TextEditingController(text: '0.00');
  final _precioMinCtrl = TextEditingController(text: '0.00');
  final _precioMayCtrl = TextEditingController(text: '0.00');
  final _precioEspCtrl = TextEditingController(text: '0.00');

  int? _catSel;
  int? _impSel;
  int? _marcaSel;
  int? _unidadSel;
  bool _activo = true;
  Producto? _productoEditar;
  bool _esEdicion = false;

  /// En edición, costos/stock los define Compra (solo lectura).
  bool get _costesSoloLectura => _esEdicion;
  bool _precioManual =
      false; // Si el usuario edita precio venta, no recalcular automáticamente

  List<T> _unicosPorId<T>(List<T> elementos, int? Function(T) obtenerId) {
    final vistos = <int>{};
    return elementos.where((elemento) {
      final id = obtenerId(elemento);
      return id != null && vistos.add(id);
    }).toList();
  }


  /// Si [id] no está en [opciones], añade un ítem placeholder para que el dropdown lo muestre.
  List<DropdownMenuItem<int>> _itemsConSeleccion({
    required List<dynamic> opciones,
    required int? Function(dynamic) idOf,
    required String Function(dynamic) nombreOf,
    required int? seleccionado,
  }) {
    final items = <DropdownMenuItem<int>>[
      for (final o in opciones)
        DropdownMenuItem(
          value: idOf(o),
          child: Text(nombreOf(o), style: AppTypography.bodyMedium),
        ),
    ];
    if (seleccionado != null &&
        seleccionado > 0 &&
        items.every((i) => i.value != seleccionado)) {
      items.insert(
        0,
        DropdownMenuItem(
          value: seleccionado,
          child: Text('#$seleccionado (no listada)', style: AppTypography.bodyMedium),
        ),
      );
    }
    return items;
  }

  int? _valorDisponible<T>(
    List<T> elementos,
    int? Function(T) obtenerId,
    int? seleccionado,
  ) {
    if (seleccionado == null) return null;
    return elementos
                .where((elemento) => obtenerId(elemento) == seleccionado)
                .length ==
            1
        ? seleccionado
        : null;
  }

  @override
  void initState() {
    super.initState();
    final args = widget.producto;
    if (args != null) {
      _productoEditar = args;
      _esEdicion = true;
      _cargarDatosProducto(args);
    }
  }

  void _cargarDatosProducto(Producto p) {
    _nombreCtrl.text = p.nombre;
    _skuCtrl.text = p.codigo;
    _stockCtrl.text = (p.stock ?? 0.0).toStringAsFixed(2);
    _stockMinCtrl.text = (p.stockMinimo ?? 0.0).toStringAsFixed(2);

    // Cargar campos de precios
    _precioCompraCtrl.text = p.precioCompra.toStringAsFixed(2);
    _gastosAsocCtrl.text = p.gastosAsociados.toStringAsFixed(2);
    _margenCtrl.text = (p.margenGanancia ?? 0.0).toStringAsFixed(2);
    _precioVentaCtrl.text = p.precioVenta.toStringAsFixed(2);
    _precioMinCtrl.text = (p.precioMinimo ?? 0.0).toStringAsFixed(2);
    _precioMayCtrl.text = (p.precioMayorista ?? 0.0).toStringAsFixed(2);
    _precioEspCtrl.text = (p.precioEspecial ?? 0.0).toStringAsFixed(2);

    _catSel = p.categoriaId > 0 ? p.categoriaId : null;
    _marcaSel = p.marcaId > 0 ? p.marcaId : null;
    _unidadSel = p.unidadMedidaId > 0 ? p.unidadMedidaId : null;
    debugPrint('EDIT producto id=${p.id} cat=${p.categoriaId} marca=${p.marcaId} uni=${p.unidadMedidaId}');
    _impSel = p.impuestoId;
    _activo = p.activo;
    _precioManual = false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _skuCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    _precioCompraCtrl.dispose();
    _gastosAsocCtrl.dispose();
    _margenCtrl.dispose();
    _precioVentaCtrl.dispose();
    _precioMinCtrl.dispose();
    _precioMayCtrl.dispose();
    _precioEspCtrl.dispose();
    super.dispose();
  }

  // Cálculo automático
  double _getCostoReal() {
    final compra = double.tryParse(_precioCompraCtrl.text) ?? 0.0;
    final gastos = double.tryParse(_gastosAsocCtrl.text) ?? 0.0;
    return compra + gastos;
  }

  void _recalcularPrecioVenta() {
    if (_precioManual) return; // Si el usuario escribió manualmente, no tocar

    final costo = _getCostoReal();
    final margen = double.tryParse(_margenCtrl.text) ?? 0.0;
    if (costo > 0 && margen > 0) {
      final precio = Producto.calcularPrecioDesdeMargen(costo, margen);
      _precioVentaCtrl.text = precio.toStringAsFixed(2);
    }
  }

  void _marcarPrecioManual() {
    _precioManual = true;
  }

  Future<({String nombre, String? abreviatura})?> _pedirDatosCatalogo({
    required String titulo,
    required String etiqueta,
    bool conAbreviatura = false,
  }) async {
    return showDialog<({String nombre, String? abreviatura})>(
      context: context,
      builder: (dialogContext) => _CatalogoRapidoDialog(
        titulo: titulo,
        etiqueta: etiqueta,
        conAbreviatura: conAbreviatura,
      ),
    );
  }

  Widget _campoConCreacionRapida({
    required Widget campo,
    required String tooltip,
    required VoidCallback onCrear,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: campo),
      const SizedBox(width: 4),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onCrear,
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    ],
  );

  Future<void> _crearCategoriaRapida() async {
    final datos = await _pedirDatosCatalogo(
      titulo: 'Nueva categoría',
      etiqueta: 'Nombre de la categoría',
    );
    if (datos == null || !mounted) return;
    final actual = ref.read(categoriaControllerProvider).valueOrNull ?? [];
    final existente = actual.where(
      (item) => item.nombre.trim().toLowerCase() == datos.nombre.toLowerCase(),
    );
    if (existente.isNotEmpty) {
      setState(() => _catSel = existente.first.id);
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('La categoría ya existía y fue seleccionada'),
        ),
      );
      return;
    }
    await ref
        .read(categoriaControllerProvider.notifier)
        .guardar(Categoria(nombre: datos.nombre, creadoEn: DateTime.now()));
    if (!mounted) return;
    final estado = ref.read(categoriaControllerProvider);
    final creada = estado.valueOrNull?.where(
      (item) => item.nombre.trim().toLowerCase() == datos.nombre.toLowerCase(),
    );
    if (creada == null || creada.isEmpty) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'No se pudo crear la categoría: ${estado.error ?? 'verifica los datos'}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _catSel = creada.first.id);
    FiscoGestNotifications.show(
      const SnackBar(content: Text('Categoría creada y seleccionada')),
    );
  }

  Future<void> _crearMarcaRapida() async {
    final datos = await _pedirDatosCatalogo(
      titulo: 'Nueva marca',
      etiqueta: 'Nombre de la marca',
    );
    if (datos == null || !mounted) return;
    final actual = ref.read(marcaControllerProvider).valueOrNull ?? [];
    final existente = actual.where(
      (item) => item.nombre.trim().toLowerCase() == datos.nombre.toLowerCase(),
    );
    if (existente.isNotEmpty) {
      setState(() => _marcaSel = existente.first.id);
      FiscoGestNotifications.show(
        const SnackBar(content: Text('La marca ya existía y fue seleccionada')),
      );
      return;
    }
    await ref
        .read(marcaControllerProvider.notifier)
        .guardar(Marca(nombre: datos.nombre, creadoEn: DateTime.now()));
    if (!mounted) return;
    final estado = ref.read(marcaControllerProvider);
    final creada = estado.valueOrNull?.where(
      (item) => item.nombre.trim().toLowerCase() == datos.nombre.toLowerCase(),
    );
    if (creada == null || creada.isEmpty) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'No se pudo crear la marca: ${estado.error ?? 'verifica los datos'}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _marcaSel = creada.first.id);
    FiscoGestNotifications.show(
      const SnackBar(content: Text('Marca creada y seleccionada')),
    );
  }

  Future<void> _crearUnidadRapida() async {
    final datos = await _pedirDatosCatalogo(
      titulo: 'Nueva unidad de medida',
      etiqueta: 'Nombre de la unidad',
      conAbreviatura: true,
    );
    if (datos == null || !mounted) return;
    final actual = ref.read(unidadMedidaControllerProvider).valueOrNull ?? [];
    final existente = actual.where(
      (item) => item.nombre.trim().toLowerCase() == datos.nombre.toLowerCase(),
    );
    if (existente.isNotEmpty) {
      setState(() => _unidadSel = existente.first.id);
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('La unidad ya existía y fue seleccionada'),
        ),
      );
      return;
    }
    await ref
        .read(unidadMedidaControllerProvider.notifier)
        .guardar(
          UnidadMedida(
            nombre: datos.nombre,
            abreviatura: datos.abreviatura,
            creadoEn: DateTime.now(),
          ),
        );
    if (!mounted) return;
    final estado = ref.read(unidadMedidaControllerProvider);
    final creada = estado.valueOrNull?.where(
      (item) => item.nombre.trim().toLowerCase() == datos.nombre.toLowerCase(),
    );
    if (creada == null || creada.isEmpty) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'No se pudo crear la unidad: ${estado.error ?? 'verifica los datos'}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _unidadSel = creada.first.id);
    FiscoGestNotifications.show(
      const SnackBar(content: Text('Unidad creada y seleccionada')),
    );
  }

  void _guardarProducto() {
    if (!_formKey.currentState!.validate()) return;
    final categorias = ref.read(categoriaControllerProvider).valueOrNull ?? [];
    final unidades = ref.read(unidadMedidaControllerProvider).valueOrNull ?? [];
    final marcas = ref.read(marcaControllerProvider).valueOrNull ?? [];
    final categoriaId = _valorDisponible(
      _unicosPorId(categorias, (c) => c.id),
      (c) => c.id,
      _catSel,
    );
    final unidadId = _valorDisponible(
      _unicosPorId(unidades, (u) => u.id),
      (u) => u.id,
      _unidadSel,
    );
    final marcaId = _valorDisponible(
      _unicosPorId(marcas, (m) => m.id),
      (m) => m.id,
      _marcaSel,
    );
    if (categoriaId == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Seleccione una categoría'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (unidadId == null) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Seleccione unidad de medida'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final stockVal = double.tryParse(_stockCtrl.text) ?? 0.0;
    final stockMinVal = double.tryParse(_stockMinCtrl.text) ?? 0.0;
    if (stockVal < 0.0 || stockMinVal < 0.0) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Las cantidades no pueden ser negativas'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final precioCompra = double.tryParse(_precioCompraCtrl.text) ?? 0.0;
    final gastosAsoc = double.tryParse(_gastosAsocCtrl.text) ?? 0.0;
    final margen = double.tryParse(_margenCtrl.text);
    final precioVenta = double.tryParse(_precioVentaCtrl.text) ?? 0.0;
    final precioMin = double.tryParse(_precioMinCtrl.text);
    final precioMay = double.tryParse(_precioMayCtrl.text);
    final precioEsp = double.tryParse(_precioEspCtrl.text);

    // Validar precio venta no menor al mínimo
    if (precioMin != null && precioMin > 0 && precioVenta < precioMin) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(
            'El precio de venta (${formatRd(precioVenta)}) no puede ser menor al mínimo (${formatRd(precioMin)})',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final sku = _skuCtrl.text.trim().isEmpty
        ? 'SKU-${DateTime.now().millisecondsSinceEpoch}'
        : _skuCtrl.text.trim();

    if (_esEdicion && _productoEditar?.id != null) {
      final actualizado = _productoEditar!.copyWith(
        codigo: sku,
        nombre: _nombreCtrl.text.trim(),
        precioCompra: precioCompra,
        gastosAsociados: gastosAsoc,
        margenGanancia: margen,
        precioVenta: precioVenta,
        precioMinimo: precioMin,
        precioMayorista: precioMay,
        precioEspecial: precioEsp,
        stock: stockVal,
        stockMinimo: stockMinVal,
        categoriaId: categoriaId,
        marcaId: marcaId ?? 1,
        unidadMedidaId: unidadId,
        impuestoId: _impSel,
        clearImpuesto: _impSel == null,
        activo: _activo,
      );
      ref.read(productoControllerProvider.notifier).guardar(actualizado);
      FiscoGestNotifications.show(
        const SnackBar(content: Text('¡Producto actualizado correctamente!')),
      );
    } else {
      final nuevoProd = Producto(
        codigo: sku,
        nombre: _nombreCtrl.text.trim(),
        descripcion: null,
        precioCompra: precioCompra,
        gastosAsociados: gastosAsoc,
        precioVenta: precioVenta,
        margenGanancia: margen,
        precioMinimo: precioMin,
        precioMayorista: precioMay,
        precioEspecial: precioEsp,
        stock: stockVal,
        stockMinimo: stockMinVal,
        categoriaId: categoriaId,
        marcaId: marcaId ?? 1,
        unidadMedidaId: unidadId,
        impuestoId: _impSel,
        activo: _activo,
      );
      ref.read(productoControllerProvider.notifier).guardar(nuevoProd);
      FiscoGestNotifications.show(
        const SnackBar(content: Text('¡Producto registrado correctamente!')),
      );
    }
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) context.pop();
    });
  }


  Widget _seccionCard({
    required String titulo,
    required List<Widget> children,
    IconData? icono,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey300.withValues(alpha: 0.85)),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Text(titulo, style: AppTypography.h4),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final costoReal = _getCostoReal();

    return AppScaffold(
      title: _esEdicion ? 'Editar Producto' : 'Registrar Producto',
      body: SafeArea(
        bottom: true,
        child: AppPage(
          maxWidth: AppSizes.formMaxWidth,
          padding: AppLayout.pantallaPadding,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Consumer(
                builder: (ctx, ref, _) {
                  final cats = ref.watch(categoriaControllerProvider);
                  final imps = ref.watch(impuestoControllerProvider);
                  final marcas = ref.watch(marcaControllerProvider);
                  final unids = ref.watch(unidadMedidaControllerProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    _seccionCard(
                      titulo: 'Información General',
                      icono: Icons.info_outline,
                      children: [
                    AppTextField(
                      label: 'Nombre del Producto',
                      hint: 'Nombre comercial del producto',
                      controller: _nombreCtrl,
                      prefixIcon: Icons.shopping_bag_outlined,
                    ),
                    AppLayout.vM,
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'SKU / Código de Barra',
                        hint: 'Código único del producto',
                        controller: _skuCtrl,
                        prefixIcon: Icons.qr_code,
                      ),
                      child2: cats.when(
                        data: (lista) {
                          final opciones = _unicosPorId(lista, (c) => c.id);
                          final items = _itemsConSeleccion(
                            opciones: opciones,
                            idOf: (c) => c.id as int?,
                            nombreOf: (c) => (c as dynamic).nombre as String,
                            seleccionado: _catSel,
                          );
                          return _campoConCreacionRapida(
                            tooltip: 'Crear categoría',
                            onCrear: _crearCategoriaRapida,
                            campo: AppDropdown<int>(
                              key: ValueKey('cat_${_catSel}_${items.length}'),
                              label: 'Categoría',
                              hint: 'Seleccione categoría',
                              value: _catSel != null &&
                                      items.any((i) => i.value == _catSel)
                                  ? _catSel
                                  : null,
                              items: items,
                              onChanged: (v) => setState(() => _catSel = v),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text(
                          'Error: $e',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    AppLayout.vM,
                    ResponsiveRow(
                      child1: marcas.when(
                        data: (lista) {
                          final opciones = _unicosPorId(lista, (m) => m.id);
                          final items = _itemsConSeleccion(
                            opciones: opciones,
                            idOf: (m) => m.id as int?,
                            nombreOf: (m) => (m as dynamic).nombre as String,
                            seleccionado: _marcaSel,
                          );
                          return _campoConCreacionRapida(
                            tooltip: 'Crear marca',
                            onCrear: _crearMarcaRapida,
                            campo: AppDropdown<int>(
                              key: ValueKey('marca_${_marcaSel}_${items.length}'),
                              label: 'Marca',
                              hint: 'Seleccione marca',
                              value: _marcaSel != null &&
                                      items.any((i) => i.value == _marcaSel)
                                  ? _marcaSel
                                  : null,
                              items: items,
                              onChanged: (v) => setState(() => _marcaSel = v),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text(
                          'Error: $e',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      child2: unids.when(
                        data: (lista) {
                          final opciones = _unicosPorId(lista, (u) => u.id);
                          final items = _itemsConSeleccion(
                            opciones: opciones,
                            idOf: (u) => u.id as int?,
                            nombreOf: (u) => (u as dynamic).nombre as String,
                            seleccionado: _unidadSel,
                          );
                          return _campoConCreacionRapida(
                            tooltip: 'Crear unidad',
                            onCrear: _crearUnidadRapida,
                            campo: AppDropdown<int>(
                              key: ValueKey('uni_${_unidadSel}_${items.length}'),
                              label: 'Unidad de Medida',
                              hint: 'Seleccione unidad',
                              value: _unidadSel != null &&
                                      items.any((i) => i.value == _unidadSel)
                                  ? _unidadSel
                                  : null,
                              items: items,
                              onChanged: (v) => setState(() => _unidadSel = v),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text(
                          'Error: $e',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    imps.when(
                      data: (lista) {
                        final activos = _unicosPorId(
                          lista.where((i) => i.activo).toList(),
                          (i) => i.id,
                        );
                        return AppDropdown<int?>(
                          key: ValueKey('imp_${_impSel}_${activos.length}'),
                          label: 'ITBIS / impuesto',
                          hint: 'Automático (categoría o default)',
                          value:
                              _impSel == null ||
                                  activos
                                          .where((i) => i.id == _impSel)
                                          .length ==
                                      1
                              ? _impSel
                              : null,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Automático (categoría / default)'),
                            ),
                            ...activos.map(
                              (i) => DropdownMenuItem<int?>(
                                value: i.id,
                                child: Text(
                                  '${i.nombre} (${i.porcentaje.toStringAsFixed(i.porcentaje == i.porcentaje.roundToDouble() ? 0 : 2)}%)',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _impSel = v),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error impuestos: $e'),
                    ),
                      ],
                    ),
                    _seccionCard(
                      titulo: 'Costos y Precios',
                      icono: Icons.attach_money,
                      children: [
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Costo de Compra',
                        controller: _precioCompraCtrl,
                        enabled: !_costesSoloLectura,
                        prefixIcon: Icons.shopping_cart,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (_) =>
                            setState(() => _recalcularPrecioVenta()),
                      ),
                      child2: AppTextField(
                        label: 'Gastos Asociados',
                        controller: _gastosAsocCtrl,
                        enabled: !_costesSoloLectura,
                        prefixIcon: Icons.receipt_long,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (_) =>
                            setState(() => _recalcularPrecioVenta()),
                      ),
                    ),
                    AppLayout.vM,

                    // Costo Real calculado
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
                            'Costo Real Total:',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatRd(costoReal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '(Compra + Gastos = Base para margen)',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppLayout.vM,

                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Margen de Ganancia %',
                        controller: _margenCtrl,
                        prefixIcon: Icons.percent,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (_) =>
                            setState(() => _recalcularPrecioVenta()),
                      ),
                      child2: AppTextField(
                        label: 'Precio de Venta',
                        controller: _precioVentaCtrl,
                        prefixIcon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (_) =>
                            _marcarPrecioManual(), // Si edita, dejar de recalcular
                      ),
                    ),
                    AppLayout.vS,
                    if (!_precioManual && costoReal > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '💡 Precio sugerido calculado automáticamente',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    if (_precioManual)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '✏️ Precio establecido manualmente — ya no se recalcula',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    AppLayout.vS,

                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Precio Mínimo',
                        controller: _precioMinCtrl,
                        prefixIcon: Icons.trending_down,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      child2: AppTextField(
                        label: 'Precio Mayorista',
                        controller: _precioMayCtrl,
                        prefixIcon: Icons.people,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                    AppLayout.vM,

                    AppTextField(
                      label: 'Precio Especial / Oferta',
                      controller: _precioEspCtrl,
                      prefixIcon: Icons.local_offer,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                      ],
                    ),
                    _seccionCard(
                      titulo: 'Inventario',
                      icono: Icons.inventory_2_outlined,
                      children: [
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Existencia Actual',
                        controller: _stockCtrl,
                        enabled: !_costesSoloLectura,
                        prefixIcon: Icons.format_list_numbered,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      child2: AppTextField(
                        label: 'Stock Mínimo (Alerta)',
                        controller: _stockMinCtrl,
                        prefixIcon: Icons.warning_amber_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                    _seccionCard(
                      titulo: 'Estado',
                      icono: Icons.toggle_on_outlined,
                      children: [
                        Text(
                          'Producto Activo para la Venta',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Switch(
                            value: _activo,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setState(() => _activo = v),
                          ),
                        ),
                      ],
                    ),
                    AppLayout.vL,

                    AppActionBar(
                      actions: [
                        AppButton(
                          text: 'Cancelar',
                          icon: Icons.close,
                          onPressed: () => context.pop(),
                        ),
                        AppButton(
                          text: _esEdicion ? 'Actualizar' : 'Guardar',
                          icon: Icons.check_circle_outline,
                          onPressed: _guardarProducto,
                        ),
                      ],
                    ),
                  ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo que posee sus TextEditingController (evita dispose prematuro).
class _CatalogoRapidoDialog extends StatefulWidget {
  const _CatalogoRapidoDialog({
    required this.titulo,
    required this.etiqueta,
    this.conAbreviatura = false,
  });

  final String titulo;
  final String etiqueta;
  final bool conAbreviatura;

  @override
  State<_CatalogoRapidoDialog> createState() => _CatalogoRapidoDialogState();
}

class _CatalogoRapidoDialogState extends State<_CatalogoRapidoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _abreviaturaCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _abreviaturaCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, (
      nombre: _nombreCtrl.text.trim(),
      abreviatura:
          widget.conAbreviatura && _abreviaturaCtrl.text.trim().isNotEmpty
          ? _abreviaturaCtrl.text.trim()
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: widget.etiqueta,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              validator: (value) {
                final nombre = value?.trim() ?? '';
                if (nombre.isEmpty) return 'Escribe un nombre';
                if (nombre.length > 60) return 'Máximo 60 caracteres';
                return null;
              },
              onFieldSubmitted: (_) => _confirmar(),
            ),
            if (widget.conAbreviatura) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _abreviaturaCtrl,
                maxLength: 12,
                decoration: const InputDecoration(
                  labelText: 'Abreviatura (opcional)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _confirmar,
          child: const Text('Crear y seleccionar'),
        ),
      ],
    );
  }
}
