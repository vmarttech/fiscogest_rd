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
    required String proveedorId,
    required double montoTotal,
    required DateTime fecha,
  }) async {
    // 1. Actualizar inventario (entrada)
    await actualizarInventario.call(
      idProducto: idProducto,
      cantidad: cantidad,
      esEntrada: true,
    );

    // 2. Actualizar costos
    await actualizarCostos.call(
      idProducto: idProducto,
      cantidadAnterior: 0,
      costoUnitarioAnterior: 0,
      cantidadNueva: cantidad.toInt(),
      costoUnitarioNuevo: costoUnitario,
    );

    // 3. Actualizar saldo proveedor
    if (proveedorId.isNotEmpty) {
      await actualizarSaldoProveedor.call(
        proveedorId: proveedorId,
        monto: montoTotal,
        esAdeudo: true,
      );
    }

    // 4. Actualizar caja (egreso por compra)
    await actualizarCaja.call(
      referencia: 'COMPRA-$fecha',
      monto: montoTotal,
      tipo: 'EGRESO',
      descripcion: 'Compra de mercancía',
    );

    // 5. Actualizar estadísticas
    await actualizarEstadisticas.call(
      tipoOperacion: 'COMPRA',
      monto: montoTotal,
      fecha: fecha,
    );

    // 6. Actualizar reportes
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
    required String clienteId,
    required DateTime fecha,
  }) async {
    // 1. Actualizar inventario (salida)
    await actualizarInventario.call(
      idProducto: idProducto,
      cantidad: cantidad,
      esEntrada: false,
    );

    // 2. Actualizar saldo cliente
    if (clienteId.isNotEmpty) {
      await actualizarSaldoCliente.call(
        clienteId: clienteId,
        monto: montoTotal,
        esCargo: true,
      );
    }

    // 3. Actualizar caja (ingreso por venta)
    await actualizarCaja.call(
      referencia: 'VENTA-$fecha',
      monto: montoTotal,
      tipo: 'INGRESO',
      descripcion: 'Venta de mercancía',
    );

    // 4. Actualizar estadísticas
    await actualizarEstadisticas.call(
      tipoOperacion: 'VENTA',
      monto: montoTotal,
      fecha: fecha,
    );

    // 5. Actualizar reportes
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
