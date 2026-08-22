import 'package:riverpod/riverpod.dart';
import 'package:fiscogest_rd/core/dependency_injection/repository_injection.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/domain/services/i_venta_inventario_service.dart';
import 'package:fiscogest_rd/features/ventas/domain/usecases/registrar_venta.dart';

final ventasRepositoryProvider = Provider<IVentasRepository>((ref) {
  return RepositoryInjection.instance.ventasRepository;
});

final ventaInventarioServiceProvider = Provider<IVentaInventarioService>((ref) {
  return RepositoryInjection.instance.ventaInventarioService;
});

final registrarVentaUseCaseProvider = Provider<RegistrarVenta>((ref) {
  final servicio = ref.watch(ventaInventarioServiceProvider);
  return RegistrarVenta(servicio);
});

final descuentosActivosProvider = FutureProvider<List<Descuento>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.obtenerDescuentosActivos();
});

final ofertasActivosProvider = FutureProvider<List<Oferta>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.obtenerOfertasActivas();
});

final listaVentasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarVentas();
});

final listaCotizacionesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarCotizaciones();
});

final listaApartadosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ventasRepositoryProvider);
  return repo.listarApartados();
});

class CotizacionState {
  const CotizacionState({
    this.id,
    this.clienteId,
    this.clienteNombre,
    this.fecha,
    this.fechaVencimiento,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.descuento = 0.0,
    this.descuentoId,
    this.descuentoNombre,
    this.itbis = 0.0,
    this.montoTotal = 0.0,
    this.estado = 'PENDIENTE',
    this.numero = '',
  });

  final int? id;
  final int? clienteId;
  final String? clienteNombre;
  final DateTime? fecha;
  final DateTime? fechaVencimiento;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double descuento;
  final int? descuentoId;
  final String? descuentoNombre;
  final double itbis;
  final double montoTotal;
  final String estado;
  final String numero;

  CotizacionState copiarCon({
    int? id,
    int? clienteId,
    String? clienteNombre,
    DateTime? fecha,
    DateTime? fechaVencimiento,
    List<DetalleVenta>? detalles,
    double? subtotal,
    double? descuento,
    int? descuentoId,
    String? descuentoNombre,
    double? itbis,
    double? montoTotal,
    String? estado,
    String? numero,
  }) {
    return CotizacionState(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      fecha: fecha ?? this.fecha,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      detalles: detalles ?? this.detalles,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      itbis: itbis ?? this.itbis,
      montoTotal: montoTotal ?? this.montoTotal,
      estado: estado ?? this.estado,
      numero: numero ?? this.numero,
    );
  }
}

class CotizacionNotifier extends StateNotifier<CotizacionState> {
  CotizacionNotifier() : super(const CotizacionState());

  void seleccionarCliente(int? idCliente, String nombre) {
    state = state.copiarCon(clienteId: idCliente, clienteNombre: nombre);
  }

  void establecerVencimiento(DateTime fechaVencimiento) {
    state = state.copiarCon(fechaVencimiento: fechaVencimiento);
  }

  void establecerDescuentoManual(double monto) {
    final baseGravable = state.subtotal - monto;
    final itbisNuevo = baseGravable * 0.18;
    final nuevoTotal = baseGravable + itbisNuevo;
    state = state.copiarCon(
      descuento: monto,
      descuentoNombre: monto > 0 ? 'Manual' : null,
      descuentoId: monto > 0 ? 0 : null,
      itbis: itbisNuevo > 0 ? itbisNuevo : 0.0,
      montoTotal: nuevoTotal > 0 ? nuevoTotal : 0.0,
    );
  }

  double _calcularSubtotalConDescuentoLinea(List<DetalleVenta> lista) {
    double suma = 0.0;
    for (final linea in lista) {
      double base = linea.subtotalLinea;
      if (linea.descuentoPorcentaje != null && linea.descuentoPorcentaje! > 0) {
        base = base * (100 - linea.descuentoPorcentaje!) / 100;
      } else if (linea.montoDescuento != null && linea.montoDescuento! > 0) {
        base = base - linea.montoDescuento!;
      }
      if (base < 0) base = 0;
      suma += base;
    }
    return suma;
  }

  double _calcularItbisConDescuentoLinea(List<DetalleVenta> lista) {
    double suma = 0.0;
    for (final linea in lista) {
      double base = linea.subtotalLinea;
      if (linea.descuentoPorcentaje != null && linea.descuentoPorcentaje! > 0) {
        base = base * (100 - linea.descuentoPorcentaje!) / 100;
      } else if (linea.montoDescuento != null && linea.montoDescuento! > 0) {
        base = base - linea.montoDescuento!;
      }
      if (base < 0) base = 0;
      suma += base * linea.tasaImpuesto / 100;
    }
    return suma;
  }

  void quitarDescuento() {
    final subtotalSinDescuento = _calcularSubtotalConDescuentoLinea(state.detalles);
    final itbisSinDescuento = _calcularItbisConDescuentoLinea(state.detalles);
    state = state.copiarCon(
      descuento: 0.0,
      descuentoId: null,
      descuentoNombre: null,
      itbis: itbisSinDescuento,
      montoTotal: subtotalSinDescuento + itbisSinDescuento,
    );
  }

  void aplicarDescuento(Descuento descuento) {
    final subtotalSinDescuento = _calcularSubtotalConDescuentoLinea(state.detalles);
    double montoDescuento;
    if (descuento.tipo == 'porcentaje') {
      montoDescuento = subtotalSinDescuento * descuento.valor / 100;
    } else {
      montoDescuento = descuento.valor;
    }
    if (montoDescuento > subtotalSinDescuento) {
      montoDescuento = subtotalSinDescuento;
    }
    final itbisSinGlobal = _calcularItbisConDescuentoLinea(state.detalles);
    final baseGravableGlobal = subtotalSinDescuento - montoDescuento;
    final promedioTasa = subtotalSinDescuento > 0 ? itbisSinGlobal / subtotalSinDescuento : 0.18;
    final itbisNuevo = baseGravableGlobal * promedioTasa;
    final nuevoTotal = baseGravableGlobal + itbisNuevo;
    state = state.copiarCon(
      descuento: montoDescuento,
      descuentoId: descuento.id,
      descuentoNombre: descuento.nombre,
      itbis: itbisNuevo > 0 ? itbisNuevo : 0.0,
      montoTotal: nuevoTotal > 0 ? nuevoTotal : 0.0,
    );
  }

  void calcularTotales(List<DetalleVenta> lista) {
    double subtotalBruto = 0.0;
    double subtotalConDescuentoLinea = 0.0;
    double itbisConDescuentoLinea = 0.0;
    for (final linea in lista) {
      subtotalBruto += linea.subtotalLinea;
      double baseLinea = linea.subtotalLinea;
      if (linea.descuentoPorcentaje != null && linea.descuentoPorcentaje! > 0) {
        baseLinea = baseLinea * (100 - linea.descuentoPorcentaje!) / 100;
      } else if (linea.montoDescuento != null && linea.montoDescuento! > 0) {
        baseLinea = baseLinea - linea.montoDescuento!;
      }
      if (baseLinea < 0) baseLinea = 0;
      subtotalConDescuentoLinea += baseLinea;
      itbisConDescuentoLinea += baseLinea * linea.tasaImpuesto / 100;
    }
    final baseGravableGlobal = subtotalConDescuentoLinea - state.descuento;
    final promedioTasa = subtotalConDescuentoLinea > 0 ? itbisConDescuentoLinea / subtotalConDescuentoLinea : 0.18;
    final itbisCalculado = baseGravableGlobal * promedioTasa;
    final total = baseGravableGlobal + itbisCalculado;
    state = state.copiarCon(
      detalles: lista,
      subtotal: subtotalBruto,
      itbis: itbisCalculado > 0 ? itbisCalculado : 0.0,
      montoTotal: total > 0 ? total : 0.0,
    );
  }

  bool validarAntesDeGuardar() {
    if (state.clienteId == null) return false;
    if (state.fechaVencimiento == null) return false;
    if (state.detalles.isEmpty) return false;
    if (state.montoTotal <= 0) return false;
    if (state.fechaVencimiento!.isBefore(DateTime.now())) return false;
    return true;
  }

  void vaciar() {
    state = const CotizacionState();
  }
}

final cotizacionProvider =
    StateNotifierProvider<CotizacionNotifier, CotizacionState>((ref) {
  return CotizacionNotifier();
});

class RegistrarVentaState {
  const RegistrarVentaState({
    this.numero = '',
    this.clienteId,
    this.clienteNombre,
    this.tipoPago = '',
    this.esCredito = false,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.montoDescuento = 0.0,
    this.descuentoId,
    this.descuentoNombre,
    this.itbis = 0.0,
    this.total = 0.0,
    this.usuarioId,
  });

  final String numero;
  final int? clienteId;
  final String? clienteNombre;
  final String tipoPago;
  final bool esCredito;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double montoDescuento;
  final int? descuentoId;
  final String? descuentoNombre;
  final double itbis;
  final double total;
  final int? usuarioId;

  RegistrarVentaState copiarCon({
    String? numero,
    int? clienteId,
    String? clienteNombre,
    String? tipoPago,
    bool? esCredito,
    List<DetalleVenta>? detalles,
    double? subtotal,
    double? montoDescuento,
    int? descuentoId,
    String? descuentoNombre,
    double? itbis,
    double? total,
    int? usuarioId,
  }) {
    return RegistrarVentaState(
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      detalles: detalles ?? this.detalles,
      subtotal: subtotal ?? this.subtotal,
      montoDescuento: montoDescuento ?? this.montoDescuento,
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      itbis: itbis ?? this.itbis,
      total: total ?? this.total,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }
}

class RegistrarVentaNotifier extends StateNotifier<RegistrarVentaState> {
  RegistrarVentaNotifier() : super(const RegistrarVentaState());

  void seleccionarCliente(int idCliente, String nombreCliente) {
    state = state.copiarCon(clienteId: idCliente, clienteNombre: nombreCliente);
  }

  void cambiarFormaPago(String formaPago, bool credito) {
    state = state.copiarCon(tipoPago: formaPago, esCredito: credito);
  }

  void agregarProducto(DetalleVenta linea) {
    final lista = List<DetalleVenta>.from(state.detalles)..add(linea);
    calcularTotales(lista);
  }

  void quitarProducto(int indice) {
    if (indice < 0 || indice >= state.detalles.length) return;
    final lista = List<DetalleVenta>.from(state.detalles)..removeAt(indice);
    calcularTotales(lista);
  }

  void cambiarCantidad(int indice, double nuevaCantidad) {
    if (indice < 0 || indice >= state.detalles.length || nuevaCantidad <= 0) return;
    final lista = List<DetalleVenta>.from(state.detalles);
    final lineaActual = lista[indice];
    final nuevoSubtotal = lineaActual.precioUnitario * nuevaCantidad;
    lista[indice] = DetalleVenta(
      productoId: lineaActual.productoId,
      nombreProducto: lineaActual.nombreProducto,
      cantidad: nuevaCantidad,
      precioUnitario: lineaActual.precioUnitario,
      subtotalLinea: nuevoSubtotal,
      descuentoPorcentaje: lineaActual.descuentoPorcentaje,
      montoDescuento: lineaActual.montoDescuento,
      tasaImpuesto: lineaActual.tasaImpuesto,
      ofertaId: lineaActual.ofertaId,
      ofertaNombre: lineaActual.ofertaNombre,
      precioOriginal: lineaActual.precioOriginal,
    );
    calcularTotales(lista);
  }

  void aplicarDescuentoLinea(int indice, double valor, bool esPorcentaje) {
    if (indice < 0 || indice >= state.detalles.length) return;
    final lista = List<DetalleVenta>.from(state.detalles);
    final lineaActual = lista[indice];
    final subtotalBruto = lineaActual.precioUnitario * lineaActual.cantidad;
    double? nuevoPorcentaje;
    double? nuevoMonto;
    if (valor <= 0) {
      nuevoPorcentaje = null;
      nuevoMonto = null;
    } else if (esPorcentaje) {
      nuevoPorcentaje = valor > 100 ? 100 : valor;
      nuevoMonto = null;
    } else {
      nuevoMonto = valor > subtotalBruto ? subtotalBruto : valor;
      nuevoPorcentaje = null;
    }
    lista[indice] = DetalleVenta(
      productoId: lineaActual.productoId,
      nombreProducto: lineaActual.nombreProducto,
      cantidad: lineaActual.cantidad,
      precioUnitario: lineaActual.precioUnitario,
      subtotalLinea: subtotalBruto,
      descuentoPorcentaje: nuevoPorcentaje,
      montoDescuento: nuevoMonto,
      tasaImpuesto: lineaActual.tasaImpuesto,
      ofertaId: lineaActual.ofertaId,
      ofertaNombre: lineaActual.ofertaNombre,
      precioOriginal: lineaActual.precioOriginal,
    );
    calcularTotales(lista);
  }

  double _subtotalConDescuentoLinea(List<DetalleVenta> lista) {
    double suma = 0.0;
    for (final linea in lista) {
      double base = linea.subtotalLinea;
      if (linea.descuentoPorcentaje != null && linea.descuentoPorcentaje! > 0) {
        base = base * (100 - linea.descuentoPorcentaje!) / 100;
      } else if (linea.montoDescuento != null && linea.montoDescuento! > 0) {
        base = base - linea.montoDescuento!;
      }
      if (base < 0) base = 0;
      suma += base;
    }
    return suma;
  }

  void calcularTotales(List<DetalleVenta> lista, {Descuento? descuento}) {
    double subtotalBruto = 0.0;
    double subtotalConDescuentoLinea = 0.0;
    double itbisConDescuentoLinea = 0.0;
    for (final linea in lista) {
      subtotalBruto += linea.subtotalLinea;
      double baseLinea = linea.subtotalLinea;
      if (linea.descuentoPorcentaje != null && linea.descuentoPorcentaje! > 0) {
        baseLinea = baseLinea * (100 - linea.descuentoPorcentaje!) / 100;
      } else if (linea.montoDescuento != null && linea.montoDescuento! > 0) {
        baseLinea = baseLinea - linea.montoDescuento!;
      }
      if (baseLinea < 0) baseLinea = 0;
      subtotalConDescuentoLinea += baseLinea;
      itbisConDescuentoLinea += baseLinea * linea.tasaImpuesto / 100;
    }
    double montoDescuentoGlobal = 0.0;
    String? descuentoNombreGlobal;
    int? descuentoIdGlobal;
    if (descuento != null) {
      descuentoIdGlobal = descuento.id;
      descuentoNombreGlobal = descuento.nombre;
      if (descuento.tipo == 'porcentaje') {
        montoDescuentoGlobal = subtotalConDescuentoLinea * descuento.valor / 100;
      } else {
        montoDescuentoGlobal = descuento.valor;
      }
      if (montoDescuentoGlobal > subtotalConDescuentoLinea) {
        montoDescuentoGlobal = subtotalConDescuentoLinea;
      }
    }
    final baseFinal = subtotalConDescuentoLinea - montoDescuentoGlobal;
    final promedioTasa = subtotalConDescuentoLinea > 0
        ? itbisConDescuentoLinea / subtotalConDescuentoLinea
        : 0.18;
    final itbisFinal = baseFinal * promedioTasa;
    final totalFinal = baseFinal + itbisFinal;
    state = state.copiarCon(
      detalles: lista,
      subtotal: subtotalBruto,
      montoDescuento: montoDescuentoGlobal,
      descuentoId: descuentoIdGlobal,
      descuentoNombre: descuentoNombreGlobal,
      itbis: itbisFinal > 0 ? itbisFinal : 0.0,
      total: totalFinal > 0 ? totalFinal : 0.0,
    );
  }

  void aplicarDescuento(Descuento descuento) {
    calcularTotales(state.detalles, descuento: descuento);
  }

  void quitarDescuento() {
    calcularTotales(state.detalles);
  }

  void aplicarDescuentoManual(double monto) {
    final baseCalculo = _subtotalConDescuentoLinea(state.detalles);
    final montoFinal = monto.clamp(0.0, baseCalculo);
    final DateTime hoy = DateTime.now();
    final descuento = Descuento(
      id: 0,
      nombre: 'Manual',
      tipo: 'monto',
      valor: montoFinal,
      aplicaA: 'general',
      vigenciaDesde: hoy,
      vigenciaHasta: hoy.add(const Duration(days: 365)),
      estado: 'activo',
    );
    aplicarDescuento(descuento);
  }

  void vaciarVenta() {
    state = const RegistrarVentaState();
  }

  bool validarAntesDeGuardar() {
    if (state.clienteId == null) return false;
    if (state.tipoPago.isEmpty) return false;
    if (state.detalles.isEmpty) return false;
    if (state.total <= 0) return false;
    return true;
  }
}

final registrarVentaProvider =
    StateNotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>((ref) {
  return RegistrarVentaNotifier();
});
