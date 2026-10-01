import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/comercial/data/repositories/providers/repositorio_providers.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_producto_repository.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/producto.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/detalle_venta.dart';
import 'package:fiscogest_rd/features/configuracion/presentation/providers/configuracion_providers.dart';

class RegistrarVentaState {
  const RegistrarVentaState({
    this.usuarioId = 1,
    this.clienteId,
    this.clienteNombre,
    this.tipoPago = 'Efectivo',
    this.esCredito = false,
    this.abonoInicial = 0.0,
    this.vencimiento,
    this.detalles = const [],
    this.subtotal = 0.0,
    this.itbis = 0.0,
    this.costoEnvio = 0.0,
    this.total = 0.0,
    this.descuentoId,
    this.descuentoNombre,
    this.montoDescuento = 0.0,
    this.resultadosBusqueda = const [],
  });

  final int usuarioId;
  final int? clienteId;
  final String? clienteNombre;
  final String tipoPago;
  final bool esCredito;
  final double abonoInicial;
  final DateTime? vencimiento;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double itbis;
  final double costoEnvio;
  final double total;
  final int? descuentoId;
  final String? descuentoNombre;
  final double montoDescuento;
  final List<DetalleVenta> resultadosBusqueda;

  RegistrarVentaState copyWith({
    int? usuarioId,
    int? clienteId,
    String? clienteNombre,
    String? tipoPago,
    bool? esCredito,
    double? abonoInicial,
    DateTime? vencimiento,
    List<DetalleVenta>? detalles,
    double? subtotal,
    double? itbis,
    double? costoEnvio,
    double? total,
    int? descuentoId,
    String? descuentoNombre,
    double? montoDescuento,
    List<DetalleVenta>? resultadosBusqueda,
  }) {
    final env = costoEnvio ?? this.costoEnvio;
    final sub = subtotal ?? this.subtotal;
    final itb = itbis ?? this.itbis;
    final desc = montoDescuento ?? this.montoDescuento;
    final totalCalculado = sub + itb + env - desc;

    return RegistrarVentaState(
      usuarioId: usuarioId ?? this.usuarioId,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      tipoPago: tipoPago ?? this.tipoPago,
      esCredito: esCredito ?? this.esCredito,
      abonoInicial: abonoInicial ?? this.abonoInicial,
      vencimiento: vencimiento ?? this.vencimiento,
      detalles: detalles ?? this.detalles,
      subtotal: sub,
      itbis: itb,
      costoEnvio: env,
      montoDescuento: desc,
      total: total ?? totalCalculado.clamp(0.0, double.infinity),
      descuentoId: descuentoId ?? this.descuentoId,
      descuentoNombre: descuentoNombre ?? this.descuentoNombre,
      resultadosBusqueda: resultadosBusqueda ?? this.resultadosBusqueda,
    );
  }
}

class RegistrarVentaNotifier extends Notifier<RegistrarVentaState> {
  /// 0 en modo simplificado; 0.18 en operación fiscal.
  double get tasaItbis {
    final cfg = ref.read(configuracionControllerProvider).valueOrNull;
    if (cfg?.modoSimplificado == true) return 0.0;
    return 0.18;
  }

  late IProductoRepository productoRepo;

  @override
  RegistrarVentaState build() {
    productoRepo = ref.read(productoRepositoryProvider);
    return const RegistrarVentaState();
  }

  bool get esConsumidorFinal {
    return state.clienteId == 0 || state.clienteNombre == 'Consumidor Final';
  }

  double precioConOferta({
    required double? precioEspecial,
    required double precioVenta,
  }) {
    if (precioEspecial != null && precioEspecial > 0) {
      return precioEspecial;
    }
    return precioVenta;
  }

  double precioUnitarioConImpuesto(DetalleVenta linea) {
    return linea.precioUnitario * (1 + tasaItbis);
  }

  double subtotalLineaConImpuesto(DetalleVenta linea) {
    return linea.subtotal * (1 + tasaItbis);
  }

  bool tieneDescuentoAplicado() {
    return state.detalles.any(
      (linea) => linea.descuentoPorcentaje > 0 || linea.montoDescuento > 0,
    );
  }

  bool productoTieneOferta(DetalleVenta linea) {
    return linea.ofertaId != null &&
        linea.ofertaNombre != null &&
        linea.ofertaNombre!.isNotEmpty;
  }

  bool get tieneDescuentoPorLinea {
    return state.detalles.any(
      (l) => l.descuentoPorcentaje > 0 || l.montoDescuento > 0,
    );
  }

  bool get tieneOfertaEnLineas {
    return state.detalles.any(productoTieneOferta);
  }

  bool get tieneDescuentoGeneral => state.montoDescuento > 0.001;

  /// Un solo tipo a la vez: oferta | descuento de línea | descuento general.
  String? puedeAplicarDescuentoLinea(DetalleVenta linea) {
    if (state.detalles.isEmpty) {
      return 'Agregue productos antes de aplicar descuento';
    }
    if (productoTieneOferta(linea)) {
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

  String? validarStockAlAgregar(DetalleVenta producto, double cantidad) {
    final stockDisponible = obtenerStock(producto);
    if (stockDisponible != null && cantidad > stockDisponible) {
      return 'Stock insuficiente. Disponible: $stockDisponible';
    }
    return null;
  }

  String? agregarProducto(DetalleVenta linea) {
    final lista = List<DetalleVenta>.from(state.detalles);
    final indice = lista.indexWhere((p) => p.productoId == linea.productoId);
    if (indice >= 0) {
      final existente = lista[indice];
      final nuevaCantidad = existente.cantidad + linea.cantidad;
      final mensajeStock = validarStockAlAgregar(
        linea,
        nuevaCantidad.toDouble(),
      );
      if (mensajeStock != null) return mensajeStock;
      final nuevoSubtotal = existente.precioUnitario * nuevaCantidad;
      lista[indice] = existente.copyWith(
        cantidad: nuevaCantidad,
        subtotal: nuevoSubtotal,
        subtotalLinea: nuevoSubtotal,
      );
    } else {
      final mensajeStock = validarStockAlAgregar(
        linea,
        linea.cantidad.toDouble(),
      );
      if (mensajeStock != null) return mensajeStock;
      lista.add(linea);
    }
    recalcularTotales(lista);
    return null;
  }

  void quitarProducto(int indice) {
    final lista = List<DetalleVenta>.from(state.detalles);
    if (indice >= 0 && indice < lista.length) {
      lista.removeAt(indice);
      recalcularTotales(lista);
    }
  }

  void eliminarProducto(int indice) {
    quitarProducto(indice);
  }

  void cambiarCantidad(int indice, int nuevaCantidad) {
    final lista = List<DetalleVenta>.from(state.detalles);
    if (indice >= 0 && indice < lista.length && nuevaCantidad > 0) {
      final linea = lista[indice];
      final nuevoSubtotal = linea.precioUnitario * nuevaCantidad;
      lista[indice] = linea.copyWith(
        cantidad: nuevaCantidad,
        subtotal: nuevoSubtotal,
        subtotalLinea: nuevoSubtotal,
      );
      recalcularTotales(lista);
    }
  }

  /// Aplica descuento general. [monto] <= 0 lo quita.
  String? aplicarDescuentoGeneral(double monto, {bool esPorcentaje = false}) {
    if (monto <= 0) {
      quitarDescuento();
      recalcularTotales(state.detalles);
      return null;
    }
    final bloqueo = puedeAplicarDescuentoGeneral();
    if (bloqueo != null) return bloqueo;

    double nuevoMontoDescuento;
    if (esPorcentaje) {
      if (monto > 100) return 'El descuento no puede superar el 100%';
      nuevoMontoDescuento = state.subtotal * (monto / 100.0);
    } else {
      nuevoMontoDescuento = monto;
    }
    if (nuevoMontoDescuento > state.subtotal) {
      nuevoMontoDescuento = state.subtotal;
    }
    state = state.copyWith(montoDescuento: nuevoMontoDescuento);
    recalcularTotales(state.detalles);
    return null;
  }

  void aplicarDescuentoManual(double monto) {
    aplicarDescuentoGeneral(monto, esPorcentaje: false);
  }

  String? aplicarDescuentoLinea(int indice, double valor, bool esPorcentaje) {
    final lista = List<DetalleVenta>.from(state.detalles);
    if (indice < 0 || indice >= lista.length) {
      return 'Línea inválida';
    }
    final linea = lista[indice];
    final quitando = valor <= 0;

    if (!quitando) {
      final estaLineaYaTieneDesc =
          linea.descuentoPorcentaje > 0 || linea.montoDescuento > 0;
      final bloqueo = puedeAplicarDescuentoLinea(linea);
      if (bloqueo != null && !estaLineaYaTieneDesc) {
        return bloqueo;
      }
      if (productoTieneOferta(linea)) {
        return 'Esta línea tiene oferta. No se puede aplicar otro descuento';
      }
      if (tieneDescuentoGeneral) {
        return 'Ya hay descuento general. Quítelo para aplicar descuento por línea';
      }
    }

    final precioBase = linea.precioUnitario * linea.cantidad;
    double descPct = 0;
    double descMonto = 0;
    double nuevoSubtotal = precioBase;

    if (!quitando) {
      if (esPorcentaje) {
        if (valor > 100) {
          return 'El descuento no puede superar el 100%';
        }
        descPct = valor;
        nuevoSubtotal = precioBase * (100 - valor) / 100;
      } else {
        if (valor > precioBase) {
          return 'El descuento no puede superar el subtotal de la línea';
        }
        descMonto = valor;
        nuevoSubtotal = precioBase - valor;
      }
    }
    if (nuevoSubtotal < 0) nuevoSubtotal = 0;

    lista[indice] = linea.copyWith(
      descuentoPorcentaje: descPct,
      montoDescuento: descMonto,
      subtotal: nuevoSubtotal,
      subtotalLinea: nuevoSubtotal,
    );
    recalcularTotales(lista);
    return null;
  }

  void cambiarDescuentoPorLinea(
    int indice,
    double valor, {
    bool esPorcentaje = false,
  }) {
    aplicarDescuentoLinea(indice, valor, esPorcentaje);
  }

  String? seleccionarDescuento(int id, String nombre, double valor) {
    final bloqueo = puedeAplicarDescuentoGeneral();
    if (bloqueo != null) return bloqueo;
    state = state.copyWith(descuentoId: id, descuentoNombre: nombre);
    return aplicarDescuentoGeneral(valor, esPorcentaje: true);
  }


  void quitarDescuento() {
    state = state.copyWith(
      descuentoId: null,
      descuentoNombre: null,
      montoDescuento: 0.0,
    );
  }

  void seleccionarCliente(int id, String nombre) {
    state = state.copyWith(clienteId: id, clienteNombre: nombre);
  }

  void establecerConsumidorFinal() {
    state = state.copyWith(clienteId: 0, clienteNombre: 'Consumidor Final');
  }

  void cambiarFormaPago(String forma) {
    state = state.copyWith(
      tipoPago: forma,
      esCredito: forma == 'crédito',
      abonoInicial: forma == 'crédito' ? 0.0 : 0.0,
      vencimiento: forma == 'crédito' ? null : null,
    );
  }

  void establecerCondicionesCredito(double abono, DateTime? vence) {
    state = state.copyWith(abonoInicial: abono, vencimiento: vence);
  }

  void asignarCostoEnvio(double valor) {
    state = state.copyWith(costoEnvio: valor);
  }

  void vaciarVenta() {
    state = const RegistrarVentaState();
  }

  bool validarAntesDeGuardar() {
    return state.detalles.isNotEmpty &&
        state.tipoPago.isNotEmpty &&
        state.total > 0;
  }

  double? obtenerStock(DetalleVenta linea) => linea.subtotalLinea;

  void recalcularTotales(List<DetalleVenta> lista) {
    final subtotal = lista.fold<double>(0.0, (sum, l) => sum + l.subtotal);
    final itbis = subtotal * tasaItbis;
    final total = subtotal + itbis + state.costoEnvio - state.montoDescuento;
    state = state.copyWith(
      detalles: lista,
      subtotal: subtotal,
      itbis: itbis,
      total: total.clamp(0.0, double.infinity),
    );
  }

  Future<void> buscarProducto(String texto) async {
    final textoBusqueda = texto.trim().toLowerCase();
    if (textoBusqueda.isEmpty) {
      state = state.copyWith(resultadosBusqueda: const []);
      return;
    }
    final todos = await productoRepo.obtenerProductos();
    final coinciden = todos.where((Producto p) {
      final coincideCodigo = p.codigo.toLowerCase().contains(textoBusqueda);
      final coincideNombre = p.nombre.toLowerCase().contains(textoBusqueda);
      final coincideCodigoBarras =
          p.codigoBarras?.toLowerCase().contains(textoBusqueda) ?? false;
      return p.activo &&
          (coincideCodigo || coincideNombre || coincideCodigoBarras);
    }).toList();
    final resultados = coinciden.map((Producto producto) {
      final precioFinal = precioConOferta(
        precioEspecial: producto.precioEspecial,
        precioVenta: producto.precioVenta,
      );
      return DetalleVenta(
        productoId: producto.id ?? 0,
        cantidad: 1,
        precioUnitario: precioFinal,
        subtotal: precioFinal,
        nombreProducto: producto.nombre,
        tasaImpuesto: tasaItbis,
      );
    }).toList();
    state = state.copyWith(resultadosBusqueda: resultados);
  }

  String? agregarProductoSeleccionado(DetalleVenta producto) {
    return agregarProducto(producto);
  }
}

final registrarVentaProvider =
    NotifierProvider<RegistrarVentaNotifier, RegistrarVentaState>(
      RegistrarVentaNotifier.new,
    );
