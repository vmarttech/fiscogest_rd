import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/pago.dart';

class PagoDataMapper {
  static CobrosTableCompanion toCompanion(Pago entidad, double saldoAnterior, double saldoActual) {
    return CobrosTableCompanion(
      cuentaCobrarId: Value(entidad.cuentaCobrarId),
      fecha: Value(entidad.fecha),
      montoAbonado: Value(entidad.monto),
      formaPago: Value(entidad.formaPago),
      saldoAnterior: Value(saldoAnterior),
      saldoActual: Value(saldoActual),
    );
  }

  static Pago toDomain(CobroData data, {required int clienteId, String? observaciones}) {
    return Pago(
      id: data.id,
      cuentaCobrarId: data.cuentaCobrarId,
      clienteId: clienteId,
      fecha: data.fecha,
      monto: data.montoAbonado,
      formaPago: data.formaPago,
      referencia: null,
      observaciones: observaciones,
      createdAt: null,
    );
  }
}

extension CobroDataEntityMapper on CobroData {
  Pago toEntity({
    required int clienteId,
    String? observaciones,
  }) {
    return Pago(
      id: id,
      cuentaCobrarId: cuentaCobrarId,
      clienteId: clienteId,
      fecha: fecha,
      monto: montoAbonado,
      formaPago: formaPago,
      referencia: null,
      observaciones: observaciones,
      createdAt: null,
    );
  }
}
