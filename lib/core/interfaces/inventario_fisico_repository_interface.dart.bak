import 'dart:typed_data';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';

abstract class InventarioFisicoRepositoryInterface {
  Future<void> registrarConteo(ConteoFisico conteo);
  Future<List<ConteoFisico>> listarConteos();
  Future<List<DiferenciaConteo>> listarDiferencias(int conteoId);
  Future<void> aprobarAjustes(int conteoId, int usuarioId);
  Future<Uint8List> generarReporte(int conteoId);
}
