import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/features/ventas/domain/entities/venta.dart';
import 'package:fiscogest_rd/features/ventas/domain/repositories/i_ventas_repository.dart';
import 'package:fiscogest_rd/features/ventas/presentation/providers/venta_providers.dart';

class RegistrarVentaUseCase {

  RegistrarVentaUseCase(this._repositorio);
  final IVentasRepository _repositorio;

  Future<Venta> ejecutar(RegistrarVentaState estado) async {
    final venta = Venta(
      numero: '',
      clienteId: estado.clienteId ?? 0,
      nombreCliente: estado.clienteNombre,
      fecha: DateTime.now(),
      detalles: estado.detalles,
      subtotal: estado.subtotal,
      itbis: estado.itbis,
      total: estado.total,
      tipoPago: estado.tipoPago,
      esCredito: estado.esCredito,
      usuarioId: estado.usuarioId,
    );
    return await _repositorio.registrarVenta(venta);
  }

  Future<Venta> call(RegistrarVentaState estado) => ejecutar(estado);
}

final registrarVentaUseCaseProvider = Provider<RegistrarVentaUseCase>((ref) {
  final repositorio = ref.read(ventasRepositoryProvider);
  return RegistrarVentaUseCase(repositorio);
});
