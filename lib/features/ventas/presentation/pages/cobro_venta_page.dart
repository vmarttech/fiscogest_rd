import 'package:fiscogest_rd/features/ventas/presentation/pages/cobrar_page.dart' show listadoCuentasCobrarProvider;
import 'package:fiscogest_rd/features/creditos/presentation/providers/credito_providers.dart';
import 'package:fiscogest_rd/features/facturacion/presentation/pdf/comprobante_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:fiscogest_rd/features/creditos/domain/entities/cuenta_por_cobrar.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/pronto_pago_acuerdos_dao.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

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
  final FocusNode _focusBusqueda = FocusNode();
  final FocusNode _focusEfectivo = FocusNode();
  final FocusNode _focusRoot = FocusNode();

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
  /// Modo terminal: cotización vs cuenta por cobrar
  bool _modoCxc = false;
  /// Header: venta | cotizacion | cxc (filtra lista izquierda)
  String _filtroModo = 'venta';
  CuentaPorCobrar? _cxcActiva;
  ProntoPagoAcuerdoData? _cxcProntoPago;
  List<CuentaPorCobrar> _cxcPendientes = [];
  final TextEditingController _cxcMontoController = TextEditingController();
  double? _efectivoCajon;
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
      _modoCxc = false;
      _filtroModo = 'venta';
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
      final mapa = <int, Venta>{};
      for (final v in lista) {
        if (v.id != null) mapa[v.id!] = v;
      }
      setState(() {
        _pendientes = mapa.values.toList();
        _cargandoLista = false;
      });
      _refrescarCajon();
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
    _focusBusqueda.dispose();
    _focusEfectivo.dispose();
    _focusRoot.dispose();
    _cxcMontoController.dispose();
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
    // Modo simplificado: cobrar desde ventas sin abrir turno de caja.
    if (cfg?.modoSimplificado == true) return true;
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
    final raw = _rncFiscalController.text.replaceAll(RegExp(r'\D'), '');
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
          rncCliente: _rncFiscalController.text.replaceAll(RegExp(r'\D'), ''),
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
      ref.invalidate(listaVentasProvider);

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


  Future<void> _refrescarCajon() async {
    try {
      final repo = ref.read(cajaRepositoryProvider);
      final sesion = await repo.obtenerSesionAbierta();
      if (sesion == null) {
        if (mounted) setState(() { _efectivoCajon = null; });
        return;
      }
      final resumen = await repo.obtenerResumenSesion(sesion.id);
      if (!mounted) return;
      setState(() {
        _efectivoCajon = resumen.efectivoEsperado;
      });
    } catch (_) {}
  }


  Future<void> _cargarCxcPendientes() async {
    try {
      final repo = ref.read(cuentaPorCobrarRepositoryProvider);
      final todas = await repo.listarCuentas();
      final abiertas = todas
          .where((c) => c.id != null && !c.estaPagada && c.saldoPendiente > 0.009)
          .toList();
      if (!mounted) return;
      setState(() => _cxcPendientes = abiertas);
    } catch (_) {
      if (mounted) setState(() => _cxcPendientes = []);
    }
  }

  Future<void> _seleccionarCxc(CuentaPorCobrar c) async {
    if (c.id == null) return;
    CuentaPorCobrar cuenta = c;
    try {
      final full =
          await ref.read(cuentaPorCobrarRepositoryProvider).obtenerPorId(c.id!);
      if (full != null) cuenta = full;
    } catch (_) {}
    ProntoPagoAcuerdoData? acuerdo;
    try {
      acuerdo = await ProntoPagoAcuerdosDao(ref.read(databaseProvider))
          .activoPorCuenta(c.id!);
    } catch (_) {}
    // Monto sugerido: próxima cuota pendiente, o liquidación pronto pago
    double montoDef = cuenta.saldoPendiente;
    if (acuerdo != null) {
      montoDef = acuerdo.montoLiquidacion;
    } else {
      final plan = cuenta.planPago;
      if (plan != null && plan.cuotas.isNotEmpty) {
        final pend = plan.cuotas.where((q) => !q.pagada).toList();
        if (pend.isNotEmpty) {
          montoDef = pend.first.montoTotal;
        } else if (plan.montoPorCuota > 0) {
          montoDef = plan.montoPorCuota;
        }
      }
    }
    if (montoDef > cuenta.saldoPendiente) montoDef = cuenta.saldoPendiente;
    setState(() {
      _modoCxc = true;
      _filtroModo = 'cxc';
      _cxcActiva = cuenta;
      _cxcProntoPago = acuerdo;
      ventaId = 0;
      _detalles = [];
      _modoBusqueda = false;
      nombreCliente = cuenta.clienteNombre;
      montoTotal = cuenta.saldoPendiente;
      _cxcMontoController.text = montoDef.toStringAsFixed(2);
      _efectivoRecibidoController.text = montoDef.toStringAsFixed(2);
      _formaPago = FormaPago.efectivo;
    });
  }

  void _limpiarTicket() {
    setState(() {
      _filtroModo = 'venta';
      _modoCxc = false;
      _modoCxc = false;
      _cxcActiva = null;
      _cxcProntoPago = null;
      ventaId = 0;
      _detalles = [];
      _modoBusqueda = true;
      _cxcMontoController.clear();
      _efectivoRecibidoController.clear();
      _referenciaController.clear();
    });
    _cargarPendientes();
    _cargarCxcPendientes();
    _focusBusqueda.requestFocus();
  }

  Future<void> _cobrarCxcDesdeTerminal() async {
    if (_procesando || _cxcActiva == null || _cxcActiva!.id == null) return;
    final c = _cxcActiva!;
    final monto = _parseMontoCobro(_cxcMontoController.text) ?? 0;
    if (monto <= 0) {
      FiscoGestNotifications.show(const SnackBar(
        content: Text('Indique un monto válido'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (monto > c.saldoPendiente + 0.01) {
      FiscoGestNotifications.show(SnackBar(
        content: Text('El monto supera el saldo (${formatRd(c.saldoPendiente)})'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!await _exigirCajaAbierta()) return;
    setState(() => _procesando = true);
    try {
      final metodo = _formaPago.nombre;
      await ref.read(databaseProvider).transaction(() async {
        await ref.read(cuentaPorCobrarRepositoryProvider).registrarAbono(
              AbonoCredito(
                cuentaId: c.id!,
                monto: monto,
                metodoPago: metodo,
                fecha: DateTime.now(),
                nota: _cxcProntoPago != null
                    ? 'Liquidación pronto pago · Caja'
                    : 'Abono · Caja',
              ),
            );
        await ref.read(cajaRepositoryProvider).registrarMovimiento(
              referencia: c.numero ?? 'CXC-${c.id}',
              monto: monto,
              tipo: 'ingreso',
              descripcion:
                  'Abono CXC ${c.numero ?? c.id} · ${c.clienteNombre ?? ''}',
              formaPago: metodo,
            );
      });
      if (_cxcProntoPago != null &&
          monto + 0.01 >= _cxcProntoPago!.montoLiquidacion) {
        try {
          await ProntoPagoAcuerdosDao(ref.read(databaseProvider))
              .marcarAplicado(_cxcProntoPago!.id);
        } catch (_) {}
      }
      try {
        ref.invalidate(listadoCuentasCobrarProvider(0));
      } catch (_) {}
      if (!mounted) return;
      FiscoGestNotifications.show(SnackBar(
        content: Text('Abono CXC registrado: ${formatRd(monto)}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _limpiarTicket();
      await _refrescarCajon();
    } catch (e) {
      if (mounted) {
        FiscoGestNotifications.show(SnackBar(
          content: Text('Error al cobrar CXC: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final usarTerminal = ancho >= 900;

    final child = usarTerminal
        ? _buildTerminalPos(context)
        : (_modoBusqueda ? _buildBusqueda(context) : _buildCobro(context));

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f2): () {
          if (usarTerminal || _modoBusqueda) {
            _focusBusqueda.requestFocus();
          } else {
            setState(() {
              _modoBusqueda = true;
              ventaId = 0;
              _detalles = [];
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusBusqueda.requestFocus();
            });
          }
        },
        const SingleActivator(LogicalKeyboardKey.f12): () {
          if (_procesando) return;
          if (_modoCxc && _cxcActiva != null) {
            _cobrarCxcDesdeTerminal();
          } else if (ventaId > 0) {
            _cobrarYGenerarFactura();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _limpiarTicket();
        },
        const SingleActivator(LogicalKeyboardKey.f8): () {
          setState(() {
            if (_tipoNcf == 'B02') {
              _tipoNcf = 'B01';
            } else if (_tipoNcf == 'B01') {
              _tipoNcf = 'B14';
            } else {
              _tipoNcf = 'B02';
            }
          });
        },
        const SingleActivator(LogicalKeyboardKey.f3): () {
          setState(() {
            _filtroModo = 'cotizacion';
            _modoCxc = false;
            _cxcActiva = null;
            _cxcProntoPago = null;
          });
          _focusBusqueda.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.f6): () {
          setState(() {
            _filtroModo = 'cxc';
            _modoCxc = true;
            ventaId = 0;
            _detalles = [];
          });
          _cargarCxcPendientes();
          _focusBusqueda.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.f4): () {
          _mostrarArqueoRapido();
        },
      },
      child: Focus(
        autofocus: true,
        focusNode: _focusRoot,
        child: child,
      ),
    );
  }

  /// Terminal POS 2 paneles (desktop/tablet ancha).
  Future<void> _mostrarArqueoRapido() async {
    final repo = ref.read(cajaRepositoryProvider);
    final sesion = await repo.obtenerSesionAbierta();
    if (sesion == null || !mounted) {
      FiscoGestNotifications.show(
        const SnackBar(
          content: Text('No hay sesión de caja abierta.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final resumen = await repo.obtenerResumenSesion(sesion.id);
    final teorico = resumen.efectivoEsperado;
    final dens = <int, TextEditingController>{
      2000: TextEditingController(text: '0'),
      1000: TextEditingController(text: '0'),
      500: TextEditingController(text: '0'),
      200: TextEditingController(text: '0'),
      100: TextEditingController(text: '0'),
      50: TextEditingController(text: '0'),
      25: TextEditingController(text: '0'),
      10: TextEditingController(text: '0'),
      5: TextEditingController(text: '0'),
      1: TextEditingController(text: '0'),
    };
    final obsCtrl = TextEditingController();

    if (!mounted) return;
    final result = await showDialog<({double contado, String? obs})>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            double contado = 0;
            for (final e in dens.entries) {
              final n = int.tryParse(e.value.text.trim()) ?? 0;
              contado += e.key * n;
            }
            final dif = contado - teorico;
            final Color difColor;
            final String difLabel;
            if (dif.abs() < 0.005) {
              difColor = const Color(0xFF059669);
              difLabel = 'Cuadre exacto';
            } else if (dif > 0) {
              difColor = const Color(0xFF2563EB);
              difLabel = 'Sobrante';
            } else {
              difColor = const Color(0xFFDC2626);
              difLabel = 'Faltante';
            }
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Arqueo & Cierre de Caja',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        'Sesión #${sesion.id} · Fondo ${formatRd(resumen.fondoInicial)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '+ Ingresos ef. ${formatRd(resumen.ingresosEfectivo)}'
                        '  − Egresos ${formatRd(resumen.egresosEfectivo)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Esperado en Caja',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B))),
                                  const SizedBox(height: 4),
                                  Text(formatRd(teorico),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Conteo Físico',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF065F46))),
                                  const SizedBox(height: 4),
                                  Text(formatRd(contado),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF047857))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: difColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: difColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Text(difLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: difColor)),
                            const Spacer(),
                            Text(formatRd(dif),
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: difColor,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Denominaciones (RD\$)',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final d in dens.keys)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 72,
                                      child: Text(
                                        formatRd(d.toDouble()),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                    ),
                                    const Text('×',
                                        style: TextStyle(
                                            color: Color(0xFF94A3B8))),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 72,
                                      child: TextField(
                                        controller: dens[d],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (_) => setLocal(() {}),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      formatRd(d *
                                          (int.tryParse(
                                                  dens[d]!.text.trim()) ??
                                              0)
                                              .toDouble()),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: obsCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Observación (si hay diferencia)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            if (dif.abs() >= 0.005 &&
                                obsCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Explique el faltante o sobrante antes de cerrar.'),
                                  backgroundColor: Color(0xFFD97706),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx, (
                              contado: contado,
                              obs: obsCtrl.text.trim().isEmpty
                                  ? null
                                  : obsCtrl.text.trim(),
                            ));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'CERRAR TURNO Y GENERAR INFORME Z',
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    for (final c in dens.values) {
      c.dispose();
    }
    obsCtrl.dispose();
    if (result == null || !mounted) return;

    try {
      final ok = await repo.cerrarSesion(
        sesionId: sesion.id,
        saldoTeorico: teorico,
        montoContado: result.contado,
        observacion: result.obs,
      );
      if (!mounted) return;
      if (ok) {
        FiscoGestNotifications.show(
          SnackBar(
            content: Text(
              'Turno cerrado. Diferencia: ${formatRd(result.contado - teorico)}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF059669),
          ),
        );
        // Volver a inicio de caja (abrir de nuevo si hace falta)
        if (context.mounted) {
          context.go('/ventas/cobro');
        }
      } else {
        FiscoGestNotifications.show(
          const SnackBar(
            content: Text('No se pudo cerrar la sesión.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      FiscoGestNotifications.show(
        SnackBar(
          content: Text('Error al cerrar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  Widget _buildTerminalPos(BuildContext context) {
    final listaRaw = _busquedaController.text.trim().isEmpty
        ? _pendientes
        : _resultados;
    // Filtrar lista según modo del header (respeta búsqueda en listaRaw)
    final lista = switch (_filtroModo) {
      'cotizacion' => listaRaw
          .where((v) => v.numeroCotizacion.toUpperCase().startsWith('C'))
          .toList(),
      'cxc' => <Venta>[], // CxC usa _cxcPendientes / panel propio
      _ => List<Venta>.from(listaRaw), // VENTA: pendientes o resultados de búsqueda
    };
    ref.watch(cajaProvider);
    final esPagoEfectivo = !esCredito && _formaPago == FormaPago.efectivo;
    final efectivoRecibido =
        _parseMontoCobro(_efectivoRecibidoController.text) ?? 0.0;
    final montoCobrar = _modoCxc
        ? (_parseMontoCobro(_cxcMontoController.text) ?? 0.0)
        : (esCredito
            ? (_parseMontoCobro(_abonoController.text) ?? 0.0)
            : montoTotal);
    final cambioADevolver =
        (efectivoRecibido - montoCobrar).clamp(0.0, double.infinity).toDouble();
    final hayTicket = ventaId > 0 || (_modoCxc && _cxcActiva != null);
    final qBusq = _busquedaController.text.trim().toLowerCase();
    final cxcFiltradas = (_filtroModo == 'cxc' || _filtroModo == 'venta')
        ? (qBusq.isEmpty
            ? _cxcPendientes
            : _cxcPendientes.where((c) {
                final n = (c.numero ?? '').toLowerCase();
                final cl = (c.clienteNombre ?? '').toLowerCase();
                return n.contains(qBusq) || cl.contains(qBusq);
              }).toList())
        : <CuentaPorCobrar>[];
    final showCxcList = _filtroModo == 'cxc';
    final showVentaList = _filtroModo != 'cxc';

    // Totales línea (venta)
    double gravado = 0, exento = 0, itbisLineas = 0;
    for (final d in _detalles) {
      final sub = d.subtotal > 0 ? d.subtotal : d.cantidad * d.precioUnitario;
      final tasa = d.tasaImpuesto;
      final pct = tasa > 1.5 ? tasa : tasa * 100;
      if (pct <= 0.001) {
        exento += sub;
      } else {
        gravado += sub;
        itbisLineas += sub * (tasa > 1.5 ? tasa / 100.0 : tasa);
      }
    }

    Color modoColor(String m) {
      if (m == 'cxc') return const Color(0xFF7C3AED);
      if (m == 'cotizacion') return const Color(0xFF2563EB);
      return const Color(0xFF059669);
    }

    Widget modoChip(String id, String label) {
      final sel = _filtroModo == id;
      final c = modoColor(id);
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: sel ? c.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              setState(() {
                _filtroModo = id;
                if (id == 'cxc') {
                  _modoCxc = true;
                  ventaId = 0;
                  _detalles = [];
                  _cargarCxcPendientes();
                } else {
                  if (_modoCxc && id != 'cxc') {
                    _modoCxc = false;
                    _cxcActiva = null;
                    _cxcProntoPago = null;
                  }
                }
              });
              _focusBusqueda.requestFocus();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? c : const Color(0xFFE2E8F0),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: sel ? c : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget fBtn(String key, String label, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            foregroundColor: const Color(0xFF334155),
          ),
          child: Text('$key $label',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: const {},
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            // ═══════ HEADER ═══════
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAJA UNIFICADA',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Color(0xFF0F172A))),
                      Text('Venta · Cotización · CxC',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(width: 20),
                  modoChip('venta', 'VENTA'),
                  modoChip('cotizacion', 'COTIZACIÓN'),
                  modoChip('cxc', 'CXC'),
                  const Spacer(),
                  fBtn('[F3]', 'Cotiz.', () {
                    setState(() {
                      _filtroModo = 'cotizacion';
                      _modoCxc = false;
                      _cxcActiva = null;
                    });
                    _focusBusqueda.requestFocus();
                  }),
                  fBtn('[F6]', 'CxC', () {
                    setState(() {
                      _filtroModo = 'cxc';
                      _modoCxc = true;
                      ventaId = 0;
                      _detalles = [];
                    });
                    _cargarCxcPendientes();
                    _focusBusqueda.requestFocus();
                  }),
                  fBtn('[F4]', 'Arqueo', _mostrarArqueoRapido),
                ],
              ),
            ),
            // ═══════ 2 COLUMNAS ═══════
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── IZQUIERDA: búsqueda + líneas / lista ──
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Row(
                              children: [
                                Text(
                                  showCxcList
                                      ? 'BUSCAR CUENTA CXC'
                                      : 'BUSCAR TICKET / COTIZACIÓN',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('F2',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1D4ED8))),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            child: TextField(
                              controller: _busquedaController,
                              focusNode: _focusBusqueda,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _buscar(),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: showCxcList
                                    ? 'N° CXC o cliente…'
                                    : 'N° cotización o cliente…',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                          ),
                          if (_errorBusqueda != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(_errorBusqueda!,
                                  style: const TextStyle(
                                      color: Color(0xFFBE123C), fontSize: 12)),
                            ),
                          // Cabecera tipo tabla
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            color: const Color(0xFFF8FAFC),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    hayTicket && !_modoCxc
                                        ? 'DESCRIPCIÓN'
                                        : (showCxcList ? 'CUENTA / CLIENTE' : 'DOCUMENTO'),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                ),
                                if (hayTicket && !_modoCxc) ...[
                                  const SizedBox(
                                    width: 48,
                                    child: Text('CANT',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF94A3B8))),
                                  ),
                                  const SizedBox(
                                    width: 80,
                                    child: Text('TOTAL',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF94A3B8))),
                                  ),
                                ] else
                                  const SizedBox(
                                    width: 90,
                                    child: Text('MONTO',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF94A3B8))),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _cargandoLista
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : (hayTicket && !_modoCxc)
                                    ? _buildLineasVenta()
                                    : (hayTicket && _modoCxc)
                                        ? _buildPanelCxcDetalle()
                                        : _buildListaPendientes(
                                            showVentaList ? lista : const [],
                                            showCxcList
                                                ? cxcFiltradas
                                                : (_filtroModo == 'venta'
                                                    ? cxcFiltradas
                                                    : const []),
                                          ),
                          ),
                          // Totales inferiores izquierda
                          if (hayTicket && !_modoCxc)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              child: Column(
                                children: [
                                  _totRow('Exento', formatRd(exento)),
                                  _totRow('Gravado', formatRd(gravado)),
                                  _totRow('ITBIS', formatRd(itbisLineas)),
                                  const Divider(height: 12),
                                  _totRow('TOTAL', formatRd(montoTotal),
                                      bold: true, green: true),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _limpiarTicket,
                                      child: const Text('Cambiar ticket (Esc)'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (hayTicket && _modoCxc && _cxcActiva != null)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              child: Column(
                                children: [
                                  _totRow('Saldo pendiente',
                                      formatRd(_cxcActiva!.saldoPendiente),
                                      bold: true, green: true),
                                  if (_cxcProntoPago != null)
                                    _totRow(
                                      'Liquidación pronto pago',
                                      formatRd(
                                          _cxcProntoPago!.montoLiquidacion),
                                      bold: true,
                                    ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _limpiarTicket,
                                      child: const Text('Cambiar cuenta (Esc)'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // ── DERECHA: cobro ──
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: !hayTicket
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.point_of_sale,
                                      size: 48, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 12),
                                  Text(
                                    'Seleccione un documento o busque con F2',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8), fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Cliente
                                  const Text('CLIENTE',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.4)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      (_modoCxc
                                              ? (_cxcActiva?.clienteNombre ??
                                                  'Cliente')
                                              : (nombreCliente ??
                                                  'Consumidor final'))
                                          .trim(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  if (!_modoCxc) ...[
                                    const Text('1. COMPROBANTE FISCAL (DGII)',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.4)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        for (final ncf
                                            in ['B02', 'B01', 'B14']) ...[
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 6),
                                              child: Material(
                                                color: _tipoNcf == ncf
                                                    ? const Color(0xFFDBEAFE)
                                                    : const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: InkWell(
                                                  onTap: () => setState(
                                                      () => _tipoNcf = ncf),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            vertical: 12),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: _tipoNcf == ncf
                                                            ? const Color(
                                                                0xFF3B82F6)
                                                            : const Color(
                                                                0xFFE2E8F0),
                                                        width: _tipoNcf == ncf
                                                            ? 2
                                                            : 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(ncf,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              fontSize: 13,
                                                              color: _tipoNcf ==
                                                                      ncf
                                                                  ? const Color(
                                                                      0xFF1D4ED8)
                                                                  : const Color(
                                                                      0xFF475569),
                                                            )),
                                                        Text(
                                                          ncf == 'B02'
                                                              ? 'Consumidor'
                                                              : ncf == 'B01'
                                                                  ? 'Crédito fiscal'
                                                                  : 'Especial',
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Color(
                                                                  0xFF94A3B8)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (_tipoNcf == 'B01' ||
                                        _tipoNcf == 'B14') ...[
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _rncFiscalController,
                                        decoration: InputDecoration(
                                          labelText: 'RNC / Cédula cliente',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          isDense: true,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                  ] else ...[
                                    // CXC: banner pronto pago + monto cuota
                                    if (_cxcProntoPago != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: const Color(0xFFC7D2FE)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('PRONTO PAGO ACTIVO',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF4F46E5))),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Liquidar por ${formatRd(_cxcProntoPago!.montoLiquidacion)}'
                                              ' (desc. interés ${formatRd(_cxcProntoPago!.descuentoMonto)})',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            if (_cxcProntoPago!
                                                    .cuotasPendientes >
                                                0)
                                              Text(
                                                '${_cxcProntoPago!.cuotasPendientes} cuota(s) pendientes cubiertas al liquidar',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    const Text('MONTO A ABONAR',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF64748B))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _cxcMontoController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        prefixText: 'RD\$ ',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            final c = _cxcActiva;
                                            if (c == null) return;
                                            final plan = c.planPago;
                                            double m = c.saldoPendiente;
                                            if (plan != null &&
                                                plan.cuotas.isNotEmpty) {
                                              final pend = plan.cuotas
                                                  .where((q) => !q.pagada)
                                                  .toList();
                                              if (pend.isNotEmpty) {
                                                m = pend.first.montoTotal;
                                              }
                                            }
                                            _cxcMontoController.text =
                                                m.toStringAsFixed(2);
                                            _efectivoRecibidoController.text =
                                                m.toStringAsFixed(2);
                                            setState(() {});
                                          },
                                          child: const Text('1 cuota'),
                                        ),
                                        if (_cxcProntoPago != null)
                                          TextButton(
                                            onPressed: () {
                                              final m = _cxcProntoPago!
                                                  .montoLiquidacion;
                                              _cxcMontoController.text =
                                                  m.toStringAsFixed(2);
                                              _efectivoRecibidoController
                                                  .text = m.toStringAsFixed(2);
                                              setState(() {});
                                            },
                                            child: const Text('Liquidar PP'),
                                          ),
                                        TextButton(
                                          onPressed: () {
                                            final m =
                                                _cxcActiva?.saldoPendiente ?? 0;
                                            _cxcMontoController.text =
                                                m.toStringAsFixed(2);
                                            _efectivoRecibidoController.text =
                                                m.toStringAsFixed(2);
                                            setState(() {});
                                          },
                                          child: const Text('Saldo total'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  const Text('2. FORMA DE PAGO',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.4)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      for (final f in _formasDisponibles(
                                          esCredito: esCredito && !_modoCxc))
                                        ChoiceChip(
                                          label: Text(f.nombre),
                                          selected: _formaPago == f,
                                          onSelected: (_) {
                                            setState(() => _formaPago = f);
                                            if (f == FormaPago.efectivo) {
                                              _efectivoRecibidoController
                                                      .text =
                                                  montoCobrar
                                                      .toStringAsFixed(2);
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                _focusEfectivo.requestFocus();
                                              });
                                            }
                                          },
                                          selectedColor:
                                              const Color(0xFFD1FAE5),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  if (esPagoEfectivo) ...[
                                    const Text('3. EFECTIVO RECIBIDO',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF64748B))),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _efectivoRecibidoController,
                                      focusNode: _focusEfectivo,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        prefixText: 'RD\$ ',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            _efectivoRecibidoController.text =
                                                montoCobrar.toStringAsFixed(2);
                                            setState(() {});
                                          },
                                          child: const Text('Exacto'),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Cambio: ${formatRd(cambioADevolver)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Color(0xFF059669)),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const Text('3. REFERENCIA',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF64748B))),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _referenciaController,
                                      decoration: InputDecoration(
                                        hintText: 'N° referencia',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                  if (esCredito && !_modoCxc) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _abonoController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Abono inicial',
                                        prefixText: 'RD\$ ',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _modoCxc
                                              ? 'A ABONAR'
                                              : 'TOTAL A COBRAR',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13),
                                        ),
                                        const Spacer(),
                                        Text(
                                          formatRd(montoCobrar),
                                          style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF059669)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 54,
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _procesando
                                          ? null
                                          : (_modoCxc
                                              ? _cobrarCxcDesdeTerminal
                                              : _cobrarYGenerarFactura),
                                      icon: _procesando
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.check_circle),
                                      label: Text(
                                        _procesando
                                            ? 'Procesando…'
                                            : (_modoCxc
                                                ? 'REGISTRAR ABONO (F12)'
                                                : 'PROCESAR COBRO (F12)'),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Atajos: F2 Buscar · F3 Cotiz · F6 CxC · F4 Arqueo · F12 Cobrar · Esc Limpiar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // ═══════ FOOTER ═══════
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Text('Efectivo en cajón: ',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12)),
                  Text(formatRd(_efectivoCajon ?? 0),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Sesión abierta',
                        style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  Text(
                    'F2 · F3 · F4 · F6 · F8 NCF · F12 · Esc',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _mostrarArqueoRapido,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('Arqueo (F4)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totRow(String k, String v, {bool bold = false, bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(k,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: const Color(0xFF475569),
              )),
          const Spacer(),
          Text(v,
              style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: FontWeight.w900,
                color: green ? const Color(0xFF059669) : const Color(0xFF0F172A),
              )),
        ],
      ),
    );
  }

  Widget _buildLineasVenta() {
    if (_detalles.isEmpty) {
      return const Center(
          child: Text('Sin líneas en el ticket',
              style: TextStyle(color: Color(0xFF94A3B8))));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: _detalles.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final d = _detalles[i];
        final nom = (d.nombreProducto ?? '').trim().isNotEmpty
            ? d.nombreProducto!.trim()
            : 'Producto #${d.productoId}';
        final sub =
            d.subtotal > 0 ? d.subtotal : d.cantidad * d.precioUnitario;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                width: 48,
                child: Text(d.cantidad.toStringAsFixed(
                        d.cantidad == d.cantidad.roundToDouble() ? 0 : 2),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13)),
              ),
              SizedBox(
                width: 80,
                child: Text(formatRd(sub),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanelCxcDetalle() {
    final c = _cxcActiva;
    if (c == null) return const SizedBox.shrink();
    final plan = c.planPago;
    final cuotas = plan?.cuotas ?? const [];
    final pend = cuotas.where((q) => !q.pagada).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      children: [
        Text(c.numero ?? 'CXC-${c.id}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        Text(c.clienteNombre ?? 'Cliente',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 8),
        if (_cxcProntoPago != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Pronto pago: liquidar ${formatRd(_cxcProntoPago!.montoLiquidacion)} '
              '(${_cxcProntoPago!.cuotasPendientes} cuotas · desc. ${formatRd(_cxcProntoPago!.descuentoMonto)})',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4338CA)),
            ),
          ),
        if (plan != null) ...[
          Text(
            '${plan.numeroCuotas} cuotas de ${formatRd(plan.montoPorCuota)}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 6),
        ],
        if (pend.isEmpty && cuotas.isEmpty)
          const Text('Sin plan de cuotas — abono libre al saldo.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        for (final q in (pend.isEmpty ? cuotas : pend).take(12))
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: q.pagada
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: q.pagada
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Text('#${q.numeroCuota}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${q.fechaVencimiento.day.toString().padLeft(2, '0')}/'
                    '${q.fechaVencimiento.month.toString().padLeft(2, '0')}/'
                    '${q.fechaVencimiento.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(q.pagada ? 'Pagada' : formatRd(q.montoTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: q.pagada
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildListaPendientes(
      List<Venta> lista, List<CuentaPorCobrar> cxcFiltradas) {
    if (lista.isEmpty && cxcFiltradas.isEmpty) {
      return Center(
        child: Text(
          _busquedaController.text.trim().isEmpty
              ? 'No hay documentos pendientes'
              : 'Sin resultados',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: lista.length + cxcFiltradas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        if (i >= lista.length) {
          final c = cxcFiltradas[i - lista.length];
          final sel = _modoCxc && _cxcActiva?.id == c.id;
          return Material(
            color: sel ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _seleccionarCxc(c),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('CXC',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4F46E5))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.numero ?? 'CXC-${c.id}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(c.clienteNombre ?? 'Cliente',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                          Text(
                            '${c.numeroCuotas} cuota(s) · saldo ${formatRd(c.saldoPendiente)}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Text(formatRd(c.saldoPendiente),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        }
        final v = lista[i];
        final ok = _listaParaCobrar(v);
        final sel = !_modoCxc && v.id == ventaId;
        return Material(
          color: sel ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: ok
                ? () {
                    setState(() {
                      _modoCxc = false;
                      _cxcActiva = null;
                      _cxcProntoPago = null;
                    });
                    _seleccionarVenta(v);
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? const Color(0xFF34D399)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('N° ${v.numeroCotizacion}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(v.nombreCliente ?? 'Sin cliente',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Text(formatRd(v.montoTotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ),
          ),
        );
      },
    );
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
