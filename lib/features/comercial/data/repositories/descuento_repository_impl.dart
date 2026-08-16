import 'package:fiscogest_rd/features/comercial/domain/entities/descuento.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_descuento_repository.dart';
import 'package:fiscogest_rd/features/comercial/data/datasources/descuento_datasource.dart';

class DescuentoRepositoryImpl implements IDescuentoRepository {

  DescuentoRepositoryImpl(this._datasource);
  final DescuentoDatasource _datasource;

  @override
  Future<Descuento> guardarDescuento(Descuento descuento) async {
    _datasource.entityToMap(descuento);
    return descuento;
  }

  @override
  Future<Descuento?> obtenerPorId(String id) async => null;

  @override
  Future<List<Descuento>> listarDescuentosActivos() async => [];

  @override
  Future<bool> validarDescuento(Descuento descuento) async {
    if (descuento.estadoAutorizacion == EstadoAutorizacion.denegado) return false;
    if (descuento.valor <= 0) return false;
    if (descuento.esPorcentaje && descuento.valor > 100) return false;
    return true;
  }

  @override
  Future<double> aplicarDescuento({
    required Descuento descuento,
    required double montoOriginal,
  }) async {
    final esValido = await validarDescuento(descuento);
    if (!esValido) return montoOriginal;

    if (descuento.esPorcentaje) {
      final porcentaje = descuento.valor / 100;
      return montoOriginal - (montoOriginal * porcentaje);
    } else {
      final montoFinal = montoOriginal - descuento.valor;
      return montoFinal > 0 ? montoFinal : 0;
    }
  }

  @override
  Future<Descuento> autorizarDescuento({
    required String descuentoId,
    required String usuarioAutorizadorId,
  }) async {
    return Descuento(
      id: descuentoId,
      tipo: TipoDescuento.porFactura,
      valor: 0,
      motivo: '',
      estadoAutorizacion: EstadoAutorizacion.autorizado,
      autorizadoPor: usuarioAutorizadorId,
      fechaRegistro: DateTime.now(),
      fechaAutorizacion: DateTime.now(),
    );
  }
}
