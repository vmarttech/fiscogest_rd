import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_secciones/encabezado_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_secciones/buscador_productos_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_secciones/carrito_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_secciones/datos_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/pages/registrar_venta_secciones/botones_accion_venta.dart';

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

  void _abrirSelectorFormaPago() {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forma de Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Efectivo'),
              onTap: () {
                ref.read(registrarVentaProvider.notifier)
                   .cambiarFormaPago('efectivo', false);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Tarjeta'),
              onTap: () {
                ref.read(registrarVentaProvider.notifier)
                   .cambiarFormaPago('tarjeta', false);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Crédito'),
              onTap: () {
                ref.read(registrarVentaProvider.notifier)
                   .cambiarFormaPago('credito', true);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirSelectorCliente() {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Consumidor Final'),
              onTap: () {
                ref.read(registrarVentaProvider.notifier).seleccionarCliente(1);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Buscar Cliente...'),
              onTap: () async {
                Navigator.pop(ctx);
                final termino = await _mostrarBusquedaDialog('Buscar Cliente');
                if (termino != null && termino.trim().isNotEmpty) {
                  final resultados = await ref
                      .read(clienteCompletoControllerProvider.notifier)
                      .buscarPorNombre(termino);
                  if (resultados.isNotEmpty && mounted) {
                    _mostrarResultadosClientes(resultados);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se encontraron clientes')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _mostrarBusquedaDialog(String titulo) async {
    final control = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: control,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escriba para buscar...'),
          onSubmitted: (valor) => Navigator.pop(ctx, valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, control.text),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _mostrarResultadosClientes(List<dynamic> lista) {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clientes Encontrados'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lista.length,
            itemBuilder: (ctx, i) {
              final cliente = lista[i];
              final nombre = cliente.nombre as String? ?? '';
              final rnc = cliente.rncCedula as String? ?? '';
              final id = cliente.id as int? ?? 1;
              return ListTile(
                title: Text(nombre),
                subtitle: Text(rnc),
                onTap: () {
                  ref.read(registrarVentaProvider.notifier).seleccionarCliente(id);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _limpiarVenta() {
    showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar Venta'),
        content: const Text('¿Desea reiniciar la venta actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(registrarVentaProvider.notifier).vaciarVenta();
              _buscadorController.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cobrarYRegistrarSalida() async {
    final estado = ref.read(registrarVentaProvider);
    if (!ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los datos antes de registrar')),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final venta = Venta(
        numero: estado.numero,
        clienteId: estado.clienteId ?? 0,
        fecha: DateTime.now(),
        detalles: estado.detalles,
        subtotal: estado.subtotal,
        itbis: estado.itbis,
        total: estado.total,
        tipoPago: estado.tipoPago,
        esCredito: estado.esCredito,
        usuarioId: estado.usuarioId ?? 0,
      );

      final casoUso = ref.read(registrarVentaUseCaseProvider);
      final ventaGuardada = await casoUso(venta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Venta registrada. ID: ${ventaGuardada.id}')),
        );
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        _buscadorController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _buscarYAgregarProducto(String termino) async {
    final resultados = await ref
        .read(productoControllerProvider.notifier)
        .buscarPorNombre(termino);

    if (resultados.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto no encontrado')),
      );
      return;
    }

    if (resultados.length == 1 && mounted) {
      final p = resultados.first;
      final linea = DetalleVenta(
        productoId: p.id ?? 0,
        nombreProducto: p.nombre,
        cantidad: 1,
        precioUnitario: p.precioVenta.toDouble(),
        subtotalLinea: p.precioVenta.toDouble(),
      );
      ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
      _buscadorController.clear();
    } else if (mounted) {
      // ignore: unawaited_futures
      showDialog<dynamic>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Seleccione Producto'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: resultados.length,
              itemBuilder: (ctx, i) {
                final p = resultados[i];
                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text('RD\$ ${p.precioVenta.toStringAsFixed(2)}'),
                  onTap: () {
                    final linea = DetalleVenta(
                      productoId: p.id ?? 0,
                      nombreProducto: p.nombre,
                      cantidad: 1,
                      precioUnitario: p.precioVenta.toDouble(),
                      subtotalLinea: p.precioVenta.toDouble(),
                    );
                    ref.read(registrarVentaProvider.notifier).agregarProducto(linea);
                    _buscadorController.clear();
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ),
      );
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
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoVenta(numeroVenta: _ventaNumero),
                const SizedBox(height: 20),
                BuscadorProductosVenta(
                  controlador: _buscadorController,
                  alBuscar: _buscarYAgregarProducto,
                ),
                const SizedBox(height: 24),
                const CarritoVenta(),
                const SizedBox(height: 24),
                DatosVenta(
                  alSeleccionarCliente: _abrirSelectorCliente,
                  alSeleccionarFormaPago: _abrirSelectorFormaPago,
                ),
                const SizedBox(height: 32),
                BotonesAccionVenta(
                  cargando: _cargando,
                  alLimpiar: _limpiarVenta,
                  alGuardar: _cobrarYRegistrarSalida,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
