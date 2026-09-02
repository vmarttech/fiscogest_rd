import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_inventario.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_costos.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_saldo_cliente.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_saldo_proveedor.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_caja.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_estadisticas.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/actualizar_reportes.dart';

class EjecutarActualizacionesComerciales {
  EjecutarActualizacionesComerciales({
    required this.actualizarInventario,
    required this.actualizarCostos,
    required this.actualizarSaldoCliente,
    required this.actualizarSaldoProveedor,
    required this.actualizarCaja,
    required this.actualizarEstadisticas,
    required this.actualizarReportes,
  });

  final ActualizarInventario actualizarInventario;
  final ActualizarCostos actualizarCostos;
  final ActualizarSaldoCliente actualizarSaldoCliente;
  final ActualizarSaldoProveedor actualizarSaldoProveedor;
  final ActualizarCaja actualizarCaja;
  final ActualizarEstadisticas actualizarEstadisticas;
  final ActualizarReportes actualizarReportes;

  Future<void> ejecutarCompra({
    required int idProducto,
    required double cantidad,
    required double costoUnitario,
    required int proveedorId,
    required double montoTotal,
    required DateTime fecha,
  }) async {
    await actualizarInventario.call(
      idProducto: idProducto,
      cantidad: cantidad,
      esEntrada: true,
    );
    await actualizarCostos.call(
      idProducto: idProducto,
      cantidadAnterior: 0,
      costoUnitarioAnterior: 0,
      cantidadNueva: cantidad.toInt(),
      costoUnitarioNuevo: costoUnitario,
    );
    await actualizarSaldoProveedor.call(
      proveedorId: proveedorId,
      monto: montoTotal,
      esAdeudo: true,
    );
    await actualizarCaja.call(
      referencia: 'COMPRA-$fecha',
      monto: montoTotal,
      tipo: 'EGRESO',
      descripcion: 'Compra de mercancía',
    );
    await actualizarEstadisticas.call(
      tipoOperacion: 'COMPRA',
      monto: montoTotal,
      fecha: fecha,
    );
    await actualizarReportes.call(
      tipoOperacion: 'COMPRA',
      fecha: fecha,
      datos: {
        'productoId': idProducto,
        'cantidad': cantidad,
        'costoUnitario': costoUnitario,
        'proveedorId': proveedorId,
        'montoTotal': montoTotal,
      },
    );
  }

  Future<void> ejecutarVenta({
    required int idProducto,
    required double cantidad,
    required double montoTotal,
    required int clienteId,
    required DateTime fecha,
  }) async {
    await actualizarInventario.call(
      idProducto: idProducto,
      cantidad: cantidad,
      esEntrada: false,
    );
    await actualizarSaldoCliente.call(
      clienteId: clienteId,
      monto: montoTotal,
      esCargo: true,
    );
    await actualizarCaja.call(
      referencia: 'VENTA-$fecha',
      monto: montoTotal,
      tipo: 'INGRESO',
      descripcion: 'Venta de mercancía',
    );
    await actualizarEstadisticas.call(
      tipoOperacion: 'VENTA',
      monto: montoTotal,
      fecha: fecha,
    );
    await actualizarReportes.call(
      tipoOperacion: 'VENTA',
      fecha: fecha,
      datos: {
        'productoId': idProducto,
        'cantidad': cantidad,
        'montoTotal': montoTotal,
        'clienteId': clienteId,
      },
    );
  }
}
