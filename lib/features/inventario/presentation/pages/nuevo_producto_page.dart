import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';

class NuevoProductoPage extends ConsumerStatefulWidget {
  const NuevoProductoPage({super.key});
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
  int? _marcaSel;
  int? _unidadSel;
  bool _activo = true;
  Producto? _productoEditar;
  bool _esEdicion = false;
  /// En edición, costos/stock los define Compra (solo lectura).
  bool get _costesSoloLectura => _esEdicion;
  bool _precioManual = false; // Si el usuario edita precio venta, no recalcular automáticamente

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = GoRouterState.of(context).extra;
      if (args is Producto) {
        setState(() {
          _productoEditar = args;
          _esEdicion = true;
          _cargarDatosProducto(args);
        });
      }
    });
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
    
    _catSel = p.categoriaId;
    _marcaSel = p.marcaId;
    _unidadSel = p.unidadMedidaId;
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

  void _guardarProducto() {
    if (!_formKey.currentState!.validate()) return;
    if (_catSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una categoría'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_unidadSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione unidad de medida'), backgroundColor: AppColors.error),
      );
      return;
    }

    final stockVal = double.tryParse(_stockCtrl.text) ?? 0.0;
    final stockMinVal = double.tryParse(_stockMinCtrl.text) ?? 0.0;
    if (stockVal < 0.0 || stockMinVal < 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las cantidades no pueden ser negativas'), backgroundColor: AppColors.error),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El precio de venta (${formatRd(precioVenta)}) no puede ser menor al mínimo (${formatRd(precioMin)})'),
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
        categoriaId: _catSel!,
        marcaId: _marcaSel ?? 1,
        unidadMedidaId: _unidadSel!,
        activo: _activo,
      );
      ref.read(productoControllerProvider.notifier).guardar(actualizado);
      ScaffoldMessenger.of(context).showSnackBar(
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
        categoriaId: _catSel!,
        marcaId: _marcaSel ?? 1,
        unidadMedidaId: _unidadSel!,
        activo: _activo,
      );
      ref.read(productoControllerProvider.notifier).guardar(nuevoProd);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Producto registrado correctamente!')),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final costoReal = _getCostoReal();

    return AppScaffold(
      title: _esEdicion ? 'Editar Producto' : 'Registrar Producto',
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: AppLayout.pantallaPadding,
          child: Form(
            key: _formKey,
            child: Consumer(
              builder: (ctx, ref, _) {
                final cats = ref.watch(categoriaControllerProvider);
                final marcas = ref.watch(marcaControllerProvider);
                final unids = ref.watch(unidadMedidaControllerProvider);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información General', style: AppTypography.h4),
                    AppLayout.vS,
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
                        data: (lista) => AppDropdown<int>(
                          label: 'Categoría',
                          hint: 'Seleccione categoría',
                          initialValue: _catSel,
                          items: lista
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.nombre, style: AppTypography.bodyMedium),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _catSel = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                      ),
                    ),
                    AppLayout.vM,
                    ResponsiveRow(
                      child1: marcas.when(
                        data: (lista) => AppDropdown<int>(
                          label: 'Marca',
                          hint: 'Seleccione marca',
                          initialValue: _marcaSel,
                          items: lista
                              .map((m) => DropdownMenuItem(
                                    value: m.id,
                                    child: Text(m.nombre, style: AppTypography.bodyMedium),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _marcaSel = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                      ),
                      child2: unids.when(
                        data: (lista) => AppDropdown<int>(
                          label: 'Unidad de Medida',
                          hint: 'Seleccione unidad',
                          initialValue: _unidadSel,
                          items: lista
                              .map((u) => DropdownMenuItem(
                                    value: u.id,
                                    child: Text(u.nombre, style: AppTypography.bodyMedium),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _unidadSel = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                      ),
                    ),
                    AppLayout.vL,

                    // === SECCIÓN DE COSTOS Y PRECIOS ===
                    const Text('Costos y Precios', style: AppTypography.h4),
                    AppLayout.vS,
                    
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Costo de Compra',
                        controller: _precioCompraCtrl,
                        enabled: !_costesSoloLectura,
                        prefixIcon: Icons.shopping_cart,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (_) => setState(() => _recalcularPrecioVenta()),
                      ),
                      child2: AppTextField(
                        label: 'Gastos Asociados',
                        controller: _gastosAsocCtrl,
                        enabled: !_costesSoloLectura,
                        prefixIcon: Icons.receipt_long,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (_) => setState(() => _recalcularPrecioVenta()),
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
                            style: AppTypography.labelMedium.copyWith(color: Colors.blue.shade800),
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
                            style: AppTypography.bodySmall.copyWith(color: Colors.blue.shade700),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (_) => setState(() => _recalcularPrecioVenta()),
                      ),
                      child2: AppTextField(
                        label: 'Precio de Venta',
                        controller: _precioVentaCtrl,
                        prefixIcon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        onChanged: (_) => _marcarPrecioManual(), // Si edita, dejar de recalcular
                      ),
                    ),
                    AppLayout.vS,
                    if (!_precioManual && costoReal > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '💡 Precio sugerido calculado automáticamente',
                          style: AppTypography.bodySmall.copyWith(color: Colors.green.shade700),
                        ),
                      ),
                    if (_precioManual)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '✏️ Precio establecido manualmente — ya no se recalcula',
                          style: AppTypography.bodySmall.copyWith(color: Colors.orange.shade700),
                        ),
                      ),
                    AppLayout.vS,

                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Precio Mínimo',
                        controller: _precioMinCtrl,
                        prefixIcon: Icons.trending_down,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      ),
                      child2: AppTextField(
                        label: 'Precio Mayorista',
                        controller: _precioMayCtrl,
                        prefixIcon: Icons.people,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      ),
                    ),
                    AppLayout.vM,

                    AppTextField(
                      label: 'Precio Especial / Oferta',
                      controller: _precioEspCtrl,
                      prefixIcon: Icons.local_offer,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                    AppLayout.vL,

                    // === SECCIÓN DE INVENTARIO ===
                    const Text('Inventario', style: AppTypography.h4),
                    AppLayout.vS,
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Existencia Actual',
                        controller: _stockCtrl,
                        enabled: !_costesSoloLectura,
                        prefixIcon: Icons.format_list_numbered,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      child2: AppTextField(
                        label: 'Stock Mínimo (Alerta)',
                        controller: _stockMinCtrl,
                        prefixIcon: Icons.warning_amber_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                    AppLayout.vL,

                    Text(
                      'Producto Activo para la Venta',
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Switch(
                        value: _activo,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _activo = v),
                      ),
                    ),
                    AppLayout.vL,

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cancelar',
                            icon: Icons.close,
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: AppButton(
                            text: _esEdicion ? 'Actualizar' : 'Guardar',
                            icon: Icons.check_circle_outline,
                            onPressed: _guardarProducto,
                          ),
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
    );
  }
}
