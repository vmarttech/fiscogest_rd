import 'package:fiscogest_rd/features/reportes/domain/usecases/generar_reporte_ventas.dart';
import 'package:fiscogest_rd/features/reportes/domain/usecases/generar_reporte_compras.dart';
import 'package:fiscogest_rd/features/reportes/domain/usecases/generar_reporte_utilidades.dart';
import 'package:fiscogest_rd/features/reportes/domain/usecases/generar_reporte_clientes.dart';
import 'package:fiscogest_rd/features/reportes/domain/usecases/generar_reporte_proveedores.dart';
import 'package:fiscogest_rd/features/reportes/domain/usecases/generar_reporte_productos.dart';

class GenerarReporteComercial {
  GenerarReporteComercial(
    this._ventas,
    this._compras,
    this._utilidades,
    this._clientes,
    this._proveedores,
    this._productos,
  );
  final GenerarReporteVentas _ventas;
  final GenerarReporteCompras _compras;
  final GenerarReporteUtilidades _utilidades;
  final GenerarReporteClientes _clientes;
  final GenerarReporteProveedores _proveedores;
  final GenerarReporteProductos _productos;

  Future<Map<String, dynamic>> call({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final resultadoVentas = await _ventas(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final resultadoCompras = await _compras(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final resultadoUtilidades = await _utilidades(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final resultadoClientes = await _clientes(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final resultadoProveedores = await _proveedores(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    final resultadoProductos = await _productos(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );

    return {
      'periodo': {'desde': fechaInicio, 'hasta': fechaFin},
      'ventas': resultadoVentas,
      'compras': resultadoCompras,
      'utilidades': resultadoUtilidades,
      'clientes': resultadoClientes,
      'proveedores': resultadoProveedores,
      'productos': resultadoProductos,
    };
  }
}
