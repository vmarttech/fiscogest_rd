import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_button.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_dropdown.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/salida_providers.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

// =====================================================================
// PANTALLA PRINCIPAL — MÓDULO DE VENTAS · SIN ERRORES
// =====================================================================
class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});
  static const String routeName = 'ventas';
  @override
  ConsumerState<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends ConsumerState<VentasPage> with SingleTickerProviderStateMixin {
  late final TabController _controladorPestanas;
  String _numeroVenta = '';
  int? _clienteSeleccionadoId;
  String _clienteNombre = 'Consumidor final';
  String _tipoPago = 'Efectivo';
  final List<ItemCarrito> _carrito = [];
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _controladorPestanas = TabController(length: 4, vsync: this);
    _numeroVenta = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  @override
  void dispose() {
    _controladorPestanas.dispose();
    super.dispose();
  }

  List<Producto> get _productosFiltrados {
    final todos = ref.watch(productoControllerProvider).value ?? [];
    if (_terminoBusqueda.trim().isEmpty) return todos;
    final busqueda = _terminoBusqueda.toLowerCase();
    return todos.where((p) =>
      p.nombre.toLowerCase().contains(busqueda) ||
      p.codigo.toLowerCase().contains(busqueda) ||
      (p.codigoBarras?.toLowerCase().contains(busqueda) ?? false)
    ).toList();
  }

  double get _subtotal {
    return _carrito.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
  }

  double get _itbis => _subtotal * 0.18;
  double get _total => _subtotal + _itbis;

  List<DetalleVenta> get _detallesVenta {
    return _carrito.map((item) => DetalleVenta(
      productoId: item.producto.id!,
      nombreProducto: item.producto.nombre,
      cantidad: item.cantidad,
      precioUnitario: item.precio,
      subtotalLinea: item.precio * item.cantidad,
    )).toList();
  }

  void _seleccionarCliente(int? clienteId, String nombre) {
    setState(() {
      _clienteSeleccionadoId = clienteId;
      _clienteNombre = nombre;
    });
  }

  void _agregarAlCarrito(Producto producto) {
    setState(() {
      final indice = _carrito.indexWhere((item) => item.producto.id == producto.id);
      if (indice >= 0) {
        _carrito[indice] = ItemCarrito(
          producto: producto,
          cantidad: _carrito[indice].cantidad + 1.0,
          precio: _carrito[indice].precio,
        );
      } else {
        _carrito.add(ItemCarrito(
          producto: producto,
          cantidad: 1.0,
          precio: producto.precioVenta,
        ));
      }
    });
  }

  void _modificarCantidad(int productoId, double delta) {
    setState(() {
      final indice = _carrito.indexWhere((item) => item.producto.id == productoId);
      if (indice >= 0) {
        final nueva = _carrito[indice].cantidad + delta;
        if (nueva < 1.0) {
          _carrito.removeAt(indice);
        } else {
          _carrito[indice] = ItemCarrito(
            producto: _carrito[indice].producto,
            cantidad: nueva,
            precio: _carrito[indice].precio,
          );
        }
      }
    });
  }

  void _eliminarDelCarrito(int productoId) {
    setState(() {
      _carrito.removeWhere((item) => item.producto.id == productoId);
    });
  }

  Future<void> _cobrarYRegistrarVenta() async {
    if (_carrito.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Agregue productos al carrito antes de cobrar')),
        );
      }
      return;
    }

    try {
      // ✅ Garantizar valor NO nulo para clienteId
      final int clienteId = _clienteSeleccionadoId ?? 0;

      final venta = Venta(
        numero: _numeroVenta,
        clienteId: clienteId,
        fecha: DateTime.now(),
        detalles: _detallesVenta,
        subtotal: _subtotal,
        itbis: _itbis,
        total: _total,
        tipoPago: _tipoPago,
      );

      final orquestador = ref.read(ventaOrquestadorServiceProvider);
      final ventaRegistrada = await orquestador.ejecutarVentaCompleta(venta);

      for (final item in _carrito) {
        await ref.read(salidaControllerProvider.notifier).registrarSalida(
          productoId: item.producto.id!,
          cantidad: item.cantidad,
          motivo: 'Venta — N° $_numeroVenta',
          usuario: 'Usuario actual',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Venta N° ${ventaRegistrada.numero} registrada. Kardex actualizado.'), backgroundColor: Colors.green),
        );
        setState(_carrito.clear);
        setState(() {
          _numeroVenta = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
          _clienteSeleccionadoId = null;
          _clienteNombre = 'Consumidor final';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Módulo de Ventas',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _controladorPestanas,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.bodyMedium,
              padding: AppSpacing.hM,
              tabs: const [
                Tab(text: 'Registrar Venta'),
                Tab(text: 'Cotizaciones'),
                Tab(text: 'Apartados'),
                Tab(text: 'Historial de Ventas'),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final esPantallaAncha = constraints.maxWidth >= 900;
                return TabBarView(
                  controller: _controladorPestanas,
                  children: [
                    esPantallaAncha ? const _VistaEscritorio() : const _VistaMovil(),
                    const Center(child: Text('Cotizaciones — En construcción', style: AppTypography.bodyLarge)),
                    const Center(child: Text('Apartados — En construcción', style: AppTypography.bodyLarge)),
                    const Center(child: Text('Historial de Ventas — En construcción', style: AppTypography.bodyLarge)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// MODELO LOCAL: ÍTEM EN CARRITO
// =====================================================================
class ItemCarrito {

  ItemCarrito({required this.producto, required this.cantidad, required this.precio});
  final Producto producto;
  final double cantidad;
  final double precio;
}

// =====================================================================
// VISTA ESCRITORIO — 2 columnas profesionales
// =====================================================================
class _VistaEscritorio extends ConsumerWidget {
  const _VistaEscritorio();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: SingleChildScrollView(padding: AppSpacing.allM, child: _PanelProductos())),
        SizedBox(width: AppSpacing.m),
        Expanded(flex: 5, child: SingleChildScrollView(padding: AppSpacing.allM, child: _PanelCarrito())),
      ],
    );
  }
}

// =====================================================================
// VISTA MÓVIL — Productos + Botón flotante del carrito
// =====================================================================
class _VistaMovil extends ConsumerStatefulWidget {
  const _VistaMovil();
  @override
  ConsumerState<_VistaMovil> createState() => _VistaMovilState();
}

class _VistaMovilState extends ConsumerState<_VistaMovil> {
  _VentasPageState? get _padre => context.findAncestorStateOfType<_VentasPageState>();

  @override
  Widget build(BuildContext context) {
    final cantidad = _padre?._carrito.length ?? 0;
    final total = _padre?._total ?? 0.0;

    return Stack(
      children: [
        const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 80),
          child: _PanelProductos(esMovil: true),
        ),
        Positioned(
          left: AppSpacing.m,
          right: AppSpacing.m,
          bottom: AppSpacing.m,
          child: AppButton(
            text: 'Ver carrito ($cantidad) • RD\$ ${total.toStringAsFixed(2)}',
            icon: Icons.shopping_cart_outlined,
            onPressed: _abrirCarrito,
          ),
        ),
      ],
    );
  }

  void _abrirCarrito() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: AppSpacing.allM,
          child: SingleChildScrollView(controller: controller, child: const _PanelCarrito()),
        ),
      ),
    );
  }
}

// =====================================================================
// PANEL PRODUCTOS — Conectado al Provider real
// =====================================================================
class _PanelProductos extends ConsumerWidget {
  const _PanelProductos({this.esMovil = false});
  final bool esMovil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagina = context.findAncestorStateOfType<_VentasPageState>();
    final carga = ref.watch(productoControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catálogo de Productos', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.xs),
            Text('Busca y agrega artículos al carrito', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        _TarjetaProfesional(
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Buscar por código, nombre o código de barras',
                  prefixIcon: Icons.search,
                  onChanged: (valor) {
                    if (pagina != null) {
                      pagina._terminoBusqueda = valor;
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              AppButton(text: '', icon: Icons.qr_code_scanner, onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        _TarjetaProfesional(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Productos Disponibles', style: AppTypography.labelMedium),
                  Consumer(
                    builder: (_, ref, __) {
                      final productos = pagina?._productosFiltrados ?? [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                        child: Text('${productos.length} artículos', style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: AppSpacing.m),
              carga.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.symmetric(vertical: 48), child: Text('Error al cargar productos: $e', style: AppTypography.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center)),
                data: (_) {
                  final productos = pagina?._productosFiltrados ?? [];
                  if (productos.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.m),
                        Text(pagina?._terminoBusqueda.isNotEmpty == true ? 'No hay coincidencias' : 'No hay productos registrados', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ]),
                    );
                  }
                  return esMovil ? _ListaProductosMovil(productos: productos, alAgregar: pagina?._agregarAlCarrito) : _TablaProductosEscritorio(productos: productos, alAgregar: pagina?._agregarAlCarrito);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// TABLA PRODUCTOS — Escritorio
// =====================================================================
class _TablaProductosEscritorio extends StatelessWidget {

  const _TablaProductosEscritorio({required this.productos, required this.alAgregar});
  final List<Producto> productos;
  final void Function(Producto)? alAgregar;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(0.8), 3: FlexColumnWidth(1.3)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
          children: const [
            Padding(padding: AppSpacing.vM, child: Text('Producto', style: AppTypography.labelSmall, textAlign: TextAlign.left)),
            Padding(padding: AppSpacing.vM, child: Text('Precio Venta', style: AppTypography.labelSmall, textAlign: TextAlign.right)),
            Padding(padding: AppSpacing.vM, child: Text('Stock', style: AppTypography.labelSmall, textAlign: TextAlign.center)),
            Padding(padding: AppSpacing.vM, child: SizedBox.shrink()),
          ],
        ),
        const TableRow(children: [Divider(height: 1)]),
        for (final prod in productos)
          TableRow(children: [
            Padding(padding: AppSpacing.vS, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(prod.nombre, style: AppTypography.bodyMedium),
              Text(prod.codigo, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            ])),
            Padding(padding: AppSpacing.vS, child: Text('RD\$ ${prod.precioVenta.toStringAsFixed(2)}', style: AppTypography.labelMedium, textAlign: TextAlign.right)),
            Padding(padding: AppSpacing.vS, child: Text('${prod.stock ?? 0.0}', style: AppTypography.bodyMedium, textAlign: TextAlign.center)),
            Padding(padding: AppSpacing.vS, child: Align(alignment: Alignment.centerRight, child: AppButton(text: 'Agregar', icon: Icons.add, onPressed: alAgregar != null ? () => alAgregar!(prod) : null))),
          ]),
      ],
    );
  }
}

// =====================================================================
// LISTA PRODUCTOS — Móvil
// =====================================================================
class _ListaProductosMovil extends StatelessWidget {

  const _ListaProductosMovil({required this.productos, required this.alAgregar});
  final List<Producto> productos;
  final void Function(Producto)? alAgregar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: productos.map((prod) => _TarjetaProductoMovil(
        producto: prod,
        alAgregar: alAgregar,
      )).toList(),
    );
  }
}

class _TarjetaProductoMovil extends StatelessWidget {

  const _TarjetaProductoMovil({required this.producto, required this.alAgregar});
  final Producto producto;
  final void Function(Producto)? alAgregar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(producto.nombre, style: AppTypography.labelMedium),
          Text(producto.codigo, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Stock disponible: ${producto.stock ?? 0.0}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('RD\$ ${producto.precioVenta.toStringAsFixed(2)}', style: AppTypography.h4.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.s),
          AppButton(text: 'Agregar', icon: Icons.add, onPressed: alAgregar != null ? () => alAgregar!(producto) : null),
        ]),
      ]),
    );
  }
}

// =====================================================================
// PANEL CARRITO — LÍNEA 352 CORREGIDA
// =====================================================================
class _PanelCarrito extends ConsumerWidget {
  const _PanelCarrito();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padre = context.findAncestorStateOfType<_VentasPageState>();
    final numeroVenta = padre?._numeroVenta ?? '';
    final clienteNombre = padre?._clienteNombre ?? 'Consumidor final';
    final clienteSeleccionadoId = padre?._clienteSeleccionadoId;
    final tipoPago = padre?._tipoPago ?? 'Efectivo';
    final carrito = padre?._carrito ?? <ItemCarrito>[];
    final subtotal = padre?._subtotal ?? 0.0;
    final itbis = padre?._itbis ?? 0.0;
    final total = padre?._total ?? 0.0;
    final seleccionarCliente = padre?._seleccionarCliente;
    final cobrar = padre?._cobrarYRegistrarVenta;
    final modificar = padre?._modificarCantidad;
    final eliminar = padre?._eliminarDelCarrito;

    final listaClientes = ref.watch(clientesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Resumen de Venta', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.xs),
        Text('Información del comprobante, cliente y artículos', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.m),

        _TarjetaProfesional(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _DatoTicket(etiqueta: 'N° VENTA', valor: numeroVenta, icono: Icons.receipt_outlined),
              _DatoTicket(etiqueta: 'CLIENTE', valor: clienteNombre, icono: Icons.person_outline),
              const _DatoTicket(etiqueta: 'FECHA', valor: 'Hoy', icono: Icons.calendar_today_outlined),
            ]),
            const SizedBox(height: AppSpacing.m),
            listaClientes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('No se pudo cargar clientes: $e', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
              data: (clientes) {
                final items = <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(value: null, child: Text('Consumidor final')),
                  ...clientes.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.nombre),
                  )),
                ];
                return AppDropdown<int?>(
                  initialValue: clienteSeleccionadoId,
                  items: items,
                  onChanged: (valor) {
                    if (seleccionarCliente != null) {
                      // ✅ LÍNEA 352 CORREGIDA: ELIMINADO operador ?? redundante
                      final String nombre;
                      if (valor != null) {
                        nombre = clientes.firstWhere((c) => c.id == valor).nombre;
                      } else {
                        nombre = 'Consumidor final';
                      }
                      seleccionarCliente(valor, nombre);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.m),
            AppDropdown<String>(
              initialValue: tipoPago,
              items: const [
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'Crédito', child: Text('Crédito')),
              ],
              onChanged: (valor) {
                if (valor != null && padre != null) {
                  padre._tipoPago = valor;
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.m),

        _TarjetaProfesional(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Artículos en Carrito', style: AppTypography.labelMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
                child: Text('${carrito.length} artículo${carrito.length != 1 ? 's' : ''}', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: AppSpacing.s),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: AppSpacing.m),
            if (carrito.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  Icon(Icons.shopping_cart_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.s),
                  Text('No hay artículos agregados', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Selecciona productos desde el catálogo', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                ]),
              )
            else
              ...carrito.map((item) => _FilaCarritoProfesional(
                    nombre: item.producto.nombre,
                    cantidad: item.cantidad,
                    precio: item.precio,
                    productoId: item.producto.id!,
                    modificar: modificar,
                    eliminar: eliminar,
                  )),
          ]),
        ),
        const SizedBox(height: AppSpacing.m),

        _TarjetaProfesional(
          colorFondo: const Color(0xFFF8F9FA),
          child: _ResumenTotales(subtotal: subtotal, descuento: 0.0, itbis: itbis, total: total),
        ),
        const SizedBox(height: AppSpacing.m),

        const Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
          AppButton(text: '% Descuento', icon: Icons.percent, onPressed: null),
          AppButton(text: 'Cotización', icon: Icons.description_outlined, onPressed: null),
          AppButton(text: 'Apartado', icon: Icons.bookmark_border, onPressed: null),
          AppButton(text: 'Nota Crédito', icon: Icons.receipt_long, onPressed: null),
        ]),
        const SizedBox(height: AppSpacing.l),

        Container(
          padding: AppSpacing.allM,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            Text('TOTAL A PAGAR', style: AppTypography.labelSmall.copyWith(color: Colors.white70, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.xs),
            Text('RD\$ ${total.toStringAsFixed(2)}', style: AppTypography.h1.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: AppSpacing.m),
            SizedBox(width: double.infinity, child: AppButton(text: 'COBRAR Y CONFIRMAR', icon: Icons.payment, onPressed: cobrar)),
          ]),
        ),
      ],
    );
  }
}

// =====================================================================
// COMPONENTE: DATO DEL COMPROBANTE
// =====================================================================
class _DatoTicket extends StatelessWidget {
  const _DatoTicket({required this.etiqueta, required this.valor, required this.icono});
  final String etiqueta;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(icono, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Text(etiqueta, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary))]),
          const SizedBox(height: 4),
          Text(valor, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =====================================================================
// FILA CARRITO — Con controles + / - / eliminar
// =====================================================================
class _FilaCarritoProfesional extends StatelessWidget {
  const _FilaCarritoProfesional({
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.productoId,
    required this.modificar,
    required this.eliminar,
  });
  final String nombre;
  final double cantidad;
  final double precio;
  final int productoId;
  final void Function(int, double)? modificar;
  final void Function(int)? eliminar;

  @override
  Widget build(BuildContext context) {
    final subtotal = precio * cantidad;
    return Padding(
      padding: AppSpacing.vS,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(nombre, style: AppTypography.labelMedium, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.s),
          Text('RD\$ ${subtotal.toStringAsFixed(2)}', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('RD\$ ${precio.toStringAsFixed(2)} c/u', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            AppButton(text: '-', onPressed: modificar != null ? () => modificar!(productoId, -1.0) : null),
            const SizedBox(width: AppSpacing.s),
            Text('${cantidad.toStringAsFixed(0)}', style: AppTypography.labelMedium),
            const SizedBox(width: AppSpacing.s),
            AppButton(text: '+', onPressed: modificar != null ? () => modificar!(productoId, 1.0) : null),
          ]),
          AppButton(text: '', icon: Icons.delete_outline, onPressed: eliminar != null ? () => eliminar!(productoId) : null),
        ]),
        const Divider(height: AppSpacing.m),
      ]),
    );
  }
}

// =====================================================================
// RESUMEN DE TOTALES
// =====================================================================
class _ResumenTotales extends StatelessWidget {
  const _ResumenTotales({required this.subtotal, required this.descuento, required this.itbis, required this.total});
  final double subtotal;
  final double descuento;
  final double itbis;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _FilaTotal(etiqueta: 'Subtotal', monto: subtotal),
      if (descuento > 0) _FilaTotal(etiqueta: 'Descuento', monto: descuento, esNegativo: true),
      _FilaTotal(etiqueta: 'ITBIS (18%)', monto: itbis),
      const Divider(height: 24, thickness: 1.5),
      _FilaTotal(etiqueta: 'TOTAL A PAGAR', monto: total, esResaltado: true),
    ]);
  }
}

class _FilaTotal extends StatelessWidget {
  const _FilaTotal({required this.etiqueta, required this.monto, this.esResaltado = false, this.esNegativo = false});
  final String etiqueta;
  final double monto;
  final bool esResaltado;
  final bool esNegativo;

  @override
  Widget build(BuildContext context) {
    final colorTexto = esResaltado ? AppColors.primary : (esNegativo ? AppColors.error : AppColors.textPrimary);
    final estiloEtiqueta = esResaltado ? AppTypography.h4.copyWith(fontWeight: FontWeight.bold) : AppTypography.bodyMedium;
    final estiloMonto = esResaltado ? AppTypography.h3.copyWith(color: colorTexto, fontWeight: FontWeight.bold) : AppTypography.labelMedium.copyWith(color: colorTexto);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(etiqueta, style: estiloEtiqueta),
        Text('${esNegativo ? '-' : ''}RD\$ ${monto.toStringAsFixed(2)}', style: estiloMonto),
      ]),
    );
  }
}

// =====================================================================
// TARJETA PROFESIONAL
// =====================================================================
class _TarjetaProfesional extends StatelessWidget {
  const _TarjetaProfesional({required this.child, this.colorFondo = Colors.white});
  final Widget child;
  final Color colorFondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allM,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
