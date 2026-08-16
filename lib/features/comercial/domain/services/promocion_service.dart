import 'package:fiscogest_rd/features/comercial/domain/entities/promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_promocion_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/validar_promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/aplicar_promocion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/promocion/listar_promociones_activas.dart';

class PromocionService {

  PromocionService(this._repositorio)
      : _validador = ValidarPromocion(),
        _aplicador = const AplicarPromocion(),
        _listarActivas = ListarPromocionesActivas(_repositorio);
  final IPromocionRepository _repositorio;
  final ValidarPromocion _validador;
  final AplicarPromocion _aplicador;
  final ListarPromocionesActivas _listarActivas;

  Future<List<Promocion>> listarActivas({DateTime? fecha}) {
    return _listarActivas.ejecutar(fechaReferencia: fecha);
  }

  Future<Promocion?> obtenerPorId(String id) {
    return _repositorio.obtenerPorId(id);
  }

  Future<Promocion> crear(Promocion promocion) {
    return _repositorio.crear(promocion);
  }

  Future<Promocion> actualizar(Promocion promocion) {
    return _repositorio.actualizar(promocion);
  }

  Future<void> eliminar(String id) {
    return _repositorio.eliminar(id);
  }

  bool validar({
    required Promocion promocion,
    required List<LineaVenta> lineas,
    DateTime? fecha,
    String? categoriaCliente,
  }) {
    return _validador.ejecutar(
      promocion: promocion,
      lineas: lineas,
      fechaReferencia: fecha,
      categoriaCliente: categoriaCliente,
    );
  }

  Future<ResultadoDescuento> aplicarMejorPromocion({
    required List<LineaVenta> lineas,
    String? categoriaCliente,
    DateTime? fecha,
  }) async {
    final activas = await listarActivas(fecha: fecha);
    ResultadoDescuento mejor = const ResultadoDescuento(
      montoDescuento: 0.0,
      tipoPromocionAplicada: 'ninguna',
    );

    for (final promo in activas) {
      final resultado = _aplicador.ejecutar(
        promocion: promo,
        lineas: lineas,
        categoriaCliente: categoriaCliente,
      );
      if (resultado.montoDescuento > mejor.montoDescuento) {
        mejor = resultado;
      }
    }

    return mejor;
  }
}
