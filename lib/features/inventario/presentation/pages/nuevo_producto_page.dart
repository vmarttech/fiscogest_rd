import 'package:flutter/material.dart';
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

enum RolUsuario { compras, ventas, almacen, administracion }

final rolUsuarioProvider = StateProvider<RolUsuario>((ref) => RolUsuario.administracion);

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
  final _costoCtrl = TextEditingController();
  final _gastosCtrl = TextEditingController(text: '0');
  final _ventaCtrl = TextEditingController();
  final _margenCtrl = TextEditingController();
  final _minimoCtrl = TextEditingController();
  final _mayoristaCtrl = TextEditingController();
  final _especialCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _stockMinCtrl = TextEditingController(text: '0');

  int? _catSel;
  int? _marcaSel;
  int? _unidadSel;
  bool _activo = true;
  bool _modificandoMargen = false;
  bool _modificandoPrecioVenta = false;
  bool _modificandoCosto = false;

  Producto? _productoEditar;
  bool _esEdicion = false;

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
    _costoCtrl.text = p.precioCompra.toStringAsFixed(2);
    _gastosCtrl.text = p.gastosAsociados.toStringAsFixed(2);
    _ventaCtrl.text = p.precioVenta.toStringAsFixed(2);
    _margenCtrl.text = (p.margenGanancia ?? 0.0).toStringAsFixed(2);
    _minimoCtrl.text = (p.precioMinimo ?? 0.0).toStringAsFixed(2);
    _mayoristaCtrl.text = (p.precioMayorista ?? 0.0).toStringAsFixed(2);
    _especialCtrl.text = (p.precioEspecial ?? 0.0).toStringAsFixed(2);
    _stockCtrl.text = (p.stock ?? 0.0).toStringAsFixed(2);
    _stockMinCtrl.text = (p.stockMinimo ?? 0.0).toStringAsFixed(2);
    _catSel = p.categoriaId;
    _marcaSel = p.marcaId;
    _unidadSel = p.unidadMedidaId;
    _activo = p.activo;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _skuCtrl.dispose();
    _costoCtrl.dispose();
    _gastosCtrl.dispose();
    _ventaCtrl.dispose();
    _margenCtrl.dispose();
    _minimoCtrl.dispose();
    _mayoristaCtrl.dispose();
    _especialCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    super.dispose();
  }

  void _recalcularDesdeCosto() {
    if (_modificandoMargen || _modificandoPrecioVenta) return;
    final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
    final gastos = double.tryParse(_gastosCtrl.text) ?? 0.0;
    final cr = costo + gastos;
    final margen = double.tryParse(_margenCtrl.text) ?? 0.0;
    if (cr > 0.0 && margen > 0.0) {
      _modificandoCosto = true;
      _ventaCtrl.text = Producto.calcularPrecioDesdeMargen(cr, margen).toStringAsFixed(2);
      _modificandoCosto = false;
    }
  }

  void _recalcularDesdeMargen() {
    _modificandoMargen = true;
    final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
    final gastos = double.tryParse(_gastosCtrl.text) ?? 0.0;
    final cr = costo + gastos;
    final margen = double.tryParse(_margenCtrl.text) ?? 0.0;
    if (cr > 0.0) {
      _ventaCtrl.text = Producto.calcularPrecioDesdeMargen(cr, margen).toStringAsFixed(2);
    }
    _modificandoMargen = false;
  }

  void _recalcularDesdePrecioVenta() {
    if (_modificandoCosto) return;
    _modificandoPrecioVenta = true;
    final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
    final gastos = double.tryParse(_gastosCtrl.text) ?? 0.0;
    final venta = double.tryParse(_ventaCtrl.text) ?? 0.0;
    final cr = costo + gastos;
    if (cr > 0.0 && venta >= cr) {
      final margen = ((venta - cr) / cr) * 100.0;
      _margenCtrl.text = margen.toStringAsFixed(2);
    }
    _modificandoPrecioVenta = false;
  }

  bool _puedeEditarCostos(RolUsuario rol) =>
      rol == RolUsuario.compras || rol == RolUsuario.administracion;

  bool _puedeEditarPrecios(RolUsuario rol) =>
      rol == RolUsuario.ventas || rol == RolUsuario.administracion;

  bool _puedeEditarInventario(RolUsuario rol) =>
      rol == RolUsuario.almacen || rol == RolUsuario.administracion;

  void _guardarProducto() {
    if (!_formKey.currentState!.validate()) return;
    final rol = ref.read(rolUsuarioProvider);
    final puedeCostos = _puedeEditarCostos(rol);
    final puedePrecios = _puedeEditarPrecios(rol);

    if (_catSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una categoría'), backgroundColor: AppColors.error)
      );
      return;
    }

    if (_unidadSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione unidad de medida'), backgroundColor: AppColors.error)
      );
      return;
    }

    final costo = puedeCostos ? double.tryParse(_costoCtrl.text) ?? 0.0 : 0.0;
    final gastos = puedeCostos ? double.tryParse(_gastosCtrl.text) ?? 0.0 : 0.0;
    final venta = puedePrecios ? double.tryParse(_ventaCtrl.text) ?? 0.0 : 0.0;
    final minimo = puedePrecios ? double.tryParse(_minimoCtrl.text) : null;
    final stockVal = _puedeEditarInventario(rol) ? double.tryParse(_stockCtrl.text) ?? 0.0 : 0.0;
    final stockMinVal = _puedeEditarInventario(rol) ? double.tryParse(_stockMinCtrl.text) ?? 0.0 : 0.0;

    if (stockVal < 0.0 || stockMinVal < 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las cantidades no pueden ser negativas'), backgroundColor: AppColors.error)
      );
      return;
    }

    if (minimo != null && minimo > 0.0 && venta < minimo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio de venta no puede ser menor al precio mínimo'), backgroundColor: AppColors.error)
      );
      return;
    }

    final margen = puedePrecios ? double.tryParse(_margenCtrl.text) : null;
    final mayorista = puedePrecios ? double.tryParse(_mayoristaCtrl.text) : null;
    final especial = puedePrecios ? double.tryParse(_especialCtrl.text) : null;

    final sku = _skuCtrl.text.trim().isEmpty
        ? 'SKU-${DateTime.now().millisecondsSinceEpoch}'
        : _skuCtrl.text.trim();

    if (_esEdicion && _productoEditar?.id != null) {
      final actualizado = _productoEditar!.copyWith(
        codigo: sku,
        nombre: _nombreCtrl.text.trim(),
        precioCompra: costo,
        gastosAsociados: gastos,
        precioVenta: venta,
        margenGanancia: margen,
        precioMinimo: minimo,
        precioMayorista: mayorista,
        precioEspecial: especial,
        stock: stockVal,
        stockMinimo: stockMinVal,
        categoriaId: _catSel!,
        marcaId: _marcaSel ?? 1,
        unidadMedidaId: _unidadSel!,
        activo: _activo,
      );
      ref.read(productoControllerProvider.notifier).guardar(actualizado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Producto actualizado correctamente!'))
      );
    } else {
      final nuevoProd = Producto(
        codigo: sku,
        nombre: _nombreCtrl.text.trim(),
        descripcion: null,
        precioCompra: costo,
        gastosAsociados: gastos,
        precioVenta: venta,
        margenGanancia: margen,
        precioMinimo: minimo,
        precioMayorista: mayorista,
        precioEspecial: especial,
        stock: stockVal,
        stockMinimo: stockMinVal,
        categoriaId: _catSel!,
        marcaId: _marcaSel ?? 1,
        unidadMedidaId: _unidadSel!,
        activo: _activo,
      );
      ref.read(productoControllerProvider.notifier).guardar(nuevoProd);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Producto registrado y movimiento en Kardex creado!'))
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(rolUsuarioProvider);
    final puedeCostos = _puedeEditarCostos(rol);
    final puedePrecios = _puedeEditarPrecios(rol);
    final puedeInventario = _puedeEditarInventario(rol);

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
                          items: lista.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre, style: AppTypography.bodyMedium),
                          )).toList(),
                          onChanged: (v) => setState(() => _catSel = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                      ),
                    ),
                    AppLayout.vM,
                    ResponsiveRow(
                      child1: marcas.when(
                        data: (lista) => AppDropdown<int>(
                          label: 'Marca',
                          hint: 'Seleccione marca',
                          initialValue: _marcaSel,
                          items: lista.map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(m.nombre, style: AppTypography.bodyMedium),
                          )).toList(),
                          onChanged: (v) => setState(() => _marcaSel = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                      ),
                      child2: unids.when(
                        data: (lista) => AppDropdown<int>(
                          label: 'Unidad de Medida',
                          hint: 'Seleccione unidad de medida',
                          initialValue: _unidadSel,
                          items: lista.map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.nombre, style: AppTypography.bodyMedium),
                          )).toList(),
                          onChanged: (v) => setState(() => _unidadSel = v),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                      ),
                    ),
                    AppLayout.vM,
                    const Text('Costos', style: AppTypography.h4),
                    AppLayout.vS,
                    if (!puedeCostos)
                      Padding(
                        padding: AppSpacing.bS,
                        child: Text('No tiene permiso para modificar estos valores',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Costo Compra (RD\$)',
                        controller: _costoCtrl,
                        prefixIcon: Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedeCostos,
                        onChanged: (_) => _recalcularDesdeCosto(),
                      ),
                      child2: AppTextField(
                        label: 'Gastos Asociados (RD\$)',
                        controller: _gastosCtrl,
                        prefixIcon: Icons.receipt_long_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedeCostos,
                        onChanged: (_) => _recalcularDesdeCosto(),
                      ),
                    ),
                    AppLayout.vM,
                    Builder(
                      builder: (_) {
                        final costo = double.tryParse(_costoCtrl.text) ?? 0.0;
                        final gastos = double.tryParse(_gastosCtrl.text) ?? 0.0;
                        final real = costo + gastos;
                        return Text('Costo Real: RD\$ ${real.toStringAsFixed(2)}',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary));
                      },
                    ),
                    AppLayout.vM,
                    const Text('Precios de Venta', style: AppTypography.h4),
                    AppLayout.vS,
                    if (!puedePrecios)
                      Padding(
                        padding: AppSpacing.bS,
                        child: Text('No tiene permiso para modificar estos valores',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Precio Venta (RD\$)',
                        controller: _ventaCtrl,
                        prefixIcon: Icons.sell_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedePrecios,
                        onChanged: (_) => _recalcularDesdePrecioVenta(),
                      ),
                      child2: AppTextField(
                        label: 'Margen de Ganancia (%)',
                        controller: _margenCtrl,
                        prefixIcon: Icons.percent,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedePrecios,
                        onChanged: (_) => _recalcularDesdeMargen(),
                      ),
                    ),
                    AppLayout.vM,
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Precio Mínimo (RD\$)',
                        hint: 'Límite inferior de venta',
                        controller: _minimoCtrl,
                        prefixIcon: Icons.warning_amber_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedePrecios,
                      ),
                      child2: AppTextField(
                        label: 'Precio Mayorista (RD\$)',
                        hint: 'Volumen',
                        controller: _mayoristaCtrl,
                        prefixIcon: Icons.storefront_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedePrecios,
                      ),
                    ),
                    AppLayout.vM,
                    AppTextField(
                      label: 'Precio Especial / Promoción (RD\$)',
                      hint: 'Clientes preferenciales',
                      controller: _especialCtrl,
                      prefixIcon: Icons.star_border,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      enabled: puedePrecios,
                    ),
                    AppLayout.vM,
                    Builder(
                      builder: (_) {
                        final venta = double.tryParse(_ventaCtrl.text) ?? 0.0;
                        final minimo = double.tryParse(_minimoCtrl.text) ?? 0.0;
                        if (minimo > 0.0 && venta < minimo) {
                          return Text('⚠️ El precio está por debajo del mínimo permitido',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    AppLayout.vM,
                    const Text('Inventario', style: AppTypography.h4),
                    AppLayout.vS,
                    if (!puedeInventario)
                      Padding(
                        padding: AppSpacing.bS,
                        child: Text('No tiene permiso para modificar estos valores',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ResponsiveRow(
                      child1: AppTextField(
                        label: 'Existencia Actual',
                        controller: _stockCtrl,
                        prefixIcon: Icons.format_list_numbered,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedeInventario,
                      ),
                      child2: AppTextField(
                        label: 'Stock Mínimo (Alerta)',
                        controller: _stockMinCtrl,
                        prefixIcon: Icons.warning_amber_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        enabled: puedeInventario,
                      ),
                    ),
                    AppLayout.vM,
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
