import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_textfield.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_entity.dart';
import 'package:fiscogest_rd/features/clientes/presentation/widgets/seleccionar_cliente_dialog.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/contenedor/enums_ventas.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/ventas_navegacion_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
import 'package:fiscogest_rd/features/apartados/presentation/providers/apartado_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/widgets/panel_carrito.dart';
import 'package:fiscogest_rd/features/creditos/presentation/widgets/formulario_credito_vista.dart';

class VistaInicioVacia extends ConsumerStatefulWidget {
  const VistaInicioVacia({super.key});

  @override
  ConsumerState<VistaInicioVacia> createState() => _VistaInicioVaciaState();
}

class _VistaInicioVaciaState extends ConsumerState<VistaInicioVacia> {
  static final NumberFormat _formatoNumero = NumberFormat('#,##0.00', 'es_DO');
  String _formatearMonto(double valor) => 'RD\$${_formatoNumero.format(valor)}';

  bool _guardando = false;
  bool _mostrarFormularioCredito = false;
  RegistrarVentaState? _estadoPasoCredito;
  final TextEditingController _buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrarVentaProvider.notifier).establecerConsumidorFinal();
    });
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _cambiarCliente() async {
    final ClienteEntity? cliente = await SeleccionarClienteDialog.mostrar(context);
    if (cliente != null && mounted) {
      ref.read(registrarVentaProvider.notifier).seleccionarCliente(cliente.id ?? 0, cliente.nombre);
    }
  }

  void _cerrarFormularioCredito() {
    setState(() {
      _mostrarFormularioCredito = false;
      _estadoPasoCredito = null;
      _guardando = false;
    });
  }

  void _confirmarCredito(ResultadoFormularioCredito resultadoCredito) async {
    _cerrarFormularioCredito();
    if (!mounted) return;
    setState(() => _guardando = true);
    try {
      final abonoRecibido = resultadoCredito.abonoInicial?.monto ?? 0.0;
      final fechaVence = resultadoCredito.cuenta.fechaVencimiento;
      ref.read(registrarVentaProvider.notifier).establecerCondicionesCredito(abonoRecibido, fechaVence);
      final estadoConCredito = ref.read(registrarVentaProvider);
      final modo = ref.read(ventasNavegacionProvider).modoOperacion;

      if (modo == ModoOperacion.apartado) {
        await ref.read(apartadoNotifierProvider.notifier).crearApartadoDesdeVenta(estadoConCredito);
      } else {
        final ventaGuardada = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoConCredito);
        if (!mounted) return;
        if (ventaGuardada.id == null) {
          throw Exception('El repositorio no devolvió ID de venta');
        }
      }

      final saldoPendiente = estadoConCredito.total - abonoRecibido;
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              modo == ModoOperacion.apartado
                  ? 'Apartado registrado — Crédito vinculado.\nAbono inicial: ${_formatearMonto(abonoRecibido)}\nSaldo pendiente: ${_formatearMonto(saldoPendiente)}\nVence: ${DateFormat('dd/MM/yyyy').format(fechaVence)}'
                  : 'Venta registrada.\nAbono inicial: ${_formatearMonto(abonoRecibido)}\nSaldo pendiente: ${_formatearMonto(saldoPendiente)}\nVence: ${DateFormat('dd/MM/yyyy').format(fechaVence)}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('Error crédito: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cobrar() async {
    final estado = ref.read(registrarVentaProvider);
    final modo = ref.read(ventasNavegacionProvider).modoOperacion;
    final valido = ref.read(registrarVentaProvider.notifier).validarAntesDeGuardar();

    if (!valido) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregue productos y seleccione forma de pago')),
        );
      }
      return;
    }

    if (!mounted) return;

    const formasPago = ['Efectivo', 'Tarjeta', 'Crédito', 'Transferencia', 'Cheque'];
    final formaSeleccionada = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          modo == ModoOperacion.apartado ? 'Forma de Reserva' : 'Forma de Pago',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${_formatearMonto(estado.total)}',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...formasPago.map(
              (forma) => ListTile(
                title: Text(forma),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => Navigator.pop(context, forma.toLowerCase()),
              ),
            ),
          ],
        ),
      ),
    );

    if (formaSeleccionada == null || !mounted) return;

    ref.read(registrarVentaProvider.notifier).cambiarFormaPago(formaSeleccionada);
    final estadoFinal = ref.read(registrarVentaProvider);

    if (formaSeleccionada == 'crédito') {
      setState(() {
        _mostrarFormularioCredito = true;
        _estadoPasoCredito = estadoFinal;
      });
      return;
    }

    if (modo == ModoOperacion.apartado) {
      final idApartado = await ref
          .read(apartadoNotifierProvider.notifier)
          .crearApartadoDesdeVenta(estadoFinal);
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apartado #$idApartado registrado — Stock reservado — ${_formatearMonto(estadoFinal.total)}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final ventaGuardada = await ref.read(registrarVentaUseCaseProvider).ejecutar(estadoFinal);
      if (!mounted) return;
      if (ventaGuardada.id == null) {
        throw Exception('El repositorio no devolvió ID de venta');
      }
      if (mounted) {
        ref.read(registrarVentaProvider.notifier).vaciarVenta();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta #${ventaGuardada.numero} registrada — ${_formatearMonto(ventaGuardada.total)}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  double _calcularDescuentoPorLinea(RegistrarVentaState estado) {
    double totalDesc = 0.0;
    for (final linea in estado.detalles) {
      final precioConCantidad = linea.subtotalLinea ?? linea.subtotal;
      double despuesDesc = precioConCantidad;
      if (linea.descuentoPorcentaje > 0) {
        despuesDesc = precioConCantidad * (100 - linea.descuentoPorcentaje) / 100;
      } else if (linea.montoDescuento > 0) {
        despuesDesc = precioConCantidad - linea.montoDescuento;
      }
      if (despuesDesc < 0) despuesDesc = 0;
      totalDesc += (precioConCantidad - despuesDesc);
    }
    return totalDesc;
  }

  void _seleccionarProducto(DetalleVenta producto) {
    _buscarController.clear();
    ref.read(registrarVentaProvider.notifier)
      ..buscarProducto('')
      ..agregarProductoSeleccionado(producto);
  }

  @override
  Widget build(BuildContext context) {
    final modo = ref.watch(ventasNavegacionProvider.select((e) => e.modoOperacion));
    final estado = ref.watch(registrarVentaProvider);
    final esConsumidorFinal = estado.clienteId == 0 || estado.clienteNombre == 'Consumidor Final';
    final isMobile = AppBreakpoints.isMobile(context);

    final colorPrimario = switch (modo) {
      ModoOperacion.venta => AppColors.primary,
      ModoOperacion.cotizacion => AppColors.info,
      ModoOperacion.apartado => AppColors.warning,
      ModoOperacion.cobrar => AppColors.error,
    };

    final nombreCliente = estado.clienteNombre?.isNotEmpty == true
        ? estado.clienteNombre!
        : 'Consumidor Final';
    final tieneProductos = estado.detalles.isNotEmpty;
    final tieneResultados = estado.resultadosBusqueda.isNotEmpty;
    final montoTotal = _formatearMonto(estado.total);
    final tieneDescuentoGeneral = estado.montoDescuento > 0;
    final descuentoPorLinea = _calcularDescuentoPorLinea(estado);
    final subtotalConDescuentoLinea = estado.subtotal - descuentoPorLinea;
    final baseGravable = (subtotalConDescuentoLinea - estado.montoDescuento).clamp(0.0, double.infinity);

    if (_mostrarFormularioCredito && _estadoPasoCredito != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _cerrarFormularioCredito,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                  ),
                ),
                const SizedBox(height: 12),
                FormularioCreditoVista(
                  estadoVenta: _estadoPasoCredito!,
                  onVolver: _cerrarFormularioCredito,
                  onConfirmado: _confirmarCredito,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── PESTAÑAS DE MODO ───
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _ModoTab(
                      label: 'VENTA',
                      active: modo == ModoOperacion.venta,
                      color: AppColors.primary,
                      onTap: _guardando
                          ? null
                          : () => ref.read(ventasNavegacionProvider.notifier).establecerModoOperacion(ModoOperacion.venta),
                    ),
                    _ModoTab(
                      label: 'COTIZACIÓN',
                      active: false,
                      color: AppColors.info,
                      onTap: _guardando ? null : () => context.push('/ventas/cotizaciones/nueva'),
                    ),
                    _ModoTab(
                      label: 'APARTADO',
                      active: modo == ModoOperacion.apartado,
                      color: AppColors.warning,
                      onTap: _guardando
                          ? null
                          : () => ref.read(ventasNavegacionProvider.notifier).establecerModoOperacion(ModoOperacion.apartado),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── BUSCADOR ───
              AppTextField(
                controller: _buscarController,
                hint: 'Buscar producto, código o escanear...',
                prefixIcon: Icons.search,
                onChanged: (texto) => ref.read(registrarVentaProvider.notifier).buscarProducto(texto),
              ),

              if (tieneResultados)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: AppRadius.allM,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: estado.resultadosBusqueda.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final prod = estado.resultadosBusqueda[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          prod.nombreProducto ?? 'Producto',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _formatearMonto(prod.precioUnitario),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        ),
                        onTap: () => _seleccionarProducto(prod),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // ─── CLIENTE ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.allM,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: colorPrimario),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        nombreCliente,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _guardando ? null : _cambiarCliente,
                      style: TextButton.styleFrom(
                        foregroundColor: colorPrimario,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── CARRITO / VACÍO ───
              if (!tieneProductos)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 56),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppRadius.allL,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.point_of_sale_outlined,
                        size: isMobile ? 48 : 56,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        modo == ModoOperacion.apartado ? 'El apartado está vacío' : 'La venta está vacía',
                        style: AppTypography.h4.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Busca un producto para comenzar',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                const PanelCarrito(),

              const SizedBox(height: 24),

              // ─── TOTALES ───
              if (tieneProductos)
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (estado.costoEnvio > 0)
                        _FilaResumen(label: 'Envío / Delivery', value: _formatearMonto(estado.costoEnvio)),
                      if (!esConsumidorFinal) ...[
                        _FilaResumen(label: 'Subtotal', value: _formatearMonto(estado.subtotal)),
                        if (descuentoPorLinea > 0.001)
                          _FilaResumen(
                            label: 'Descuento por línea',
                            value: '- ${_formatearMonto(descuentoPorLinea)}',
                            color: AppColors.error,
                          ),
                        if (tieneDescuentoGeneral)
                          _FilaResumen(
                            label: 'Descuento general',
                            value: '- ${_formatearMonto(estado.montoDescuento)}',
                            color: AppColors.error,
                          ),
                        _FilaResumen(label: 'Base Gravable', value: _formatearMonto(baseGravable)),
                        _FilaResumen(label: 'ITBIS (18%)', value: _formatearMonto(estado.itbis)),
                      ],
                      const SizedBox(height: 8),
                      _FilaResumen(
                        label: 'TOTAL',
                        value: montoTotal,
                        destacado: true,
                        color: colorPrimario,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ─── BOTÓN COBRAR ───
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: isMobile ? double.infinity : 280,
                  height: isMobile ? 56 : 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: AppColors.grey300,
                    ),
                    onPressed: tieneProductos && !_guardando ? _cobrar : null,
                    child: _guardando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tieneProductos
                                    ? (modo == ModoOperacion.apartado ? 'RESERVAR' : 'COBRAR')
                                    : 'AGREGUE PRODUCTOS',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (tieneProductos) ...[
                                const SizedBox(height: 2),
                                Text(
                                  montoTotal,
                                  style: TextStyle(
                                    fontSize: isMobile ? 15 : 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _ModoTab extends StatelessWidget {

  const _ModoTab({
    required this.label,
    required this.active,
    required this.color,
    this.onTap,
  });
  final String label;
  final bool active;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: active ? AppColors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {

  const _FilaResumen({
    required this.label,
    required this.value,
    this.destacado = false,
    this.color,
  });
  final String label;
  final String value;
  final bool destacado;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textSecondary,
              fontSize: destacado ? 15 : 13.5,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 130,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.textPrimary,
                fontSize: destacado ? 16 : 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
