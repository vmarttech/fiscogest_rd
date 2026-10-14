import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';

class RegistrarAjustePage extends ConsumerStatefulWidget {
  const RegistrarAjustePage({super.key});
  static const String routeName = 'registrar-ajuste';

  @override
  ConsumerState<RegistrarAjustePage> createState() =>
      _RegistrarAjustePageState();
}

class _RegistrarAjustePageState extends ConsumerState<RegistrarAjustePage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  String _tipoSeleccionado = 'entrada';
  Producto? _productoSeleccionado;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  void _seleccionarProducto(Producto prod) {
    setState(() {
      _productoSeleccionado = prod;
      _codigoCtrl.text = prod.codigo;
    });
    Navigator.of(context, rootNavigator: false).pop();
  }

  void _abrirBuscador(List<Producto> todos) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DialogoBusqueda(
        productos: todos,
        onSeleccionar: _seleccionarProducto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final productosAsync = ref.watch(productoControllerProvider);

    return AppScaffold(
      // ✅ Barra superior UNIFORME — igual a todas las pantallas
      title: 'Registrar Ajuste',
      subtitle: 'Conteo físico, mermas y correcciones de stock',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: const [],
      body: SafeArea(
        bottom: true,
        child: productosAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text(
              'Error: $e',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          data: (todos) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              isMobile ? 12 : 16,
              isMobile ? 16 : 24,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grey900.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Producto', style: AppTypography.labelLarge),
                        const SizedBox(height: AppSpacing.s),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _abrirBuscador(todos),
                            icon: const Icon(Icons.search_rounded),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _productoSeleccionado == null
                                    ? 'Buscar y seleccionar producto'
                                    : '${_productoSeleccionado!.codigo} · ${_productoSeleccionado!.nombre}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _productoSeleccionado == null
                                  ? AppColors.textSecondary
                                  : AppColors.primaryDark,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_productoSeleccionado != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 6,
                              bottom: AppSpacing.m,
                            ),
                            child: Text(
                              '✅ ${_productoSeleccionado!.nombre} | Stock actual: ${_productoSeleccionado!.stock ?? 0.0}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.m),
                        const Text(
                          'Tipo de Ajuste',
                          style: AppTypography.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppDropdown<String>(
                          initialValue: _tipoSeleccionado,
                          items: const [
                            DropdownMenuItem(
                              value: 'entrada',
                              child: Text('Entrada (+)'),
                            ),
                            DropdownMenuItem(
                              value: 'salida',
                              child: Text('Salida (-)'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _tipoSeleccionado = v!),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        const Text('Cantidad', style: AppTypography.labelLarge),
                        const SizedBox(height: AppSpacing.s),
                        AppTextField(
                          controller: _cantidadCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          hint: 'Ej: 5.5',
                        ),
                        const SizedBox(height: AppSpacing.m),
                        const Text('Motivo', style: AppTypography.labelLarge),
                        const SizedBox(height: AppSpacing.s),
                        AppTextField(
                          controller: _motivoCtrl,
                          hint: 'Ej: Conteo físico / Pérdida',
                        ),
                        const SizedBox(height: AppSpacing.m),
                        const Text(
                          'Observaciones',
                          style: AppTypography.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        AppTextField(
                          controller: _observacionesCtrl,
                          hint: 'Comentarios adicionales (opcional)',
                        ),
                        const SizedBox(height: AppSpacing.l),
                        Align(
                          alignment: isMobile
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: SizedBox(
                            width: isMobile ? double.infinity : 220,
                            child: AppButton(
                              text: 'Guardar Ajuste',
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                final codigo = _codigoCtrl.text.trim();
                                final producto = _productoSeleccionado;
                                if (producto == null) {
                                  FiscoGestNotifications.show(
                                    const SnackBar(
                                      content: Text(
                                        'Seleccione un producto usando la lupa',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final cant =
                                    double.tryParse(_cantidadCtrl.text) ?? 0.0;
                                if (cant <= 0) {
                                  FiscoGestNotifications.show(
                                    const SnackBar(
                                      content: Text(
                                        'La cantidad debe ser mayor a cero',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final stockActual = producto.stock ?? 0.0;
                                if (_tipoSeleccionado == 'salida' &&
                                    cant > stockActual) {
                                  FiscoGestNotifications.show(
                                    SnackBar(
                                      content: Text(
                                        'Stock insuficiente. Disponible: $stockActual',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final usuarioId = ref.read(
                                  usuarioAutenticadoProvider,
                                );
                                if (usuarioId == null) {
                                  FiscoGestNotifications.show(
                                    const SnackBar(
                                      content: Text('Usuario no autenticado'),
                                    ),
                                  );
                                  return;
                                }
                                final ajuste = AjusteInventario(
                                  productoId: producto.id!,
                                  codigoBusqueda: codigo,
                                  cantidad: cant,
                                  tipoAjuste: _tipoSeleccionado,
                                  motivo: _motivoCtrl.text,
                                  observaciones: _observacionesCtrl.text.trim(),
                                  usuarioId: usuarioId,
                                  fechaCreacion: DateTime.now(),
                                );
                                final exito = await ref
                                    .read(ajusteInventarioProvider)
                                    .registrar(ajuste);
                                setState(() {
                                  final stockBase =
                                      _productoSeleccionado?.stock ?? 0;
                                  final cantAjuste = (cant).toDouble();
                                  final tipoTxt = (_tipoSeleccionado)
                                      .toString();
                                  final stockNuevo = tipoTxt == 'entrada'
                                      ? stockBase + cantAjuste
                                      : stockBase - cantAjuste;
                                  _productoSeleccionado = _productoSeleccionado
                                      ?.copyWith(stock: stockNuevo);
                                });
                                ref.invalidate(productoControllerProvider);
                                ref.invalidate(kardexHistorialCompletoProvider);
                                ref.invalidate(kardexPorProductoProvider);
                                if (!exito || !context.mounted) return;
                                FiscoGestNotifications.show(
                                  const SnackBar(
                                    content: Text(
                                      '✅ Ajuste guardado — stock actualizado',
                                    ),
                                  ),
                                );
                                context.pop();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogoBusqueda extends StatefulWidget {
  const _DialogoBusqueda({
    required this.productos,
    required this.onSeleccionar,
  });
  final List<Producto> productos;
  final void Function(Producto) onSeleccionar;

  @override
  State<_DialogoBusqueda> createState() => _DialogoBusquedaState();
}

class _DialogoBusquedaState extends State<_DialogoBusqueda> {
  final _buscarCtrl = TextEditingController();
  List<Producto> _resultados = [];

  @override
  void initState() {
    super.initState();
    _resultados = widget.productos;
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _filtrar(String texto) {
    setState(() {
      final t = texto.toLowerCase();
      _resultados = widget.productos.where((p) {
        return p.codigo.toLowerCase().contains(t) ||
            p.nombre.toLowerCase().contains(t);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Buscar Producto',
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _buscarCtrl,
              hint: 'Buscar por código o nombre...',
              prefixIcon: Icons.search,
              onChanged: _filtrar,
            ),
            const SizedBox(height: AppSpacing.s),
            Flexible(
              child: SizedBox(
                height: 340,
                child: _resultados.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: AppSpacing.allM,
                          child: Text('Sin resultados'),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),

                        itemCount: _resultados.length,
                        itemBuilder: (_, i) {
                          final p = _resultados[i];
                          return ListTile(
                            title: Text('${p.codigo} • ${p.nombre}'),
                            subtitle: Text(
                              'Stock: ${p.stock ?? 0.0} | Compra: ${p.precioCompra} | Venta: ${p.precioVenta}',
                            ),
                            onTap: () => widget.onSeleccionar(p),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
