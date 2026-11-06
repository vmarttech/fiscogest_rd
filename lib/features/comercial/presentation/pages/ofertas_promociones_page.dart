import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';

class OfertasPromocionesPage extends ConsumerStatefulWidget {
  const OfertasPromocionesPage({super.key});

  static const String routeName = 'ofertas-promociones';

  @override
  ConsumerState<OfertasPromocionesPage> createState() =>
      _OfertasPromocionesPageState();
}

class _OfertasPromocionesPageState
    extends ConsumerState<OfertasPromocionesPage> {
  late Future<List<Promocion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _listar();
  }

  Future<List<Promocion>> _listar() =>
      ref.read(promocionRepositoryProvider).listarTodas();

  void _recargar() {
    setState(() => _future = _listar());
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);
    final categoriasAsync = ref.watch(categoriaControllerProvider);

    return AppScaffold(
      showAppBar: false,
      useAppPage: false,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Volver a Productos',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ofertas y promociones',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _recargar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Promocion>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _estado(
                    Icons.error_outline,
                    'No se pudieron cargar las promociones.',
                    '\${snapshot.error}',
                    _recargar,
                  );
                }

                return productosAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _estado(
                    Icons.inventory_2_outlined,
                    'No se pudieron cargar los productos.',
                    '$error',
                    () => ref
                        .read(productoControllerProvider.notifier)
                        .cargarProductos(),
                  ),
                  data: (productos) => categoriasAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _estado(
                      Icons.category_outlined,
                      'No se pudieron cargar las categorías.',
                      '$error',
                      () => ref.invalidate(categoriaControllerProvider),
                    ),
                    data: (categorias) => _listado(
                      snapshot.data ?? const <Promocion>[],
                      productos,
                      categorias,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _listado(
    List<Promocion> promociones,
    List<Producto> productos,
    List<Categoria> categorias,
  ) {
    if (promociones.isEmpty) {
      return _estado(
        Icons.local_offer_outlined,
        'Todavía no tienes ofertas ni promociones.',
        'Crea una promoción para que Caja pueda aplicarla cuando corresponda.',
        () => _abrirFormulario(productos: productos, categorias: categorias),
        textoAccion: 'Crear primera promoción',
      );
    }

    final vigentes = promociones
        .where((p) => p.estaVigente(DateTime.now()))
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _indicador('Registradas', '${promociones.length}'),
                _indicador('Vigentes ahora', '$vigentes'),
                _indicador(
                  'Inactivas/vencidas',
                  '${promociones.length - vigentes}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...promociones.map((p) {
          final vigente = p.estaVigente(DateTime.now());
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(child: Icon(_icono(p.tipo))),
              title: Text(
                p.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${_tipoTexto(p)}\n'
                  '${_alcance(p, productos, categorias)}\n'
                  '${_periodo(p)} · ${vigente
                      ? 'Vigente'
                      : p.activa
                      ? 'Fuera de vigencia'
                      : 'Inactiva'}',
                ),
              ),
              isThreeLine: true,
              onTap: () => _abrirFormulario(
                promocion: p,
                productos: productos,
                categorias: categorias,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (accion) async {
                  if (accion == 'editar') {
                    await _abrirFormulario(
                      promocion: p,
                      productos: productos,
                      categorias: categorias,
                    );
                  } else if (accion == 'estado') {
                    await _cambiarEstado(p);
                  } else if (accion == 'eliminar') {
                    await _eliminar(p);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(
                    value: 'estado',
                    child: Text(p.activa ? 'Desactivar' : 'Activar'),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _indicador(String label, String valor) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );

  Future<void> _abrirFormulario({
    Promocion? promocion,
    List<Producto>? productos,
    List<Categoria>? categorias,
  }) async {
    final listaProductos =
        productos ??
        ref.read(productoControllerProvider).valueOrNull ??
        <Producto>[];
    final listaCategorias =
        categorias ??
        ref.read(categoriaControllerProvider).valueOrNull ??
        <Categoria>[];

    final nombre = TextEditingController(text: promocion?.nombre ?? '');
    final descripcion = TextEditingController(
      text: promocion?.descripcion ?? '',
    );
    final valor = TextEditingController(
      text: promocion?.valor.toString() ?? '10',
    );
    final cantidad = TextEditingController(
      text: promocion?.minimoCantidad?.toString() ?? '',
    );
    final minimoMonto = TextEditingController(
      text: promocion?.minimoMonto?.toString() ?? '',
    );

    final productosMarcados = <int>{...promocion?.productoIds ?? const <int>[]};
    final categoriasMarcadas = <int>{
      ...promocion?.categoriaIds ?? const <int>[],
    };
    final formKey = GlobalKey<FormState>();

    var tipo = promocion?.tipo ?? 'porcentaje';
    var activa = promocion?.activa ?? true;
    DateTime? inicio = promocion?.fechaInicio;
    DateTime? fin = promocion?.fechaFin;

    final resultado = await showDialog<Promocion>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refrescarDialogo) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          titlePadding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          contentPadding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          actionsPadding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            promocion == null ? 'Nueva promoción' : 'Editar promoción',
          ),
          content: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width < 600
                ? MediaQuery.sizeOf(dialogContext).width - 48
                : 560,
            height: (MediaQuery.sizeOf(dialogContext).height * 0.65).clamp(
              160.0,
              620.0,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nombre,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la promoción *',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Escribe un nombre.'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descripcion,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de promoción',
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
                      onChanged: (v) => refrescarDialogo(() {
                        tipo = v ?? 'porcentaje';
                        valor.text = tipo == 'porcentaje'
                            ? '10'
                            : tipo == 'montoFijo'
                            ? '100'
                            : '1';
                      }),
                    ),
                    if (tipo != 'lleve2Pague1') ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: valor,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: tipo == 'porcentaje'
                              ? 'Porcentaje de descuento *'
                              : 'Monto de descuento (RD\$) *',
                        ),
                        validator: (v) {
                          final n = double.tryParse(
                            (v ?? '').replaceAll(',', '.'),
                          );
                          if (n == null || n <= 0) {
                            return 'Introduce un valor mayor que cero.';
                          }
                          if (tipo == 'porcentaje' && n > 100) {
                            return 'El porcentaje no puede superar 100.';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (tipo == 'lleve2Pague1')
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'El descuento se calcula por cada línea: dos unidades del mismo producto y una gratis.',
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vigencia',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              inicio == null
                                  ? 'Fecha inicial'
                                  : DateFormat('dd/MM/yyyy').format(inicio!),
                            ),
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: inicio ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (fecha != null) {
                                refrescarDialogo(() {
                                  inicio = DateTime(
                                    fecha.year,
                                    fecha.month,
                                    fecha.day,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event),
                            label: Text(
                              fin == null
                                  ? 'Fecha final'
                                  : DateFormat('dd/MM/yyyy').format(fin!),
                            ),
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: fin ?? inicio ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (fecha != null) {
                                refrescarDialogo(() {
                                  fin = DateTime(
                                    fecha.year,
                                    fecha.month,
                                    fecha.day,
                                    23,
                                    59,
                                    59,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Condiciones mínimas (opcionales)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cantidad,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad mínima',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = int.tryParse(v);
                              return n == null || n < 0
                                  ? 'Cantidad inválida.'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: minimoMonto,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Compra mínima (RD\$)',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final n = double.tryParse(v.replaceAll(',', '.'));
                              return n == null || n < 0
                                  ? 'Monto inválido.'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aplicación de la promoción',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Si no seleccionas productos ni categorías, se aplicará a todos los productos elegibles.',
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Productos (${productosMarcados.length} seleccionados)',
                      ),
                      children: [
                        if (listaProductos.isEmpty)
                          const ListTile(
                            title: Text('No hay productos disponibles.'),
                          )
                        else
                          SizedBox(
                            height: 130,
                            child: ListView(
                              children: listaProductos
                                  .where((p) => p.id != null)
                                  .map(
                                    (p) => CheckboxListTile(
                                      dense: true,
                                      value: productosMarcados.contains(p.id),
                                      title: Text(p.nombre),
                                      subtitle: Text(p.codigo),
                                      onChanged: (marcado) {
                                        refrescarDialogo(() {
                                          if (marcado == true) {
                                            productosMarcados.add(p.id!);
                                          } else {
                                            productosMarcados.remove(p.id);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        'Categorías (${categoriasMarcadas.length} seleccionadas)',
                      ),
                      children: [
                        if (listaCategorias.isEmpty)
                          const ListTile(
                            title: Text('No hay categorías disponibles.'),
                          )
                        else
                          SizedBox(
                            height: 130,
                            child: ListView(
                              children: listaCategorias
                                  .where((c) => c.id != null)
                                  .map(
                                    (c) => CheckboxListTile(
                                      dense: true,
                                      value: categoriasMarcadas.contains(c.id),
                                      title: Text(c.nombre),
                                      onChanged: (marcado) {
                                        refrescarDialogo(() {
                                          if (marcado == true) {
                                            categoriasMarcadas.add(c.id!);
                                          } else {
                                            categoriasMarcadas.remove(c.id);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Promoción activa'),
                      value: activa,
                      onChanged: (v) => refrescarDialogo(() => activa = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (inicio != null && fin != null && fin!.isBefore(inicio!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La fecha final no puede ser anterior a la inicial.',
                      ),
                    ),
                  );
                  return;
                }

                final importe = tipo == 'lleve2Pague1'
                    ? 1.0
                    : double.parse(valor.text.replaceAll(',', '.'));

                Navigator.pop(
                  dialogContext,
                  Promocion(
                    id: promocion?.id ?? 0,
                    nombre: nombre.text.trim(),
                    descripcion: descripcion.text.trim(),
                    tipo: tipo,
                    valor: importe,
                    fechaInicio: inicio,
                    fechaFin: fin,
                    activa: activa,
                    minimoCantidad: cantidad.text.trim().isEmpty
                        ? null
                        : int.parse(cantidad.text.trim()),
                    minimoMonto: minimoMonto.text.trim().isEmpty
                        ? null
                        : double.parse(minimoMonto.text.replaceAll(',', '.')),
                    productoIds: productosMarcados.toList(),
                    categoriaIds: categoriasMarcadas.toList(),
                  ),
                );
              },
              child: const Text('Guardar promoción'),
            ),
          ],
        ),
      ),
    );

    nombre.dispose();
    descripcion.dispose();
    valor.dispose();
    cantidad.dispose();
    minimoMonto.dispose();

    if (resultado == null || !mounted) return;

    try {
      final repo = ref.read(promocionRepositoryProvider);
      if (promocion == null) {
        await repo.crear(resultado);
      } else {
        await repo.actualizar(resultado);
      }
      if (!mounted) return;
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            promocion == null ? 'Promoción creada.' : 'Promoción actualizada.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
    }
  }

  Future<void> _cambiarEstado(Promocion p) async {
    try {
      await ref
          .read(promocionRepositoryProvider)
          .actualizar(
            Promocion(
              id: p.id,
              nombre: p.nombre,
              descripcion: p.descripcion,
              tipo: p.tipo,
              valor: p.valor,
              fechaInicio: p.fechaInicio,
              fechaFin: p.fechaFin,
              activa: !p.activa,
              minimoCantidad: p.minimoCantidad,
              minimoMonto: p.minimoMonto,
              productoIds: p.productoIds,
              categoriaIds: p.categoriaIds,
            ),
          );
      _recargar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar el estado: $error')),
        );
      }
    }
  }

  Future<void> _eliminar(Promocion p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar promoción'),
        content: Text(
          '¿Seguro que deseas eliminar "${p.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    try {
      await ref.read(promocionRepositoryProvider).eliminar(p.id);
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Promoción eliminada.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  String _tipoTexto(Promocion p) {
    switch (p.tipo) {
      case 'porcentaje':
        return '${p.valor.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')}% de descuento';
      case 'lleve2Pague1':
        return 'Lleve 2 y pague 1';
      case 'montoFijo':
        return 'Descuento de RD\$ ${p.valor.toStringAsFixed(2)}';
      default:
        return p.tipo;
    }
  }

  IconData _icono(String tipo) {
    switch (tipo) {
      case 'porcentaje':
        return Icons.percent;
      case 'lleve2Pague1':
        return Icons.shopping_bag_outlined;
      case 'montoFijo':
        return Icons.payments_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }

  String _alcance(
    Promocion p,
    List<Producto> productos,
    List<Categoria> categorias,
  ) {
    if (p.productoIds.isEmpty && p.categoriaIds.isEmpty) {
      return 'Alcance: todos los productos';
    }

    final nombresProductos = productos
        .where((x) => x.id != null && p.productoIds.contains(x.id))
        .map((x) => x.nombre)
        .toList();
    final nombresCategorias = categorias
        .where((x) => x.id != null && p.categoriaIds.contains(x.id))
        .map((x) => x.nombre)
        .toList();

    final partes = <String>[];
    if (nombresProductos.isNotEmpty) {
      partes.add('Productos: ${nombresProductos.join(', ')}');
    }
    if (nombresCategorias.isNotEmpty) {
      partes.add('Categorías: ${nombresCategorias.join(', ')}');
    }
    return partes.isEmpty
        ? 'Alcance: selección no disponible'
        : partes.join(' · ');
  }

  String _periodo(Promocion p) {
    final inicio = p.fechaInicio == null
        ? 'Sin fecha inicial'
        : DateFormat('dd/MM/yyyy').format(p.fechaInicio!);
    final fin = p.fechaFin == null
        ? 'Sin fecha final'
        : DateFormat('dd/MM/yyyy').format(p.fechaFin!);
    return '$inicio — $fin';
  }

  Widget _estado(
    IconData icono,
    String mensaje,
    String detalle,
    VoidCallback accion, {
    String textoAccion = 'Reintentar',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(detalle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: accion, child: Text(textoAccion)),
          ],
        ),
      ),
    );
  }
}
