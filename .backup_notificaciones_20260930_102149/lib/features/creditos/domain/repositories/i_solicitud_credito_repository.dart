import 'package:fiscogest_rd/features/creditos/domain/entities/solicitud_credito_expediente.dart';

abstract class ISolicitudCreditoRepository {
  Future<SolicitudCreditoExpediente> obtenerOCrearPorVenta({
    required int ventaId,
    String nombreInicial = '',
    int? clienteId,
    int usuarioId = 1,
  });

  Future<void> guardar(SolicitudCreditoExpediente expediente);
}
