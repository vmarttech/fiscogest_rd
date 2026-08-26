import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta_borrador.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/editar_venta_borrador.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_cotizacion_service.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

@immutable
class VentaBorradorState {
  const VentaBorradorState({
    required this.numero,
    required this.fecha,
    this.vencimiento,
    this.clienteId,
    this.clienteNombre,
    required this.subtotal,
    required this.itbis,
    required this.descuento,
    this.descuentoId,
    this.descuentoNombre,
    required this.montoDescuento,
    required this.montoTotal,
    this.tipoPago = 'Contado',
    this.esCredito = false,
    this.detalles = const [],
  });

  final String numero;
  final DateTime fecha;
  final DateTime? vencimiento;
  final int? clienteId;
  final String? clienteNombre;
  final double subtotal;
  final double itbis;
  final double descuento;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
  final double montoTotal;
  final String tipoPago;
  final bool esCredito;
  final List<dynamic> detalles;

  VentaBorradorState copyWith({
    String? numero,
    DateTime? fecha,
    DateTime? vencimiento,
    int? clienteId,
    String? clienteNombre,
    double? subtotal,
    double? itbis,
    double? descuento,
    int? descuentoId,
    String? descuentoNombre,
    double? montoDescuento,
    double? montoTotal,
    String? tipoPago,
    bool? esCredito,
    List<dynamic>? detalles,
  }) {
    return VentaBorradorState(
      numero: numero ?? this.numero,
      fecha: fecha ?? this.fecha,
      vencimiento: vencimiento ?? this.vencimiento,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      subtotal: subtotal ?? this.subtotal,
      itbis: itbis ?? this.itbis,
      descuento: descuento ?? this.descuento,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      montoTotal: montoTotal ?? this.montoTotal,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
    );
  }
}

class VentaBorradorNotifier extends StateNotifier<VentaBorradorState> {

  VentaBorradorNotifier(this._ref)
      : super(VentaBorradorState(
          numero: '',
          fecha: DateTime.now(),
          subtotal: 0.0,
          itbis: 0.0,
          descuento: 0.0,
          montoDescuento: 0.0,
          montoTotal: 0.0,
        ));
  final Ref _ref;

  void seleccionarCliente(int id, String nombre) {
    state = state.copyWith(clienteId: id, clienteNombre: nombre);
  }

  void establecerVencimiento(DateTime fecha) {
    state = state.copyWith(vencimiento: fecha);
  }

  void aplicarDescuento(double valor) {
    final baseImponible = state.subtotal - valor;
    const tasaItbis = 0.18;
    final nuevoItbis = baseImponible * tasaItbis;
    final nuevoTotal = baseImponible + nuevoItbis;
    state = state.copyWith(
      descuento: valor,
      montoDescuento: valor,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }

  void quitarDescuento() {
    final baseImponible = state.subtotal;
    const tasaItbis = 0.18;
    final nuevoItbis = baseImponible * tasaItbis;
    final nuevoTotal = baseImponible + nuevoItbis;
    state = state.copyWith(
      descuento: 0.0,
      descuentoId: null,
      descuentoNombre: null,
      montoDescuento: 0.0,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
  }

  bool validarAntesDeGuardar() {
    if (state.clienteId == null || (state.clienteNombre?.trim().isEmpty ?? true)) return false;
    if (state.numero.trim().isEmpty) return false;
    if (state.montoTotal <= 0) return false;
    return true;
  }

  void vaciar() {
    state = VentaBorradorState(
      numero: '',
      fecha: DateTime.now(),
      subtotal: 0.0,
      itbis: 0.0,
      descuento: 0.0,
      montoDescuento: 0.0,
      montoTotal: 0.0,
    );
  }

  Venta _construirEntidad() {
    return Venta(
      numero: state.numero,
      fecha: state.fecha,
      clienteId: state.clienteId ?? 0,
      nombreCliente: state.clienteNombre,
      subtotal: state.subtotal,
      itbis: state.itbis,
      total: state.montoTotal,
      detalles: state.detalles,
      tipoPago: state.tipoPago,
      esCredito: state.esCredito,
      descuentoId: state.descuentoId,
      descuentoNombre: state.descuentoNombre,
      montoDescuento: state.montoDescuento,
    );
  }

  Future<String> guardar() async {
    if (!validarAntesDeGuardar()) throw Exception('Datos incompletos');
    final repositorio = _ref.read<IVentasRepository>(ventasRepositoryProvider);
    final entidad = _construirEntidad();
    final casoUso = RegistrarVentaBorrador(repositorio);
    final resultado = await casoUso(entidad);
    _ref.invalidate(listaVentasBorradorProvider);
    return resultado.numero;
  }

  Future<String> editar(int ventaBorradorId) async {
    if (!validarAntesDeGuardar()) throw Exception('Datos incompletos');
    final repositorio = _ref.read<IVentasRepository>(ventasRepositoryProvider);
    final entidad = _construirEntidad();
    final casoUso = EditarVentaBorrador(repositorio);
    final resultado = await casoUso(entidad);
    _ref.invalidate(listaVentasBorradorProvider);
    return resultado.numero;
  }

  Future<String> imprimir(Venta cotizacion) async {
    final servicio = _ref.read<ICotizacionService>(ventaBorradorServicioProvider);
    return servicio.generarImpresion(cotizacion);
  }

  Future<String> exportarPDF(Venta cotizacion) async {
    final servicio = _ref.read<ICotizacionService>(ventaBorradorServicioProvider);
    return servicio.exportarPDF(cotizacion);
  }

  Future<void> enviarPorCorreo(Venta cotizacion, String correoDestinatario) async {
    final servicio = _ref.read<ICotizacionService>(ventaBorradorServicioProvider);
    return servicio.enviarPorCorreo(cotizacion, correoDestinatario);
  }
}

final ventaBorradorProvider = StateNotifierProvider<VentaBorradorNotifier, VentaBorradorState>(
  (ref) => VentaBorradorNotifier(ref),
);
