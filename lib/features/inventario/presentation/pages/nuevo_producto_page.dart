import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/marca_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/unidad_medida_providers.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

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
  final _ventaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _stockMinCtrl = TextEditingController(text: '0');
  int? _catSel;
  int? _marcaSel;
  int? _unidadSel;
  bool _activo = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _skuCtrl.dispose();
    _costoCtrl.dispose();
    _ventaCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriaControllerProvider);
    final marcas = ref.watch(marcaControllerProvider);
    final unids = ref.watch(unidadMedidaControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: AppBar(
        title: const Text('Registrar Nuevo Producto'),
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.allL,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: AppSpacing.hM,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                  ),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _skuCtrl,
                decoration: InputDecoration(
                  labelText: 'SKU / Código de Barra',
                  prefixIcon: const Icon(Icons.qr_code, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: AppSpacing.hM,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              cats.when(
                data: (lista) => DropdownButtonFormField<int>(
                  initialValue: _catSel,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: AppSpacing.hM,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                    ),
                  ),
                  items: lista.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                  onChanged: (v) => setState(() => _catSel = v),
                  validator: (v) => v == null ? 'Seleccione una categoría' : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error cargando categorías: $e', style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: AppSpacing.m),
              marcas.when(
                data: (lista) => DropdownButtonFormField<int>(
                  initialValue: _marcaSel,
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    prefixIcon: const Icon(Icons.branding_watermark_outlined, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: AppSpacing.hM,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                    ),
                  ),
                  items: lista.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
                  onChanged: (v) => setState(() => _marcaSel = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error cargando marcas: $e', style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: AppSpacing.m),
              unids.when(
                data: (lista) => DropdownButtonFormField<int>(
                  initialValue: _unidadSel,
                  decoration: InputDecoration(
                    labelText: 'Unidad de Medida',
                    prefixIcon: const Icon(Icons.straighten_outlined, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: AppSpacing.hM,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                    ),
                  ),
                  items: lista.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nombre))).toList(),
                  onChanged: (v) => setState(() => _unidadSel = v),
                  validator: (v) => v == null ? 'Seleccione unidad de medida' : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error cargando unidades: $e', style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Costo (RD\$)',
                        prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: AppSpacing.hM,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: TextFormField(
                      controller: _ventaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Precio Venta (RD\$)',
                        prefixIcon: const Icon(Icons.sell_outlined, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: AppSpacing.hM,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Existencia Actual',
                        prefixIcon: const Icon(Icons.format_list_numbered, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: AppSpacing.hM,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: TextFormField(
                      controller: _stockMinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock Mínimo (Alerta)',
                        prefixIcon: const Icon(Icons.warning_amber_rounded, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: AppSpacing.hM,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.focusedBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              SwitchListTile(
                title: Text(
                  'Producto Activo para la Venta',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.darkSurface, fontWeight: FontWeight.w500),
                ),
                value: _activo,
                activeThumbColor: AppColors.focusedBlue,
                onChanged: (v) => setState(() => _activo = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkSurface,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final stockVal = double.tryParse(_stockCtrl.text) ?? 0;
                    final stockMinVal = double.tryParse(_stockMinCtrl.text) ?? 0;
                    if (stockVal < 0 || stockMinVal < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Las cantidades no pueden ser negativas'), backgroundColor: AppColors.error),
                      );
                      return;
                    }
                    final nuevoProd = Producto(
                      codigo: _skuCtrl.text.trim().isEmpty ? 'SKU-${DateTime.now().millisecondsSinceEpoch}' : _skuCtrl.text.trim(),
                      nombre: _nombreCtrl.text.trim(),
                      precioCompra: double.tryParse(_costoCtrl.text) ?? 0,
                      precioVenta: double.tryParse(_ventaCtrl.text) ?? 0,
                      stock: stockVal,
                      stockMinimo: stockMinVal,
                      categoriaId: _catSel!,
                      marcaId: _marcaSel ?? 1,
                      unidadMedidaId: _unidadSel!,
                      activo: _activo,
                    );
                    ref.read(productoControllerProvider.notifier).guardar(nuevoProd);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Producto registrado y movimiento en Kardex creado!')),
                    );
                  },
                  child: const Text('Guardar Producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
