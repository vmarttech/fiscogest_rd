import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/descuento.dart';

class DescuentoDataMapper {
  static Descuento toDomain(DescuentoData data) {
    return Descuento(
      id: data.id,
      nombre: data.nombre,
      tipo: data.tipo,
      valor: data.valor,
      aplicaA: data.aplicaA,
      referenciaId: data.referenciaId,
      vigenciaDesde: data.vigenciaDesde,
      vigenciaHasta: data.vigenciaHasta,
      estado: data.estado,
    );
  }
}

extension DescuentoDataEntityMapper on DescuentoData {
  Descuento toEntity() {
    return Descuento(
      id: id,
      nombre: nombre,
      tipo: tipo,
      valor: valor,
      aplicaA: aplicaA,
      referenciaId: referenciaId,
      vigenciaDesde: vigenciaDesde,
      vigenciaHasta: vigenciaHasta,
      estado: estado,
    );
  }
}
