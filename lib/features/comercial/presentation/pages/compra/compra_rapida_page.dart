import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/services/compra_rapida_defaults.dart';
import 'package:fiscogest_rd/features/comercial/presentation/providers/compra/compra_usecase_providers.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart'
    as repo;
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

// ─── Paleta local (alineada al resto de la app) ─────────────────────────────
class _C {
  static const teal = Color(0xFF0D9488);
  static const tealDark = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFE6F7F5);
  static const navy = Color(0xFF0B1C2E);
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const bg = Color(0xFFF8FAFC);
  static const white = Colors.white;
}

class _LineaRapida {
  final nombre = TextEditingController();
  final cantidad = TextEditingController(text: '1');
  final costo = TextEditingController();
  Producto? producto;

  void dispose() {
    nombre.dispose();
    cantidad.dispose();
    costo.dispose();
  }

  void aplicarProducto(Producto p) {
    producto = p;
    nombre.text = p.nombre;
    if (p.precioCompra > 0 && costo.text.trim().isEmpty) {
      final v = p.precioCompra;
      costo.text = v == v.roundToDouble()
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(2);
    }
  }

  void limpiarProducto() => producto = null;

  double get subtotal {
    final c = double.tryParse(cantidad.text.replaceAll(',', '.')) ?? 0;
    final k = double.tryParse(costo.text.replaceAll(',', '.')) ?? 0;
    return c * k;
  }
}

class CompraRapidaPage extends ConsumerStatefulWidget {
  const CompraRapidaPage({super.key});

  static const routeName = 'compra-rapida';
  static const path = '/compras/rapida';

  @override
  ConsumerState<CompraRapidaPage> createState() => _CompraRapidaPageState();
}

class _CompraRapidaPageState extends ConsumerState<CompraRapidaPage> {
  final _lineas = <_LineaRapida>[_LineaRapida()];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productoControllerProvider.notifier).cargarProductos();
    });
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  double get _total => _lineas.fold(0.0, (a, l) => a + l.subtotal);

  void _agregarLinea() => setState(() => _lineas.add(_LineaRapida()));

  void _quitarLinea(int i) {
    if (_lineas.length <= 1) return;
    setState(() {
      _lineas[i].dispose();
      _lineas.removeAt(i);
    });
  }

  Future<void> _buscarProducto(int index) async {
    final catalogo =
        ref.read(productoControllerProvider).valueOrNull ?? <Producto>[];
    if (catalogo.isEmpty) {
      FiscoGestNotifications.show(
        const SnackBar(content: Text('No hay productos en inventario')),
      );
      return;
    }

    final elegido = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _C.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SelectorProductoSheet(
        productos: catalogo,
        queryInicial: _lineas[index].nombre.text.trim(),
      ),
    );

    if (!mounted || elegido == null) return;
    setState(() {
      if (elegido is Producto) {
        _lineas[index].aplicarProducto(elegido);
      } else if (elegido is String) {
        final nombre = elegido.trim();
        _lineas[index].limpiarProducto();
        _lineas[index].nombre.text = nombre;
      }
    });
  }

  Future<void> _registrarYConfirmar() async {
    if (_guardando) return;

    for (var i = 0; i < _lineas.length; i++) {
      final l = _lineas[i];
      final nom = l.nombre.text.trim();
      final cant = double.tryParse(l.cantidad.text.replaceAll(',', '.')) ?? 0;
      final cost = double.tryParse(l.costo.text.replaceAll(',', '.')) ?? 0;
      if (nom.isEmpty) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Línea ${i + 1}: indica el producto')),
        );
        return;
      }
      if (cant <= 0) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Línea ${i + 1}: cantidad > 0')),
        );
        return;
      }
      if (cost <= 0) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('Línea ${i + 1}: costo > 0')),
        );
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final proveedorRepo = ref.read(repo.proveedorRepositoryProvider);
      final productoRepo = ref.read(repo.inventarioProductoRepositoryProvider);
      final defaults = CompraRapidaDefaults(
        proveedorRepo: proveedorRepo,
        productoRepo: productoRepo,
      );

      final proveedor = await defaults.obtenerOCrearProveedorGenerico();
      if (proveedor.id == null) {
        throw StateError('No se pudo crear el proveedor genérico');
      }

      final catalogo =
          ref.read(productoControllerProvider).valueOrNull ?? <Producto>[];
      const usuarioId = 1;

      final productosLinea = <Producto>[];
      final cantidades = <double>[];
      final costos = <double>[];

      for (final l in _lineas) {
        final nom = l.nombre.text.trim();
        final cant = double.parse(l.cantidad.text.replaceAll(',', '.'));
        final cost = double.parse(l.costo.text.replaceAll(',', '.'));

        final Producto prod = (l.producto?.id != null)
            ? l.producto!
            : await defaults.obtenerOCrearProducto(
                nombre: nom,
                costo: cost,
                usuarioId: usuarioId,
                catalogoActual: [...catalogo, ...productosLinea],
              );

        productosLinea.add(prod);
        cantidades.add(cant);
        costos.add(cost);
      }

      final ahora = DateTime.now();
      final compraId = ahora.millisecondsSinceEpoch;

      final detalles = <DetalleCompra>[];
      double subtotal = 0;
      for (var i = 0; i < productosLinea.length; i++) {
        final p = productosLinea[i];
        final cant = cantidades[i];
        final cost = costos[i];
        final lineaSub = cant * cost;
        subtotal += lineaSub;
        detalles.add(
          DetalleCompra(
            id: compraId * 1000 + i,
            compraId: compraId,
            productoId: p.id!,
            nombreProducto: p.nombre,
            cantidad: cant,
            costoUnitario: cost,
            costoAdquisicion: cost,
            subtotalLinea: lineaSub,
            baseImponibleLinea: lineaSub,
            tasaImpuestoLinea: 0,
            itbisLinea: 0,
            totalLinea: lineaSub,
          ),
        );
      }

      final compra = Compra(
        id: compraId,
        proveedorId: proveedor.id!,
        nombreProveedor: proveedor.nombreEmpresa,
        fechaEmision: ahora,
        numeroComprobante: '',
        ncf: '',
        tipoComprobante: 'compra',
        formaPago: 'contado',
        condicionPago: 'contado',
        diasCredito: 0,
        subtotalSinImpuestos: subtotal,
        montoDescuentoGlobal: 0,
        tasaImpuesto: 0,
        montoImpuesto: 0,
        totalCompra: subtotal,
        observaciones: 'Compra rápida (modo simplificado)',
        estado: EstadoCompra.registrada,
        creadoEn: ahora,
      );

      final registrada = await ref.read(registrarCompraUseCaseProvider).call(
            compra: compra,
            detalles: detalles,
          );

      await ref.read(confirmarCompraUseCaseProvider).call(registrada.id);
      ref.invalidate(productoControllerProvider);

      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(content: Text('✅ Compra registrada y confirmada')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _fieldDeco({
    required String label,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: _C.muted),
      floatingLabelStyle: const TextStyle(fontSize: 12, color: _C.tealDark),
      isDense: true,
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.teal, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nProductos =
        ref.watch(productoControllerProvider).valueOrNull?.length ?? 0;

    return AppScaffold(
      title: 'Compra rápida',
      body: ColoredBox(
        color: _C.bg,
        child: Column(
          children: [
            // ── Cabecera suave ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: _C.white,
                border: Border(
                  bottom: BorderSide(color: _C.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.tealSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: _C.tealDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Registro express',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _C.navy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nProductos > 0
                              ? 'Elige del inventario o crea al vuelo'
                              : 'Escribe el producto y listo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _C.muted,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Líneas ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  for (var i = 0; i < _lineas.length; i++) ...[
                    _buildLineaCard(i),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: _guardando ? null : _agregarLinea,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _C.tealDark,
                      side: const BorderSide(color: Color(0xFF99D5CE)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Agregar otra línea',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pie fijo: total + CTA ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _C.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 13,
                              color: _C.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'RD\$ ${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _C.navy,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _guardando ? null : _registrarYConfirmar,
                          style: FilledButton.styleFrom(
                            backgroundColor: _C.teal,
                            disabledBackgroundColor: _C.teal.withValues(
                              alpha: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _guardando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Registrar y confirmar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineaCard(int i) {
    final l = _lineas[i];
    final deInventario = l.producto != null;

    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _C.tealSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: _C.tealDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (deInventario)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.tealSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 12, color: _C.tealDark),
                      SizedBox(width: 4),
                      Text(
                        'Inventario',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.tealDark,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text(
                  'Producto',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.muted,
                  ),
                ),
              const Spacer(),
              if (_lineas.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  onPressed: _guardando ? null : () => _quitarLinea(i),
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: l.nombre,
            enabled: !_guardando,
            style: const TextStyle(fontSize: 14, color: _C.ink),
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (l.producto != null &&
                  l.nombre.text.trim() != l.producto!.nombre) {
                setState(() => l.limpiarProducto());
              } else {
                setState(() {}); // refresca total si aplica
              }
            },
            decoration: _fieldDeco(
              label: 'Nombre del producto',
              suffix: IconButton(
                tooltip: 'Buscar en inventario',
                onPressed: _guardando ? null : () => _buscarProducto(i),
                icon: const Icon(Icons.search_rounded, color: _C.tealDark),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: l.cantidad,
                  enabled: !_guardando,
                  style: const TextStyle(fontSize: 14, color: _C.ink),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDeco(label: 'Cantidad'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: l.costo,
                  enabled: !_guardando,
                  style: const TextStyle(fontSize: 14, color: _C.ink),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDeco(label: 'Costo unitario'),
                ),
              ),
            ],
          ),
          if (l.subtotal > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal RD\$ ${l.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.tealDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Selector de inventario ─────────────────────────────────────────────────

class _SelectorProductoSheet extends StatefulWidget {
  const _SelectorProductoSheet({
    required this.productos,
    this.queryInicial = '',
  });

  final List<Producto> productos;
  final String queryInicial;

  @override
  State<_SelectorProductoSheet> createState() => _SelectorProductoSheetState();
}

class _SelectorProductoSheetState extends State<_SelectorProductoSheet> {
  late final TextEditingController _q;
  late List<Producto> _filtrados;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.queryInicial);
    _filtrados = _filtrar(widget.queryInicial);
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) return widget.productos.take(100).toList();
    return widget.productos
        .where((p) {
          final n = p.nombre.toLowerCase();
          final c = p.codigo.toLowerCase();
          final b = (p.codigoBarras ?? '').toLowerCase();
          return n.contains(q) || c.contains(q) || b.contains(q);
        })
        .take(100)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.78;

    return SizedBox(
      height: h,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Inventario',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _C.navy,
                    ),
                  ),
                ),
                Text(
                  '${_filtrados.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _q,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nombre, código o barra…',
                hintStyle: const TextStyle(color: _C.muted, fontSize: 13),
                isDense: true,
                filled: true,
                fillColor: _C.bg,
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _C.tealDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _C.teal, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _filtrados = _filtrar(v)),
            ),
          ),
          // Opción fija: crear producto con el texto buscado
          if (_q.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Material(
                color: _C.tealSoft,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context, _q.text.trim()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _C.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: _C.tealDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Crear producto nuevo',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: _C.tealDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '"${_q.text.trim()}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _C.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: _C.tealDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _filtrados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _q.text.trim().isEmpty
                                ? 'Escribe para buscar o crear un producto'
                                : 'No está en inventario.\nUsa “Crear producto nuevo” arriba.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filtrados.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) {
                      final p = _filtrados[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _C.tealSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: _C.tealDark,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.ink,
                          ),
                        ),
                        subtitle: Text(
                          '${p.codigo} · Costo ${p.precioCompra.toStringAsFixed(2)} · Stock ${(p.stock ?? 0).toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _C.muted,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: _C.muted,
                        ),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
