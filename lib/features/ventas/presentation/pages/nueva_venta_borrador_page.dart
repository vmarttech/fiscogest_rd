import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_card.dart';
import 'package:fiscogest_rd/core/ui/app_layout.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_productos.dart';

class NuevaVentaBorradorPage extends ConsumerStatefulWidget {
  const NuevaVentaBorradorPage({super.key});
  static const String routeName = '/ventas/cotizaciones/nueva';

  @override
  ConsumerState<NuevaVentaBorradorPage> createState() =>
      _NuevaVentaBorradorPageState();
}

class _NuevaVentaBorradorPageState
    extends ConsumerState<NuevaVentaBorradorPage> {
  final TextEditingController _buscadorController = TextEditingController();
  DateTime? _fechaVencimientoSeleccionada;
  bool _esCredito = false;
  bool _guardando = false;

  bool get _modoCotizacion {
    final ubicacion = GoRouterState.of(context).uri.path;
    return ubicacion.contains('cotizacion');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ventaBorradorProvider.notifier).establecerConsumidorFinal();
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  Future<void> _agregarProductoACotizacion(
    Producto producto,
    double cantidad,
  ) async {
    ref
        .read(ventaBorradorProvider.notifier)
        .agregarProducto(producto, cantidad);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${producto.nombre} agregado')),
      );
    }
  }

  Future<void> _seleccionarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(
      context,
    );
    if (cliente != null && mounted) {
      ref
          .read(ventaBorradorProvider.notifier)
          .seleccionarCliente(cliente.id ?? 0, cliente.nombre);
    }
  }

  Future<void> _seleccionarVencimiento() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 30)),
      firstDate: hoy.add(const Duration(days: 1)),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() => _fechaVencimientoSeleccionada = fecha);
      ref.read(ventaBorradorProvider.notifier).establecerVencimiento(fecha);
    }
  }

  void _limpiarFormulario() {
    ref.read(ventaBorradorProvider.notifier).vaciar();
    _buscadorController.clear();
    setState(() {
      _fechaVencimientoSeleccionada = null;
      _esCredito = false;
    });
    ref.read(ventaBorradorProvider.notifier).establecerConsumidorFinal();
  }

  Future<void> _guardarCotizacion() async {
    setState(() => _guardando = true);
    try {
      final notificador = ref.read(ventaBorradorProvider.notifier);
      final repositorio = ref.read(ventasRepositoryProvider);
      final numeroCotizacion = await repositorio.siguienteNumeroCotizacion(
        esCredito: _esCredito,
      );
      notificador.establecerNumeroCotizacion(numeroCotizacion);
      notificador.establecerEstadoDocumento(EstadoDocumento.cotizado);
      final numeroGuardado = await notificador.guardar();
      if (numeroGuardado == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agregue productos antes de generar la cotización'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Cotización N° $numeroGuardado generada.\n'
            'Consúltela en el Historial de Cotizaciones.',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      ref.invalidate(listaCotizacionesProvider);
      _limpiarFormulario();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar cotización: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(ventaBorradorProvider);
    final anchoPantalla = MediaQuery.of(context).size.width;
    final pantallaPequena = anchoPantalla < 720;
    final puedeGenerar = estado.detalles.isNotEmpty && estado.montoTotal > 0;

    return AppScaffold(
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: AppLayout.pantallaPadding,
          child: SingleChildScrollView(
            child: pantallaPequena
                ? _buildUnaColumna(estado, puedeGenerar)
                : _buildDosColumnas(estado, puedeGenerar),
          ),
        ),
      ),
    );
  }

  Widget _buildUnaColumna(VentaBorradorState estado, bool puedeGenerar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCabecera(),
        const SizedBox(height: AppSpacing.m),
        _buildTipoVenta(),
        const SizedBox(height: AppSpacing.m),
        _buildCliente(estado),
        const SizedBox(height: AppSpacing.m),
        _buildProductos(),
        const SizedBox(height: AppSpacing.m),
        _buildResumen(estado),
        const SizedBox(height: AppSpacing.l),
        _buildBotonera(puedeGenerar),
      ],
    );
  }

  Widget _buildDosColumnas(VentaBorradorState estado, bool puedeGenerar) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: Column(
              children: [
                _buildCabecera(),
                const SizedBox(height: AppSpacing.m),
                _buildTipoVenta(),
                const SizedBox(height: AppSpacing.m),
                _buildCliente(estado),
                const SizedBox(height: AppSpacing.m),
                _buildProductos(),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            child: Column(
              children: [
                _buildResumen(estado),
                const SizedBox(height: AppSpacing.l),
                _buildBotonera(puedeGenerar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCabecera() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _modoCotizacion ? 'NUEVA COTIZACIÓN' : 'NUEVA VENTA',
          style: AppTypography.h4,
        ),
        const SizedBox(height: AppSpacing.s),
        AppCard(
          padding: AppSpacing.allM,
          child: ListTile(
            title: const Text(
              'Vencimiento',
              style: AppTypography.bodyMedium,
            ),
            subtitle: Text(
              _fechaVencimientoSeleccionada != null
                  ? '${_fechaVencimientoSeleccionada!.day}/${_fechaVencimientoSeleccionada!.month}/${_fechaVencimientoSeleccionada!.year}'
                  : 'Seleccione fecha (opcional)',
              style: AppTypography.bodySmall,
            ),
            trailing: const Icon(Icons.calendar_today, size: 20),
            onTap: _seleccionarVencimiento,
          ),
        ),
      ],
    );
  }

  Widget _buildTipoVenta() {
    return AppCard(
      padding: AppSpacing.allM,
      child: SwitchListTile(
        title: const Text('Venta a Crédito', style: AppTypography.bodyMedium),
        subtitle: Text(
          _esCredito
              ? 'Genera cotización con prefijo CR'
              : 'Genera cotización con prefijo C',
          style: AppTypography.bodySmall,
        ),
        value: _esCredito,
        onChanged: (valor) => setState(() => _esCredito = valor),
        secondary: Icon(
          _esCredito ? Icons.schedule : Icons.payments_outlined,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCliente(VentaBorradorState estado) {
    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        AppCard(
          padding: AppSpacing.allM,
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombreCliente, style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: _seleccionarCliente,
                      child: const Text('Cambiar cliente'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.s),
        PanelProductos(alAgregar: _agregarProductoACotizacion),
      ],
    );
  }

  Widget _buildResumen(VentaBorradorState estado) {
    return AppCard(
      padding: AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumen', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.m),
          _buildFilaResumen('Subtotal', estado.subtotal),
          _buildFilaResumen('ITBIS (18%)', estado.itbis),
          _buildFilaResumen('Descuento', estado.montoDescuento),
          const Divider(),
          _buildFilaResumen('TOTAL', estado.montoTotal, esTotal: true),
        ],
      ),
    );
  }

  Widget _buildFilaResumen(String etiqueta, double monto, {bool esTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: esTotal ? AppTypography.h4 : AppTypography.bodyMedium,
          ),
          Text(
            'RD\$ ${monto.toStringAsFixed(2)}',
            style: esTotal ? AppTypography.h4 : AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonera(bool puedeGenerar) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: puedeGenerar && !_guardando ? _guardarCotizacion : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _modoCotizacion ? 'GENERAR COTIZACIÓN' : 'GUARDAR VENTA',
                ),
        ),
        const SizedBox(height: AppSpacing.m),
        TextButton.icon(
          icon: const Icon(Icons.history),
          label: const Text('Ver Historial de Cotizaciones'),
          onPressed: () => context.push('/ventas/cotizaciones/historial'),
        ),
      ],
    );
  }
}
