import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_pagar_table.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/pagos_proveedor_table.dart';
// ignore: unused_import — necesario para el join con ProveedoresTable
import 'package:fiscogest_rd/features/proveedores/data/dao/proveedores_table.dart';
import 'package:fiscogest_rd/features/comercial/data/enums/comercial_enums.dart';

part 'cuentas_pagar_dao.g.dart';

@DriftAccessor(tables: [CuentasPagarTable, PagosProveedorTable])
class CuentasPagarDao extends DatabaseAccessor<AppDatabase>
    with _$CuentasPagarDaoMixin {
  CuentasPagarDao(super.db);

  Future<List<CuentaPagarConProveedor>> listarCuentasPorPagar({
    PagarEstado? estado,
  }) async {
    final q = select(cuentasPagarTable).join([
      innerJoin(
        proveedoresTable,
        proveedoresTable.id.equalsExp(cuentasPagarTable.proveedorId),
      ),
    ]);
    if (estado != null) {
      q.where(cuentasPagarTable.estado.equals(estado.name));
    }
    final registros = await q.get();
    return registros.map((fila) {
      final cuenta = fila.readTable(cuentasPagarTable);
      final proveedor = fila.readTable(proveedoresTable);
      return CuentaPagarConProveedor(
        cuenta: cuenta,
        nombreProveedor: proveedor.nombreEmpresa,
      );
    }).toList();
  }

  Future<CuentaPagarData?> obtenerCuentaPorId(int cuentaId) async {
    return await (select(cuentasPagarTable)..where((t) => t.id.equals(cuentaId)))
        .getSingleOrNull();
  }

  Future<int> registrarCuentaPagar({
    required int proveedorId,
    required String concepto,
    required double monto,
    required DateTime fechaEmision,
    required DateTime fechaVencimiento,
    TipoGasto tipoGasto = TipoGasto.compra,
    PagarEstado estado = PagarEstado.pendiente,
  }) async {
    return await into(cuentasPagarTable).insert(
      CuentasPagarTableCompanion(
        proveedorId: Value(proveedorId),
        concepto: Value(concepto),
        monto: Value(monto),
        fechaEmision: Value(fechaEmision),
        fechaVencimiento: Value(fechaVencimiento),
        tipoGasto: Value(tipoGasto),
        estado: Value(estado),
      ),
    );
  }

  Future<int> registrarAbono({
    required int cuentaPagarId,
    required int proveedorId,
    required double monto,
    required DateTime fechaPago,
    String formaPago = 'efectivo',
    String? referencia,
    String? nota,
  }) async {
    return await transaction(() async {
      final cuenta = await obtenerCuentaPorId(cuentaPagarId);
      if (cuenta == null) {
        throw StateError('Cuenta por pagar no encontrada');
      }
      final pagosAnteriores = await listarPagosPorCuenta(cuentaPagarId);
      final totalAbonado = pagosAnteriores.fold(0.0, (sum, p) => sum + p.monto);
      final saldoPendiente = cuenta.monto - totalAbonado;
      if (monto <= 0) {
        throw StateError('El monto del abono debe ser mayor a cero');
      }
      if (monto > saldoPendiente) {
        throw StateError('El abono excede el saldo pendiente');
      }
      final pagoId = await into(pagosProveedorTable).insert(
        PagosProveedorTableCompanion(
          cuentaPagarId: Value(cuentaPagarId),
          proveedorId: Value(proveedorId),
          monto: Value(monto),
          fechaPago: Value(fechaPago),
          formaPago: Value(formaPago),
          referencia: Value(referencia),
          nota: Value(nota),
        ),
      );
      final nuevoTotalAbonado = totalAbonado + monto;
      final nuevoSaldo = cuenta.monto - nuevoTotalAbonado;
      final nuevoEstado = nuevoSaldo <= 0
          ? PagarEstado.pagado
          : PagarEstado.parcial;
      await update(cuentasPagarTable).replace(
        CuentasPagarTableCompanion(
          id: Value(cuenta.id),
          proveedorId: Value(cuenta.proveedorId),
          concepto: Value(cuenta.concepto),
          monto: Value(cuenta.monto),
          fechaEmision: Value(cuenta.fechaEmision),
          fechaVencimiento: Value(cuenta.fechaVencimiento),
          tipoGasto: Value(cuenta.tipoGasto),
          estado: Value(nuevoEstado),
        ),
      );
      return pagoId;
    });
  }

  Future<List<PagoProveedorData>> listarPagosPorCuenta(int cuentaPagarId) async {
    return await (select(pagosProveedorTable)
          ..where((t) => t.cuentaPagarId.equals(cuentaPagarId))
          ..orderBy([(t) => OrderingTerm(expression: t.fechaPago, mode: OrderingMode.desc)]))
        .get();
  }

  /// Anula (elimina) la cuenta por pagar asociada a una compra.
  /// Solo se permite si no tiene abonos registrados.
  /// Busca por proveedor + monto + fecha de emisión (tolerancia de 1 día).
  Future<bool> anularCuentaRelacionadaACompra({
    required int proveedorId,
    required double monto,
    required DateTime fechaEmision,
    String? conceptoContiene,
  }) async {
    return await transaction(() async {
      final inicio = DateTime(fechaEmision.year, fechaEmision.month, fechaEmision.day);
      final fin = inicio.add(const Duration(days: 1));

      final query = select(cuentasPagarTable)
        ..where((t) =>
            t.proveedorId.equals(proveedorId) &
            t.monto.equals(monto) &
            t.fechaEmision.isBiggerOrEqualValue(inicio) &
            t.fechaEmision.isSmallerThanValue(fin) &
            t.estado.isIn([PagarEstado.pendiente.name, PagarEstado.parcial.name, PagarEstado.vencido.name]));

      final candidatas = await query.get();

      CuentaPagarData? cuenta;
      if (conceptoContiene != null && conceptoContiene.isNotEmpty) {
        cuenta = candidatas.cast<CuentaPagarData?>().firstWhere(
              (c) => c!.concepto.contains(conceptoContiene),
              orElse: () => candidatas.isNotEmpty ? candidatas.first : null,
            );
      } else if (candidatas.isNotEmpty) {
        cuenta = candidatas.first;
      }

      if (cuenta == null) return false;

      // Verificar que no tenga abonos
      final pagos = await listarPagosPorCuenta(cuenta.id);
      if (pagos.isNotEmpty) {
        throw StateError(
          'No se puede anular la cuenta por pagar #${cuenta.id}: '
          'tiene ${pagos.length} abono(s) registrado(s). '
          'Elimine primero los abonos o registre una nota de crédito.',
        );
      }

      // Eliminar la cuenta (no hay estado "anulado" en el enum actual)
      await (delete(cuentasPagarTable)..where((t) => t.id.equals(cuenta!.id))).go();
      return true;
    });
  }
}

class CuentaPagarConProveedor {
  const CuentaPagarConProveedor({
    required this.cuenta,
    required this.nombreProveedor,
  });
  final CuentaPagarData cuenta;
  final String nombreProveedor;
}
