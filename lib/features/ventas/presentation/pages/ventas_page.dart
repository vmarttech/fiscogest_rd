import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/salida_providers.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/item_carrito.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/widgets/vistas.dart';

class VentasPage extends ConsumerStatefulWidget {
  const VentasPage({super.key});
  static const String routeName = 'ventas';
  @override
  ConsumerState<VentasPage> createState() => VentasPageState();
}

// ✅ QUITADO EL GUION BAJO → clase pública accesible desde widgets hermanos
class VentasPageState extends ConsumerState<VentasPage> with SingleTickerProviderStateMixin {
  late final TabController controladorPestanas;
  String numeroVenta = '';
  int? clienteSeleccionadoId;
  String clienteNombre = 'Consumidor final';
  String tipoPago = 'Efectivo';
  final List<ItemCarrito> carrito = [];
  String terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    controladorPestanas = TabController(length: 4, vsync: this);
    numeroVenta = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  @override
  void dispose() {
    controladorPestanas.dispose();
    super.dispose();
  }

  List<Producto> get productosFiltrados {
    final todos = ref.watch(productoControllerProvider).value ?? <Producto>[];
    if (terminoBusqueda.trim().isEmpty) return todos;
    final busqueda = terminoBusqueda.toLowerCase();
    return todos.where((Producto p) =>
      p.nombre.toLowerCase().contains(busqueda) ||
      p.codigo.toLowerCase().contains(busqueda) ||
      (p.codigoBarras?.toLowerCase().contains(busqueda) ?? false)
    ).toList();
  }

  double get subtotal {
    return carrito.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
  }

  double get itbis => subtotal * 0.18;
  double get total => subtotal + itbis;

  List<DetalleVenta> get detallesVenta {
    return carrito.map((item) => DetalleVenta(
      productoId: item.producto.id!,
      nombreProducto: item.producto.nombre,
      cantidad: item.cantidad,
      precioUnitario: item.precio,
      subtotalLinea: item.precio * item.cantidad,
    )).toList();
  }

  void seleccionarCliente(int? clienteId, String nombre) {
    setState(() {
      clienteSeleccionadoId = clienteId;
      clienteNombre = nombre;
    });
  }

  void agregarAlCarrito(Producto producto) {
    setState(() {
      final indice = carrito.indexWhere((item) => item.producto.id == producto.id);
      if (indice >= 0) {
        carrito[indice] = ItemCarrito(
          producto: producto,
          cantidad: carrito[indice].cantidad + 1.0,
          precio: carrito[indice].precio,
        );
      } else {
        carrito.add(ItemCarrito(
          producto: producto,
          cantidad: 1.0,
          precio: producto.precioVenta,
        ));
      }
    });
  }

  void modificarCantidad(int productoId, double delta) {
    setState(() {
      final indice = carrito.indexWhere((item) => item.producto.id == productoId);
      if (indice >= 0) {
        final nueva = carrito[indice].cantidad + delta;
        if (nueva < 1.0) {
          carrito.removeAt(indice);
        } else {
          carrito[indice] = ItemCarrito(
            producto: carrito[indice].producto,
            cantidad: nueva,
            precio: carrito[indice].precio,
          );
        }
      }
    });
  }

  void eliminarDelCarrito(int productoId) {
    setState(() {
      carrito.removeWhere((item) => item.producto.id == productoId);
    });
  }

  Future<void> cobrarYRegistrarVenta() async {
    if (carrito.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Agregue productos al carrito antes de cobrar')),
        );
      }
      return;
    }

    try {
      final int clienteId = clienteSeleccionadoId ?? 0;

      final venta = Venta(
        numero: numeroVenta,
        clienteId: clienteId,
        fecha: DateTime.now(),
        detalles: detallesVenta,
        subtotal: subtotal,
        itbis: itbis,
        total: total,
        tipoPago: tipoPago,
      );

      final orquestador = ref.read(ventaOrquestadorServiceProvider);
      final ventaRegistrada = await orquestador.ejecutarVentaCompleta(venta);

      for (final item in carrito) {
        await ref.read(salidaControllerProvider.notifier).registrarSalida(
          productoId: item.producto.id!,
          cantidad: item.cantidad,
          motivo: 'Venta — N° $numeroVenta',
          usuario: 'Usuario actual',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Venta N° ${ventaRegistrada.numero} registrada. Kardex actualizado.'), backgroundColor: Colors.green),
        );
        setState(carrito.clear);
        setState(() {
          numeroVenta = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
          clienteSeleccionadoId = null;
          clienteNombre = 'Consumidor final';
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
              controller: controladorPestanas,
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
                  controller: controladorPestanas,
                  children: [
                    esPantallaAncha ? const VistaEscritorio() : const VistaMovil(),
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
