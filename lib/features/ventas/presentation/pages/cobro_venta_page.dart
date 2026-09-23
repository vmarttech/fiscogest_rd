import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/caja_provider.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart'
    as venta_providers;
import 'package:fiscogest_rd/features/ventas/presentation/providers/registrar_venta_usecase_provider.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';

class CobroVentaPage extends ConsumerStatefulWidget {
  const CobroVentaPage({super.key});

  static const String routeName = 'cobro-venta-operacion';
  /// Operación: buscar cotización y cobrar (no es el home de Caja).
  static const String path = '/ventas/cobro';
  static const String pathOperacion = '/ventas/cobro/operacion';

  @override
  ConsumerState<CobroVentaPage> createState() => _CobroVentaPageState();
}

class _CobroVentaPageState extends ConsumerState<CobroVentaPage> {
  final TextEditingController _abonoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();

  int ventaId = 0;
  double montoTotal = 0.0;
  bool esCredito = false;
  String numeroCotizacion = 'N/A';
  String? nombreCliente;
  List<DetalleVenta> _detalles = [];
  FormaPago _formaPago = FormaPago.efectivo;
  bool _procesando = false;
  bool _argsListos = false;
  bool _modoBusqueda = true;
  List<Venta> _pendientes = [];
  List<Venta> _resultados = [];
  bool _cargandoLista = false;
  String? _errorBusqueda;

  Map<String, dynamic>? _leerArgs(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map) return Map<String, dynamic>.from(extra);
    final modal = ModalRoute.of(context)?.settings.arguments;
    if (modal is Map) return Map<String, dynamic>.from(modal);
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsListos) return;
    _argsListos = true;
    final args = _leerArgs(context);
    final id = args?['ventaId'] as int? ?? 0;
    if (id > 0) {
      _cargarDocumento(
        id: id,
        monto: (args?['montoTotal'] as num?)?.toDouble() ?? 0.0,
        credito: args?['esCredito'] as bool? ?? false,
        numero: args?['numeroCotizacion'] as String? ?? 'N/A',
        cliente: args?['nombreCliente'] as String?,
      );
    } else {
      _modoBusqueda = true;
      _cargarPendientes();
    }
  }

  Future<void> _cargarDocumento({
    required int id,
    required double monto,
    required bool credito,
    required String numero,
    String? cliente,
  }) async {
    ventaId = id;
    montoTotal = monto;
    esCredito = credito;
    numeroCotizacion = numero;
    nombreCliente = cliente;
    _modoBusqueda = false;

    // Cargar detalles de productos para el resumen compacto
    try {
      final repo = ref.read(venta_providers.ventasRepositoryProvider);
      final ventaCompleta = await repo.obtenerVentaPorId(id);
      if (ventaCompleta != null && ventaCompleta.detalles.isNotEmpty) {
        _detalles = List<DetalleVenta>.from(ventaCompleta.detalles);
      } else {
        _detalles = [];
      }
    } catch (_) {
      _detalles = [];
    }

    ref.read(cajaProvider.notifier).inicializarVenta(montoTotal, esCredito);
    if (esCredito) {
      final abonoMinimo = montoTotal * 0.30;
      _abonoController.text = abonoMinimo.toStringAsFixed(2);
      ref.read(cajaProvider.notifier).establecerAbono(abonoMinimo);
    } else {
      _abonoController.text = montoTotal.toStringAsFixed(2);
      ref.read(cajaProvider.notifier).establecerAbono(montoTotal);
    }
    if (mounted) setState(() {});
  }

  Future<void> _cargarPendientes() async {
    setState(() {
      _cargandoLista = true;
      _errorBusqueda = null;
    });
    try {
      final repo = ref.read(venta_providers.ventasRepositoryProvider);
      final lista = await repo.listarPendientesCobro();
      if (!mounted) return;
      setState(() {
        _pendientes = lista;
        _cargandoLista = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBusqueda = '$e';
        _cargandoLista = false;
      });
    }
  }

  Future<void> _buscar() async {
    final texto = _busquedaController.text.trim();
    if (texto.isEmpty) {
      setState(() => _resultados = []);
      await _cargarPendientes();
      return;
    }
    setState(() {
      _cargandoLista = true;
      _errorBusqueda = null;
    });
    try {
      final repo = ref.read(venta_providers.ventasRepositoryProvider);
      final porNumero = await repo.buscarPorNumeroCotizacion(texto);
      final porCliente = await repo.buscarPorNombreCliente(texto);
      final mapa = <int, Venta>{};
      if (porNumero != null && porNumero.id != null) {
        mapa[porNumero.id!] = porNumero;
      }
      for (final v in porCliente) {
        if (v.id != null) mapa[v.id!] = v;
      }
      if (!mounted) return;
      setState(() {
        _resultados = mapa.values.toList();
        _cargandoLista = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBusqueda = '$e';
        _cargandoLista = false;
      });
    }
  }

  bool _esCreditoVenta(Venta v) {
    if (v.esCredito) return true;
    final p = v.formaPago.toLowerCase();
    if (p.contains('credito') || p.contains('crédito')) return true;
    return v.numeroCotizacion.startsWith('CR-');
  }

  bool _listaParaCobrar(Venta v) {
    if (v.estadoDocumento == EstadoDocumento.aprobado) return true;
    if (v.estadoDocumento == EstadoDocumento.cotizado && !_esCreditoVenta(v)) {
      return true;
    }
    return false;
  }

  void _seleccionarVenta(Venta v) {
    if (v.id == null) return;
    if (!_listaParaCobrar(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            v.estadoDocumento == EstadoDocumento.enCredito
                ? 'Esta cotización está en aprobación de crédito'
                : 'Esta cotización no está lista para cobrar',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _cargarDocumento(
      id: v.id!,
      monto: v.montoTotal,
      credito: _esCreditoVenta(v),
      numero: v.numeroCotizacion,
      cliente: v.nombreCliente,
    );
  }

  @override
  void dispose() {
    _abonoController.dispose();
    _referenciaController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  void _onAbonoChanged(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    final valor = double.tryParse(limpio) ?? 0.0;
    ref.read(cajaProvider.notifier).establecerAbono(valor);
  }

  Future<void> _cobrarYGenerarFactura() async {
    if (!mounted || _procesando) return;
    final cajaNotifier = ref.read(cajaProvider.notifier);
    final estado = ref.read(cajaProvider);

    if (!cajaNotifier.validarCobroCompleto()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esCredito
                ? 'El abono debe ser mayor a RD\$ 0 y no exceder el total'
                : 'Debe cubrir el monto total',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (ventaId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una cotización'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    try {
      final repositorio = ref.read(venta_providers.ventasRepositoryProvider);
      final Venta venta;
      final formaPagoNombre = _formaPago.nombre;

      if (esCredito) {
        venta = await repositorio.registrarVentaConAbono(
          ventaId,
          estado.abono,
          _referenciaController.text.trim(),
          formaPago: formaPagoNombre,
        );
      } else {
        venta = await repositorio.confirmarVentaBorrador(
          ventaId,
          formaPago: formaPagoNombre,
        );
      }

      // Inventario + Kardex
      final ventaConDetalle =
          await repositorio.obtenerVentaPorId(venta.id ?? ventaId);
      if (ventaConDetalle == null) {
        throw Exception('No se pudo recargar la venta facturada');
      }
      if (ventaConDetalle.detalles.isEmpty) {
        throw Exception(
          'La cotización no tiene líneas de detalle. '
          'Genere una cotización nueva (con productos) y vuelva a cobrar.',
        );
      }
      final inv = ref.read(ventaInventarioServiceProvider);
      await inv.aplicarSalidaInventario(ventaConDetalle);

      // Ingreso módulo Caja
      final montoCaja = esCredito ? estado.abono : montoTotal;
      if (montoCaja > 0) {
        final cajaRepo = ref.read(cajaRepositoryProvider);
        final nFactura = venta.numeroFactura ?? venta.numeroCotizacion;
        await cajaRepo.registrarMovimiento(
          referencia: nFactura,
          monto: montoCaja,
          tipo: 'ingreso',
          descripcion:
              'Cobro factura $nFactura (cotización ${venta.numeroCotizacion})',
          formaPago: formaPagoNombre,
        );
      }

      ref.invalidate(listaVentasBorradorProvider);
      ref.invalidate(listaCotizacionesProvider);

      if (!mounted) return;
      final numeroFactura = venta.numeroFactura ?? '—';
      final saldo = esCredito ? (montoTotal - estado.abono) : 0.0;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Factura generada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N° Factura: $numeroFactura',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Ref. Cotización: ${venta.numeroCotizacion}'),
                if (esCredito) ...[
                  const SizedBox(height: 8),
                  Text('Abono: RD\$ ${estado.abono.toStringAsFixed(2)}'),
                  Text('Saldo: RD\$ ${saldo.toStringAsFixed(2)}'),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _modoBusqueda = true;
                    ventaId = 0;
                    _detalles = [];
                    _abonoController.clear();
                    _referenciaController.clear();
                  });
                  _cargarPendientes();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cobrar: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_modoBusqueda) return _buildBusqueda(context);
    return _buildCobro(context);
  }

  Widget _buildBusqueda(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 600;
    final padding = esPequena ? 12.0 : 20.0;
    final maxAncho = esPequena ? double.infinity : 720.0;
    final tamanoCuerpo = esPequena ? 13.0 : 14.0;
    final tamanoEtiqueta = esPequena ? 11.0 : 12.0;

    final lista =
        _busquedaController.text.trim().isEmpty ? _pendientes : _resultados;

    return AppScaffold(
      title: 'CAJA — BUSCAR COTIZACIÓN',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/ventas');
          }
        },
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxAncho),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaController,
                          style: TextStyle(fontSize: tamanoCuerpo),
                          decoration: InputDecoration(
                            hintText: 'N° cotización o nombre del cliente',
                            hintStyle: TextStyle(fontSize: tamanoCuerpo),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _buscar(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _cargandoLista ? null : _buscar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            'Buscar',
                            style: TextStyle(fontSize: tamanoCuerpo),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorBusqueda != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Text(
                      _errorBusqueda!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: tamanoCuerpo,
                      ),
                    ),
                  ),
                Expanded(
                  child: _cargandoLista
                      ? const Center(child: CircularProgressIndicator())
                      : lista.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(padding),
                                child: Text(
                                  _busquedaController.text.trim().isEmpty
                                      ? 'No hay cotizaciones pendientes de cobro'
                                      : 'Sin resultados',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: tamanoCuerpo,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _cargarPendientes,
                              child: ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  padding,
                                  0,
                                  padding,
                                  padding + 16,
                                ),
                                itemCount: lista.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final v = lista[i];
                                  final credito = _esCreditoVenta(v);
                                  final listaOk = _listaParaCobrar(v);
                                  final colorEstado = credito
                                      ? AppColors.warning
                                      : AppColors.primary;
                                  return Material(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: listaOk
                                          ? () => _seleccionarVenta(v)
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(
                                            esPequena ? 14 : 16),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'N° ${v.numeroCotizacion}',
                                                    style: AppTypography
                                                        .labelMedium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          tamanoCuerpo,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    v.nombreCliente ??
                                                        'Sin cliente',
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: tamanoCuerpo,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: colorEstado
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      credito
                                                          ? 'Crédito · ${v.estadoDocumento.name}'
                                                          : 'Contado · ${v.estadoDocumento.name}',
                                                      style: AppTypography
                                                          .labelSmall
                                                          .copyWith(
                                                        color: colorEstado,
                                                        fontSize:
                                                            tamanoEtiqueta,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'RD\$ ${v.montoTotal.toStringAsFixed(2)}',
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                                fontSize: tamanoCuerpo + 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCobro(BuildContext context) {
    final estado = ref.watch(cajaProvider);
    final ancho = MediaQuery.of(context).size.width;
    final esPequena = ancho < 600;
    final padding = esPequena ? 12.0 : 20.0;
    final maxAncho = esPequena ? double.infinity : 720.0;
    final tamanoCuerpo = esPequena ? 13.0 : 14.0;
    final tamanoEtiqueta = esPequena ? 11.0 : 12.0;
    final tamanoTotal = esPequena ? 28.0 : 34.0;
    final alturaBoton = esPequena ? 54.0 : 58.0;

    return AppScaffold(
      title: esCredito ? 'COBRO A CRÉDITO' : 'COBRO EN CAJA',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _modoBusqueda = true;
            ventaId = 0;
            _detalles = [];
          });
          _cargarPendientes();
        },
      ),
      body: SafeArea(
        bottom: true,
        maintainBottomViewPadding: true,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxAncho),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // === TARJETA RESUMEN PRINCIPAL ===
                        Container(
                          padding: EdgeInsets.all(esPequena ? 16 : 20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // N° Cotización
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    color: AppColors.primary,
                                    size: esPequena ? 20 : 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'N° $numeroCotizacion',
                                      style: AppTypography.h4.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: esPequena ? 17 : 19,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Cliente
                              if (nombreCliente != null &&
                                  nombreCliente!.isNotEmpty)
                                Text(
                                  nombreCliente!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: tamanoCuerpo,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, thickness: 1),
                              const SizedBox(height: 14),

                              // === PRODUCTOS COMPACTO ===
                              if (_detalles.isNotEmpty) ...[
                                Text(
                                  'PRODUCTOS',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: tamanoEtiqueta,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._detalles.take(5).map((d) {
                                  final subtotal =
                                      d.subtotalLinea ?? d.subtotal;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${d.cantidad} × ${d.nombreProducto ?? "Producto"}',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              fontSize: tamanoCuerpo,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'RD\$ ${subtotal.toStringAsFixed(2)}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            fontSize: tamanoCuerpo,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                if (_detalles.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '+ ${_detalles.length - 5} productos más',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: tamanoEtiqueta,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                const Divider(height: 1, thickness: 1),
                                const SizedBox(height: 14),
                              ],

                              // === TOTAL DOMINANTE ===
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL A COBRAR',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: tamanoEtiqueta,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'RD\$ ${montoTotal.toStringAsFixed(2)}',
                                    style: AppTypography.h3.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: tamanoTotal,
                                      color: AppColors.primary,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: esPequena ? 16 : 20),

                        // === FORMA DE PAGO ===
                        Text(
                          'Forma de pago',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: tamanoCuerpo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: FormaPago.values.map((forma) {
                            final sel = _formaPago == forma;
                            return ChoiceChip(
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  forma.nombre,
                                  style: TextStyle(
                                    fontSize: tamanoCuerpo,
                                    fontWeight:
                                        sel ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ),
                              selected: sel,
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              onSelected: (_) =>
                                  setState(() => _formaPago = forma),
                              side: sel
                                  ? const BorderSide(color: AppColors.primary)
                                  : const BorderSide(color: AppColors.border),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: esPequena ? 16 : 20),

                        // === MONTO / ABONO ===
                        Text(
                          esCredito ? 'Abono inicial (mín. 30%)' : 'Monto a pagar',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: tamanoCuerpo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _abonoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: esCredito,
                          onChanged: _onAbonoChanged,
                          style: TextStyle(
                            fontSize: tamanoCuerpo + 2,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'RD\$ ',
                            prefixStyle: TextStyle(
                              fontSize: tamanoCuerpo + 2,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),

                        // === SALDO PENDIENTE (solo crédito) ===
                        if (esCredito) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saldo pendiente',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: tamanoCuerpo,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'RD\$ ${estado.saldoPendiente.toStringAsFixed(2)}',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: tamanoCuerpo + 1,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _referenciaController,
                            style: TextStyle(fontSize: tamanoCuerpo),
                            decoration: InputDecoration(
                              labelText: 'Referencia (opcional)',
                              labelStyle: TextStyle(fontSize: tamanoCuerpo),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],

                        // Espacio para que el botón fijo no tape contenido
                        SizedBox(height: esPequena ? 20 : 24),
                      ],
                    ),
                  ),
                ),

                // === BOTÓN FIJO: COBRAR Y GENERAR FACTURA ===
                Container(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    12,
                    padding,
                    esPequena ? 14 : 18,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: const Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: alturaBoton,
                      child: ElevatedButton.icon(
                        onPressed:
                            _procesando ? null : _cobrarYGenerarFactura,
                        icon: _procesando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.receipt_long, size: 22),
                        label: Text(
                          _procesando
                              ? 'Procesando...'
                              : 'COBRAR Y GENERAR FACTURA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: esPequena ? 14 : 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
