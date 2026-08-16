import 'package:fiscogest_rd/core/eventos/eventos_sistema.dart';
import 'package:fiscogest_rd/core/eventos/evento_bus.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/detalle_compra.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/registrar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/confirmar_compra_usecase.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/compra/listar_compras_usecase.dart';

/// Servicio de dominio: Coordina operaciones de Compra.
///
/// Orquesta casos de uso y dispara eventos de dominio
/// para actualizaciones automáticas tras confirmación.
class CompraService {
  CompraService({
    required RegistrarCompraUseCase registrarCompra,
    required ConfirmarCompraUseCase confirmarCompra,
    required ListarComprasUseCase listarCompras,
  })  : _registrarCompra = registrarCompra,
        _confirmarCompra = confirmarCompra,
        _listarCompras = listarCompras;

  final RegistrarCompraUseCase _registrarCompra;
  final ConfirmarCompraUseCase _confirmarCompra;
  final ListarComprasUseCase _listarCompras;

  Future<Compra> registrarCompra({
    required Compra compra,
    required List<DetalleCompra> detalles,
  }) async {
    final compraRegistrada = await _registrarCompra(
      compra: compra,
      detalles: detalles,
    );
    return compraRegistrada;
  }

  Future<Compra> confirmarCompra(String compraId) async {
    final compraConfirmada = await _confirmarCompra(compraId);
    EventoBus.emitir(EventosSistema.compraConfirmada, { 'compraId': compraId });
    return compraConfirmada;
  }

  Future<List<Compra>> listarCompras() async {
    return _listarCompras();
  }
}
