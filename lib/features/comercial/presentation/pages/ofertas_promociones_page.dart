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
import 'package:fiscogest_rd/features/comercial/presentation/pages/promocion_form_sheet.dart';

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
    setState(() {
      _future = _listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productoControllerProvider);
    final categoriasAsync = ref.watch(categoriaControllerProvider);

    return AppScaffold(
      title: 'Ofertas y promociones',
      subtitle: 'Descuentos y reglas para Caja',
      showAppBar: true,
      useAppPage: false,
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _recargar,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        children: [
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _indicador('Registradas', '${promociones.length}'),
                _indicador('Vigentes', '$vigentes'),
                _indicador(
                  'Inactivas',
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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

    final resultado = await showModalBottomSheet<Promocion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final h = MediaQuery.sizeOf(sheetContext).height;
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SizedBox(
            height: (h * 0.50).clamp(260.0, 420.0),
            child: PromocionFormSheet(
              promocion: promocion,
              productos: listaProductos,
              categorias: listaCategorias,
            ),
          ),
        );
      },
    );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icono, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton(
                  onPressed: accion,
                  child: Text(textoAccion),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
