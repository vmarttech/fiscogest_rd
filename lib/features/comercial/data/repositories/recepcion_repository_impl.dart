import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_recepcion_repository.dart';

class RecepcionRepositoryImpl implements IRecepcionRepository {
  final _almacen = <String, Recepcion>{};

  @override
  Future<String> crear(Recepcion recepcion) async {
    final fechaCreacion = recepcion.fechaCreacion ?? DateTime.now();
    final recepcionConFechas = recepcion.copyWith(
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaCreacion,
    );
    _almacen[recepcionConFechas.id!] = recepcionConFechas;
    return recepcionConFechas.id!;
  }

  @override
  Future<void> actualizar(Recepcion recepcion) async {
    if (!_almacen.containsKey(recepcion.id)) {
      throw StateError('Recepción no existe: ${recepcion.id}');
    }
    _almacen[recepcion.id!] = recepcion.copyWith(
      fechaActualizacion: DateTime.now(),
    );
  }

  @override
  Future<Recepcion?> obtenerPorId(String id) async {
    return _almacen[id];
  }

  @override
  Future<List<Recepcion>> listarPorCompra(String compraId) async {
    return _almacen.values.where((r) => r.compraId == compraId).toList();
  }

  @override
  Future<List<Recepcion>> listarTodos({DateTime? desde, DateTime? hasta}) async {
    var lista = _almacen.values.toList();
    if (desde != null) {
      lista = lista.where((r) {
        final fecha = r.fechaRecepcion ?? r.fechaCreacion;
        return fecha != null && fecha.isAfter(desde);
      }).toList();
    }
    if (hasta != null) {
      lista = lista.where((r) {
        final fecha = r.fechaRecepcion ?? r.fechaCreacion;
        return fecha != null && fecha.isBefore(hasta);
      }).toList();
    }
    return lista;
  }
}
