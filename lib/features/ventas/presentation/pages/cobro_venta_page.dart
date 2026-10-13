import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/e_cf/presentation/providers/ecfe_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
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
import 'package:fiscogest_rd/features/inventario/presentation/providers/producto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/providers/facturacion_providers.dart';
import 'package:fiscogest_rd/features/clientes/presentation/providers/cliente_completo_providers.dart';
import 'package:fiscogest_rd/features/clientes/domain/entities/cliente_completo.dart';
import 'package:fiscogest_rd/core/services/dgii_rnc_consulta_service.dart';
import 'package:fiscogest_rd/core/ui/fisco_gest_notifications.dart';
import 'package:fiscogest_rd/core/ui/app_formatters.dart';

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
  final TextEditingController _efectivoRecibidoController =
      TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();

  int ventaId = 0;

  /// Comprobante fiscal en Caja (antes de cobrar).
  String _tipoNcf = 'B02';
  final TextEditingController _rncFiscalController = TextEditingController();
  bool _buscandoRnc = false;
  String? _rncNombreEncontrado;
  String _dirCliente = '';
  String _telCliente = '';
  double montoTotal = 0.0;
  final double _costoEnvio = 0.0;
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
    var abonoDesdeDoc = 0.0;
    try {
      final repo = ref.read(venta_providers.ventasRepositoryProvider);
      final ventaCompleta = await repo.obtenerVentaPorId(id);
      if (ventaCompleta != null) {
        if (ventaCompleta.detalles.isNotEmpty) {
          _detalles = List<DetalleVenta>.from(ventaCompleta.detalles);
        } else {
          _detalles = [];
        }
        abonoDesdeDoc = ventaCompleta.abonoInicial;
      } else {
        _detalles = [];
      }
    } catch (_) {
      _detalles = [];
    }

    ref.read(cajaProvider.notifier).inicializarVenta(montoTotal, esCredito);
    if (esCredito) {
      // Abono pactado en cotización / crédito (no regla comercial del 30% en caja)
      final abonoPactado = (abonoDesdeDoc > 0 ? abonoDesdeDoc : 0.0).clamp(
        0.0,
        montoTotal,
      );
      _abonoController.text = abonoPactado.toStringAsFixed(2);
      ref.read(cajaProvider.notifier).establecerAbono(abonoPactado);
    } else {
      _abonoController.text = montoTotal.toStringAsFixed(2);
      _efectivoRecibidoController.text = montoTotal.toStringAsFixed(2);
      ref.read(cajaProvider.notifier).establecerAbono(montoTotal);
    }
    _aplicarConfigCaja();
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
      FiscoGestNotifications.show(
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
    _cargarRncCliente(v.clienteId);
  }

  @override
  void dispose() {
    _rncFiscalController.dispose();
    _abonoController.dispose();
    _efectivoRecibidoController.dispose();
    _referenciaController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _opcionesComprobantePdf(Venta ventaConDetalle) async {
    final emp = ref.read(configuracionControllerProvider).valueOrNull;
    final simple = emp?.modoSimplificado == true;
    final ncf = (ventaConDetalle.numeroFactura ?? '').trim();
    if (ncf.isEmpty && !simple) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Sin NCF fiscal: no se puede generar el PDF'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final accion = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(simple ? 'Comprobante' : 'Comprobante fiscal'),
        content: Text(
          'NCF: $ncf\n\nElija imprimir o enviar (WhatsApp, correo, etc.).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'imprimir'),
            child: const Text('Imprimir'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'enviar'),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (accion == null || !mounted) return;
    try {
      if (accion == 'enviar') {
        final codigoTicket4 = ventaConDetalle.id == null
            ? null
            : await ref
                  .read(ecfeRepositoryProvider)
                  .codigoSeguridadPorVenta(ventaConDetalle.id!);
        final ambienteTicket4 =
            (await ref.read(ecfeRepositoryProvider).obtenerConfig()).ambiente;
        await ComprobantePdf.imprimirFactura(
          ventaConDetalle,
          compartir: true,
          empresa: emp,
          rncCliente: _rncFiscalController.text.trim(),
          direccionCliente: _dirCliente,
          telefonoCliente: _telCliente,
          codigoSeguridad: codigoTicket4,
          ambienteDgii: ambienteTicket4,
        );
      } else {
        final codigoTicket5 = ventaConDetalle.id == null
            ? null
            : await ref
                  .read(ecfeRepositoryProvider)
                  .codigoSeguridadPorVenta(ventaConDetalle.id!);
        final ambienteTicket5 =
            (await ref.read(ecfeRepositoryProvider).obtenerConfig()).ambiente;
        await ComprobantePdf.imprimirFactura(
          ventaConDetalle,
          compartir: false,
          empresa: emp,
          rncCliente: _rncFiscalController.text.trim(),
          direccionCliente: _dirCliente,
          telefonoCliente: _telCliente,
          codigoSeguridad: codigoTicket5,
          ambienteDgii: ambienteTicket5,
        );
      }
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('PDF: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double? _parseMontoCobro(String raw) {
    final s = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  /// null = OK. Mensaje = error.
  String? _validarMontoCobro({
    required String textoAbono,
    required double montoTotal,
    required bool esCredito,
  }) {
    final v = _parseMontoCobro(textoAbono);
    if (v == null) {
      return 'Monto inválido. Use números (ej. 1500.50)';
    }
    if (v < 0) return 'El monto no puede ser negativo';
    if (v > 999999999) return 'Monto fuera de rango';

    if (esCredito) {
      // Caja no impone % comercial; crédito ya autorizó condiciones.
      // Solo rangos coherentes: 0 <= abono <= total
      if (v < 0) {
        return 'El monto no puede ser negativo';
      }
      if (v > montoTotal + 0.009) {
        return 'El abono no puede exceder el total '
            '(${formatRd(montoTotal)})';
      }
    } else {
      // Contado: debe cubrir el total (tolerancia 1 centavo)
      if (v + 0.009 < montoTotal) {
        return 'Debe cubrir el total: ${formatRd(montoTotal)}';
      }
      if (v > montoTotal + 0.05) {
        // opcional: permitir sobrante pequeño como cambio; bloquear exceso grande
        // return 'Monto mayor al total. Ajuste a ${formatRd(montoTotal)}';
      }
    }
    return null;
  }

  void _onAbonoChanged(String texto) {
    final limpio = texto.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (limpio.isEmpty) {
      ref.read(cajaProvider.notifier).establecerAbono(0);
      return;
    }
    final valor = double.tryParse(limpio);
    if (valor == null || valor < 0) return; // no actualiza con basura
    ref.read(cajaProvider.notifier).establecerAbono(valor);
  }

  Future<bool> _exigirCajaAbierta() async {
    // Solo exige sesión si el switch está explícitamente ON.
    // cfg null o false → permitir cobrar.
    final cfg =
        ref.read(configuracionControllerProvider).valueOrNull ??
        ref.read(configuracionControllerProvider).asData?.value;
    final exige = cfg?.cajaExigirSesion ?? false;
    if (!exige) return true;

    final sesion = await ref
        .read(cajaRepositoryProvider)
        .obtenerSesionAbierta();
    if (sesion == null || !sesion.estaAbierta) {
      if (mounted) {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text(
              'La caja está cerrada. Ábrala desde el menú Caja '
              '(o desactiva "Exigir sesión" en Configuración → Caja).',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _buscarRncFiscalEnLinea() async {
    final raw = _rncFiscalController.text.trim();
    if (!DgiiRncConsultaService.esFormatoValido(raw)) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Ingrese RNC (9) o cédula (11 dígitos)'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() {
      _buscandoRnc = true;
      _rncNombreEncontrado = null;
    });
    final svc = DgiiRncConsultaService();
    try {
      final r = await svc.consultar(raw);
      if (!mounted) return;
      setState(() {
        _rncFiscalController.text = r.rnc;
        _rncNombreEncontrado = r.estado != null
            ? '${r.nombre} · ${r.estado}'
            : r.nombre;
      });
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('RNC verificado: ${r.nombre}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _rncNombreEncontrado = null);
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      svc.dispose();
      if (mounted) setState(() => _buscandoRnc = false);
    }
  }

  Future<void> _cargarRncCliente(int clienteId) async {
    try {
      final repo = ref.read(clienteCompletoRepositoryProvider);
      final lista = await repo.obtenerClientes();
      ClienteCompleto? cli;
      for (final c in lista) {
        if (c.id == clienteId) {
          cli = c;
          break;
        }
      }
      final rnc = (cli?.rncCedula ?? '').trim();
      if (!mounted) return;
      setState(() {
        _rncFiscalController.text = rnc;
        _dirCliente = (cli?.direccion ?? '').trim();
        _telCliente = (cli?.telefono ?? '').trim();
        // Solo el cajero elige B01/B02. Cliente en ficha ≠ crédito fiscal automático.
        if (_tipoNcf != 'B01' && _tipoNcf != 'B02' && _tipoNcf != 'B14') {
          _tipoNcf = 'B02';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _rncFiscalController.clear();
          _dirCliente = '';
          _telCliente = '';
          _tipoNcf = 'B02';
        });
      }
    }
  }

  /// Emite NCF B01/B02 si aún no hay NCF fiscal (reemplaza B03 legado).
  Future<void> _asegurarNcfFiscal(int ventaIdDoc) async {
    final repo = ref.read(venta_providers.ventasRepositoryProvider);
    final doc = await repo.obtenerVentaPorId(ventaIdDoc);
    final actual = (doc?.numeroFactura ?? '').trim();
    final yaFiscal =
        actual.startsWith('B01') ||
        actual.startsWith('B02') ||
        actual.startsWith('B14');
    if (yaFiscal) return;

    if (_tipoNcf == 'B01' || _tipoNcf == 'B14') {
      final rnc = _rncFiscalController.text.trim().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      if (rnc.length != 9 && rnc.length != 11) {
        throw StateError('B01 o B14 requiere RNC (9) o cédula (11 dígitos)');
      }
    }

    final ncf = await ref.read(secuenciasNcfDaoProvider).siguienteNcf(_tipoNcf);
    await repo.emitirNcfFiscal(ventaIdDoc, ncf);
    // e-CF: encolado opt-in; no afecta cobro
    try {
      final ventaEcfe = await repo.obtenerVentaPorId(ventaIdDoc);
      if (ventaEcfe != null) {
        final tipo = ncf.length >= 3 ? ncf.substring(0, 3) : ncf;
        final resultadoEcfe = await ref.read(encolarEcfeDesdeVentaProvider)(
          venta: ventaEcfe,
          tipoNcf: tipo,
          rncCliente: _rncFiscalController.text.trim(),
          nombreCliente: ventaEcfe.nombreCliente ?? '',
        );
        final detalleEcfe = resultadoEcfe.erroresValidacion.join(' · ');
        final omisionEcfe = (resultadoEcfe.omitidoPor ?? '').trim();
        final silencioso =
            omisionEcfe.contains('deshabilitado') ||
            omisionEcfe.contains('sin envío');
        if (mounted &&
            !silencioso &&
            (detalleEcfe.isNotEmpty ||
                (!resultadoEcfe.encolado && omisionEcfe.isNotEmpty))) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text(
                'e-CF no quedó listo: ${detalleEcfe.isNotEmpty ? detalleEcfe : omisionEcfe}',
              ),
            ),
          );
        }
        ref.invalidate(ecfeColaProvider);
      }
    } catch (errorEcfe) {
      if (mounted) {
        FiscoGestNotifications.show(
          SnackBar(content: Text('e-CF no quedó listo: $errorEcfe')),
        );
      }
    }
  }

  Future<void> _cobrarYGenerarFactura() async {
    if (!mounted || _procesando) return;

    final errMonto = _validarMontoCobro(
      textoAbono: !esCredito && _formaPago == FormaPago.efectivo
          ? _efectivoRecibidoController.text
          : _abonoController.text,
      montoTotal: montoTotal,
      esCredito: esCredito,
    );
    if (errMonto != null) {
      FiscoGestNotifications.show(
        SnackBar(
          content: Text(errMonto),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final montoCapturado =
        _parseMontoCobro(
          !esCredito && _formaPago == FormaPago.efectivo
              ? _efectivoRecibidoController.text
              : _abonoController.text,
        ) ??
        0;
    ref
        .read(cajaProvider.notifier)
        .establecerAbono(esCredito ? montoCapturado : montoTotal);

    final cajaNotifier = ref.read(cajaProvider.notifier);
    final estado = ref.read(cajaProvider);

    if (!cajaNotifier.validarCobroCompleto()) {
      FiscoGestNotifications.show(
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
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('Seleccione una cotización'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!await _exigirCajaAbierta()) return;

    // Crédito: solo cotizaciones aprobadas
    final repoCheck = ref.read(venta_providers.ventasRepositoryProvider);
    final doc = await repoCheck.obtenerVentaPorId(ventaId);
    if (doc != null) {
      final esCr =
          doc.numeroCotizacion.startsWith('CR-') ||
          doc.estadoDocumento == EstadoDocumento.enCredito ||
          (doc.formaPago.toLowerCase().contains('credito') ||
              doc.formaPago.toLowerCase().contains('crédito'));
      if (esCr && doc.estadoDocumento == EstadoDocumento.enCredito) {
        if (mounted) {
          FiscoGestNotifications.show(
            const SnackBar(
              content: Text(
                'Pendiente de aprobación en Crédito. No se puede facturar aún.',
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      if (esCr &&
          doc.estadoDocumento != EstadoDocumento.aprobado &&
          doc.estadoDocumento != EstadoDocumento.facturado) {
        if (mounted) {
          FiscoGestNotifications.show(
            SnackBar(
              content: Text(
                'Estado ${doc.estadoDocumento.name}: no listo para cobro a crédito',
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    // NCF fiscal se asigna en Caja (B01/B02) justo antes de cobrar
    setState(() => _procesando = true);
    try {
      await _asegurarNcfFiscal(ventaId);
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
      final ventaConDetalle = await repositorio.obtenerVentaPorId(
        venta.id ?? ventaId,
      );
      if (ventaConDetalle == null) {
        throw Exception('No se pudo recargar la venta facturada');
      }
      if (ventaConDetalle.detalles.isEmpty) {
        throw Exception(
          'La cotización ${ventaConDetalle.numeroCotizacion} no tiene productos '
          'guardados en base de datos (ventas_detalle vacío). '
          'Eso ocurre con cotizaciones creadas antes de persistir líneas. '
          'Genere una cotización NUEVA con productos y cobre esa.',
        );
      }
      final inv = ref.read(ventaInventarioServiceProvider);
      await inv.aplicarSalidaInventario(ventaConDetalle);
      // Refrescar listados de inventario / kárdex en UI
      ref.invalidate(productoControllerProvider);
      try {
        ref.invalidate(kardexPorProductoProvider);
      } catch (_) {}

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

      // El cobro queda cerrado antes de ofrecer la impresión o el envío.
      setState(() {
        _modoBusqueda = true;
        ventaId = 0;
        _detalles = [];
        _abonoController.clear();
        _efectivoRecibidoController.clear();
        _referenciaController.clear();
        _procesando = false;
      });
      ref.read(cajaProvider.notifier).limpiar();
      await _cargarPendientes();
      if (!mounted) return;

      final deseaComprobante = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Cobro completado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N° Factura: $numeroFactura',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Ref. Cotización: ${venta.numeroCotizacion}'),
                if (esCredito) ...[
                  const SizedBox(height: 8),
                  Text('Abono: ${formatRd(estado.abono)}'),
                  Text('Saldo: ${formatRd(saldo)}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Más tarde'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Imprimir / enviar'),
              ),
            ],
          );
        },
      );
      if (deseaComprobante == true && mounted) {
        await _opcionesComprobantePdf(ventaConDetalle);
      }
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(
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

  void _aplicarConfigCaja() {
    final cfg = ref.read(configuracionControllerProvider).valueOrNull;
    if (cfg == null || !mounted) return;
    final def = cfg.cajaFormaPagoDefault.toLowerCase();
    FormaPago forma = FormaPago.efectivo;
    if (def.contains('tarjeta')) {
      forma = FormaPago.tarjeta;
    } else if (def.contains('transfer')) {
      forma = FormaPago.transferencia;
    }
    setState(() => _formaPago = forma);
  }

  List<FormaPago> _formasDisponibles({required bool esCredito}) {
    final cfg = ref.read(configuracionControllerProvider).valueOrNull;
    final list = <FormaPago>[FormaPago.efectivo];
    if (cfg?.cajaPermitirTarjeta ?? true) list.add(FormaPago.tarjeta);
    if (cfg?.cajaPermitirTransferencia ?? true) {
      list.add(FormaPago.transferencia);
    }
    if (esCredito) list.add(FormaPago.credito);
    return list;
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

    final lista = _busquedaController.text.trim().isEmpty
        ? _pendientes
        : _resultados;

    return AppScaffold(
      title: 'CAJA — BUSCAR COTIZACIÓN',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            final s = ref.read(sesionProvider);
            context.go(s?.rutaInicio ?? '/ventas/cobro');
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
                                      esPequena ? 14 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                                style: AppTypography.labelMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: tamanoCuerpo,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                v.nombreCliente ??
                                                    'Sin cliente',
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: tamanoCuerpo,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colorEstado.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
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
                                          formatRd(v.montoTotal),
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
    final esPagoEfectivo = !esCredito && _formaPago == FormaPago.efectivo;
    final efectivoRecibido =
        _parseMontoCobro(_efectivoRecibidoController.text) ?? 0.0;
    final cambioADevolver = (efectivoRecibido - montoTotal)
        .clamp(0.0, double.infinity)
        .toDouble();
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
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
                                          formatRd(subtotal),
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

                              // === ENVÍO / DELIVERY (detalle visible) ===
                              if (_costoEnvio > 0.001) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Envío / Delivery',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: tamanoCuerpo,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      formatRd(_costoEnvio),
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: tamanoCuerpo,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                                    formatRd(montoTotal),
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

                        // === COMPROBANTE FISCAL (Caja) ===
                        if (ventaId > 0 &&
                            (ref
                                    .watch(configuracionControllerProvider)
                                    .valueOrNull
                                    ?.modoSimplificado !=
                                true)) ...[
                          Text(
                            'Comprobante fiscal',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('B02 · Consumidor final'),
                                selected: _tipoNcf == 'B02',
                                onSelected: (sel) {
                                  if (sel) setState(() => _tipoNcf = 'B02');
                                },
                              ),
                              ChoiceChip(
                                label: const Text('B01 · Crédito fiscal'),
                                selected: _tipoNcf == 'B01',
                                onSelected: (sel) {
                                  if (sel) setState(() => _tipoNcf = 'B01');
                                },
                              ),
                              ChoiceChip(
                                label: const Text('B14 · Regímenes especiales'),
                                selected: _tipoNcf == 'B14',
                                onSelected: (sel) {
                                  if (sel) setState(() => _tipoNcf = 'B14');
                                },
                              ),
                            ],
                          ),
                          if (_tipoNcf == 'B01') ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _rncFiscalController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText:
                                          'RNC (9) o cédula (11 dígitos)',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      helperText: _rncNombreEncontrado,
                                      helperMaxLines: 2,
                                    ),
                                    onChanged: (_) {
                                      if (_rncNombreEncontrado != null) {
                                        setState(
                                          () => _rncNombreEncontrado = null,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _buscandoRnc
                                      ? const SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : IconButton.filledTonal(
                                          tooltip: 'Buscar RNC en línea',
                                          onPressed: _buscarRncFiscalEnLinea,
                                          icon: const Icon(
                                            Icons.travel_explore,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
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
                          children: _formasDisponibles(esCredito: esCredito)
                              .map((forma) {
                                final sel = _formaPago == forma;
                                return ChoiceChip(
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      forma.nombre,
                                      style: TextStyle(
                                        fontSize: tamanoCuerpo,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  selected: sel,
                                  selectedColor: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  onSelected: (_) {
                                    setState(() => _formaPago = forma);
                                  },
                                  side: sel
                                      ? const BorderSide(
                                          color: AppColors.primary,
                                        )
                                      : const BorderSide(
                                          color: AppColors.border,
                                        ),
                                );
                              })
                              .toList(),
                        ),

                        SizedBox(height: esPequena ? 16 : 20),

                        // === MONTO / ABONO ===
                        Text(
                          esCredito
                              ? 'Abono inicial (según crédito)'
                              : esPagoEfectivo
                              ? 'Efectivo recibido'
                              : 'Monto a pagar',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: tamanoCuerpo,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: esPagoEfectivo
                              ? _efectivoRecibidoController
                              : _abonoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: esCredito || esPagoEfectivo,
                          onChanged: esPagoEfectivo
                              ? (_) => setState(() {})
                              : _onAbonoChanged,
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

                        if (esPagoEfectivo) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cambio a devolver',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: tamanoCuerpo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  formatRd(cambioADevolver),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: tamanoCuerpo + 1,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // === SALDO PENDIENTE (solo crédito) ===
                        if (esCredito) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.warning.withValues(
                                  alpha: 0.30,
                                ),
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
                                  formatRd(estado.saldoPendiente),
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
                    child: Align(
                      alignment: esPequena
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: SizedBox(
                        width: esPequena ? double.infinity : 360,
                        height: alturaBoton,
                        child: ElevatedButton.icon(
                          onPressed: _procesando
                              ? null
                              : _cobrarYGenerarFactura,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
