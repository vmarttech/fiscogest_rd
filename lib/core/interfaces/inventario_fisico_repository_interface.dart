import 'dart:typed_data';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/conteo_fisico.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/diferencia_conteo.dart';
import 'package:fiscogest_rd/features/inventario_fisico/domain/entities/estado_conteo.dart';

abstract class InventarioFisicoRepositoryInterface {
  Future<void> registrarConteo(ConteoFisico conteo);
  Future<List<ConteoFisico>> listarConteos();
  Future<List<DiferenciaConteo>> listarDiferencias(int conteoId);
  Future<void> guardarDiferencia(DiferenciaConteo dif);
  Future<void> aprobarAjustes(int conteoId, int usuarioId);
  Future<void> actualizarEstadoConteo(int conteoId, EstadoConteo estado);
  Future<Uint8List> generarReporte(int conteoId);
}
