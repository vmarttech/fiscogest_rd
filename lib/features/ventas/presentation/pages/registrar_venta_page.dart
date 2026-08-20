import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEncabezado(),
            const SizedBox(height: 20),
            _buildBuscadorProductos(),
            const SizedBox(height: 24),
            _buildCarrito(),
            const SizedBox(height: 24),
            _buildDatosVenta(),
            const SizedBox(height: 32),
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nueva Venta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            _buildNumeroVenta(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumeroVenta() {
    return Text(
      'Nº $_ventaNumero',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey),
    );
  }

  Widget _buildBuscadorProductos() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _buscadorController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () {
                    final valor = _buscadorController.text.trim();
                    if (valor.isNotEmpty) {
                      _buscarYAgregarProducto(valor);
                    }
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (valor) {
                if (valor.trim().isNotEmpty) {
                  _buscarYAgregarProducto(valor.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarrito() {
    final estadoLocal = ref.watch(registrarVentaProvider);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${estadoLocal.detalles.length} productos'),
              ],
            ),
            const Divider(),
            if (estadoLocal.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Busque y agregue productos arriba')),
              )
            else
              ...estadoLocal.detalles.map((detalle) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(detalle.nombreProducto),
                  subtitle: Text('Cant: ${detalle.cantidad} • RD\$ ${detalle.subtotalLinea.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => ref
                        .read(registrarVentaProvider.notifier)
                        .quitarProducto(estadoLocal.detalles.indexOf(detalle)),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosVenta() {
    final estadoLocal = ref.watch(registrarVentaProvider);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Datos de la Venta', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildFilaDato(
              Icons.person,
              'Cliente',
              estadoLocal.clienteId != null ? 'Cliente ID ${estadoLocal.clienteId}' : 'Seleccionar',
              _abrirSelectorCliente,
            ),
            const SizedBox(height: 10),
            _buildFilaDato(
              Icons.payment,
              'Forma de Pago',
              estadoLocal.tipoPago.isNotEmpty
                  ? '${estadoLocal.tipoPago[0].toUpperCase()}${estadoLocal.tipoPago.substring(1)}${estadoLocal.esCredito ? ' (Crédito)' : ''}'
                  : 'Seleccionar',
              _abrirSelectorFormaPago,
            ),
            const Divider(height: 24),
            _buildFilaTotal('Subtotal', estadoLocal.subtotal),
            _buildFilaTotal('ITBIS (18%)', estadoLocal.itbis),
            const Divider(),
            _buildFilaTotal('TOTAL A PAGAR', estadoLocal.total, esTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaDato(IconData icono, String etiqueta, String valor, VoidCallback alPresionar) {
    return InkWell(
      onTap: alPresionar,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icono, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(child: Text(etiqueta)),
            Row(children: [
              Text(valor, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTotal(String etiqueta, double monto, {bool esTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 16 : 14)),
          Text('RD\$ ${monto.toStringAsFixed(2)}', style: TextStyle(fontWeight: esTotal ? FontWeight.bold : FontWeight.normal, fontSize: esTotal ? 18 : 14, color: esTotal ? Colors.green : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _limpiarVenta,
            icon: const Icon(Icons.refresh),
            label: const Text('Limpiar Venta'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
