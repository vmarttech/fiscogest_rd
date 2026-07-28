import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String _tipoSeleccionado = 'entrada';
  Producto? _productoSeleccionado;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ajuste'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: productosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (todos) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codigoCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Seleccione o escriba el código',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onChanged: (val) {
                          setState(() => _productoSeleccionado = null);
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Seleccione un producto' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.blue),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                          side: BorderSide(color: Colors.grey),
                        ),
                      ),
                      onPressed: () => _abrirBuscador(todos),
                    ),
                  ],
                ),
                if (_productoSeleccionado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 16),
                    child: Text(
                      '✅ ${_productoSeleccionado!.nombre} | Stock actual: ${_productoSeleccionado!.stock}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 16),

                const Text('Tipo de Ajuste', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _tipoSeleccionado,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                  items: const [
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada (Sumar stock)')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida (Restar stock)')),
                  ],
                  onChanged: (v) => setState(() => _tipoSeleccionado = v!),
                ),
                const SizedBox(height: 16),

                const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cantidadCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Ej: 5.5', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                  validator: (v) => v == null || v.isEmpty ? 'Ingrese cantidad' : null,
                ),
                const SizedBox(height: 16),

                const Text('Motivo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motivoCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Ej: Conteo físico / Pérdida', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                  validator: (v) => v == null || v.isEmpty ? 'Ingrese motivo' : null,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final codigo = _codigoCtrl.text.trim();
                      final producto = _productoSeleccionado ?? todos.firstWhere(
                        (p) => p.codigo == codigo,
                        orElse: () => throw Exception('Producto no encontrado'),
                      );

                      final ajuste = AjusteInventario(
                        idProducto: producto.id!,
                        codigoBusqueda: codigo,
                        cantidad: double.parse(_cantidadCtrl.text),
                        tipoAjuste: _tipoSeleccionado,
                        motivo: _motivoCtrl.text,
                        usuarioId: 1,
                        fechaCreacion: DateTime.now(),
                      );

                      await ref.read(registrarAjusteProvider).call(ajuste);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Ajuste guardado — stock actualizado en inventario')),
                        );
                        context.pop();
                      }
                    },
                    child: const Text('Guardar Ajuste'),
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
    return AlertDialog(
      title: const Text('Buscar Producto'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _buscarCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar por código o nombre...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filtrar,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _resultados.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin resultados')))
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
