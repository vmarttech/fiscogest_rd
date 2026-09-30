import 'dart:typed_data';
import 'package:fiscogest_rd/core/interfaces/inventario_fisico_repository_interface.dart';

class GenerarReporteUsecase {
  GenerarReporteUsecase(this._repo);
  final InventarioFisicoRepositoryInterface _repo;

  Future<Uint8List> call(int conteoId) async {
    return _repo.generarReporte(conteoId);
  }
}
