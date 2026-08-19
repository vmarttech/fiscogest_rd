import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/cotizacion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/apartado.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/devolucion.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ventas_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cotizaciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/apartados_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/devoluciones_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/descuentos_dao.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/ofertas_dao.dart';

class VentasRepositoryImpl implements IVentasRepository {
  VentasRepositoryImpl({
    required this.ventasDao,
    required this.cotizacionesDao,
    required this.apartadosDao,
    required this.devolucionesDao,
    required this.cuentasCobrarDao,
    required this.descuentosDao,
    required this.ofertasDao,
  });

  final VentasDao ventasDao;
  final CotizacionesDao cotizacionesDao;
  final ApartadosDao apartadosDao;
  final DevolucionesDao devolucionesDao;
  final CuentasCobrarDao cuentasCobrarDao;
  final DescuentosDao descuentosDao;
  final OfertasDao ofertasDao;

  @override
  Future<List<Map<String, dynamic>>> listarVentas({
    DateTime? desde,
    DateTime? hasta,
    int? clienteId,
    int? usuarioId,
  }) async {
    throw UnimplementedError('listarVentas: Consultar ventas filtradas por rango, cliente y usuario');
  }

  @override
  Future<List<Map<String, dynamic>>> listarCotizaciones() async {
    throw UnimplementedError('listarCotizaciones: Consultar todas las cotizaciones desde cotizacionesDao');
  }

  @override
  Future<List<Map<String, dynamic>>> listarApartados() async {
    throw UnimplementedError('listarApartados: Consultar todos los apartados desde apartadosDao');
  }

  @override
  Future<Venta> registrarVenta(Venta venta) async {
    throw UnimplementedError('registrarVenta: Insertar venta → actualizar inventario, caja, cliente');
  }

  @override
  Future<Cotizacion> registrarCotizacion(Cotizacion cotizacion) async {
    throw UnimplementedError('registrarCotizacion: Crear cotización desde módulo ventas');
  }

  @override
  Future<Venta> convertirCotizacionAVenta(int cotizacionId) async {
    throw UnimplementedError('convertirCotizacionAVenta: Leer cotización → generar venta');
  }

  @override
  Future<Apartado> registrarApartado(Apartado apartado) async {
    throw UnimplementedError('registrarApartado: Reservar productos → estado Reservado');
  }

  @override
  Future<Devolucion> registrarDevolucion(Devolucion devolucion) async {
    throw UnimplementedError('registrarDevolucion: Procesar devolución desde módulo ventas');
  }

  @override
  Future<Pago> registrarPago(Pago pago) async {
    throw UnimplementedError('registrarPago: Registrar abono o pago parcial');
  }

  @override
  Future<double> consultarSaldoCliente(int clienteId) async {
    throw UnimplementedError('consultarSaldoCliente: Saldos pendientes en cuentas por cobrar');
  }

  @override
  Future<List<Descuento>> obtenerDescuentosActivos() async {
    throw UnimplementedError('obtenerDescuentosActivos: Listar descuentos vigentes');
  }

  @override
  Future<List<Oferta>> obtenerOfertasActivas() async {
    throw UnimplementedError('obtenerOfertasActivas: Listar promociones vigentes');
  }

  @override
  Future<bool> aplicarDescuento(int ventaId, int descuentoId) async {
    throw UnimplementedError('aplicarDescuento: Asociar descuento a venta → recalcular total');
  }

  @override
  Future<bool> validarOferta(int ofertaId, double montoCompra) async {
    throw UnimplementedError('validarOferta: Verificar vigencia y monto mínimo');
  }

  @override
  Future<void> actualizarEnCascada(int ventaId) async {
    throw UnimplementedError('actualizarEnCascada: Inventario, caja, kardex, cliente, estadísticas');
  }
}
