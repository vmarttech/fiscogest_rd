import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';

/// Formulario de promoción (móvil/desktop).
/// Controllers propios → evita pantalla roja al cerrar.
class PromocionFormSheet extends StatefulWidget {
  const PromocionFormSheet({
    super.key,
    required this.promocion,
    required this.productos,
    required this.categorias,
  });

  final Promocion? promocion;
  final List<Producto> productos;
  final List<Categoria> categorias;

  @override
  State<PromocionFormSheet> createState() => _PromocionFormSheetState();
}

class _PromocionFormSheetState extends State<PromocionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _valor;
  late final TextEditingController _cantidad;
  late final TextEditingController _minimoMonto;
  late final Set<int> _productosMarcados;
  late final Set<int> _categoriasMarcadas;
  late String _tipo;
  late bool _activa;
  DateTime? _inicio;
  DateTime? _fin;

  @override
  void initState() {
    super.initState();
    final p = widget.promocion;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _valor = TextEditingController(text: p?.valor.toString() ?? '10');
    _cantidad =
        TextEditingController(text: p?.minimoCantidad?.toString() ?? '');
    _minimoMonto =
        TextEditingController(text: p?.minimoMonto?.toString() ?? '');
    _productosMarcados = {...p?.productoIds ?? const <int>[]};
    _categoriasMarcadas = {...p?.categoriaIds ?? const <int>[]};
    _tipo = p?.tipo ?? 'porcentaje';
    _activa = p?.activa ?? true;
    _inicio = p?.fechaInicio;
    _fin = p?.fechaFin;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _valor.dispose();
    _cantidad.dispose();
    _minimoMonto.dispose();
    super.dispose();
  }

  Future<void> _pickFecha({required bool esInicio}) async {
    final base = esInicio
        ? (_inicio ?? DateTime.now())
        : (_fin ?? _inicio ?? DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: esInicio ? 'Fecha inicial' : 'Fecha final',
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        final size = MediaQuery.sizeOf(ctx);
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width * 0.94,
                maxHeight: size.height * 0.72,
              ),
              child: child,
            ),
          ),
        );
      },
    );
    if (fecha == null || !mounted) return;
    setState(() {
      if (esInicio) {
        _inicio = DateTime(fecha.year, fecha.month, fecha.day);
      } else {
        _fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      }
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_inicio != null && _fin != null && _fin!.isBefore(_inicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha final no puede ser anterior a la inicial.'),
        ),
      );
      return;
    }
    final importe = _tipo == 'lleve2Pague1'
        ? 1.0
        : double.parse(_valor.text.replaceAll(',', '.'));
    Navigator.pop(
      context,
      Promocion(
        id: widget.promocion?.id ?? 0,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        tipo: _tipo,
        valor: importe,
        fechaInicio: _inicio,
        fechaFin: _fin,
        activa: _activa,
        minimoCantidad: _cantidad.text.trim().isEmpty
            ? null
            : int.parse(_cantidad.text.trim()),
        minimoMonto: _minimoMonto.text.trim().isEmpty
            ? null
            : double.parse(_minimoMonto.text.replaceAll(',', '.')),
        productoIds: _productosMarcados.toList(),
        categoriaIds: _categoriasMarcadas.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaProductos = widget.productos;
    final listaCategorias = widget.categorias;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.promocion == null
                      ? 'Nueva promoción'
                      : 'Editar promoción',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: [
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la promoción *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Escribe un nombre.'
                      : null,
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descripcion,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de promoción',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'porcentaje',
                      child: Text('Descuento por porcentaje'),
                    ),
                    DropdownMenuItem(
                      value: 'lleve2Pague1',
                      child: Text('Lleve 2 y pague 1'),
                    ),
                    DropdownMenuItem(
                      value: 'montoFijo',
                      child: Text('Descuento de monto fijo'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _tipo = v ?? 'porcentaje';
                    _valor.text = _tipo == 'porcentaje'
                        ? '10'
                        : _tipo == 'montoFijo'
                            ? '100'
                            : '1';
                  }),
                ),
                if (_tipo != 'lleve2Pague1') ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _valor,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _tipo == 'porcentaje'
                          ? 'Porcentaje de descuento *'
                          : 'Monto de descuento (RD\$) *',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    validator: (v) {
                      final n =
                          double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (n == null || n <= 0) {
                        return 'Introduce un valor mayor que cero.';
                      }
                      if (_tipo == 'porcentaje' && n > 100) {
                        return 'El porcentaje no puede superar 100.';
                      }
                      return null;
                    },
                  ),
                ],
                if (_tipo == 'lleve2Pague1')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'El descuento se calcula por cada línea: dos unidades del mismo producto y una gratis.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Vigencia',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _inicio == null
                              ? 'Inicio'
                              : DateFormat('dd/MM/yy').format(_inicio!),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _pickFecha(esInicio: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          _fin == null
                              ? 'Fin'
                              : DateFormat('dd/MM/yy').format(_fin!),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _pickFecha(esInicio: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Condiciones mínimas (opcionales)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cantidad,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad mínima',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v);
                    return n == null || n < 0 ? 'Cantidad inválida.' : null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _minimoMonto,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Compra mínima (RD\$)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    return n == null || n < 0 ? 'Monto inválido.' : null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplicación de la promoción',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Si no eliges productos ni categorías, aplica a todos.',
                  style: TextStyle(fontSize: 12),
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Productos (${_productosMarcados.length})',
                    style: const TextStyle(fontSize: 14),
                  ),
                  children: [
                    if (listaProductos.isEmpty)
                      const ListTile(
                        dense: true,
                        title: Text('No hay productos disponibles.'),
                      )
                    else
                      ...listaProductos.where((p) => p.id != null).map(
                            (p) => CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: _productosMarcados.contains(p.id),
                              title: Text(
                                p.nombre,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle: Text(
                                p.codigo,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onChanged: (marcado) {
                                setState(() {
                                  if (marcado == true) {
                                    _productosMarcados.add(p.id!);
                                  } else {
                                    _productosMarcados.remove(p.id);
                                  }
                                });
                              },
                            ),
                          ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Categorías (${_categoriasMarcadas.length})',
                    style: const TextStyle(fontSize: 14),
                  ),
                  children: [
                    if (listaCategorias.isEmpty)
                      const ListTile(
                        dense: true,
                        title: Text('No hay categorías disponibles.'),
                      )
                    else
                      ...listaCategorias.where((c) => c.id != null).map(
                            (c) => CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: _categoriasMarcadas.contains(c.id),
                              title: Text(
                                c.nombre,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onChanged: (marcado) {
                                setState(() {
                                  if (marcado == true) {
                                    _categoriasMarcadas.add(c.id!);
                                  } else {
                                    _categoriasMarcadas.remove(c.id);
                                  }
                                });
                              },
                            ),
                          ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Promoción activa'),
                  value: _activa,
                  onChanged: (v) => setState(() => _activa = v),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _guardar,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
