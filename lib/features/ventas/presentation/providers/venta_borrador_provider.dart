import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/ventas/domain/enums/estado_documento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/listas_ventas_providers.dart';

@immutable
class VentaBorradorState {
  const VentaBorradorState({
    this.id,
    required this.numero,
    required this.fecha,
    this.vencimiento,
    this.clienteId,
    this.clienteNombre,
    this.clienteTelefono,
    this.clienteWhatsapp,
    this.clienteDireccion,
    required this.subtotal,
    required this.itbis,
    this.costoEnvio = 0.0,
    this.descuento,
    this.descuentoId,
    this.descuentoNombre,
    required this.montoDescuento,
    required this.montoTotal,
    this.tipoPago = 'Contado',
    this.esCredito = false,
    this.detalles = const [],
    this.estadoDocumento = EstadoDocumento.borrador,
    this.modoCotizacion = false,
    this.usuarioId = 1,
  });

  final int? id;
  final String numero;
  final DateTime fecha;
  final DateTime? vencimiento;
  final int? clienteId;
  final String? clienteNombre;
  final String? clienteTelefono;
  final String? clienteWhatsapp;
  final String? clienteDireccion;
  final double subtotal;
  final double itbis;
  final double costoEnvio;
  final double? descuento;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
  final double montoTotal;
  final String tipoPago;
  final bool esCredito;
  final List<Map<String, dynamic>> detalles;
  final EstadoDocumento estadoDocumento;
  final bool modoCotizacion;
  final int usuarioId;

  VentaBorradorState copyWith({
    int? id,
    String? numero,
    DateTime? fecha,
    DateTime? vencimiento,
    int? clienteId,
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteWhatsapp,
    String? clienteDireccion,
    double? subtotal,
    double? itbis,
    double? costoEnvio,
    double? descuento,
    int? descuentoId,
    String? descuentoNombre,
    double? montoDescuento,
    double? montoTotal,
    String? tipoPago,
    bool? esCredito,
    List<Map<String, dynamic>>? detalles,
    EstadoDocumento? estadoDocumento,
    bool? modoCotizacion,
    int? usuarioId,
  }) {
    return VentaBorradorState(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      fecha: fecha ?? this.fecha,
      vencimiento: vencimiento ?? this.vencimiento,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteWhatsapp: clienteWhatsapp ?? this.clienteWhatsapp,
      clienteDireccion: clienteDireccion ?? this.clienteDireccion,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      descuento: descuento ?? this.descuento,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      montoTotal: montoTotal ?? this.montoTotal,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
      estadoDocumento: estadoDocumento ?? this.estadoDocumento,
      modoCotizacion: modoCotizacion ?? this.modoCotizacion,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}

class VentaBorradorNotifier extends StateNotifier<VentaBorradorState> {
  VentaBorradorNotifier(this._ref)
    : super(
        VentaBorradorState(
          numero: '',
          fecha: DateTime.now(),
          subtotal: 0.0,
          itbis: 0.0,
          costoEnvio: 0.0,
          descuento: 0.0,
          montoDescuento: 0.0,
          montoTotal: 0.0,
        ),
      );

  final Ref _ref;

  /// 0 en modo simplificado; 18% en operación fiscal.
  double get _tasaItbis {
    final simp =
        _ref
            .read(configuracionControllerProvider)
            .valueOrNull
            ?.modoSimplificado ??
        false;
    return simp ? 0.0 : 0.18;
  }

  void establecerModoCotizacion() {
    state = state.copyWith(modoCotizacion: true);
  }

  void establecerModoVenta() {
    state = state.copyWith(modoCotizacion: false);
  }

  void seleccionarCliente(
    int id,
    String nombre, {
    String? telefono,
    String? whatsapp,
    String? direccion,
  }) {
    state = state.copyWith(
      clienteId: id,
      clienteNombre: nombre,
      clienteTelefono: telefono,
      clienteWhatsapp: whatsapp,
      clienteDireccion: direccion,
    );
  }

  void establecerConsumidorFinal() {
    state = state.copyWith(clienteId: 0, clienteNombre: 'Consumidor Final');
  }

  void establecerVencimiento(DateTime fecha) {
    state = state.copyWith(vencimiento: fecha);
  }

  void establecerNumeroCotizacion(String numero) {
    state = state.copyWith(numero: numero);
  }

  void establecerEstadoDocumento(EstadoDocumento estado) {
    state = state.copyWith(estadoDocumento: estado);
  }

  /// Contado o Crédito — afecta formaPago guardada y prefijo del número.
  void establecerFormaPago({required bool esCredito}) {
    state = state.copyWith(
      esCredito: esCredito,
      tipoPago: esCredito ? 'Credito' : 'Contado',
    );
  }

  void agregarProducto(Producto producto, double cantidad) {
    final nuevosDetalles = List<Map<String, dynamic>>.from(state.detalles);
    final precioUnitario = producto.precioVenta;
    final indice = nuevosDetalles.indexWhere(
      (item) => item['productoId'] == producto.id,
    );
    if (indice >= 0) {
      nuevosDetalles[indice]['cantidad'] =
          (nuevosDetalles[indice]['cantidad'] as double) + cantidad;
      nuevosDetalles[indice]['subtotal'] =
          (nuevosDetalles[indice]['cantidad'] as double) * precioUnitario;
    } else {
      nuevosDetalles.add({
        'productoId': producto.id,
        'productoNombre': producto.nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'subtotal': cantidad * precioUnitario,
      });
    }
    final nuevoSubtotal = nuevosDetalles.fold<double>(
      0.0,
      (sum, item) => sum + (item['subtotal'] as double),
    );
    _recalcularTotal(nuevoSubtotal: nuevoSubtotal, detalles: nuevosDetalles);
  }

  void quitarProducto(int productoId) {
    final nuevosDetalles = state.detalles
        .where((item) => item['productoId'] != productoId)
        .toList();
    final nuevoSubtotal = nuevosDetalles.fold<double>(
      0.0,
      (sum, item) => sum + (item['subtotal'] as double),
    );
    _recalcularTotal(nuevoSubtotal: nuevoSubtotal, detalles: nuevosDetalles);
  }

  void _recalcularTotal({
    double? nuevoSubtotal,
    double? nuevoItbis,
    double? nuevoEnvio,
    double? nuevoDescuento,
    List<Map<String, dynamic>>? detalles,
  }) {
    final subt = nuevoSubtotal ?? state.subtotal;
    final tasaItbis = _tasaItbis;
    final itb = nuevoItbis ?? subt * tasaItbis;
    final env = nuevoEnvio ?? state.costoEnvio;
    final desc = nuevoDescuento ?? state.montoDescuento;
    final total = subt + itb + env - desc;
    state = state.copyWith(
      subtotal: subt,
      itbis: itb,
      costoEnvio: env,
      montoDescuento: desc,
      montoTotal: total,
      detalles: detalles,
    );
  }

  void asignarCostoEnvio(double valor) {
    _recalcularTotal(nuevoEnvio: valor);
  }

  void aplicarDescuento(double valor) {
    final baseImponible = state.subtotal - valor;
    final tasaItbis = _tasaItbis;
    final nuevoItbis = baseImponible * tasaItbis;
    final subtMasItbis = baseImponible + nuevoItbis;
    final nuevoTotal = subtMasItbis + state.costoEnvio;
    state = state.copyWith(
      descuento: valor,
      montoDescuento: valor,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }

  void quitarDescuento() {
    final baseImponible = state.subtotal;
    final tasaItbis = _tasaItbis;
    final nuevoItbis = baseImponible * tasaItbis;
    final subtMasItbis = baseImponible + nuevoItbis;
    final nuevoTotal = subtMasItbis + state.costoEnvio;
    state = state.copyWith(
      descuento: 0.0,
      descuentoId: null,
      descuentoNombre: null,
      montoDescuento: 0.0,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }

  void vaciar() {
    state = VentaBorradorState(
      numero: '',
      fecha: DateTime.now(),
      subtotal: 0.0,
      itbis: 0.0,
      costoEnvio: 0.0,
      descuento: 0.0,
      montoDescuento: 0.0,
      montoTotal: 0.0,
      tipoPago: 'Contado',
      esCredito: false,
      detalles: const [],
      estadoDocumento: EstadoDocumento.borrador,
      modoCotizacion: false,
    );
  }

  bool validarAntesDeGuardar() {
    final bool tieneCliente =
        state.clienteId != null &&
        state.clienteId! >= 0 &&
        (state.clienteNombre?.trim().isNotEmpty ?? false);
    final bool tieneProductos =
        state.detalles.isNotEmpty && state.montoTotal > 0;
    final bool numeroGenerado = state.numero.trim().isNotEmpty;
    if (!tieneCliente) return false;
    if (!tieneProductos) return false;
    if (!numeroGenerado) return false;
    return true;
  }

  Future<String?> guardar() async {
    if (!validarAntesDeGuardar()) return null;
    final repositorio = _ref.read(ventasRepositoryProvider);
    final venta = Venta(
      id: state.id,
      numeroCotizacion: state.numero,
      numeroFactura: null,
      clienteId: state.clienteId ?? 0,
      nombreCliente: state.clienteNombre,
      clienteTelefono: state.clienteTelefono,
      clienteWhatsapp: state.clienteWhatsapp,
      clienteDireccion: state.clienteDireccion,
      fecha: state.fecha,
      vencimiento: state.vencimiento,
      detalles: state.detalles.map((m) {
        final cant = (m['cantidad'] as num?)?.toDouble() ?? 0.0;
        final precio = (m['precioUnitario'] as num?)?.toDouble() ?? 0.0;
        final sub = (m['subtotal'] as num?)?.toDouble() ?? (cant * precio);
        final pid = m['productoId'];
        final productoId = pid is int ? pid : int.tryParse('$pid') ?? 0;
        return DetalleVenta(
          productoId: productoId,
          cantidad: cant.round().clamp(1, 999999),
          precioUnitario: precio,
          subtotal: sub,
          nombreProducto: m['productoNombre'] as String?,
          subtotalLinea: sub,
        );
      }).toList(),
      montoSubtotal: state.subtotal,
      descuentoGlobal: state.descuento ?? 0.0,
      itbis: state.itbis,
      montoTotal: state.montoTotal,
      formaPago: state.tipoPago,
      costoEnvio: state.costoEnvio,
      abonoInicial: 0.0,
      estadoDocumento: state.estadoDocumento,
      usuarioId: state.usuarioId,
      fechaRegistro: DateTime.now(),
      descuentoId: state.descuentoId,
      descuentoNombre: state.descuentoNombre,
      montoDescuento: state.montoDescuento,
    );
    final guardada = await repositorio.registrarVentaBorrador(venta);
    state = state.copyWith(id: guardada.id);
    return state.numero.trim();
  }
}

final ventaBorradorProvider =
    StateNotifierProvider<VentaBorradorNotifier, VentaBorradorState>((ref) {
      return VentaBorradorNotifier(ref);
    });
