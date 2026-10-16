import 'package:fiscogest_rd/features/impuestos/presentation/providers/impuesto_providers.dart';
import 'package:fiscogest_rd/features/inventario/presentation/providers/categoria_providers.dart';
import 'package:fiscogest_rd/features/impuestos/domain/services/resolver_tasa_itbis.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return _ref.read(tasaItbisVigenteProvider);
  }

  double _tasaDeProducto(Producto producto) {
    return resolverTasaItbisProducto(
      impuestoId: producto.impuestoId,
      categoriaId: producto.categoriaId,
      impuestos: _ref.read(impuestoControllerProvider).valueOrNull ?? const [],
      categorias: _ref.read(categoriaControllerProvider).valueOrNull ?? const [],
      tasaGlobal: _tasaItbis,
    );
  }

  double _itbisDetalles(
    List<Map<String, dynamic>> detalles, {
    required double subtotal,
    required double descuento,
  }) {
    return itbisDeLineas(
      subtotales: detalles.map(_subtotalLineaNeto),
      tasas: detalles.map(
        (item) => (item['tasaImpuesto'] as num?)?.toDouble() ?? _tasaItbis,
      ),
      descuentoGeneral: descuento,
    );
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


  void establecerUsuarioId(int usuarioId) {
    state = state.copyWith(usuarioId: usuarioId);
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


  bool _lineaTieneOferta(Map<String, dynamic> item) {
    if (item['esOferta'] == true) return true;
    final oid = item['ofertaId'];
    final oname = item['ofertaNombre'] as String?;
    return oid != null && oname != null && oname.isNotEmpty;
  }

  ({double precio, bool esOferta}) _resolverPrecio({
    required double precioVenta,
    required double? precioMayorista,
    required double? precioEspecial,
    required double? precioMinimo,
    required bool ofertaVigente,
    required double cantidad,
    required bool permitirOferta,
  }) {
    var precio = precioVenta;
    var esOferta = false;

    if (permitirOferta &&
        ofertaVigente &&
        precioEspecial != null &&
        precioEspecial > 0 &&
        precioEspecial <= precio) {
      precio = precioEspecial;
      esOferta = true;
    }
    if (cantidad >= 2 &&
        precioMayorista != null &&
        precioMayorista > 0 &&
        precioMayorista < precio) {
      precio = precioMayorista;
      esOferta = false;
    }

    final minimo = precioMinimo ?? 0;
    if (minimo > precio) precio = minimo;
    return (precio: precio, esOferta: esOferta);
  }

  ({double precio, bool esOferta}) _resolverPrecioDeLinea(
    Map<String, dynamic> item,
    double cantidad, {
    required bool permitirOferta,
  }) {
    return _resolverPrecio(
      precioVenta:
          (item['precioVentaBase'] as num?)?.toDouble() ??
          (item['precioUnitario'] as num?)?.toDouble() ??
          0,
      precioMayorista: (item['precioMayorista'] as num?)?.toDouble(),
      precioEspecial: (item['precioEspecial'] as num?)?.toDouble(),
      precioMinimo: (item['precioMinimo'] as num?)?.toDouble(),
      ofertaVigente: item['ofertaVigente'] == true,
      cantidad: cantidad,
      permitirOferta: permitirOferta,
    );
  }

  bool _lineaTieneDesc(Map<String, dynamic> item) {
    final pct = (item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0;
    final mon = (item['montoDescuento'] as num?)?.toDouble() ?? 0;
    return pct > 0 || mon > 0;
  }

  double _subtotalLineaNeto(Map<String, dynamic> item) {
    final cant = (item['cantidad'] as num?)?.toDouble() ?? 0;
    final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0;
    final bruto = cant * precio;
    final pct = (item['descuentoPorcentaje'] as num?)?.toDouble() ?? 0;
    final mon = (item['montoDescuento'] as num?)?.toDouble() ?? 0;
    if (pct > 0) return (bruto * (100 - pct) / 100).clamp(0.0, double.infinity);
    if (mon > 0) return (bruto - mon).clamp(0.0, double.infinity);
    return bruto;
  }

  bool get tieneDescuentoPorLinea =>
      state.detalles.any(_lineaTieneDesc);

  bool get tieneOfertaEnLineas =>
      state.detalles.any(_lineaTieneOferta);

  bool get tieneDescuentoGeneral => state.montoDescuento > 0.001;

  String? puedeAplicarDescuentoLinea(Map<String, dynamic> item) {
    if (state.detalles.isEmpty) {
      return 'Agregue productos antes de aplicar descuento';
    }
    if (_lineaTieneOferta(item)) {
      return 'Esta línea tiene oferta. No se puede aplicar otro descuento';
    }
    if (tieneDescuentoGeneral) {
      return 'Ya hay descuento general. Quítelo para aplicar descuento por línea';
    }
    if (tieneOfertaEnLineas) {
      return 'Hay productos en oferta. No se pueden combinar con descuentos adicionales';
    }
    return null;
  }

  String? puedeAplicarDescuentoGeneral() {
    if (state.detalles.isEmpty) {
      return 'Agregue productos antes de aplicar descuento';
    }
    if (tieneOfertaEnLineas) {
      return 'Hay productos en oferta. No se puede aplicar descuento general';
    }
    if (tieneDescuentoPorLinea) {
      return 'Ya hay descuento por línea. Quítelo para aplicar descuento general';
    }
    return null;
  }

  void agregarProducto(Producto producto, double cantidad) {
    final nuevosDetalles = List<Map<String, dynamic>>.from(state.detalles);
    final indice = nuevosDetalles.indexWhere(
      (item) => item['productoId'] == producto.id,
    );
    final cantidadActual = indice >= 0
        ? (nuevosDetalles[indice]['cantidad'] as num?)?.toDouble() ?? 0
        : 0.0;
    final cantidadFinal = cantidadActual + cantidad;
    final precio = _resolverPrecio(
      precioVenta: producto.precioVenta,
      precioMayorista: producto.precioMayorista,
      precioEspecial: producto.precioEspecial,
      precioMinimo: producto.precioMinimo,
      ofertaVigente: producto.ofertaVigente,
      cantidad: cantidadFinal,
      permitirOferta: !tieneDescuentoGeneral && !tieneDescuentoPorLinea,
    );

    final detalle = indice >= 0
        ? Map<String, dynamic>.from(nuevosDetalles[indice])
        : <String, dynamic>{
            'productoId': producto.id,
            'productoNombre': producto.nombre,
            'productoCodigo': producto.codigo,
            'codigoBarras': producto.codigoBarras,
            'descuentoPorcentaje': 0.0,
            'montoDescuento': 0.0,
          };
    detalle.addAll({
      'productoCodigo': producto.codigo,
      'codigoBarras': producto.codigoBarras,
      'productoNombre': producto.nombre,
      'cantidad': cantidadFinal,
      'precioUnitario': precio.precio,
      'tasaImpuesto': _tasaDeProducto(producto),
      'precioVentaBase': producto.precioVenta,
      'precioMayorista': producto.precioMayorista,
      'precioEspecial': producto.precioEspecial,
      'precioMinimo': producto.precioMinimo,
      'ofertaVigente': producto.ofertaVigente,
      'esOferta': precio.esOferta,
    });
    detalle['subtotal'] = _subtotalLineaNeto(detalle);

    if (indice >= 0) {
      nuevosDetalles[indice] = detalle;
    } else {
      nuevosDetalles.add(detalle);
    }
    final nuevoSubtotal = nuevosDetalles.fold<double>(
      0.0,
      (sum, item) => sum + _subtotalLineaNeto(item),
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


  void cambiarCantidad(int productoId, double nuevaCantidad) {
    if (nuevaCantidad <= 0) {
      quitarProducto(productoId);
      return;
    }
    final nuevosDetalles = List<Map<String, dynamic>>.from(state.detalles);
    final indice = nuevosDetalles.indexWhere(
      (item) => item['productoId'] == productoId,
    );
    if (indice < 0) return;
    final detalle = Map<String, dynamic>.from(nuevosDetalles[indice]);
    final precio = _resolverPrecioDeLinea(
      detalle,
      nuevaCantidad,
      permitirOferta: !tieneDescuentoGeneral && !tieneDescuentoPorLinea,
    );
    detalle['cantidad'] = nuevaCantidad;
    detalle['precioUnitario'] = precio.precio;
    detalle['esOferta'] = precio.esOferta;
    detalle['subtotal'] = _subtotalLineaNeto(detalle);
    nuevosDetalles[indice] = detalle;
    final nuevoSubtotal = nuevosDetalles.fold<double>(
      0.0,
      (sum, item) => sum + _subtotalLineaNeto(item),
    );
    // Si hay desc general y ahora hay desc línea, quitar general (exclusividad)
    double descGen = state.montoDescuento;
    if (tieneDescuentoPorLinea || nuevosDetalles.any(_lineaTieneDesc)) {
      // recalcular flag sobre nuevosDetalles
      final hayLinea = nuevosDetalles.any(_lineaTieneDesc);
      if (hayLinea) descGen = 0;
    }
    _recalcularTotal(
      nuevoSubtotal: nuevoSubtotal,
      nuevoDescuento: descGen,
      detalles: nuevosDetalles,
    );
  }

  /// valor <= 0 quita el descuento de línea.
  String? aplicarDescuentoLinea(
    int productoId,
    double valor, {
    bool esPorcentaje = false,
  }) {
    final nuevosDetalles = List<Map<String, dynamic>>.from(state.detalles);
    final indice = nuevosDetalles.indexWhere(
      (item) => item['productoId'] == productoId,
    );
    if (indice < 0) return 'Línea no encontrada';
    final item = Map<String, dynamic>.from(nuevosDetalles[indice]);
    final quitando = valor <= 0;

    if (!quitando) {
      final yaTiene = _lineaTieneDesc(item);
      final bloqueo = puedeAplicarDescuentoLinea(item);
      if (bloqueo != null && !yaTiene) return bloqueo;
    }

    final cant = (item['cantidad'] as num?)?.toDouble() ?? 0;
    final precio = (item['precioUnitario'] as num?)?.toDouble() ?? 0;
    final bruto = cant * precio;
    double pct = 0;
    double mon = 0;
    double neto = bruto;

    if (!quitando) {
      if (esPorcentaje) {
        if (valor > 100) return 'El descuento no puede superar el 100%';
        pct = valor;
        neto = bruto * (100 - valor) / 100;
      } else {
        if (valor > bruto) {
          return 'El descuento no puede superar el subtotal de la línea';
        }
        mon = valor;
        neto = bruto - valor;
      }
    }
    if (neto < 0) neto = 0;
    item['descuentoPorcentaje'] = pct;
    item['montoDescuento'] = mon;
    item['subtotal'] = neto;
    nuevosDetalles[indice] = item;

    final nuevoSubtotal = nuevosDetalles.fold<double>(
      0.0,
      (sum, it) => sum + _subtotalLineaNeto(it),
    );
    // Exclusividad: al poner desc línea, limpiar general
    state = state.copyWith(
      descuento: 0,
      descuentoId: null,
      descuentoNombre: null,
      montoDescuento: 0,
    );
    _recalcularTotal(
      nuevoSubtotal: nuevoSubtotal,
      nuevoDescuento: 0,
      detalles: nuevosDetalles,
    );
    return null;
  }

  void _recalcularTotal({
    double? nuevoSubtotal,
    double? nuevoItbis,
    double? nuevoEnvio,
    double? nuevoDescuento,
    List<Map<String, dynamic>>? detalles,
  }) {
    final subt = nuevoSubtotal ?? state.subtotal;
    final dets = detalles ?? state.detalles;
    final desc0 = nuevoDescuento ?? state.montoDescuento;
    final itb = nuevoItbis ??
        _itbisDetalles(dets, subtotal: subt, descuento: desc0);
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

  /// Descuento general. [valor] <= 0 lo quita.
  /// Devuelve mensaje de error o null.
  String? aplicarDescuento(double valor) {
    if (valor <= 0) {
      quitarDescuento();
      return null;
    }
    final bloqueo = puedeAplicarDescuentoGeneral();
    if (bloqueo != null) return bloqueo;
    if (valor > state.subtotal) valor = state.subtotal;
    final baseImponible = state.subtotal - valor;
    final nuevoItbis = _itbisDetalles(
      state.detalles,
      subtotal: state.subtotal,
      descuento: valor,
    );
    final subtMasItbis = baseImponible + nuevoItbis;
    final nuevoTotal = subtMasItbis + state.costoEnvio;
    state = state.copyWith(
      descuento: valor,
      montoDescuento: valor,
      itbis: nuevoItbis,
      montoTotal: nuevoTotal,
    );
    return null;
  }

  void quitarDescuento() {
    final baseImponible = state.subtotal;
    final nuevoItbis = _itbisDetalles(
      state.detalles,
      subtotal: state.subtotal,
      descuento: 0,
    );
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
