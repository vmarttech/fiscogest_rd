import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
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
        SnackBar(
          content: Text('✅ ${producto.nombre} agregado'),
          backgroundColor: AppColors.success,
        ),
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
              content: Text(
                'Agregue productos antes de generar la cotización',
              ),
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
    final puedeGenerar = estado.detalles.isNotEmpty && estado.montoTotal > 0;
    final tituloPantalla =
        _modoCotizacion ? 'NUEVA COTIZACIÓN' : 'NUEVA VENTA';

    return AppScaffold(
      title: tituloPantalla,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      // ✅ PROTECCIÓN CONTRA BARRA INFERIOR
      body: SafeArea(
        bottom: true,
        maintainBottomViewPadding: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pantallaAncha = constraints.maxWidth >= 720;
                  return pantallaAncha
                      ? _buildDosColumnas(estado, puedeGenerar)
                      : _buildUnaColumna(estado, puedeGenerar);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnaColumna(VentaBorradorState estado, bool puedeGenerar) {
    return SingleChildScrollView(
      padding: AppSpacing.allM,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSeccionVencimiento(),
          AppLayout.vM,
          _buildSeccionTipoVenta(),
          AppLayout.vM,
          _buildSeccionCliente(estado),
          AppLayout.vM,
          _buildSeccionProductos(),
          AppLayout.vM,
          _buildSeccionResumen(estado),
          AppLayout.vL,
          _buildBotonera(puedeGenerar),
        ],
      ),
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
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSeccionVencimiento(),
                AppLayout.vM,
                _buildSeccionTipoVenta(),
                AppLayout.vM,
                _buildSeccionCliente(estado),
                AppLayout.vM,
                _buildSeccionProductos(),
              ],
            ),
          ),
        ),
        AppLayout.hM,
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: AppSpacing.allM,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildSeccionResumen(estado),
                AppLayout.vL,
                _buildBotonera(puedeGenerar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionVencimiento() {
    return AppCard(
      onTap: _seleccionarVencimiento,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vencimiento', style: AppTypography.labelMedium),
          AppLayout.vXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fechaVencimientoSeleccionada != null
                    ? '${_fechaVencimientoSeleccionada!.day}/${_fechaVencimientoSeleccionada!.month}/${_fechaVencimientoSeleccionada!.year}'
                    : 'Seleccione fecha (opcional)',
                style: AppTypography.bodyMediumSecondary,
              ),
              const Icon(
                Icons.calendar_today,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTipoVenta() {
    return AppCard(
      child: SwitchListTile(
        title: const Text('Venta a Crédito', style: AppTypography.labelMedium),
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

  Widget _buildSeccionCliente(VentaBorradorState estado) {
    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente', style: AppTypography.h4),
        AppLayout.vS,
        AppCard(
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
              AppLayout.hM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombreCliente, style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: _seleccionarCliente,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(88, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
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

  Widget _buildSeccionProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos', style: AppTypography.h4),
        AppLayout.vS,
        PanelProductos(alAgregar: _agregarProductoACotizacion),
      ],
    );
  }

  Widget _buildSeccionResumen(VentaBorradorState estado) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Resumen', style: AppTypography.h4),
          AppLayout.vM,
          AppLayout.filaDato(
            etiqueta: 'Subtotal',
            valor: 'RD\$ ${estado.subtotal.toStringAsFixed(2)}',
          ),
          AppLayout.filaDato(
            etiqueta: 'ITBIS (18%)',
            valor: 'RD\$ ${estado.itbis.toStringAsFixed(2)}',
          ),
          AppLayout.filaDato(
            etiqueta: 'Descuento',
            valor: 'RD\$ ${estado.montoDescuento.toStringAsFixed(2)}',
          ),
          const Divider(height: AppSpacing.l),
          AppLayout.filaDato(
            etiqueta: 'TOTAL',
            valor: 'RD\$ ${estado.montoTotal.toStringAsFixed(2)}',
            estiloEtiqueta: AppTypography.h4,
            estiloValor: AppTypography.h4,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonera(bool puedeGenerar) {
    return Column(
      children: [
        AppButton(
          text: _modoCotizacion ? 'GENERAR COTIZACIÓN' : 'GUARDAR VENTA',
          onPressed: puedeGenerar ? _guardarCotizacion : null,
          isLoading: _guardando,
          isDisabled: !puedeGenerar,
          width: double.infinity,
        ),
        AppLayout.vM,
        TextButton.icon(
          icon: const Icon(Icons.history, size: 18),
          label: const Text('Ver Historial de Cotizaciones'),
          onPressed: () => context.push('/ventas/cotizaciones/historial'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        // ✅ ESPACIO GARANTIZADO — EVITA QUE QUEDE TAPADO
        const SizedBox(height: 48),
      ],
    );
  }
}
