import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion.dart';
import 'package:fiscogest_rd/features/comercial/domain/entities/recepcion_elemento.dart';
import 'package:fiscogest_rd/features/comercial/domain/repositories/i_recepcion_repository.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/recepcion/registrar_recepcion.dart';
import 'package:fiscogest_rd/features/comercial/domain/usecases/recepcion/validar_diferencias.dart';

class RecepcionService {
  RecepcionService(this._repo) {
    registrarRecepcion = RegistrarRecepcion(_repo);
    validarDiferencias = ValidarDiferencias();
  }

  final IRecepcionRepository _repo;
  late final RegistrarRecepcion registrarRecepcion;
  late final ValidarDiferencias validarDiferencias;

  Future<int> registrar(Recepcion recepcion, String usuarioResponsable) async {
    final detallesConDiferencia = recepcion.detalles != null
        ? validarDiferencias.ejecutar(recepcion.detalles!)
        : <DetalleRecepcion>[];
    final recepcionValidada = recepcion.copyWith(
      detalles: detallesConDiferencia,
    );
    return registrarRecepcion.ejecutar(recepcionValidada, usuarioResponsable);
  }
}
