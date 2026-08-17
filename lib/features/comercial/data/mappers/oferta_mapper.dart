import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/oferta.dart';

class OfertaDataMapper {
  static Oferta toDomain(OfertaData data) {
    return Oferta(
      id: data.id,
      nombre: data.nombre,
      productoId: data.productoId,
      cantidadMinima: data.cantidadMinima,
      precioOferta: data.precioOferta,
      vigenciaDesde: data.vigenciaDesde,
      vigenciaHasta: data.vigenciaHasta,
      estado: data.estado,
    );
  }
}

extension OfertaDataEntityMapper on OfertaData {
  Oferta toEntity() {
    return Oferta(
      id: id,
      nombre: nombre,
      productoId: productoId,
      cantidadMinima: cantidadMinima,
      precioOferta: precioOferta,
      vigenciaDesde: vigenciaDesde,
      vigenciaHasta: vigenciaHasta,
      estado: estado,
    );
  }
}
