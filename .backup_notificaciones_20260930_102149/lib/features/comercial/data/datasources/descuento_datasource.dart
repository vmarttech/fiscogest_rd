import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';

class DescuentoDatasource {
  Map<String, dynamic> entityToMap(Descuento descuento) {
    return {
      'id': descuento.id,
      'tipo': descuento.tipo.name,
      'valor': descuento.valor,
      'motivo': descuento.motivo,
      'estado_autorizacion': descuento.estadoAutorizacion.name,
      'autorizado_por': descuento.autorizadoPor,
      'fecha_registro': descuento.fechaRegistro.toIso8601String(),
      'fecha_autorizacion': descuento.fechaAutorizacion?.toIso8601String(),
      'producto_id': descuento.productoId,
      'es_porcentaje': descuento.esPorcentaje ? 1 : 0,
      'activo': descuento.activo ? 1 : 0,
    };
  }

  Descuento mapToEntity(Map<String, dynamic> mapa) {
    return Descuento(
      id: mapa['id'] as int,
      tipo: TipoDescuento.values.byName((mapa['tipo'] as String).toLowerCase()),
      valor: (mapa['valor'] as num).toDouble(),
      motivo: mapa['motivo'] as String,
      estadoAutorizacion: EstadoAutorizacion.values.byName(
        (mapa['estado_autorizacion'] as String).toLowerCase(),
      ),
      autorizadoPor: mapa['autorizado_por'] as String?,
      fechaRegistro: DateTime.parse(mapa['fecha_registro'] as String),
      fechaAutorizacion: mapa['fecha_autorizacion'] != null
          ? DateTime.parse(mapa['fecha_autorizacion'] as String)
          : null,
      productoId: mapa['producto_id'] as int?,
      esPorcentaje: (mapa['es_porcentaje'] as int) == 1,
      activo: (mapa['activo'] as int) == 1,
    );
  }
}
