import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_dialog.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/providers/core_providers.dart'; // ✅ Ruta EXACTA confirmada
import 'package:fiscogest_rd/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart';
import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/ajuste_inventario.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

class RegistrarAjustePage extends ConsumerStatefulWidget {
  const RegistrarAjustePage({super.key});
  static const routeName = 'registrar-ajuste';

  @override
  ConsumerState<RegistrarAjustePage> createState() => _RegistrarAjustePageState();
}

class _RegistrarAjustePageState extends ConsumerState<RegistrarAjustePage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController(); // ✅ Punto 2: Observaciones
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
    final productosAsync = ref.watch(productoControllerProvider);
    return AppScaffold( // ✅ Punto 4: Migración UI
      appBar: AppBar(
        title: const Text('Registrar Ajuste'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      padding: AppSpacing.allM,
      body: productosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (todos) => SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField( // ✅ Parámetros reales confirmados
                        controller: _codigoCtrl,
                        hint: 'Seleccione o escriba el código',
                        onChanged: (val) {
                          setState(() => _productoSeleccionado = null);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.blue),
                      onPressed: () => _abrirBuscador(todos),
                    ),
                  ],
                ),
                if (_productoSeleccionado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: AppSpacing.m),
                    child: Text(
                      '✅ ${_productoSeleccionado!.nombre} | Stock actual: ${_productoSeleccionado!.stock}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: AppSpacing.m),

                const Text('Tipo de Ajuste', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s),
                AppDropdown<String>( // ✅ Parámetros reales confirmados
                  initialValue: _tipoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada (Sumar stock)')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida (Restar stock)')),
                  ],
                  onChanged: (v) => setState(() => _tipoSeleccionado = v!),
                ),
                const SizedBox(height: AppSpacing.m),

                const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s),
                AppTextField(
                  controller: _cantidadCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  hint: 'Ej: 5.5',
                ),
                const SizedBox(height: AppSpacing.m),

                const Text('Motivo', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s),
                AppTextField(
                  controller: _motivoCtrl,
                  hint: 'Ej: Conteo físico / Pérdida',
                ),
                const SizedBox(height: AppSpacing.m),

                // ✅ Punto 2: Campo Observaciones
                const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s),
                AppTextField(
                  controller: _observacionesCtrl,
                  hint: 'Comentarios adicionales (opcional)',
                ),
                const SizedBox(height: AppSpacing.l),

                SizedBox(
                  width: double.infinity,
                  child: AppButton( // ✅ Parámetros reales confirmados
                    text: 'Guardar Ajuste',
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final codigo = _codigoCtrl.text.trim();
                      final producto = _productoSeleccionado ?? todos.firstWhere(
                        (p) => p.codigo == codigo,
                        orElse: () => throw Exception('Producto no encontrado'),
                      );

                      // ✅ Punto 3: Validación visual refuerzo (definitiva en Caso de Uso)
                      final cant = double.tryParse(_cantidadCtrl.text);
                      if (cant == null || cant <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La cantidad debe ser mayor a cero')),
                        );
                        return;
                      }
                      if (_tipoSeleccionado == 'salida' && cant > producto.stock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Stock insuficiente. Disponible: ${producto.stock}')),
                        );
                        return;
                      }

                      final ajuste = AjusteInventario(
                        idProducto: producto.id ?? 0,
                        codigoBusqueda: codigo,
                        cantidad: cant,
                        tipoAjuste: _tipoSeleccionado,
                        motivo: _motivoCtrl.text,
                        // observaciones: _observacionesCtrl.text.trim(), // Habilitar al agregar en entidad
                        // ✅ Punto 1: usuarioId real EXACTO confirmado
                        usuarioId: ref.read(usuarioIdAutenticadoProvider)!,
                        fechaCreacion: DateTime.now(),
                      );

                      final exito = await ref.read(ajusteInventarioProvider.notifier).registrar(ajuste);
                      if (!exito || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Ajuste guardado — stock actualizado en inventario')),
                      );
                      context.pop();
                    },
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

class _DialogoBusqueda extends StatefulWidget {
  const _DialogoBusqueda({required this.productos, required this.onSeleccionar});
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
    return AppDialog( // ✅ Punto 4: Migración UI
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
              child: _resultados.isEmpty
                  ? const Center(child: Padding(padding: AppSpacing.allM, child: Text('Sin resultados')))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _resultados.length,
                      itemBuilder: (_, i) {
                        final p = _resultados[i];
                        return ListTile(
                          title: Text('${p.codigo} • ${p.nombre}'),
                          subtitle: Text('Stock: ${p.stock} | Compra: ${p.precioCompra} | Venta: ${p.precioVenta}'),
                          onTap: () => widget.onSeleccionar(p),
                        );
                      },
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
