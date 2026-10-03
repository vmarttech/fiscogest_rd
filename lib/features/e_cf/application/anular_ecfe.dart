import 'package:fiscogest_rd/features/e_cf/data/repositories/ecfe_repository.dart';
import 'package:fiscogest_rd/features/e_cf/domain/enums/estado_ecf_interno.dart';

class AnularEcfeResultado {
  const AnularEcfeResultado({required this.ok, this.errores = const []});
  final bool ok;
  final List<String> errores;
}

/// Anulación interna de control: marca el documento como anulado y deja
/// constancia del motivo. No sustituye el procedimiento formal DGII de
/// invalidación cuando aplique; sí evita reenvíos y deja traza en el negocio.
class AnularEcfe {
  AnularEcfe({required this.repo});
  final EcfeRepository repo;

  Future<AnularEcfeResultado> call({
    required int documentoId,
    required String motivo,
  }) async {
    try {
      final doc = await repo.obtenerPorId(documentoId);
      if (doc == null) {
        return const AnularEcfeResultado(
          ok: false,
          errores: ['Documento no encontrado'],
        );
      }
      if (doc.estado == EstadoEcfInterno.anulado) {
        return const AnularEcfeResultado(
          ok: false,
          errores: ['El documento ya está anulado'],
        );
      }
      if (doc.estado.esTerminalExito) {
        return const AnularEcfeResultado(
          ok: false,
          errores: [
            'Documento aceptado por DGII: la anulación formal requiere '
            'el procedimiento normativo (no solo marca interna). '
            'Usa nota de crédito electrónica si aplica.',
          ],
        );
      }
      await repo.anularDocumento(id: documentoId, motivo: motivo);
      await repo.registrarEvento(
        documentoId: documentoId,
        paso: 'anular',
        ok: true,
        detalle: motivo.trim(),
      );
      return const AnularEcfeResultado(ok: true);
    } catch (e) {
      return AnularEcfeResultado(ok: false, errores: ['$e']);
    }
  }
}
