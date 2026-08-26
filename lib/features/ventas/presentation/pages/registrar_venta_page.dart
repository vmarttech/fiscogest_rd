import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/formulario_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';

class RegistrarVentaPage extends ConsumerStatefulWidget {
  const RegistrarVentaPage({super.key});
  static const String routeName = 'registrar-ventas';
  @override
  ConsumerState<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends ConsumerState<RegistrarVentaPage> {
  final TextEditingController _buscadorController = TextEditingController();
  String _ventaNumero = '';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _ventaNumero = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Oferta? _buscarOfertaAplicable(List<Oferta> ofertas, int productoId, double cantidad) {
    for (final oferta in ofertas) {
      if (oferta.productoId == productoId && cantidad >= oferta.cantidadMinima) {
        return oferta;
      }
    }
    return null;
  }

  Future<void> _buscarYAgregarProducto(String termino) async {
    final resultados = await ref
        .read(productoControllerProvider.notifier)
        .buscarPorNombre(termino);

    final ofertasActivas = await ref.watch(ofertasActivosProvider.future);
    final List<Oferta> listaOfertas = ofertasActivas.cast<Oferta>();

    // ✅ Si no hay resultados → abrir diálogo con opción de ir a Inventario
    if (resultados.isEmpty && mounted) {
      unawaitedShowDialog(context, AlertDialog(
        title: const Text('Producto no encontrado'),
        content: const Text('No hay coincidencias. ¿Desea abrir el inventario completo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pushNamed('productos'); // ✅ Abre pantalla de inventario
            },
            child: const Text('Abrir Inventario'),
          ),
        ],
      ));
      return;
    }

    if (resultados.length == 1 && mounted) {
      final p = resultados.first;
      if ((p.stock ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${p.nombre}" sin existencias disponibles'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final oferta = _buscarOfertaAplicable(listaOfertas, p.id ?? 0, 1);
      final double precioUnitario = (oferta != null) ? oferta.precioOferta : p.precioVenta.toDouble();
      final double subtotal = precioUnitario * 1;
      final double? precioOriginal = (oferta != null) ? p.precioVenta.toDouble() : null;
      final String? ofertaId = (oferta != null) ? oferta.id.toString() : null;
      final String? ofertaNombre = (oferta != null) ? oferta.nombre : null;
      final linea = DetalleVenta(
        productoId: p.id ?? 0,
        nombreProducto: p.nombre,
        cantidad: 1,
        precioUnitario: precioUnitario,
        subtotal: subtotal,
        subtotalLinea: subtotal,
        ofertaId: ofertaId,
        ofertaNombre: ofertaNombre,
        precioOriginal: precioOriginal,
      );
      ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
      _buscadorController.clear();
      if (oferta != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oferta aplicada: ${oferta.nombre}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (mounted) {
      unawaitedShowDialog(context, AlertDialog(
        title: const Text('Seleccione Producto'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: resultados.length + 1, // ✅ +1 para opción "Abrir Inventario"
            itemBuilder: (ctx, i) {
              // ✅ ÚLTIMA OPCIÓN: Abrir Inventario completo
              if (i == resultados.length) {
                return ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.blue),
                  title: const Text('Abrir Inventario completo'),
                  subtitle: const Text('Ver todos los productos'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.pushNamed('productos'); // ✅ Navega sin condiciones
                  },
                );
              }
              final p = resultados[i];
              final oferta = _buscarOfertaAplicable(listaOfertas, p.id ?? 0, 1);
              final hayStock = (p.stock ?? 0) > 0;
              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(p.nombre)),
                    if (!hayStock)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SIN STOCK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    if (oferta != null && hayStock)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'OFERTA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  hayStock
                      ? (oferta != null
                          ? 'Oferta: RD\$ ${oferta.precioOferta.toStringAsFixed(2)} (antes RD\$ ${p.precioVenta.toStringAsFixed(2)}) — Stock: ${p.stock ?? 0}'
                          : 'RD\$ ${p.precioVenta.toStringAsFixed(2)} — Stock: ${p.stock ?? 0}')
                      : 'Sin existencias',
                ),
                enabled: hayStock,
                onTap: hayStock
                    ? () {
                        final double precioUnitario = (oferta != null) ? oferta.precioOferta : p.precioVenta.toDouble();
                        final double subtotal = precioUnitario * 1;
                        final double? precioOriginal = (oferta != null) ? p.precioVenta.toDouble() : null;
                        final String? ofertaId = (oferta != null) ? oferta.id.toString() : null;
                        final String? ofertaNombre = (oferta != null) ? oferta.nombre : null;
                        final linea = DetalleVenta(
                          productoId: p.id ?? 0,
                          nombreProducto: p.nombre,
                          cantidad: 1,
                          precioUnitario: precioUnitario,
                          subtotal: subtotal,
                          subtotalLinea: subtotal,
                          ofertaId: ofertaId,
                          ofertaNombre: ofertaNombre,
                          precioOriginal: precioOriginal,
                        );
                        ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
                        _buscadorController.clear();
                        Navigator.pop(ctx);
                        if (oferta != null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Oferta aplicada: ${oferta.nombre}'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      ));
    }
  }

  void _abrirSelectorFormaPago() {
    unawaitedShowDialog(context, AlertDialog(
      title: const Text('Forma de Pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Efectivo'),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('efectivo');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Tarjeta'),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('tarjeta');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Transferencia'),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('transferencia');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Crédito'),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('credito');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Cheque'),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).cambiarFormaPago('cheque');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ));
  }

  void _abrirSelectorCliente() {
    unawaitedShowDialog(context, AlertDialog(
      title: const Text('Seleccionar Cliente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Consumidor Final'),
            onTap: () {
              ref.read(registrarVentaProvider.notifier).seleccionarCliente(1, 'Consumidor Final');
              Navigator.pop(context);
            },
          ),
          // ✅ BUSCAR CLIENTE → ABRIR LISTA, NO FORMULARIO
          ListTile(
            title: const Text('Buscar Cliente...'),
            subtitle: const Text('Ver lista de clientes registrados'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('clientes'); // ✅ PANTALLA DE LISTADO, NO DE NUEVO
            },
          ),
        ],
      ),
    ));
  }

  void _limpiarVenta() {
    unawaitedShowDialog(context, AlertDialog(
      title: const Text('Limpiar Venta'),
      content: const Text('¿Desea reiniciar la venta actual?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            ref.read(registrarVentaProvider.notifier).vaciarVenta();
            _buscadorController.clear();
            Navigator.pop(context);
          },
          child: const Text('Aceptar'),
        ),
      ],
    ));
  }

  Future<void> _cobrarYRegistrarSalida() async {
    final estado = ref.read(registrarVentaProvider);
    if (!ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete los datos: Cliente, Forma de Pago y al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      final casoUso = ref.read(registrarVentaUseCaseProvider);
      final ventaGuardada = await casoUso.ejecutar(estado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta registrada. Nº $_ventaNumero — ID: $ventaGuardada'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        _buscadorController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(registrarVentaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Venta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nueva Venta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Nº $_ventaNumero',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PanelProductos(
                  controlador: _buscadorController,
                  alAgregar: _buscarYAgregarProducto,
                ),
                const SizedBox(height: 16),
                FormularioVenta(
                  alSeleccionarCliente: _abrirSelectorCliente,
                  alSeleccionarFormaPago: _abrirSelectorFormaPago,
                ),
                const SizedBox(height: 16),
                const PanelCarrito(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _limpiarVenta,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Limpiar Venta'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : _cobrarYRegistrarSalida,
                        icon: _cargando
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Icon(Icons.save),
                        label: Text(_cargando ? 'Guardando...' : 'Registrar Venta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void unawaitedShowDialog(BuildContext context, Widget dialog) {
  showDialog<dynamic>(context: context, builder: (_) => dialog);
}
