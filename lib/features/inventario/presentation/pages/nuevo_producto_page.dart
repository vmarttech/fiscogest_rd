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
import 'package:fiscogest_rd/core/ui/app_sizes.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_section.dart';
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
    final costo = double.tryParse(_costoCtrl.text) ?? 0;
    final gastos = double.tryParse(_gastosCtrl.text) ?? 0;
    final cr = costo + gastos;
    final margen = double.tryParse(_margenCtrl.text) ?? 0;
    if (cr > 0 && margen > 0) {
      _modificandoCosto = true;
      _ventaCtrl.text = Producto.calcularPrecioDesdeMargen(cr, margen).toStringAsFixed(2);
      _modificandoCosto = false;
    }
  }

  void _recalcularDesdeMargen() {
    _modificandoMargen = true;
    final costo = double.tryParse(_costoCtrl.text) ?? 0;
    final gastos = double.tryParse(_gastosCtrl.text) ?? 0;
    final cr = costo + gastos;
    final margen = double.tryParse(_margenCtrl.text) ?? 0;
    if (cr > 0) {
      _ventaCtrl.text = Producto.calcularPrecioDesdeMargen(cr, margen).toStringAsFixed(2);
    }
    _modificandoMargen = false;
  }

  void _recalcularDesdePrecioVenta() {
    if (_modificandoCosto) return;
    _modificandoPrecioVenta = true;
    final costo = double.tryParse(_costoCtrl.text) ?? 0;
    final gastos = double.tryParse(_gastosCtrl.text) ?? 0;
    final venta = double.tryParse(_ventaCtrl.text) ?? 0;
    final cr = costo + gastos;
    if (cr > 0 && venta >= cr) {
      final margen = ((venta - cr) / cr) * 100;
      _margenCtrl.text = margen.toStringAsFixed(2);
    }
    _modificandoPrecioVenta = false;
  }

  bool _puedeEditarCostos(RolUsuario rol) {
    return rol == RolUsuario.compras || rol == RolUsuario.administracion;
  }

  bool _puedeEditarPrecios(RolUsuario rol) {
    return rol == RolUsuario.ventas || rol == RolUsuario.administracion;
  }

  bool _puedeEditarInventario(RolUsuario rol) {
    return rol == RolUsuario.almacen || rol == RolUsuario.administracion;
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(rolUsuarioProvider);
    final cats = ref.watch(categoriaControllerProvider);
    final marcas = ref.watch(marcaControllerProvider);
    final unids = ref.watch(unidadMedidaControllerProvider);
    final puedeCostos = _puedeEditarCostos(rol);
    final puedePrecios = _puedeEditarPrecios(rol);
    final puedeInventario = _puedeEditarInventario(rol);

    return AppScaffold(
      title: 'Registrar Nuevo Producto',
      body: SingleChildScrollView(
        padding: AppSpacing.allL,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSection(
                title: 'Información General',
                children: [
                  AppTextField(
                    label: 'Nombre del Producto',
                    hint: 'Nombre comercial del producto',
                    controller: _nombreCtrl,
                    prefixIcon: Icons.shopping_bag_outlined,
                  ),
                  AppLayout.vM,
                  AppTextField(
                    label: 'SKU / Código de Barra',
                    hint: 'Código único del producto',
                    controller: _skuCtrl,
                    prefixIcon: Icons.qr_code,
                  ),
                  AppLayout.vM,
                  cats.when(
                    data: (lista) => AppDropdown<int>(
                      hint: 'Seleccione categoría',
                      initialValue: _catSel,
                      items: lista.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre, style: AppTypography.bodyMedium))).toList(),
                      onChanged: (v) => setState(() => _catSel = v),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                  ),
                  AppLayout.vM,
                  marcas.when(
                    data: (lista) => AppDropdown<int>(
                      hint: 'Seleccione marca',
                      initialValue: _marcaSel,
                      items: lista.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre, style: AppTypography.bodyMedium))).toList(),
                      onChanged: (v) => setState(() => _marcaSel = v),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                  ),
                  AppLayout.vM,
                  unids.when(
                    data: (lista) => AppDropdown<int>(
                      hint: 'Seleccione unidad de medida',
                      initialValue: _unidadSel,
                      items: lista.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nombre, style: AppTypography.bodyMedium))).toList(),
                      onChanged: (v) => setState(() => _unidadSel = v),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
              AppSection(
                title: 'Costos',
                children: [
                  if (!puedeCostos)
                    Padding(
                      padding: AppSpacing.bS,
                      child: Text('No tiene permiso para modificar estos valores', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Costo Compra (RD\$)',
                          controller: _costoCtrl,
                          prefixIcon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedeCostos,
                          onChanged: (_) => _recalcularDesdeCosto(),
                        ),
                      ),
                      AppLayout.hM,
                      Expanded(
                        child: AppTextField(
                          label: 'Gastos Asociados (RD\$)',
                          controller: _gastosCtrl,
                          prefixIcon: Icons.receipt_long_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedeCostos,
                          onChanged: (_) => _recalcularDesdeCosto(),
                        ),
                      ),
                    ],
                  ),
                  AppLayout.vS,
                  Consumer(
                    builder: (ctx, ref, _) {
                      final costo = double.tryParse(_costoCtrl.text) ?? 0;
                      final gastos = double.tryParse(_gastosCtrl.text) ?? 0;
                      final real = costo + gastos;
                      return Text('Costo Real: RD\$ ${real.toStringAsFixed(2)}', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary));
                    },
                  ),
                ],
              ),
              AppSection(
                title: 'Precios de Venta',
                children: [
                  if (!puedePrecios)
                    Padding(
                      padding: AppSpacing.bS,
                      child: Text('No tiene permiso para modificar estos valores', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Precio Venta (RD\$)',
                          controller: _ventaCtrl,
                          prefixIcon: Icons.sell_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedePrecios,
                          onChanged: (_) => _recalcularDesdePrecioVenta(),
                        ),
                      ),
                      AppLayout.hM,
                      Expanded(
                        child: AppTextField(
                          label: 'Margen de Ganancia (%)',
                          controller: _margenCtrl,
                          prefixIcon: Icons.percent,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedePrecios,
                          onChanged: (_) => _recalcularDesdeMargen(),
                        ),
                      ),
                    ],
                  ),
                  AppLayout.vM,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Precio Mínimo (RD\$)',
                          hint: 'Límite inferior de venta',
                          controller: _minimoCtrl,
                          prefixIcon: Icons.warning_amber_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedePrecios,
                        ),
                      ),
                      AppLayout.hM,
                      Expanded(
                        child: AppTextField(
                          label: 'Precio Mayorista (RD\$)',
                          hint: 'Volumen',
                          controller: _mayoristaCtrl,
                          prefixIcon: Icons.storefront_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedePrecios,
                        ),
                      ),
                    ],
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
                  AppLayout.vS,
                  Consumer(
                    builder: (ctx, ref, _) {
                      final venta = double.tryParse(_ventaCtrl.text) ?? 0;
                      final minimo = double.tryParse(_minimoCtrl.text) ?? 0;
                      if (minimo > 0 && venta < minimo) {
                        return Text('⚠️ El precio está por debajo del mínimo permitido', style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              AppSection(
                title: 'Inventario',
                children: [
                  if (!puedeInventario)
                    Padding(
                      padding: AppSpacing.bS,
                      child: Text('No tiene permiso para modificar estos valores', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Existencia Actual',
                          controller: _stockCtrl,
                          prefixIcon: Icons.format_list_numbered,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedeInventario,
                        ),
                      ),
                      AppLayout.hM,
                      Expanded(
                        child: AppTextField(
                          label: 'Stock Mínimo (Alerta)',
                          controller: _stockMinCtrl,
                          prefixIcon: Icons.warning_amber_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          enabled: puedeInventario,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppLayout.vM,
              SwitchListTile(
                title: Text('Producto Activo para la Venta', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w500)),
                value: _activo,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _activo = v),
                contentPadding: EdgeInsets.zero,
              ),
              AppLayout.vXl,
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Guardar Producto',
                  height: AppSizes.buttonHeightLg,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    if (_catSel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione una categoría'), backgroundColor: AppColors.error));
                      return;
                    }
                    if (_unidadSel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione unidad de medida'), backgroundColor: AppColors.error));
                      return;
                    }
                    final costo = double.tryParse(_costoCtrl.text) ?? 0;
                    final gastos = double.tryParse(_gastosCtrl.text) ?? 0;
                    final venta = double.tryParse(_ventaCtrl.text) ?? 0;
                    final minimo = double.tryParse(_minimoCtrl.text);
                    final stockVal = double.tryParse(_stockCtrl.text) ?? 0;
                    final stockMinVal = double.tryParse(_stockMinCtrl.text) ?? 0;
                    if (stockVal < 0 || stockMinVal < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las cantidades no pueden ser negativas'), backgroundColor: AppColors.error));
                      return;
                    }
                    if (minimo != null && minimo > 0 && venta < minimo) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El precio de venta no puede ser menor al precio mínimo'), backgroundColor: AppColors.error));
                      return;
                    }
                    final margen = double.tryParse(_margenCtrl.text);
                    final mayorista = double.tryParse(_mayoristaCtrl.text);
                    final especial = double.tryParse(_especialCtrl.text);
                    final sku = _skuCtrl.text.trim().isEmpty ? 'SKU-${DateTime.now().millisecondsSinceEpoch}' : _skuCtrl.text.trim();
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
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Producto registrado y movimiento en Kardex creado!')));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
